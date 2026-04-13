import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_state.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_state.dart';
import 'package:bb_mobile/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'screens/bringin_dashboard_screen.dart';
import 'screens/bringin_sell_beneficiaries_screen.dart';
import 'screens/bringin_sell_dashboard_screen.dart';
import 'screens/bringin_sell_iban_input_screen.dart';
import 'screens/bringin_sell_webview_screen.dart';
import 'screens/bringin_webview_screen.dart';

enum BringinRoute {
  // Buy
  bringinWebview('/bringin-buy'),
  bringinDashboard('/bringin-dashboard'),
  // Sell
  bringinSellEntry('/bringin-sell'),
  bringinSellBeneficiaries('/bringin-sell-beneficiaries'),
  bringinSellIbanInput('/bringin-sell-iban-input'),
  bringinSellWebview('/bringin-sell-webview'),
  bringinSellDashboard('/bringin-sell-dashboard');

  const BringinRoute(this.path);
  final String path;
}

class BringinRouter {
  static final routes = [
    // Buy flow
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider<BringinBloc>(
          create: (_) =>
              locator<BringinBloc>()..add(const BringinEvent.started()),
          child: child,
        );
      },
      routes: [
        GoRoute(
          name: BringinRoute.bringinWebview.name,
          path: BringinRoute.bringinWebview.path,
          builder: (context, state) {
            return BlocBuilder<BringinBloc, BringinState>(
              buildWhen: (prev, curr) =>
                  prev.isStarted != curr.isStarted ||
                  prev.connection != curr.connection,
              builder: (context, bringinState) {
                if (!bringinState.isStarted) {
                  return const SizedBox.shrink();
                }
                if (bringinState.connection != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.goNamed(BringinRoute.bringinDashboard.name);
                  });
                  return const SizedBox.shrink();
                }
                return const BringinWebviewScreen();
              },
            );
          },
        ),
        GoRoute(
          name: BringinRoute.bringinDashboard.name,
          path: BringinRoute.bringinDashboard.path,
          builder: (context, state) => const BringinDashboardScreen(),
        ),
      ],
    ),
    // Sell flow
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider<BringinSellBloc>(
          create: (_) =>
              locator<BringinSellBloc>()
                ..add(const BringinSellEvent.started()),
          child: child,
        );
      },
      routes: [
        // Entry point: routes to beneficiaries list or IBAN input
        GoRoute(
          name: BringinRoute.bringinSellEntry.name,
          path: BringinRoute.bringinSellEntry.path,
          builder: (context, state) {
            return BlocBuilder<BringinSellBloc, BringinSellState>(
              buildWhen: (prev, curr) =>
                  prev.isStarted != curr.isStarted,
              builder: (context, sellState) {
                if (!sellState.isStarted) {
                  return const SizedBox.shrink();
                }
                if (sellState.connections.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.goNamed(
                      BringinRoute.bringinSellBeneficiaries.name,
                    );
                  });
                  return const SizedBox.shrink();
                }
                // No connections — go to IBAN input
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.goNamed(BringinRoute.bringinSellIbanInput.name);
                });
                return const SizedBox.shrink();
              },
            );
          },
        ),
        GoRoute(
          name: BringinRoute.bringinSellBeneficiaries.name,
          path: BringinRoute.bringinSellBeneficiaries.path,
          builder: (context, state) =>
              const BringinSellBeneficiariesScreen(),
        ),
        GoRoute(
          name: BringinRoute.bringinSellIbanInput.name,
          path: BringinRoute.bringinSellIbanInput.path,
          builder: (context, state) => const BringinSellIbanInputScreen(),
        ),
        GoRoute(
          name: BringinRoute.bringinSellWebview.name,
          path: BringinRoute.bringinSellWebview.path,
          builder: (context, state) => const BringinSellWebviewScreen(),
        ),
        GoRoute(
          name: BringinRoute.bringinSellDashboard.name,
          path: BringinRoute.bringinSellDashboard.path,
          builder: (context, state) => const BringinSellDashboardScreen(),
        ),
      ],
    ),
  ];
}
