import 'package:freezed_annotation/freezed_annotation.dart';

part 'bringin_sell_event.freezed.dart';

@freezed
sealed class BringinSellEvent with _$BringinSellEvent {
  /// Load all stored sell connections
  const factory BringinSellEvent.started() = BringinSellStarted;

  /// User selected a beneficiary from the list
  const factory BringinSellEvent.selectConnection({
    required String bringinLinkId,
  }) = BringinSellSelectConnection;

  /// Widget returned success — add to connections list
  const factory BringinSellEvent.connectionCreated({
    required String depositAddress,
    required String bringinLinkId,
    required String walletId,
    String? iban,
    String? bic,
    String? beneficiaryName,
  }) = BringinSellConnectionCreated;

  /// User wants to remove a sell connection
  const factory BringinSellEvent.removeConnection({
    required String bringinLinkId,
  }) = BringinSellRemoveConnection;

  /// IBAN input form field updates
  const factory BringinSellEvent.updateIbanInput(String iban) =
      BringinSellUpdateIbanInput;
  const factory BringinSellEvent.updateBicInput(String bic) =
      BringinSellUpdateBicInput;
  const factory BringinSellEvent.updateBeneficiaryNameInput(String name) =
      BringinSellUpdateBeneficiaryNameInput;

  const factory BringinSellEvent.clearError() = BringinSellClearError;
}
