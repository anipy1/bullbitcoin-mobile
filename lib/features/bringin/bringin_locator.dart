import 'package:bb_mobile/core/seed/data/repository/seed_repository.dart';
import 'package:bb_mobile/core/storage/data/datasources/key_value_storage/key_value_storage_datasource.dart';
import 'package:bb_mobile/core/utils/constants.dart';
import 'package:bb_mobile/core/wallet/domain/usecases/get_address_at_index_usecase.dart';
import 'package:bb_mobile/core/wallet/domain/usecases/get_wallets_usecase.dart';
import 'package:bb_mobile/features/bringin/application/ports/bringin_local_storage_port.dart';
import 'package:bb_mobile/features/bringin/application/usecases/create_bringin_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/create_bringin_sell_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/get_bringin_address_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/get_stored_bringin_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/get_stored_bringin_sell_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/remove_bringin_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/remove_bringin_sell_connection_usecase.dart';
import 'package:bb_mobile/features/bringin/application/usecases/sign_bringin_message_usecase.dart';
import 'package:bb_mobile/features/bringin/frameworks/storage/bringin_local_storage.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_bloc.dart';
import 'package:get_it/get_it.dart';

class BringinLocator {
  static void setup(GetIt locator) {
    registerFrameworks(locator);
    registerInterfaceAdapters(locator);
    registerUsecases(locator);
    registerPresentation(locator);
  }

  static void registerFrameworks(GetIt locator) {
    locator.registerLazySingleton<BringinLocalStorage>(
      () => BringinLocalStorage(
        secureStorage: locator<KeyValueStorageDatasource<String>>(
          instanceName: LocatorInstanceNameConstants.secureStorageDatasource,
        ),
      ),
    );
  }

  static void registerInterfaceAdapters(GetIt locator) {
    locator.registerLazySingleton<BringinLocalStoragePort>(
      () => locator<BringinLocalStorage>(),
    );
  }

  static void registerUsecases(GetIt locator) {
    // Buy usecases
    locator.registerFactory<GetBringinAddressUsecase>(
      () => GetBringinAddressUsecase(
        getWalletsUsecase: locator<GetWalletsUsecase>(),
        getAddressAtIndexUsecase: locator<GetAddressAtIndexUsecase>(),
      ),
    );

    locator.registerFactory<SignBringinMessageUsecase>(
      () => SignBringinMessageUsecase(
        seedRepository: locator<SeedRepository>(),
      ),
    );

    locator.registerFactory<CreateBringinConnectionUsecase>(
      () => CreateBringinConnectionUsecase(
        localStorage: locator<BringinLocalStoragePort>(),
      ),
    );

    locator.registerFactory<GetStoredBringinConnectionUsecase>(
      () => GetStoredBringinConnectionUsecase(
        localStorage: locator<BringinLocalStoragePort>(),
      ),
    );

    locator.registerFactory<RemoveBringinConnectionUsecase>(
      () => RemoveBringinConnectionUsecase(
        localStorage: locator<BringinLocalStoragePort>(),
      ),
    );

    // Sell usecases
    locator.registerFactory<CreateBringinSellConnectionUsecase>(
      () => CreateBringinSellConnectionUsecase(
        localStorage: locator<BringinLocalStoragePort>(),
      ),
    );

    locator.registerFactory<GetStoredBringinSellConnectionUsecase>(
      () => GetStoredBringinSellConnectionUsecase(
        localStorage: locator<BringinLocalStoragePort>(),
      ),
    );

    locator.registerFactory<RemoveBringinSellConnectionUsecase>(
      () => RemoveBringinSellConnectionUsecase(
        localStorage: locator<BringinLocalStoragePort>(),
      ),
    );
  }

  static void registerPresentation(GetIt locator) {
    // Buy BLoC
    locator.registerFactory<BringinBloc>(
      () => BringinBloc(
        getBringinAddressUsecase: locator<GetBringinAddressUsecase>(),
        signBringinMessageUsecase: locator<SignBringinMessageUsecase>(),
        createBringinConnectionUsecase:
            locator<CreateBringinConnectionUsecase>(),
        getStoredBringinConnectionUsecase:
            locator<GetStoredBringinConnectionUsecase>(),
        removeBringinConnectionUsecase:
            locator<RemoveBringinConnectionUsecase>(),
      ),
    );

    // Sell BLoC
    locator.registerFactory<BringinSellBloc>(
      () => BringinSellBloc(
        createSellConnectionUsecase:
            locator<CreateBringinSellConnectionUsecase>(),
        getStoredSellConnectionUsecase:
            locator<GetStoredBringinSellConnectionUsecase>(),
        removeSellConnectionUsecase:
            locator<RemoveBringinSellConnectionUsecase>(),
      ),
    );
  }
}
