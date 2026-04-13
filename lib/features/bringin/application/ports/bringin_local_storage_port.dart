import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';

/// Port (interface) for local storage operations
abstract class BringinLocalStoragePort {
  // Buy connections (single)
  Future<void> storeBuyConnection(BringinBuyConnection connection);
  Future<BringinBuyConnection?> getStoredBuyConnection();
  Future<void> removeBuyConnection();
  Future<bool> hasStoredBuyConnection();

  // Sell connections (list — multiple beneficiaries)
  Future<void> addSellConnection(BringinSellConnection connection);
  Future<List<BringinSellConnection>> getSellConnections();
  Future<void> removeSellConnection(String bringinLinkId);
  Future<bool> hasSellConnections();
}
