import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/widgets/qr_scanner_widget.dart';
import 'package:bb_mobile/core/widgets/buttons/button.dart';
import 'package:bb_mobile/core/widgets/text/text.dart';
import 'package:bb_mobile/features/interactive_entropy/interactive_entropy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One round of Desert Shooter played with this phone as the gun; the raw
/// motion of the round hardens the entropy of the new wallet's seed.
///
/// Strings are intentionally hardcoded English for now — this is a prototype
/// feature; run it through the repo's l10n flow before any real release.
class InteractiveEntropyPage extends StatefulWidget {
  const InteractiveEntropyPage({super.key, required this.onCreateWallet});

  /// Consumes the round's mnemonic. Returns null on success (the page then
  /// pops itself) or a user-facing error message to show. Lets the same
  /// round UI serve both onboarding (dispatch to the onboarding bloc) and
  /// the add-a-new-wallet flow (ImportWalletUsecase).
  final Future<String?> Function(List<String> words) onCreateWallet;

  @override
  State<InteractiveEntropyPage> createState() => _InteractiveEntropyPageState();
}

class _InteractiveEntropyPageState extends State<InteractiveEntropyPage> {
  final InteractiveEntropyService _service = InteractiveEntropyService();

  @override
  void initState() {
    super.initState();
    _service.onShot = (_) => HapticFeedback.heavyImpact();
    _service.addListener(_onService);
  }

  void _onService() => setState(() {});

  @override
  void dispose() {
    _service.removeListener(_onService);
    _service.dispose();
    super.dispose();
  }

  bool _creating = false;

  Future<void> _createWallet() async {
    final words = _service.mnemonicWords;
    if (words == null || _creating) return;
    setState(() => _creating = true);
    final error = await widget.onCreateWallet(words);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _creating = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final s = _service;
    return Scaffold(
      backgroundColor: context.appColors.primaryFixed,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.appColors.onPrimaryFixed,
        title: const Text('Interactive entropy'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (s.phase) {
            EntropyRoundPhase.idle ||
            EntropyRoundPhase.connecting => _ConnectView(service: s),
            EntropyRoundPhase.pinEntry => _PinEntryView(service: s),
            EntropyRoundPhase.connected => _ReadyView(service: s),
            EntropyRoundPhase.playing => _PlayingView(service: s),
            EntropyRoundPhase.failed => _FailedView(service: s),
            EntropyRoundPhase.done => _DoneView(
              service: s,
              busy: _creating,
              onCreate: _createWallet,
            ),
          },
        ),
      ),
    );
  }
}

class _ConnectView extends StatelessWidget {
  const _ConnectView({required this.service});
  final InteractiveEntropyService service;

  @override
  Widget build(BuildContext context) {
    final connecting = service.phase == EntropyRoundPhase.connecting;
    final onColor = context.appColors.onPrimaryFixed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.qr_code_scanner,
          size: 72,
          color: onColor.withValues(alpha: 0.9),
        ),
        const SizedBox(height: 24),
        BBText(
          'Play one round of Entropy Shooter using this phone as the gun. '
          'Your motion during the round is mixed into the randomness of '
          'your new wallet. The game itself never sees it.',
          style: context.font.bodyMedium,
          color: onColor,
          maxLines: 6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        BBButton.big(
          label: 'Scan game QR',
          bgColor: context.appColors.secondaryFixed,
          textColor: context.appColors.onSecondaryFixed,
          iconData: Icons.qr_code_scanner,
          disabled: connecting,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _QrScanPage(service: service)),
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: BBText(
            'Start the game on your Mac and point the camera at its QR code',
            style: context.font.labelSmall,
            color: onColor.withValues(alpha: 0.7),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        Center(
          child: BBText(
            service.statusText,
            style: context.font.labelSmall,
            color: onColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.service});
  final InteractiveEntropyService service;

  @override
  Widget build(BuildContext context) {
    final onColor = context.appColors.onPrimaryFixed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.sports_esports, size: 64, color: onColor),
        const SizedBox(height: 16),
        Center(
          child: BBText(
            service.statusText,
            style: context.font.bodyMedium,
            color: onColor,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: BBText(
            'Hold the phone flat like a gun, muzzle at the screen. '
            'Jerk it back to fire. Your aim is already live, so the game '
            'can tune sensitivity before you start.',
            style: context.font.labelSmall,
            color: onColor.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ),
        const Spacer(),
        BBButton.big(
          label: 'Start 60-second round',
          bgColor: context.appColors.secondaryFixed,
          textColor: context.appColors.onSecondaryFixed,
          iconData: Icons.play_arrow,
          onPressed: service.startRound,
        ),
      ],
    );
  }
}

class _PlayingView extends StatelessWidget {
  const _PlayingView({required this.service});
  final InteractiveEntropyService service;

  @override
  Widget build(BuildContext context) {
    final onColor = context.appColors.onPrimaryFixed;
    final total = service.roundDuration.inSeconds;
    final progress = 1 - service.secondsLeft / (total == 0 ? 1 : total);
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                color: context.appColors.secondaryFixed,
                backgroundColor: onColor.withValues(alpha: 0.15),
              ),
              Center(
                child: BBText(
                  '${service.secondsLeft}',
                  style: context.font.displayMedium,
                  color: onColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BBText(
          service.statusText,
          style: context.font.bodyMedium,
          color: onColor,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: 'Shots', value: '${service.shotsFired}'),
            _Stat(label: 'Samples', value: '${service.samplesCollected}'),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: service.recenter,
          child: BBText(
            'Re-center aim',
            style: context.font.bodyMedium,
            color: onColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onColor = context.appColors.onPrimaryFixed;
    return Column(
      children: [
        BBText(value, style: context.font.headlineMedium, color: onColor),
        BBText(
          label,
          style: context.font.labelSmall,
          color: onColor.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.service});
  final InteractiveEntropyService service;

  @override
  Widget build(BuildContext context) {
    final onColor = context.appColors.onPrimaryFixed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 64, color: onColor),
        const SizedBox(height: 16),
        Center(
          child: BBText(
            service.statusText,
            style: context.font.bodyMedium,
            color: onColor,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
        const Spacer(),
        BBButton.big(
          label: 'Try again',
          bgColor: context.appColors.secondaryFixed,
          textColor: context.appColors.onSecondaryFixed,
          iconData: Icons.replay,
          onPressed: service.startRound,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: service.resetToIdle,
          child: BBText(
            'Back to connect',
            style: context.font.bodyMedium,
            color: onColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Full-screen scanner for the game's pairing QR.
class _QrScanPage extends StatefulWidget {
  const _QrScanPage({required this.service});

  final InteractiveEntropyService service;

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _handled = false;
  bool _invalid = false;

  void _onScanned(String data) {
    if (_handled) return;
    if (widget.service.connectWithQr(data)) {
      _handled = true;
      Navigator.of(context).pop();
    } else {
      setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.primaryFixed,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.appColors.onPrimaryFixed,
        title: const Text('Scan the game QR'),
      ),
      body: Stack(
        children: [
          // Full-frame decode: the QR's on-screen size depends on how far
          // the phone is from the Mac, so the default center crop misses it.
          QrScannerWidget(onScanned: _onScanned, cropPercent: 0),
          if (_invalid)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: BBText(
                'Not a game pairing code. Point at the QR on the game '
                'screen',
                style: context.font.bodyMedium,
                color: context.appColors.onPrimaryFixed,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }
}

/// The game shows a 6-digit PIN; the user types it here to finish pairing.
class _PinEntryView extends StatefulWidget {
  const _PinEntryView({required this.service});

  final InteractiveEntropyService service;

  @override
  State<_PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<_PinEntryView> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final onColor = context.appColors.onPrimaryFixed;
    final wrongPin = service.pinAttemptsLeft != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.pin_outlined, size: 64, color: onColor),
        const SizedBox(height: 16),
        Center(
          child: BBText(
            'Enter the PIN shown on the game screen',
            style: context.font.bodyMedium,
            color: onColor,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          style: TextStyle(
            color: onColor,
            fontSize: 32,
            letterSpacing: 12,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(color: onColor.withValues(alpha: 0.3)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: onColor.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: onColor),
            ),
          ),
        ),
        if (wrongPin) ...[
          const SizedBox(height: 12),
          Center(
            child: BBText(
              service.statusText,
              style: context.font.bodyMedium,
              color: context.appColors.secondaryFixed,
            ),
          ),
        ],
        const SizedBox(height: 24),
        BBButton.big(
          label: 'Pair',
          bgColor: context.appColors.secondaryFixed,
          textColor: context.appColors.onSecondaryFixed,
          iconData: Icons.link,
          onPressed: () => service.submitPin(_pin.text),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: service.resetToIdle,
          child: BBText(
            'Cancel',
            style: context.font.bodyMedium,
            color: onColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.service,
    required this.busy,
    required this.onCreate,
  });
  final InteractiveEntropyService service;
  final bool busy;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final onColor = context.appColors.onPrimaryFixed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.verified_user_outlined, size: 64, color: onColor),
        const SizedBox(height: 16),
        Center(
          child: BBText(
            service.statusText,
            style: context.font.bodyMedium,
            color: onColor,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: BBText(
            'Your motion was hashed together with the system\'s secure '
            'random generator. The 12 words stay hidden until you back '
            'them up from settings, like any new wallet.',
            style: context.font.labelSmall,
            color: onColor.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ),
        const Spacer(),
        BBButton.big(
          label: busy ? 'Creating wallet…' : 'Create wallet with this entropy',
          bgColor: context.appColors.secondaryFixed,
          textColor: context.appColors.onSecondaryFixed,
          iconData: Icons.account_balance_wallet_outlined,
          disabled: busy,
          onPressed: onCreate,
        ),
      ],
    );
  }
}
