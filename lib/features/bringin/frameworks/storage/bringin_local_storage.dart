import 'dart:convert';

import 'package:bb_mobile/core/storage/data/datasources/key_value_storage/key_value_storage_datasource.dart';
import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';

/// Local storage for Bringin Connect connections
class BringinLocalStorage implements BringinLocalStoragePort {
  final KeyValueStorageDatasource<String> _secureStorage;
  static const String _buyKey = 'bringin_buy_connection';
  static const String _sellKey = 'bringin_sell_connections';

  BringinLocalStorage({
    required KeyValueStorageDatasource<String> secureStorage,
  }) : _secureStorage = secureStorage;

  // --- Buy (single) ---

  @override
  Future<void> storeBuyConnection(BringinBuyConnection connection) async {
    final json = {
      'depositIban': connection.depositIban,
      'bringinLinkId': connection.bringinLinkId,
      'btcAddress': connection.btcAddress,
      'walletId': connection.walletId,
      'createdAt': connection.createdAt?.toIso8601String(),
    };
    await _secureStorage.saveValue(key: _buyKey, value: jsonEncode(json));
  }

  @override
  Future<BringinBuyConnection?> getStoredBuyConnection() async {
    final jsonString = await _secureStorage.getValue(_buyKey);
    if (jsonString == null) return null;

    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    return BringinBuyConnection(
      depositIban: json['depositIban'] as String,
      bringinLinkId: json['bringinLinkId'] as String,
      btcAddress: json['btcAddress'] as String,
      walletId: json['walletId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  Future<void> removeBuyConnection() async {
    await _secureStorage.deleteValue(_buyKey);
  }

  @override
  Future<bool> hasStoredBuyConnection() async {
    return await _secureStorage.hasValue(_buyKey);
  }

  // --- Sell (list — multiple beneficiaries) ---

  @override
  Future<void> addSellConnection(BringinSellConnection connection) async {
    final existing = await getSellConnections();
    existing.add(connection);
    await _saveSellConnections(existing);
  }

  @override
  Future<List<BringinSellConnection>> getSellConnections() async {
    final jsonString = await _secureStorage.getValue(_sellKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((item) {
      final json = item as Map<String, dynamic>;
      return BringinSellConnection(
        depositAddress: json['depositAddress'] as String,
        bringinLinkId: json['bringinLinkId'] as String,
        walletId: json['walletId'] as String,
        iban: json['iban'] as String?,
        bic: json['bic'] as String?,
        beneficiaryName: json['beneficiaryName'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
    }).toList();
  }

  @override
  Future<void> removeSellConnection(String bringinLinkId) async {
    final existing = await getSellConnections();
    existing.removeWhere((c) => c.bringinLinkId == bringinLinkId);
    if (existing.isEmpty) {
      await _secureStorage.deleteValue(_sellKey);
    } else {
      await _saveSellConnections(existing);
    }
  }

  @override
  Future<bool> hasSellConnections() async {
    final connections = await getSellConnections();
    return connections.isNotEmpty;
  }

  Future<void> _saveSellConnections(
    List<BringinSellConnection> connections,
  ) async {
    final jsonList = connections.map((c) => {
      'depositAddress': c.depositAddress,
      'bringinLinkId': c.bringinLinkId,
      'walletId': c.walletId,
      'iban': c.iban,
      'bic': c.bic,
      'beneficiaryName': c.beneficiaryName,
      'createdAt': c.createdAt?.toIso8601String(),
    }).toList();
    await _secureStorage.saveValue(
      key: _sellKey,
      value: jsonEncode(jsonList),
    );
  }
}
