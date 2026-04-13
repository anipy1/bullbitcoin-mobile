import 'package:bb_mobile/core/wallet/domain/entities/wallet.dart';
import 'package:bb_mobile/core/wallet/domain/usecases/get_address_at_index_usecase.dart';
import 'package:bb_mobile/core/wallet/domain/usecases/get_wallets_usecase.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Result containing the derived BTC address and the wallet it belongs to.
class BringinAddressResult {
  final String btcAddress;
  final Wallet wallet;

  const BringinAddressResult({
    required this.btcAddress,
    required this.wallet,
  });
}

/// Derives the deterministic BTC address at index 0 for the default Bitcoin
/// wallet. This address is permanently linked to the Bringin IBAN.
///
/// Uses m/84'/0'/0'/0/0 (BIP84 native segwit, first external receive address).
class GetBringinAddressUsecase {
  final GetWalletsUsecase _getWalletsUsecase;
  final GetAddressAtIndexUsecase _getAddressAtIndexUsecase;

  GetBringinAddressUsecase({
    required GetWalletsUsecase getWalletsUsecase,
    required GetAddressAtIndexUsecase getAddressAtIndexUsecase,
  }) : _getWalletsUsecase = getWalletsUsecase,
       _getAddressAtIndexUsecase = getAddressAtIndexUsecase;

  Future<BringinAddressResult> execute() async {
    try {
      // Get the default Bitcoin mainnet wallet
      final wallets = await _getWalletsUsecase.execute(
        onlyDefaults: true,
        onlyBitcoin: true,
      );

      if (wallets.isEmpty) {
        throw NoBitcoinWalletError();
      }

      final wallet = wallets.first;

      // Derive address at index 0 — this is deterministic and permanent
      final walletAddress = await _getAddressAtIndexUsecase.execute(
        walletId: wallet.id,
        index: 0,
      );

      return BringinAddressResult(
        btcAddress: walletAddress.address,
        wallet: wallet,
      );
    } on BringinError {
      rethrow;
    } catch (e) {
      throw AddressDerivationError(e.toString());
    }
  }
}
