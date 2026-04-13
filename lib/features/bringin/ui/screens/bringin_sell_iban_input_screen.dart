import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/widgets/buttons/button.dart';
import 'package:bb_mobile/core/widgets/inputs/text_input.dart';
import 'package:bb_mobile/core/widgets/navbar/top_bar.dart';
import 'package:bb_mobile/core/widgets/text/text.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_state.dart';
import 'package:bb_mobile/features/bringin/ui/bringin_router.dart';
import 'package:bb_mobile/features/wallet/ui/wallet_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class BringinSellIbanInputScreen extends StatelessWidget {
  const BringinSellIbanInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        flexibleSpace: TopBar(
          title: 'Bank Account Details',
          onBack: () {
            final state = context.read<BringinSellBloc>().state;
            if (state.connections.isNotEmpty) {
              context.goNamed(BringinRoute.bringinSellBeneficiaries.name);
            } else {
              context.goNamed(WalletRoute.walletHome.name);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BBText(
                'Enter the bank account where you want to receive EUR.',
                style: context.font.bodyMedium?.copyWith(
                  color: context.appColors.textMuted,
                ),
              ),
              const Gap(24),

              // IBAN field
              BBText(
                'IBAN',
                style: context.font.labelLarge?.copyWith(
                  color: context.appColors.text,
                ),
              ),
              const Gap(8),
              BlocBuilder<BringinSellBloc, BringinSellState>(
                buildWhen: (prev, curr) =>
                    prev.ibanInput != curr.ibanInput,
                builder: (context, state) {
                  return BBInputText(
                    value: state.ibanInput,
                    hint: 'e.g. DE89370400440532013000',
                    onChanged: (value) {
                      context
                          .read<BringinSellBloc>()
                          .add(BringinSellEvent.updateIbanInput(value));
                    },
                  );
                },
              ),
              const Gap(16),

              // BIC field (optional)
              BBText(
                'BIC / SWIFT (optional)',
                style: context.font.labelLarge?.copyWith(
                  color: context.appColors.text,
                ),
              ),
              const Gap(8),
              BlocBuilder<BringinSellBloc, BringinSellState>(
                buildWhen: (prev, curr) =>
                    prev.bicInput != curr.bicInput,
                builder: (context, state) {
                  return BBInputText(
                    value: state.bicInput,
                    hint: 'e.g. COBADEFFXXX',
                    onChanged: (value) {
                      context
                          .read<BringinSellBloc>()
                          .add(BringinSellEvent.updateBicInput(value));
                    },
                  );
                },
              ),
              const Gap(16),

              // Account Holder Name field
              BBText(
                'Account Holder Name',
                style: context.font.labelLarge?.copyWith(
                  color: context.appColors.text,
                ),
              ),
              const Gap(8),
              BlocBuilder<BringinSellBloc, BringinSellState>(
                buildWhen: (prev, curr) =>
                    prev.beneficiaryNameInput != curr.beneficiaryNameInput,
                builder: (context, state) {
                  return BBInputText(
                    value: state.beneficiaryNameInput,
                    hint: 'e.g. Max Mustermann',
                    onChanged: (value) {
                      context.read<BringinSellBloc>().add(
                        BringinSellEvent.updateBeneficiaryNameInput(value),
                      );
                    },
                  );
                },
              ),

              const Spacer(),

              // Continue button
              BlocBuilder<BringinSellBloc, BringinSellState>(
                buildWhen: (prev, curr) =>
                    prev.ibanInput != curr.ibanInput ||
                    prev.beneficiaryNameInput != curr.beneficiaryNameInput,
                builder: (context, state) {
                  final canContinue = state.ibanInput.isNotEmpty &&
                      state.beneficiaryNameInput.isNotEmpty;

                  return SizedBox(
                    width: double.infinity,
                    child: BBButton.big(
                      label: 'Continue',
                      onPressed: canContinue
                          ? () {
                              context.goNamed(
                                BringinRoute.bringinSellWebview.name,
                              );
                            }
                          : () {},
                      bgColor: canContinue
                          ? context.appColors.primary
                          : context.appColors.outline,
                      textColor: canContinue
                          ? context.appColors.onPrimary
                          : context.appColors.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
