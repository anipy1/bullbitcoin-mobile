import 'package:bb_mobile/core/utils/logger.dart';
import 'package:bb_mobile/features/bringin/application/usecases/create_bringin_sell_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/get_stored_bringin_sell_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/remove_bringin_sell_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/domain/errors/bringin_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bringin_sell_event.dart';
import 'bringin_sell_state.dart';

class BringinSellBloc extends Bloc<BringinSellEvent, BringinSellState> {
  final CreateBringinSellConnectionUsecase _createSellConnectionUsecase;
  final GetStoredBringinSellConnectionUsecase _getStoredSellConnectionUsecase;
  final RemoveBringinSellConnectionUsecase _removeSellConnectionUsecase;

  BringinSellBloc({
    required CreateBringinSellConnectionUsecase createSellConnectionUsecase,
    required GetStoredBringinSellConnectionUsecase
        getStoredSellConnectionUsecase,
    required RemoveBringinSellConnectionUsecase removeSellConnectionUsecase,
  }) : _createSellConnectionUsecase = createSellConnectionUsecase,
       _getStoredSellConnectionUsecase = getStoredSellConnectionUsecase,
       _removeSellConnectionUsecase = removeSellConnectionUsecase,
       super(const BringinSellState()) {
    on<BringinSellStarted>(_onStarted);
    on<BringinSellSelectConnection>(_onSelectConnection);
    on<BringinSellConnectionCreated>(_onConnectionCreated);
    on<BringinSellRemoveConnection>(_onRemoveConnection);
    on<BringinSellUpdateIbanInput>(_onUpdateIbanInput);
    on<BringinSellUpdateBicInput>(_onUpdateBicInput);
    on<BringinSellUpdateBeneficiaryNameInput>(_onUpdateBeneficiaryNameInput);
    on<BringinSellClearError>(_onClearError);
  }

  Future<void> _onStarted(
    BringinSellStarted event,
    Emitter<BringinSellState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final connections = await _getStoredSellConnectionUsecase.execute();

      emit(
        state.copyWith(
          connections: connections,
          isLoading: false,
          isStarted: true,
        ),
      );
    } on BringinError catch (e) {
      log.severe('Error starting Bringin Sell: $e');
      emit(state.copyWith(isLoading: false, isStarted: true, error: e));
    } catch (e) {
      log.severe('Unexpected error starting Bringin Sell: $e');
      emit(
        state.copyWith(
          isLoading: false,
          isStarted: true,
          error: UnexpectedBringinError(e.toString()),
        ),
      );
    }
  }

  void _onSelectConnection(
    BringinSellSelectConnection event,
    Emitter<BringinSellState> emit,
  ) {
    final connection = state.connections.where(
      (c) => c.bringinLinkId == event.bringinLinkId,
    ).firstOrNull;

    emit(state.copyWith(selectedConnection: connection));
  }

  Future<void> _onConnectionCreated(
    BringinSellConnectionCreated event,
    Emitter<BringinSellState> emit,
  ) async {
    try {
      final connection = await _createSellConnectionUsecase.execute(
        depositAddress: event.depositAddress,
        bringinLinkId: event.bringinLinkId,
        walletId: event.walletId,
        iban: event.iban,
        bic: event.bic,
        beneficiaryName: event.beneficiaryName,
      );

      final updatedConnections = [...state.connections, connection];

      emit(
        state.copyWith(
          connections: updatedConnections,
          selectedConnection: connection,
          // Clear form inputs after successful creation
          ibanInput: '',
          bicInput: '',
          beneficiaryNameInput: '',
          error: null,
        ),
      );
    } on BringinError catch (e) {
      log.severe('Error creating Bringin sell connection: $e');
      emit(state.copyWith(error: e));
    } catch (e) {
      log.severe('Unexpected error creating Bringin sell connection: $e');
      emit(state.copyWith(error: UnexpectedBringinError(e.toString())));
    }
  }

  Future<void> _onRemoveConnection(
    BringinSellRemoveConnection event,
    Emitter<BringinSellState> emit,
  ) async {
    try {
      emit(state.copyWith(isRemovingConnection: true));

      await _removeSellConnectionUsecase.execute(event.bringinLinkId);

      final updatedConnections = state.connections
          .where((c) => c.bringinLinkId != event.bringinLinkId)
          .toList();

      emit(
        state.copyWith(
          connections: updatedConnections,
          selectedConnection: null,
          isRemovingConnection: false,
          error: null,
        ),
      );

      log.info('Bringin sell connection removed: ${event.bringinLinkId}');
    } on BringinError catch (e) {
      log.severe('Error removing Bringin sell connection: $e');
      emit(state.copyWith(isRemovingConnection: false, error: e));
    } catch (e) {
      log.severe('Unexpected error removing Bringin sell connection: $e');
      emit(
        state.copyWith(
          isRemovingConnection: false,
          error: UnexpectedBringinError(e.toString()),
        ),
      );
    }
  }

  void _onUpdateIbanInput(
    BringinSellUpdateIbanInput event,
    Emitter<BringinSellState> emit,
  ) {
    emit(state.copyWith(ibanInput: event.iban));
  }

  void _onUpdateBicInput(
    BringinSellUpdateBicInput event,
    Emitter<BringinSellState> emit,
  ) {
    emit(state.copyWith(bicInput: event.bic));
  }

  void _onUpdateBeneficiaryNameInput(
    BringinSellUpdateBeneficiaryNameInput event,
    Emitter<BringinSellState> emit,
  ) {
    emit(state.copyWith(beneficiaryNameInput: event.name));
  }

  Future<void> _onClearError(
    BringinSellClearError event,
    Emitter<BringinSellState> emit,
  ) async {
    emit(state.copyWith(error: null));
  }
}
