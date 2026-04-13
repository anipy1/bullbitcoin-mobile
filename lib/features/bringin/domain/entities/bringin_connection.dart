import 'package:freezed_annotation/freezed_annotation.dart';

part 'bringin_connection.freezed.dart';

/// Domain entity representing a Bringin Connect connection.
@freezed
sealed class BringinConnection with _$BringinConnection {
  /// Buy connection: EUR → BTC.
  /// User gets a deposit IBAN; sends EUR to it and receives BTC.
  const factory BringinConnection.buy({
    required String depositIban,
    required String bringinLinkId,
    required String btcAddress,
    required String walletId,
    DateTime? createdAt,
  }) = BringinBuyConnection;

  /// Sell connection: BTC → EUR.
  /// User gets a BTC deposit address; sends BTC to it and receives EUR.
  const factory BringinConnection.sell({
    required String depositAddress,
    required String bringinLinkId,
    required String walletId,
    String? iban,
    String? bic,
    String? beneficiaryName,
    DateTime? createdAt,
  }) = BringinSellConnection;
}
