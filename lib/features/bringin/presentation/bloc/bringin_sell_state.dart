import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bringin_sell_state.freezed.dart';

@freezed
sealed class BringinSellState with _$BringinSellState {
  const factory BringinSellState({
    /// All stored sell connections (beneficiaries)
    @Default([]) List<BringinSellConnection> connections,

    /// Currently selected connection for the detail view
    BringinSellConnection? selectedConnection,

    /// Whether the initial load is complete
    @Default(false) bool isStarted,

    @Default(false) bool isLoading,

    @Default(false) bool isRemovingConnection,

    /// IBAN input form fields (for native input screen)
    @Default('') String ibanInput,
    @Default('') String bicInput,
    @Default('') String beneficiaryNameInput,

    BringinError? error,
  }) = _BringinSellState;
}
