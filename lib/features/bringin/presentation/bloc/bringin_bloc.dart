import 'package:bb_mobile/core/utils/logger.dart';
import 'package:bb_mobile/features/bringin/application/usecases/create_bringin_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/get_bringin_address_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/get_stored_bringin_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/remove_bringin_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/sign_bringin_message_usecase.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bringin_event.dart';
import 'bringin_state.dart';

class BringinBloc extends Bloc<BringinEvent, BringinState> {
  final GetBringinAddressUsecase _getBringinAddressUsecase;
  final SignBringinMessageUsecase _signBringinMessageUsecase;
  final CreateBringinConnectionUsecase _createBringinConnectionUsecase;
  final GetStoredBringinConnectionUsecase _getStoredBringinConnectionUsecase;
  final RemoveBringinConnectionUsecase _removeBringinConnectionUsecase;

  BringinBloc({
    required GetBringinAddressUsecase getBringinAddressUsecase,
    required SignBringinMessageUsecase signBringinMessageUsecase,
    required CreateBringinConnectionUsecase createBringinConnectionUsecase,
    required GetStoredBringinConnectionUsecase
        getStoredBringinConnectionUsecase,
    required RemoveBringinConnectionUsecase removeBringinConnectionUsecase,
  }) : _getBringinAddressUsecase = getBringinAddressUsecase,
       _signBringinMessageUsecase = signBringinMessageUsecase,
       _createBringinConnectionUsecase = createBringinConnectionUsecase,
       _getStoredBringinConnectionUsecase = getStoredBringinConnectionUsecase,
       _removeBringinConnectionUsecase = removeBringinConnectionUsecase,
       super(const BringinState()) {
    on<BringinStarted>(_onStarted);
    on<BringinConnectionCreated>(_onConnectionCreated);
    on<BringinRemoveConnection>(_onRemoveConnection);
    on<BringinClearError>(_onClearError);
  }

  Future<void> _onStarted(
    BringinStarted event,
    Emitter<BringinState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Check if a connection already exists
      final storedConnection =
          await _getStoredBringinConnectionUsecase.execute();

      if (storedConnection != null) {
        emit(
          state.copyWith(
            connection: storedConnection,
            isLoading: false,
            isStarted: true,
          ),
        );
        return;
      }

      // No existing connection — derive address and sign for widget
      final addressResult = await _getBringinAddressUsecase.execute();

      final walletSignature = await _signBringinMessageUsecase.execute(
        wallet: addressResult.wallet,
        btcAddress: addressResult.btcAddress,
      );

      emit(
        state.copyWith(
          btcAddress: addressResult.btcAddress,
          walletId: addressResult.wallet.id,
          walletSignature: walletSignature,
          isLoading: false,
          isStarted: true,
        ),
      );
    } on BringinError catch (e) {
      log.severe('Error starting Bringin: $e');
      emit(state.copyWith(isLoading: false, isStarted: true, error: e));
    } catch (e) {
      log.severe('Unexpected error starting Bringin: $e');
      emit(
        state.copyWith(
          isLoading: false,
          isStarted: true,
          error: UnexpectedBringinError(e.toString()),
        ),
      );
    }
  }

  Future<void> _onConnectionCreated(
    BringinConnectionCreated event,
    Emitter<BringinState> emit,
  ) async {
    try {
      final connection = await _createBringinConnectionUsecase.execute(
        depositIban: event.depositIban,
        bringinLinkId: event.bringinLinkId,
        btcAddress: event.btcAddress,
        walletId: event.walletId,
      );

      emit(state.copyWith(connection: connection, error: null));
    } on BringinError catch (e) {
      log.severe('Error creating Bringin connection: $e');
      emit(state.copyWith(error: e));
    } catch (e) {
      log.severe('Unexpected error creating Bringin connection: $e');
      emit(state.copyWith(error: UnexpectedBringinError(e.toString())));
    }
  }

  Future<void> _onRemoveConnection(
    BringinRemoveConnection event,
    Emitter<BringinState> emit,
  ) async {
    try {
      emit(state.copyWith(isRemovingConnection: true));

      await _removeBringinConnectionUsecase.execute();

      emit(
        const BringinState(isStarted: true),
      );

      log.info('Bringin connection removed successfully');
    } on BringinError catch (e) {
      log.severe('Error removing Bringin connection: $e');
      emit(state.copyWith(isRemovingConnection: false, error: e));
    } catch (e) {
      log.severe('Unexpected error removing Bringin connection: $e');
      emit(
        state.copyWith(
          isRemovingConnection: false,
          error: UnexpectedBringinError(e.toString()),
        ),
      );
    }
  }

  Future<void> _onClearError(
    BringinClearError event,
    Emitter<BringinState> emit,
  ) async {
    emit(state.copyWith(error: null));
  }
}
