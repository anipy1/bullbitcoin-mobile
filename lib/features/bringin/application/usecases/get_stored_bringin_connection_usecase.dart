import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Loads a stored Bringin Buy connection from secure storage.
class GetStoredBringinConnectionUsecase {
  final BringinLocalStoragePort _localStorage;

  GetStoredBringinConnectionUsecase({
    required BringinLocalStoragePort localStorage,
  }) : _localStorage = localStorage;

  Future<BringinBuyConnection?> execute() async {
    try {
      return await _localStorage.getStoredBuyConnection();
    } catch (e) {
      throw ConnectionStorageError(e.toString());
    }
  }
}
