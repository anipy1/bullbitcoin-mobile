part of 'onboarding_bloc.dart';

sealed class OnboardingEvent {
  const OnboardingEvent();
}

class OnboardingGoBack extends OnboardingEvent {
  const OnboardingGoBack();
}

class OnboardingCreateNewWallet extends OnboardingEvent {
  const OnboardingCreateNewWallet();
}

/// Create a new wallet from words produced by the interactive entropy
/// round (Desert Shooter motion mixed with the platform CSPRNG). Unlike a
/// recovery, this is a brand-new seed: no history scan, no backup done yet.
class OnboardingCreateWalletWithInteractiveEntropy extends OnboardingEvent {
  const OnboardingCreateWalletWithInteractiveEntropy({required this.words});

  final List<String> words;
}

class OnboardingRecoveryWordChanged extends OnboardingEvent {
  const OnboardingRecoveryWordChanged({
    required this.index,
    required this.word,
  });

  final int index;
  final String word;
}

class OnboardingRecoverWalletClicked extends OnboardingEvent {
  const OnboardingRecoverWalletClicked({required this.mnemonic});

  final ({
    List<String> words,
    String passphrase,
    String label,
    bip39.Language language,
  })
  mnemonic;
}
