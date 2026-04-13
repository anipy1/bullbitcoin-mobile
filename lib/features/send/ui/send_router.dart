import 'package:bb_mobile/core/wallet/domain/entities/wallet.dart';
import 'package:bb_mobile/features/send/presentation/bloc/send_cubit.dart';
import 'package:bb_mobile/features/send/request_identifier/request_identifier_cubit.dart';
import 'package:bb_mobile/features/send/request_identifier/request_identifier_screen.dart';
import 'package:bb_mobile/features/send/ui/screens/send_screen.dart';
import 'package:bb_mobile/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum SendRoute {
  send('/send'),
  requestIdentifier('request-identifier');

  const SendRoute(this.path);

  final String path;
}

class SendRouter {
  static final route = GoRoute(
    name: SendRoute.send.name,
    path: SendRoute.send.path,
    builder: (context, state) {
      // Support both:
      // 1. Wallet only (existing): extra: wallet
      // 2. Wallet + address (new): extra: (wallet: w, address: addr)
      Wallet? wallet;
      String? initialAddress;

      if (state.extra is Wallet) {
        wallet = state.extra! as Wallet;
      } else if (state.extra is ({Wallet? wallet, String? address})) {
        final params =
            state.extra! as ({Wallet? wallet, String? address});
        wallet = params.wallet;
        initialAddress = params.address;
      }

      return BlocProvider(
        create: (_) =>
            locator<SendCubit>(param1: wallet, param2: initialAddress)
              ..loadWalletWithRatesAndFees(),
        child: const SendScreen(),
      );
    },
    routes: [
      GoRoute(
        name: SendRoute.requestIdentifier.name,
        path: SendRoute.requestIdentifier.path,
        builder: (context, state) => BlocProvider(
          create: (_) => RequestIdentifierCubit(),
          child: const RequestIdentifierScreen(),
        ),
      ),
    ],
  );
}
