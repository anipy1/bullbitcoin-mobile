import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:bip39_mnemonic/bip39_mnemonic.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shooter_core/shooter_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum EntropyRoundPhase {
  idle,
  connecting,

  /// Paired-connection flow: the game showed a PIN, waiting for the user
  /// to type it here.
  pinEntry,
  connected,
  playing,
  done,
  failed,
}

/// Drives one "interactive entropy" round: the phone acts as the Desert
/// Shooter gun controller while the raw accelerometer stream is buffered
/// locally as a supplemental entropy source for a new BIP39 seed.
///
/// Security model (defense in depth, never a downgrade):
/// - Only the *smoothed aim* and discrete fire events cross the WebSocket;
///   the raw sample buffer never leaves this object or the device.
/// - The seed entropy is `SHA-256(raw samples ‖ 32 CSPRNG bytes)` truncated
///   to 128 bits, so even an attacker who recorded every wire frame — or a
///   sensor that produced nothing unpredictable — still faces the full
///   strength of the platform CSPRNG. Motion can only add, never subtract.
class InteractiveEntropyService extends ChangeNotifier {
  InteractiveEntropyService({this.roundDuration = const Duration(seconds: 60)});

  static const _codec = GunMessageCodec();

  /// The round must gather at least this many samples (50 Hz for a full
  /// round is ~3000) and show real motion before entropy is accepted.
  static const int minSamples = 1200;

  /// Minimum standard deviation of user-acceleration magnitude (in G) over
  /// the round. A phone lying on a table shows < 0.01; active play is > 0.3.
  static const double minMotionStdDev = 0.08;

  final Duration roundDuration;

  final GunAim _aim = GunAim();
  final RecoilDetector _recoil = RecoilDetector();
  final Stopwatch _clock = Stopwatch()..start();

  WebSocketChannel? _channel;
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  int? _lastGyroUs;
  Timer? _sendTimer;
  Timer? _roundTimer;
  Timer? _tickTimer;

  /// Raw sensor stream buffer — full float64 bits of every axis plus a
  /// microsecond timestamp per sample. Local only, wiped after use.
  final BytesBuilder _raw = BytesBuilder(copy: false);

  // Welford accumulators over user-acceleration magnitude, for the
  // motion health check.
  int _statN = 0;
  double _statMean = 0;
  double _statM2 = 0;
  double _gx = 0, _gy = 0, _gz = 1;

  EntropyRoundPhase phase = EntropyRoundPhase.idle;
  String statusText = 'Not connected';
  double aimX = 0, aimY = 0;
  int samplesCollected = 0;
  int shotsFired = 0;
  int secondsLeft = 0;
  List<String>? mnemonicWords;

  void Function(double strength)? onShot;

  double _lastAx = 0, _lastAy = 0, _lastAz = 1;
  int _aimSeq = 0;

  /// Aim low-pass factor; retunable live by a [TuneMessage] from the game.
  /// Tuning only touches the gameplay path — the raw entropy buffer records
  /// unfiltered sensor values regardless of these settings.
  double _smooth = 0.3;

  void _applyTune(TuneMessage t) {
    _aim
      ..gainX = t.gainX
      ..gainY = t.gainY
      ..deadzone = t.deadzone;
    _smooth = t.smooth;
  }

  bool get isPlaying => phase == EntropyRoundPhase.playing;

  /// Set while a paired-connection flow is in progress.
  String? _pendingToken;

  /// Attempts left after a wrong PIN, for the entry screen's error line.
  int? pinAttemptsLeft;

  /// Parses a scanned pairing QR and starts the paired connection.
  /// Returns false when the code isn't a valid game pairing QR.
  bool connectWithQr(String data) {
    final qr = decodePairingQr(data);
    if (qr == null) return false;
    connect(qr.wsUrl, token: qr.token);
    return true;
  }

  /// Sends the PIN the user read off the game screen.
  void submitPin(String pin) {
    if (phase != EntropyRoundPhase.pinEntry) return;
    _channel?.sink.add(_codec.encode(PairPinMessage(pin: pin.trim())));
  }

  /// [token] non-null = QR pairing flow (Entropy Shooter); null = legacy
  /// hello flow (old desert_shooter game, manual IP entry).
  void connect(String host, {String? token}) {
    var target = host.trim();
    if (target.isEmpty) return;
    if (!target.startsWith('ws://')) target = 'ws://$target';
    if (!RegExp(r':\d+$').hasMatch(target)) target = '$target:8766';
    _closeChannel();
    _pendingToken = token;
    pinAttemptsLeft = null;
    phase = EntropyRoundPhase.connecting;
    statusText = 'Connecting…';
    notifyListeners();
    try {
      final ch = WebSocketChannel.connect(Uri.parse(target));
      _channel = ch;
      ch.ready
          .then((_) {
            if (!identical(_channel, ch)) return;
            final pending = _pendingToken;
            if (pending != null) {
              // Paired flow: request candidacy; the game reveals a PIN.
              ch.sink.add(
                _codec.encode(
                  PairRequestMessage(
                    token: pending,
                    device: Platform.localHostname,
                  ),
                ),
              );
              phase = EntropyRoundPhase.pinEntry;
              statusText = 'Enter the PIN shown on the game screen';
            } else {
              phase = EntropyRoundPhase.connected;
              statusText = 'Linked to ${target.replaceFirst('ws://', '')}';
              ch.sink.add(
                _codec.encode(HelloMessage(device: Platform.localHostname)),
              );
            }
            notifyListeners();
          })
          .catchError((Object e) {
            if (!identical(_channel, ch)) return;
            phase = EntropyRoundPhase.idle;
            statusText = 'Failed: $e';
            notifyListeners();
          });
      ch.stream.listen(
        (data) {
          if (data is! String) return;
          switch (_codec.decode(data)) {
            case TuneMessage tune:
              _applyTune(tune);
            case RecenterMessage():
              recenter();
            case PairResultMessage(:final ok, :final attemptsLeft):
              if (ok) {
                _pendingToken = null;
                pinAttemptsLeft = null;
                phase = EntropyRoundPhase.connected;
                statusText = 'Paired with the game';
                // Hello from the paired socket fetches the tune echo.
                ch.sink.add(
                  _codec.encode(HelloMessage(device: Platform.localHostname)),
                );
              } else {
                pinAttemptsLeft = attemptsLeft;
                statusText = 'Wrong PIN. $attemptsLeft attempts left';
              }
              notifyListeners();
            default:
              break;
          }
        },
        onDone: () {
          if (identical(_channel, ch)) _onLinkLost();
        },
        onError: (_) {
          if (identical(_channel, ch)) _onLinkLost();
        },
      );
    } catch (e) {
      phase = EntropyRoundPhase.idle;
      statusText = 'Failed: $e';
      notifyListeners();
    }
  }

  void _onLinkLost() {
    final wasPairing = phase == EntropyRoundPhase.pinEntry;
    _closeChannel();
    // Losing the game mid-round doesn't invalidate the entropy (the game
    // never contributes any); the round simply continues headless.
    if (wasPairing) {
      // Session rejected/renewed on the game side: rescan.
      _pendingToken = null;
      phase = EntropyRoundPhase.failed;
      statusText = 'Pairing rejected. Scan the QR code again';
      notifyListeners();
    } else if (!isPlaying) {
      phase = EntropyRoundPhase.idle;
      statusText = 'Not connected';
      notifyListeners();
    } else {
      statusText = 'Game link lost. Keep moving, entropy still counts';
      notifyListeners();
    }
  }

  /// Back to the connect view (e.g. to rescan after a pairing rejection).
  void resetToIdle() {
    _closeChannel();
    _pendingToken = null;
    pinAttemptsLeft = null;
    phase = EntropyRoundPhase.idle;
    statusText = 'Not connected';
    notifyListeners();
  }

  void startRound() {
    if (phase == EntropyRoundPhase.connecting ||
        phase == EntropyRoundPhase.pinEntry ||
        isPlaying) {
      return;
    }
    _raw.clear();
    _statN = 0;
    _statMean = 0;
    _statM2 = 0;
    samplesCollected = 0;
    shotsFired = 0;
    mnemonicWords = null;
    secondsLeft = roundDuration.inSeconds;
    phase = EntropyRoundPhase.playing;
    statusText = 'Round running, shoot!';
    _startSensors();
    _sendTimer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _sendAim(),
    );
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft > 0) secondsLeft--;
      notifyListeners();
    });
    _roundTimer = Timer(roundDuration, _finishRound);
    notifyListeners();
  }

  void recenter() => _aim.calibrate(_lastAx, _lastAy, _lastAz);

  void _startSensors() {
    _accelSub ??=
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 20),
        ).listen((e) {
          final tUs = _clock.elapsedMicroseconds;

          // --- entropy path: raw, unfiltered, local only -------------------
          if (isPlaying) {
            final b = ByteData(32)
              ..setInt64(0, tUs)
              ..setFloat64(8, e.x)
              ..setFloat64(16, e.y)
              ..setFloat64(24, e.z);
            _raw.add(b.buffer.asUint8List());
            samplesCollected++;

            // Welford update on user-acceleration magnitude (gravity removed
            // with the same low-pass idea RecoilDetector uses).
            const k = 0.04;
            final axG = e.x / 9.81, ayG = e.y / 9.81, azG = e.z / 9.81;
            _gx += (axG - _gx) * k;
            _gy += (ayG - _gy) * k;
            _gz += (azG - _gz) * k;
            final ux = axG - _gx, uy = ayG - _gy, uz = azG - _gz;
            final mag = math.sqrt(ux * ux + uy * uy + uz * uz);
            _statN++;
            final d = mag - _statMean;
            _statMean += d / _statN;
            _statM2 += d * (mag - _statMean);
          }

          // --- gameplay path: smoothed aim + recoil, same as the stock
          // desert_shooter controller ---------------------------------------
          final ax = _lastAx = e.x / 9.81;
          final ay = _lastAy = e.y / 9.81;
          final az = _lastAz = e.z / 9.81;
          final (x, y) = _aim.aimFrom(ax, ay, az);
          aimX += (x - aimX) * _smooth;
          aimY += (y - aimY) * _smooth;
          final strength = _recoil.onSample(ax, ay, az, tUs / 1e6);
          if (strength != null && isPlaying) _fire(strength);
        }, onError: (_) {});
    // Yaw (left/right gun swing) is invisible to the accelerometer, so the
    // X axis integrates the gyroscope — see GunAim.gyro. The raw gyro
    // stream is also independent sensor noise, so it feeds the entropy
    // buffer alongside the accelerometer.
    _gyroSub ??=
        gyroscopeEventStream(
          samplingPeriod: const Duration(milliseconds: 20),
        ).listen((e) {
          final t = _clock.elapsedMicroseconds;
          final last = _lastGyroUs;
          _lastGyroUs = t;
          final dt = last == null ? 0.02 : ((t - last) / 1e6).clamp(0.0, 0.1);
          if (isPlaying) {
            final b = ByteData(32)
              ..setInt64(0, -t) // negative timestamp marks a gyro record
              ..setFloat64(8, e.x)
              ..setFloat64(16, e.y)
              ..setFloat64(24, e.z);
            _raw.add(b.buffer.asUint8List());
          }
          _aim.gyro(e.x, e.y, e.z, dt);
        }, onError: (_) {});
  }

  void _sendAim() {
    final ch = _channel;
    if (ch == null) return;
    _aimSeq++;
    ch.sink.add(_codec.encode(AimMessage(x: aimX, y: aimY, seq: _aimSeq)));
  }

  void _fire(double strength) {
    shotsFired++;
    _channel?.sink.add(
      _codec.encode(FireMessage(strength: strength, seq: shotsFired)),
    );
    onShot?.call(strength);
    notifyListeners();
  }

  void _finishRound() {
    _sendTimer?.cancel();
    _tickTimer?.cancel();
    _roundTimer?.cancel();
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;

    final stdDev = _statN > 1 ? math.sqrt(_statM2 / (_statN - 1)) : 0.0;
    if (samplesCollected < minSamples || stdDev < minMotionStdDev) {
      _raw.clear();
      phase = EntropyRoundPhase.failed;
      statusText = samplesCollected < minSamples
          ? 'Not enough sensor samples. Try again'
          : 'Not enough motion detected. Play more energetically';
      notifyListeners();
      return;
    }

    // Condition and mix: SHA-256(raw stream ‖ 32 CSPRNG bytes) -> 128 bits.
    final csprng = Uint8List(32);
    final rng = Random.secure();
    for (var i = 0; i < csprng.length; i++) {
      csprng[i] = rng.nextInt(256);
    }
    final rawBytes = _raw.takeBytes();
    final digest = sha256.convert([...rawBytes, ...csprng]);
    final entropy = digest.bytes.sublist(0, 16);

    mnemonicWords = bip39.Mnemonic(
      entropy,
      bip39.Language.english,
    ).words.toList();
    phase = EntropyRoundPhase.done;
    statusText =
        'Entropy captured ($samplesCollected samples, '
        '$shotsFired shots, motion σ ${stdDev.toStringAsFixed(2)} G)';
    notifyListeners();
  }

  void _closeChannel() {
    _sendTimer?.cancel();
    _sendTimer = null;
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _closeChannel();
    _raw.clear();
    mnemonicWords = null;
    super.dispose();
  }
}
