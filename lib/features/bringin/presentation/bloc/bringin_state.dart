import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bringin_state.freezed.dart';

@freezed
sealed class BringinState with _$BringinState {
  const factory BringinState({
    /// Stored buy connection (null = none exists yet)
    BringinBuyConnection? connection,

    /// Derived BTC address for the widget (m/84'/0'/0'/0/0)
    String? btcAddress,

    /// Wallet ID for the derived address
    String? walletId,

    /// BIP-137 wallet signature for the widget
    String? walletSignature,

    /// Timestamp (Unix ms) included in the signed message
    String? timestamp,

    /// Whether the initial check/load is complete
    @Default(false) bool isStarted,

    @Default(false) bool isLoading,

    @Default(false) bool isRemovingConnection,

    BringinError? error,
  }) = _BringinState;
}
