import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';

/// Loads all stored Bringin Sell connections (beneficiaries list).
class GetStoredBringinSellConnectionUsecase {
  final BringinLocalStoragePort _localStorage;

  GetStoredBringinSellConnectionUsecase({
    required BringinLocalStoragePort localStorage,
  }) : _localStorage = localStorage;

  Future<List<BringinSellConnection>> execute() async {
    try {
      return await _localStorage.getSellConnections();
    } catch (e) {
      throw ConnectionStorageError(e.toString());
    }
  }
}
