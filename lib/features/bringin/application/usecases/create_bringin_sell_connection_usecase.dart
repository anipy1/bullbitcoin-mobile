import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Stores a new Bringin Sell connection (adds to the list of beneficiaries).
class CreateBringinSellConnectionUsecase {
  final BringinLocalStoragePort _localStorage;

  CreateBringinSellConnectionUsecase({
    required BringinLocalStoragePort localStorage,
  }) : _localStorage = localStorage;

  Future<BringinSellConnection> execute({
    required String depositAddress,
    required String bringinLinkId,
    required String walletId,
    String? iban,
    String? bic,
    String? beneficiaryName,
  }) async {
    try {
      final connection = BringinSellConnection(
        depositAddress: depositAddress,
        bringinLinkId: bringinLinkId,
        walletId: walletId,
        iban: iban,
        bic: bic,
        beneficiaryName: beneficiaryName,
        createdAt: DateTime.now(),
      );

      await _localStorage.addSellConnection(connection);

      return connection;
    } catch (e) {
      throw ConnectionStorageError(e.toString());
    }
  }
}
