import 'package:freezed_annotation/freezed_annotation.dart';

part 'bringin_event.freezed.dart';

@freezed
sealed class BringinEvent with _$BringinEvent {
  /// Check for stored connection; if none, derive address + sign for widget
  const factory BringinEvent.started() = BringinStarted;

  /// Widget returned success — store the connection
  const factory BringinEvent.connectionCreated({
    required String depositIban,
    required String bringinLinkId,
    required String btcAddress,
    required String walletId,
  }) = BringinConnectionCreated;

  /// User wants to remove the stored connection
  const factory BringinEvent.removeConnection() = BringinRemoveConnection;

  const factory BringinEvent.clearError() = BringinClearError;
}
