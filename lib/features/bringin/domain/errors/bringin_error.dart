import 'package:bb_mobile/core/errors/bull_exception.dart';

/// Domain-specific errors for Bringin Connect feature
sealed class BringinError extends BullException {
  BringinError(super.message);
}

class NoBitcoinWalletError extends BringinError {
  NoBitcoinWalletError() : super('No default Bitcoin wallet found');
}

class AddressDerivationError extends BringinError {
  AddressDerivationError(String reason)
    : super('Failed to derive BTC address: $reason');
}

class MessageSigningError extends BringinError {
  MessageSigningError(String reason)
    : super('Failed to sign message: $reason');
}

class ConnectionStorageError extends BringinError {
  ConnectionStorageError(String reason)
    : super('Connection storage error: $reason');
}

/// Wrapper for non-domain errors.
/// Used when the BLoC catches something that is not a [BringinError].
class UnexpectedBringinError extends BringinError {
  UnexpectedBringinError(super.reason);
}
