import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/widgets/bottom_sheet/x.dart';
import 'package:bb_mobile/core/widgets/buttons/button.dart';
import 'package:bb_mobile/core/widgets/inputs/copy_input.dart';
import 'package:bb_mobile/core/widgets/navbar/top_bar.dart';
import 'package:bb_mobile/core/widgets/text/text.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_state.dart';
import 'package:bb_mobile/features/wallet/ui/wallet_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class BringinDashboardScreen extends StatelessWidget {
  const BringinDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BringinBloc, BringinState>(
      listenWhen: (prev, curr) =>
          prev.connection != null && curr.connection == null,
      listener: (context, state) {
        // Connection removed — go back to wallet home
        context.goNamed(WalletRoute.walletHome.name);
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
          flexibleSpace: TopBar(
            title: 'Bringin Connection',
            onBack: () => context.goNamed(WalletRoute.walletHome.name),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<BringinBloc, BringinState>(
            builder: (context, state) {
              final connection = state.connection;
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
                            'EUR to BTC Standing Order',
                            style: context.font.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.text,
                            ),
                          ),
                          const Gap(8),
                          BBText(
                            'Send EUR to the IBAN below from your bank. '
                            'Each payment is automatically converted to BTC '
                            'and sent to your wallet.',
                            style: context.font.bodyMedium?.copyWith(
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // Deposit IBAN
                    BBText(
                      'Deposit IBAN',
                      style: context.font.labelLarge?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    const Gap(8),
                    CopyInput(
                      text: connection.depositIban,
                    ),
                    const Gap(20),

                    // Linked BTC Address
                    BBText(
                      'Linked BTC Address',
                      style: context.font.labelLarge?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    const Gap(8),
                    CopyInput(
                      text: connection.btcAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(20),

                    // Connection ID
                    BBText(
                      'Connection ID',
                      style: context.font.labelLarge?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    const Gap(8),
                    CopyInput(
                      text: connection.bringinLinkId,
                    ),
                    const Gap(32),

                    // Remove Connection button
                    Center(
                      child: BBButton.small(
                        label: 'Remove Connection',
                        onPressed: () => _showRemoveDialog(context),
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

  Future<void> _showRemoveDialog(BuildContext context) async {
    final confirmed = await BlurredBottomSheet.show<bool>(
      context: context,
      child: _RemoveConnectionDialog(),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<BringinBloc>()
          .add(const BringinEvent.removeConnection());
    }
  }
}

class _RemoveConnectionDialog extends StatelessWidget {
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
                'Are you sure you want to remove this Bringin connection? '
                'The deposit IBAN will no longer be displayed. '
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
