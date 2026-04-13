import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/widgets/bottom_sheet/x.dart';
import 'package:bb_mobile/core/widgets/buttons/button.dart';
import 'package:bb_mobile/core/widgets/inputs/copy_input.dart';
import 'package:bb_mobile/core/widgets/navbar/top_bar.dart';
import 'package:bb_mobile/core/widgets/text/text.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_state.dart';
import 'package:bb_mobile/features/bringin/ui/bringin_router.dart';
import 'package:bb_mobile/features/send/ui/send_router.dart';
import 'package:bb_mobile/features/wallet/ui/wallet_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class BringinSellDashboardScreen extends StatelessWidget {
  const BringinSellDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BringinSellBloc, BringinSellState>(
      listenWhen: (prev, curr) =>
          prev.selectedConnection != null && curr.selectedConnection == null,
      listener: (context, state) {
        // Connection removed — go back to list or home
        if (state.connections.isNotEmpty) {
          context.goNamed(BringinRoute.bringinSellBeneficiaries.name);
        } else {
          context.goNamed(WalletRoute.walletHome.name);
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
          flexibleSpace: TopBar(
            title: 'Sell Connection',
            onBack: () {
              final state = context.read<BringinSellBloc>().state;
              if (state.connections.length > 1) {
                context.goNamed(BringinRoute.bringinSellBeneficiaries.name);
              } else {
                context.goNamed(WalletRoute.walletHome.name);
              }
            },
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<BringinSellBloc, BringinSellState>(
            builder: (context, state) {
              final connection = state.selectedConnection;
              if (connection == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BBText(
                            'BTC to EUR Standing Order',
                            style: context.font.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.text,
                            ),
                          ),
                          const Gap(8),
                          BBText(
                            'Send BTC to the address below. '
                            'Each payment is automatically converted to EUR '
                            'and deposited to your bank account.',
                            style: context.font.bodyMedium?.copyWith(
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // BTC Deposit Address
                    BBText(
                      'BTC Deposit Address',
                      style: context.font.labelLarge?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    const Gap(8),
                    CopyInput(text: connection.depositAddress),
                    const Gap(16),

                    // Send BTC button
                    SizedBox(
                      width: double.infinity,
                      child: BBButton.big(
                        label: 'Send BTC',
                        onPressed: () {
                          context.pushNamed(
                            SendRoute.send.name,
                            extra: (
                              wallet: null,
                              address: connection.depositAddress,
                            ),
                          );
                        },
                        bgColor: context.appColors.primary,
                        textColor: context.appColors.onPrimary,
                      ),
                    ),
                    const Gap(20),

                    // Beneficiary Name
                    if (connection.beneficiaryName != null &&
                        connection.beneficiaryName!.isNotEmpty) ...[
                      BBText(
                        'Account Holder',
                        style: context.font.labelLarge?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
                      const Gap(8),
                      CopyInput(text: connection.beneficiaryName!),
                      const Gap(20),
                    ],

                    // Linked IBAN
                    if (connection.iban != null &&
                        connection.iban!.isNotEmpty) ...[
                      BBText(
                        'Linked IBAN',
                        style: context.font.labelLarge?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
                      const Gap(8),
                      CopyInput(text: connection.iban!),
                      const Gap(20),
                    ],

                    // Connection ID
                    BBText(
                      'Connection ID',
                      style: context.font.labelLarge?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    const Gap(8),
                    CopyInput(text: connection.bringinLinkId),
                    const Gap(32),

                    // Remove Connection button
                    Center(
                      child: BBButton.small(
                        label: 'Remove Connection',
                        onPressed: () => _showRemoveDialog(
                          context,
                          connection.bringinLinkId,
                        ),
                        bgColor: context.appColors.transparent,
                        outlined: true,
                        textColor: context.appColors.error,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showRemoveDialog(
    BuildContext context,
    String bringinLinkId,
  ) async {
    final confirmed = await BlurredBottomSheet.show<bool>(
      context: context,
      child: _RemoveSellConnectionDialog(),
    );
    if (confirmed == true && context.mounted) {
      context.read<BringinSellBloc>().add(
        BringinSellEvent.removeConnection(bringinLinkId: bringinLinkId),
      );
    }
  }
}

class _RemoveSellConnectionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BBText(
                'Remove Connection',
                style: context.font.headlineSmall?.copyWith(
                  color: context.appColors.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              BBText(
                'Are you sure you want to remove this beneficiary? '
                'You can create a new connection at any time.',
                style: context.font.bodyMedium?.copyWith(
                  color: context.appColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: BBButton.small(
                      label: 'Cancel',
                      onPressed: () => context.pop(false),
                      bgColor: context.appColors.transparent,
                      outlined: true,
                      textColor: context.appColors.text,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: BBButton.small(
                      label: 'Remove',
                      onPressed: () => context.pop(true),
                      bgColor: context.appColors.error,
                      textColor: context.appColors.onError,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
