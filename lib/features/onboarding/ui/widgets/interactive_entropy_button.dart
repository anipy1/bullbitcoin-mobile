import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/widgets/buttons/button.dart';
import 'package:bb_mobile/features/interactive_entropy/interactive_entropy_page.dart';
import 'package:bb_mobile/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the interactive entropy flow: a round of Desert Shooter played
/// with this phone as the gun, whose motion hardens the new seed's entropy.
class InteractiveEntropyButton extends StatelessWidget {
  const InteractiveEntropyButton({super.key});

  @override
  Widget build(BuildContext context) {
    final busy = context.select(
      (OnboardingBloc bloc) =>
          bloc.state.onboardingStepStatus == OnboardingStepStatus.loading,
    );

    return BBButton.big(
      label: 'Interactive entropy',
      bgColor: context.appColors.onPrimaryFixed,
      textColor: context.appColors.primaryFixed,
      iconData: Icons.sports_esports_outlined,
      disabled: busy,
      onPressed: () {
        if (busy) return;
        final bloc = context.read<OnboardingBloc>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InteractiveEntropyPage(
              onCreateWallet: (words) async {
                // The onboarding bloc owns loading/success/navigation from
                // here; the page just needs to pop.
                bloc.add(
                  OnboardingCreateWalletWithInteractiveEntropy(words: words),
                );
                return null;
              },
            ),
          ),
        );
      },
    );
  }
}
