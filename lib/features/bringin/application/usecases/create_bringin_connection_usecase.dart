import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Stores a new Bringin Buy connection after the widget succeeds.
class CreateBringinConnectionUsecase {
  final BringinLocalStoragePort _localStorage;

  CreateBringinConnectionUsecase({
    required BringinLocalStoragePort localStorage,
  }) : _localStorage = localStorage;

  Future<BringinBuyConnection> execute({
    required String depositIban,
    required String bringinLinkId,
    required String btcAddress,
    required String walletId,
  }) async {
    try {
      final connection = BringinBuyConnection(
        depositIban: depositIban,
        bringinLinkId: bringinLinkId,
        btcAddress: btcAddress,
        walletId: walletId,
        createdAt: DateTime.now(),
      );

      await _localStorage.storeBuyConnection(connection);

      return connection;
    } catch (e) {
      throw ConnectionStorageError(e.toString());
    }
  }
}
