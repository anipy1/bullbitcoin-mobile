import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Removes a stored Bringin Sell connection by its bringinLinkId.
class RemoveBringinSellConnectionUsecase {
  final BringinLocalStoragePort _localStorage;

  RemoveBringinSellConnectionUsecase({
    required BringinLocalStoragePort localStorage,
  }) : _localStorage = localStorage;

  Future<void> execute(String bringinLinkId) async {
    try {
      await _localStorage.removeSellConnection(bringinLinkId);
    } catch (e) {
      throw ConnectionStorageError(e.toString());
    }
  }
}
