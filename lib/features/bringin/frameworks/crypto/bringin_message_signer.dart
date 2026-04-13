import 'dart:typed_data';

import 'package:bb_mobile/core/wallet/domain/entities/wallet.dart';
import 'package:bip32_keys/bip32_keys.dart' as bip32;
import 'package:bitcoin_base/bitcoin_base.dart';

/// Signs messages for Bringin Connect using BIP-137 wallet signature (Mode 3a).
///
/// Derives the private key at m/84'/0'/0'/0/0 from the seed and signs the
/// canonical message format required by Bringin Connect.
class BringinMessageSigner {
  /// Constructs the canonical message for Bringin Connect signing.
  ///
  /// Params are sorted alphabetically by key and joined as key=value&key=value.
  /// Example: "btcAddress=bc1q...&currency=BTC&network=BTC"
  static String buildCanonicalMessage(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys.map((k) => '$k=${params[k]}').join('&');
  }

  /// Signs a message using BIP-137 format with the private key at the
  /// Bringin-designated derivation path (m/84'/0'/0'/0/0).
  ///
  /// Returns a Base64-encoded BIP-137 signature string suitable for passing
  /// as `walletSignature` to the Bringin Connect widget.
  static String signBip137({
    required Uint8List seedBytes,
    required String message,
    required Network network,
  }) {
    // Derive the private key at m/84'/{coinType}'/0'/0/0
    final nw = network == Network.bitcoinTestnet
        ? bip32.NetworkType(
            wif: 0x80,
            bip32:
                bip32.Bip32Type(public: 0x043587CF, private: 0x04358394),
          )
        : null;
    final root = bip32.Bip32Keys.fromSeed(seedBytes, network: nw);
    final coinType = network == Network.bitcoinTestnet ? 1 : 0;
    final derivationPath = "m/84'/$coinType'/0'/0/0";
    final derivedKey = root.derivePath(derivationPath);

    // Get the raw private key bytes (32 bytes)
    final privateKeyBytes = derivedKey.private;
    if (privateKeyBytes == null) {
      throw StateError('Failed to derive private key');
    }

    // Create ECPrivate from bitcoin_base and sign using BIP-137
    // Use p2pkhCompressed (header 31-34) as most BIP-137 verifiers
    // (including Bringin) expect this mode regardless of address type.
    final ecPrivate = ECPrivate.fromBytes(privateKeyBytes);
    final signature = ecPrivate.signBip137(
      message.codeUnits,
      mode: BIP137Mode.p2pkhCompressed,
    );

    return signature;
  }
}
