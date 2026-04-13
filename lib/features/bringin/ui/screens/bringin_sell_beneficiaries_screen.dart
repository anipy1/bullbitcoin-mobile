import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/widgets/buttons/button.dart';
import 'package:bb_mobile/core/widgets/navbar/top_bar.dart';
import 'package:bb_mobile/core/widgets/text/text.dart';
import 'package:bb_mobile/features/bringin/domain/entities/bringin_connection.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_state.dart';
import 'package:bb_mobile/features/bringin/ui/bringin_router.dart';
import 'package:bb_mobile/features/wallet/ui/wallet_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class BringinSellBeneficiariesScreen extends StatelessWidget {
  const BringinSellBeneficiariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        flexibleSpace: TopBar(
          title: 'Sell Bitcoin',
          onBack: () => context.goNamed(WalletRoute.walletHome.name),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BBText(
                  'Select a bank account to sell BTC, or add a new one.',
                  style: context.font.bodyMedium?.copyWith(
                    color: context.appColors.textMuted,
                  ),
                ),
              ),
            ),
            const Gap(16),

            // Beneficiaries list
            Expanded(
              child: BlocBuilder<BringinSellBloc, BringinSellState>(
                builder: (context, state) {
                  if (state.connections.isEmpty) {
                    return const Center(
                      child: Text('No beneficiaries yet'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.connections.length,
                    itemBuilder: (context, index) {
                      final connection = state.connections[index];
                      return _BeneficiaryTile(connection: connection);
                    },
                  );
                },
              ),
            ),

            // Add Beneficiary button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: BBButton.big(
                  label: 'Add Beneficiary',
                  onPressed: () {
                    context.goNamed(BringinRoute.bringinSellIbanInput.name);
                  },
                  bgColor: context.appColors.primary,
                  textColor: context.appColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeneficiaryTile extends StatelessWidget {
  final BringinSellConnection connection;

  const _BeneficiaryTile({required this.connection});

  String _maskIban(String iban) {
    if (iban.length <= 8) return iban;
    return '${iban.substring(0, 4)}...${iban.substring(iban.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final name = connection.beneficiaryName?.isNotEmpty == true
        ? connection.beneficiaryName!
        : 'Beneficiary';
    final iban = connection.iban ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.read<BringinSellBloc>().add(
            BringinSellEvent.selectConnection(
              bringinLinkId: connection.bringinLinkId,
            ),
          );
          context.goNamed(BringinRoute.bringinSellDashboard.name);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.outline),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance,
                color: context.appColors.secondary,
                size: 24,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BBText(
                      name,
                      style: context.font.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.text,
                      ),
                    ),
                    if (iban.isNotEmpty) ...[
                      const Gap(4),
                      BBText(
                        _maskIban(iban),
                        style: context.font.bodySmall?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.appColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
