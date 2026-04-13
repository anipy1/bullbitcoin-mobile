import 'package:bb_mobile/core/seed/data/repository/seed_repository.dart';
import 'package:bb_mobile/core/utils/logger.dart';
import 'package:bb_mobile/core/wallet/domain/entities/wallet.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';
import 'package:bb_mobile/features/bringin/frameworks/crypto/bringin_message_signer.dart';

/// Constructs the canonical message from widget params and signs it using
/// BIP-137 with the wallet's private key at m/84'/0'/0'/0/0.
///
/// Mode 3a canonical message: `btcAddress=bc1q...&currency=BTC&network=BTC`
/// No timestamp — timestamp is only for Mode 2 (HMAC).
class SignBringinMessageUsecase {
  final SeedRepository _seedRepository;

  SignBringinMessageUsecase({required SeedRepository seedRepository})
    : _seedRepository = seedRepository;

  /// Signs the Bringin Connect canonical message for the given wallet and
  /// BTC address. Returns a Base64-encoded BIP-137 signature.
  Future<String> execute({
    required Wallet wallet,
    required String btcAddress,
  }) async {
    try {
      // Build canonical message: params sorted alphabetically (NO timestamp for Mode 3a)
      final params = {
        'btcAddress': btcAddress,
        'currency': 'BTC',
        'direction': 'FIAT_TO_CRYPTO',
        'network': 'BTC',
      };
      final message = BringinMessageSigner.buildCanonicalMessage(params);
      log.info('[Bringin] Canonical message to sign: $message');

      // Get the seed for this wallet
      final seed = await _seedRepository.get(wallet.masterFingerprint);

      // Sign using BIP-137 with the private key at m/84'/0'/0'/0/0
      final signature = BringinMessageSigner.signBip137(
        seedBytes: seed.bytes,
        message: message,
        network: wallet.network,
      );

      log.info('[Bringin] BIP-137 signature: $signature');

      return signature;
    } catch (e) {
      throw MessageSigningError(e.toString());
    }
  }
}
