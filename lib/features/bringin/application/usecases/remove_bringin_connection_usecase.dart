import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Removes a stored Bringin connection.
class RemoveBringinConnectionUsecase {
  final BringinLocalStoragePort _localStorage;

  RemoveBringinConnectionUsecase({
    required BringinLocalStoragePort localStorage,
  }) : _localStorage = localStorage;

  Future<void> execute() async {
    try {
      await _localStorage.removeBuyConnection();
    } catch (e) {
      throw ConnectionStorageError(e.toString());
    }
  }
}
