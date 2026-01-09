// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Done';

  @override
  String get select => 'Select';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'Enter Amount';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'SKIP (ANY AMOUNT)';

  @override
  String get contin => 'CONTINUE';

  @override
  String get currencyUpdatedSuccessfully => 'Currency updated successfully';

  @override
  String get changeCurrency => 'Change Currency';

  @override
  String get languageUpdatedSuccessfully => 'Language updated successfully';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get themeAppliedSuccessfully => 'Theme applied successfully';

  @override
  String get chooseYourColor => 'Choose Your Color';

  @override
  String get selectColor => 'Select color';

  @override
  String get selectColorShade => 'Select color shade';

  @override
  String get changeYourStyle => 'Change Your Style';

  @override
  String get chooseYourPreferredTheme => 'Choose your preferred theme';

  @override
  String get dark => 'Dark';

  @override
  String get originalDarkTheme => 'Original dark theme';

  @override
  String get light => 'Light';

  @override
  String get cleanLightTheme => 'Clean light theme';

  @override
  String get applyTheme => 'Apply Theme';

  @override
  String get custom => 'Custom';

  @override
  String get createYourOwnTheme => 'Create your own theme';

  @override
  String get timezoneUpdatedSuccessfully => 'Timezone updated successfully';

  @override
  String get changeTimezone => 'Change Timezone';

  @override
  String get searchTimezone => 'Search timezone...';

  @override
  String get couldntUpdateTransactions => 'Couldn\'t update transactions:';

  @override
  String get couldntUpdateBalance => 'Couldn\'t update balance:';

  @override
  String showingBalanceType(String balanceType) {
    return 'Showing $balanceType balance';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'Pending Balance';

  @override
  String get confirmedBalance => 'Confirmed Balance';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get errorLoadingBalance => 'Error loading balance';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get failedToCreateWallet => 'Failed to create wallet';

  @override
  String errorCreatingWallet(String error) {
    return 'There was an error creating your new wallet. Please try again.\n\nError: $error';
  }

  @override
  String get failedToRestoreWallet => 'Failed to restore wallet';

  @override
  String errorRestoringWallet(String error) {
    return 'There was an error restoring your wallet. Please check your nsec and try again.\n\nError: $error';
  }

  @override
  String get appTagline => 'The first Bitcoin wallet that doesn\'t suck.';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'Choose an option:';

  @override
  String get createNewWallet => 'Create New Wallet';

  @override
  String get generateANewSecureWallet => 'Generate a new secure wallet';

  @override
  String get restoreExistingWallet => 'Restore Existing Wallet';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'Use your secret key to access your wallet';

  @override
  String get enterYourNsec => 'Enter your nsec:';

  @override
  String get pasteYourRecoveryNsec => 'Paste your recovery nsec...';

  @override
  String paymentMonitoringError(String error) {
    return 'Payment monitoring error: $error';
  }

  @override
  String get paymentReceived => 'Payment Received!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'Share Which Address?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'Lightning Invoice';

  @override
  String get qrCodeImage => 'QR Code Image';

  @override
  String get errorSharing => 'Error sharing';

  @override
  String get myBitcoinAddressQrCode => 'My Bitcoin Address QR Code';

  @override
  String get requesting => 'Requesting: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'Please enter both address and amount';

  @override
  String get pleaseEnterAValidAmount => 'Please enter a valid amount';

  @override
  String get insufficientFunds => 'Insufficient funds';

  @override
  String get sendLower => 'Send';

  @override
  String get receiveLower => 'Receive';

  @override
  String get recipientAddress => 'Recipient address';

  @override
  String get bitcoinOrArkAddress => 'Bitcoin or Arkade address';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Esplora URL saved  - will only take effect after a restart';

  @override
  String get failedToSaveEsploraUrl => 'Failed to save Esplora URL';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'Network saved - will only take effect after a restart';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Ark Server URL saved - will only take effect after a restart';

  @override
  String get failedToSaveArkServerUrl => 'Failed to save Ark Server URL';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Boltz URL saved - will only take effect after a restart';

  @override
  String get failedToSaveBoltzUrl => 'Failed to save Boltz URL';

  @override
  String get securityWarning => 'Security Warning';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'Never share your recovery key with anyone!';

  @override
  String get anyoneWithThisKeyCan =>
      'Anyone with this key can access your wallet and steal your funds. Store it in a secure place.';

  @override
  String get iUnderstand => 'I UNDERSTAND';

  @override
  String get yourRecoveryPhrase => 'Your Recovery Phrase';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'Recovery phrase copied to clipboard';

  @override
  String get copyToClipboard => 'COPY TO CLIPBOARD';

  @override
  String get close => 'CLOSE';

  @override
  String get resetWallet => 'Reset Wallet';

  @override
  String get thisWillDeleteAllWalletData =>
      'This will delete all wallet data from this device. Make sure you have backed up your recovery phrase before proceeding. This action cannot be undone.';

  @override
  String get restartingApp => 'Restarting App';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'Please tap here to open the app again.';

  @override
  String get reset => 'RESET';

  @override
  String get wallet => 'Wallet';

  @override
  String get viewRecoveryKey => 'View Recovery Key';

  @override
  String get backupYourWalletWithTheseKey =>
      'Backup your wallet with these key';

  @override
  String get appearancePreferences => 'Appearance & Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get customizeAppAppearance => 'Customize app appearance';

  @override
  String get language => 'Language';

  @override
  String get selectYourPreferredLanguage => 'Select your preferred language';

  @override
  String get timezone => 'Timezone';

  @override
  String get chooseYourPreferredTimezone => 'Choose your preferred timezone';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'Choose your preferred currency';

  @override
  String get serverConfiguration => 'Server Configuration';

  @override
  String get network => 'Network';

  @override
  String get esploraUrl => 'Esplora URL';

  @override
  String get arkServer => 'Ark Server';

  @override
  String get boltzUrl => 'Boltz URL';

  @override
  String get about => 'About';

  @override
  String get loading => 'loading';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'Delete all wallet data from this device';

  @override
  String get transactionFailed => 'Transaction failed:';

  @override
  String get signTransaction => 'Sign transaction';

  @override
  String get networkFees => 'Network fees';

  @override
  String get total => 'Total';

  @override
  String get tapToSign => 'TAP TO SIGN';

  @override
  String get settlingTransaction => 'Settling transaction...';

  @override
  String get success => 'Success';

  @override
  String get transactionSettledSuccessfully =>
      'Transaction settled successfully!';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get error => 'Error';

  @override
  String get failedToSettleTransaction => 'Failed to settle transaction:';

  @override
  String get pendingConfirmation => 'Pending Confirmation';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get status => 'Status';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get pending => 'Pending';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get transactionVolume => 'Transaction Volume';

  @override
  String get confirmedAt => 'Confirmed At';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'Transaction pending. Funds will be non-reversible after settlement.';

  @override
  String get settle => 'SETTLE';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'No transaction history yet';

  @override
  String get boardingTransaction => 'Onchain Transaction';

  @override
  String get roundTransaction => 'Round Transaction';

  @override
  String get redeemTransaction => 'Redeem Transaction';

  @override
  String get sent => 'Sent';

  @override
  String get received => 'Received';

  @override
  String get direction => 'Direction';

  @override
  String get settled => 'Settled';

  @override
  String get sentSuccessfully => 'sent successfully';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Returning to wallet after successful transaction';

  @override
  String get backToWallet => 'BACK TO WALLET';

  @override
  String get transactionFees => 'Transaction Fees';

  @override
  String get fastest10Min => 'Fastest (~10 min)';

  @override
  String get halfHour => 'Half Hour';

  @override
  String get oneHour => 'One Hour';

  @override
  String get economy => 'Economy';

  @override
  String get minutesAgo => 'minutes ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String get daysAgo => 'days ago';

  @override
  String get miningInformation => 'Mining Information';

  @override
  String get miningPool => 'Mining Pool';

  @override
  String get mined => 'Mined';

  @override
  String get blockReward => 'Block Reward';

  @override
  String get totalFees => 'Total Fees';

  @override
  String get min => 'Min';

  @override
  String get networkHashrate => 'Network Hashrate';

  @override
  String get currentNetworkHashrate => 'Current Network Hashrate';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get dataPoints => 'Data Points';

  @override
  String get days => 'days';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get difficultyAdjustment => 'Difficulty Adjustment';

  @override
  String get complete => 'complete';

  @override
  String get remainingBlocks => 'Remaining Blocks';

  @override
  String get estTime => 'Est. Time';

  @override
  String get estDate => 'Est. Date';

  @override
  String get mAgo => 'm ago';

  @override
  String get hAgo => 'h ago';

  @override
  String get dAgo => 'd ago';

  @override
  String get blockSize => 'Block Size';

  @override
  String get weight => 'Weight';

  @override
  String get transactions => 'Transactions';

  @override
  String get avgSize => 'Avg Size';

  @override
  String get healthy => 'Healthy';

  @override
  String get fair => 'Fair';

  @override
  String get low => 'Low';

  @override
  String get blockHealth => 'Block Health';

  @override
  String get full => 'Full';

  @override
  String get actual => 'Actual';

  @override
  String get expected => 'Expected';

  @override
  String get difference => 'Difference';

  @override
  String get setAmount => 'Set Amount';

  @override
  String get clear => 'Clear';

  @override
  String get errorSharingQrCode => 'Error sharing QR code:';

  @override
  String get qr => 'QR';

  @override
  String get type => 'Type';

  @override
  String get sellBitcoin => 'Sell Bitcoin';

  @override
  String get errorLoadingSellScreen => 'Error loading sell screen';

  @override
  String get availableBalance => 'Available Balance';

  @override
  String get amountToSell => 'Amount to Sell';

  @override
  String get sellLimits => 'Sell Limits';

  @override
  String get insufficientBalance => 'Insufficient balance';

  @override
  String get max => 'Max';

  @override
  String get payoutMethods => 'Payout Methods';

  @override
  String get pendingBlock => 'Pending Block';

  @override
  String get nextBlock => 'Next Block';

  @override
  String get medianFee => 'Median Fee';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get feeDistribution => 'Fee Distribution';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get loadingMoreTransactions => 'Loading more transactions...';

  @override
  String get scrollDownToLoadMore => 'Scroll down to load more';

  @override
  String get med => 'Med';

  @override
  String get feeRate => 'Fee Rate';

  @override
  String get size => 'Size';

  @override
  String get value => 'Value';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get errorLoadingTransaction => 'Error loading transaction';

  @override
  String get blockHeight => 'Block Height';

  @override
  String get blockTime => 'Block Time';

  @override
  String get details => 'Details';

  @override
  String get fee => 'Fee';

  @override
  String get version => 'Version';

  @override
  String get locktime => 'Locktime';

  @override
  String get inputs => 'Inputs';

  @override
  String get outputs => 'Outputs';

  @override
  String get searchBlockchain => 'Search Blockchain';

  @override
  String get transaction => 'Transaction';

  @override
  String get enterBlockHeightOrBlockHash => 'Enter block height or block hash';

  @override
  String get enterTransactionIdTxid => 'Enter transaction ID (TXID)';

  @override
  String get blockchain => 'Blockchain';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get block => 'Block';

  @override
  String get yourTx => 'Your TX';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get buyLimits => 'Buy Limits';

  @override
  String get errorLoadingBuyScreen => 'Error loading buy screen';

  @override
  String get buyBitcoin => 'Buy Bitcoin';

  @override
  String get failedToLaunchMoonpay => 'Failed to launch MoonPay';

  @override
  String get bitcoinPriceChart => 'Bitcoin Price Chart';

  @override
  String get aboutBitcoin => 'About Bitcoin';

  @override
  String get bitcoinDescription =>
      'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.';

  @override
  String get aboutBitcoinPriceData => 'About Bitcoin Price Data';

  @override
  String get thePriceDataShown =>
      'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.';

  @override
  String get dataSource => 'Data Source';

  @override
  String get liveBitcoinMarketData => 'Live Bitcoin Market Data';

  @override
  String get updateFrequency => 'Update Frequency';

  @override
  String get realTime => 'Real-time';

  @override
  String get sendBitcoin => 'Send Bitcoin';

  @override
  String get sendNow => 'SEND NOW';

  @override
  String get notEnoughFunds => 'Not enough funds';

  @override
  String get recipient => 'Recipient';

  @override
  String get unknown => 'Unknown';

  @override
  String get fromClipboard => 'from clipboard';

  @override
  String get walletAddressCopied => 'Wallet address copied';

  @override
  String get hashrate => 'Hashrate';

  @override
  String get fearAndGreedIndex => 'Fear & Greed Index';

  @override
  String get health => 'Health';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get positionQrCodeInFrame => 'Position QR code in frame';

  @override
  String get noQrCodeFoundInImage => 'No QR code found in image';

  @override
  String get switchCamera => 'Switch Camera';

  @override
  String get flashOn => 'Flash On';

  @override
  String get flashOff => 'Flash Off';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get reportBugFeedback => 'Report Bug / Feedback';

  @override
  String get recoveryOptions => 'Recovery Options';

  @override
  String get securityStatus => 'Security Status';

  @override
  String get setupRecoveryWarning =>
      'For your security, please set up as many recovery options as possible.';

  @override
  String get recoveryFullySetup => 'Your wallet recovery is fully configured!';

  @override
  String get recoveryMethods => 'Recovery Methods';

  @override
  String get wordRecovery => 'Word Recovery';

  @override
  String get wordRecoveryDescription => 'Your 12-word recovery phrase';

  @override
  String get emailRecovery => 'Email Recovery';

  @override
  String get emailRecoveryDescription =>
      'Recover wallet via email and password';

  @override
  String get enabled => 'Enabled';

  @override
  String get notSetUp => 'Not Set Up';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get emailRecoveryComingSoon =>
      'Email recovery will be available in a future update. For now, please make sure to backup your recovery phrase.';

  @override
  String get recoverWithEmail => 'Recover with Email';

  @override
  String get recoverWithEmailSubtitle =>
      'Use email and password to restore your wallet';

  @override
  String get emailRecoverySetup => 'Email Recovery Setup';

  @override
  String get emailRecoveryWarningMessage =>
      'Your password encrypts your recovery phrase locally. The server only stores the encrypted version and cannot access your funds. If you forget your password, your backup cannot be recovered.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get pleaseEnterEmail => 'Please enter an email address';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get passwordTooWeak => 'Password is too weak';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get setupRecovery => 'Setup Recovery';

  @override
  String get emailRecoverySetupSuccess =>
      'Email recovery has been set up successfully! You can now recover your wallet using your email and password.';

  @override
  String get sendCode => 'Send Code';

  @override
  String get codeSentToEmail => 'Verification code sent to your email';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get recoveryPassword => 'Recovery Password';

  @override
  String get enterYourRecoveryPassword => 'Enter your recovery password';

  @override
  String get recoverWallet => 'Recover Wallet';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get pleaseEnterCode => 'Please enter the 6-digit verification code';

  @override
  String get wrongPassword => 'Wrong password. Please try again.';

  @override
  String get emailRecoveryLoginInfo =>
      'Enter the email and password you used when setting up email recovery. Your wallet will be restored securely.';

  @override
  String get authenticateToViewRecoveryPhrase =>
      'Authenticate to view your recovery phrase';

  @override
  String get authenticationFailed => 'Authentication failed. Please try again.';

  @override
  String get confirmRecoveryPhrase => 'Confirm Recovery Phrase';

  @override
  String get recoveryComplete => 'Recovery Complete';

  @override
  String get writeDownYourRecoveryPhrase => 'Write down your recovery phrase';

  @override
  String get youWillNeedToConfirmIt =>
      'You will need to confirm it in the next step';

  @override
  String get continueToVerify => 'Continue to Verify';

  @override
  String get verifyYourRecoveryPhrase => 'Verify your recovery phrase';

  @override
  String get enterTheFollowingWords =>
      'Enter the following words from your phrase';

  @override
  String get enterWord => 'Enter word';

  @override
  String get verify => 'Verify';

  @override
  String get incorrectWordsPleaseTryAgain =>
      'Incorrect words. Please try again.';

  @override
  String get skipVerification => 'Skip Verification?';

  @override
  String get skipVerificationWarning =>
      'Skipping verification means you haven\'t confirmed that you wrote down your recovery phrase correctly. If you lose access to your wallet, you may not be able to recover it.';

  @override
  String get skipAtOwnRisk => 'Skip at own risk';

  @override
  String get recoveryPhraseConfirmed => 'Recovery Phrase Confirmed!';

  @override
  String get yourRecoveryPhraseIsSecured =>
      'Your recovery phrase has been verified and secured. Keep it safe!';

  @override
  String get enterYourEmail => 'Enter Your Email';

  @override
  String get emailSignupDescription =>
      'Your email is used to create your Lendasat account for loans and other services.';

  @override
  String get emailUsageInfo =>
      'We\'ll use this email for account verification and important updates. Your wallet remains secured by your recovery phrase.';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get restoreWallet => 'Restore Wallet';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get registrationWarning =>
      'Account registration had an issue. You can still use your wallet.';

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get termsAndConditionsTitle1 => 'Terms and';

  @override
  String get termsAndConditionsTitle2 => 'Conditions';

  @override
  String get lastUpdated => 'Last Updated: December 2025';

  @override
  String get alphaVersion => 'Alpha Version';

  @override
  String get alphaVersionWarning =>
      'This app is under development. Use at your own risk.';

  @override
  String get agbScopeTitle => 'Scope of Application';

  @override
  String get agbScopeContent =>
      'These terms and conditions govern the use of the Bitcoin wallet app (hereinafter Lenda), provided by COBLOX PTY LTD. By using the app, you agree to these terms and conditions.';

  @override
  String get agbFunctionalityTitle => 'Functionality';

  @override
  String get agbFunctionalityContent =>
      'The app allows users to receive, send, and manage Bitcoin. The app is not a bank and does not provide banking services. Additionally, Taproot Assets, also known as digital assets, are offered and sold as a service platform.';

  @override
  String get agbUserResponsibilityTitle => 'User Responsibility';

  @override
  String get agbUserResponsibilityContent =>
      'The user is solely responsible for the security of their Bitcoin. The app provides security features such as password protection and two-factor authentication, but it is the user\'s responsibility to use these features carefully. COBLOX PTY LTD is not liable for losses resulting from carelessness, loss of devices, or user credentials.';

  @override
  String get agbFeesTitle => 'Fees';

  @override
  String get agbFeesContent =>
      'Certain functions of the app may incur fees. These fees will be communicated to the user in advance and are visible in the app.';

  @override
  String get agbLiabilityTitle => 'Limitation of Liability';

  @override
  String get agbLiabilityContent =>
      'COBLOX PTY LTD is only liable for damages caused by intentional or grossly negligent actions by COBLOX PTY LTD. COBLOX PTY LTD is not liable for damages resulting from the use of the app or the loss of Bitcoin.';

  @override
  String get agbChangesTitle => 'Changes';

  @override
  String get agbChangesContent =>
      'COBLOX PTY LTD reserves the right to change these terms and conditions at any time. The user will be informed of such changes and must agree to them in order to continue using the app.';

  @override
  String get agbFinalProvisionsTitle => 'Final Provisions';

  @override
  String get agbFinalProvisionsContent =>
      'These terms and conditions represent the entire agreement between the user and COBLOX PTY LTD. Should any provision be invalid, the remaining provisions shall remain in effect.';

  @override
  String get contact => 'Contact';

  @override
  String get responsibleForContent => 'Responsible for Content';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get disclaimerContent =>
      'The provider assumes no liability for the accuracy, correctness, completeness, or quality of the information provided. Liability claims against the provider are generally excluded unless there is proven intentional or grossly negligent fault.';

  @override
  String get allRightsReserved => 'All rights reserved';

  @override
  String get loansAndLeverage => 'Loans Marketplace';

  @override
  String get availableOffers => 'Available Offers';

  @override
  String get myContracts => 'My Contracts';

  @override
  String get signInRequired => 'Sign In Required';

  @override
  String get signInToViewContracts =>
      'Sign in to view your contracts and take loans. You can still browse available offers.';

  @override
  String get noArkadeOffersAvailable => 'No Arkade offers available';

  @override
  String get signInToViewYourContracts => 'Sign in to view your contracts';

  @override
  String get noContractsMatchSearch => 'No contracts match your search';

  @override
  String get noContractsYet =>
      'No contracts yet. Take an offer to get started!';

  @override
  String get duration => 'Duration';

  @override
  String get minLtv => 'Min LTV';

  @override
  String get limitedTimeOffer => 'Limited time offer — super cheap!';

  @override
  String get interest => 'Interest';

  @override
  String get due => 'Due';

  @override
  String get overdue => 'Overdue';

  @override
  String get swapDetails => 'Swap Details';

  @override
  String get errorLoadingSwap => 'Error loading swap';

  @override
  String get refundAddress => 'Refund Address';

  @override
  String get fundSwap => 'Fund Swap';

  @override
  String get youSend => 'You send';

  @override
  String get youReceive => 'You receive';

  @override
  String get walletConnected => 'Wallet Connected';

  @override
  String get switchWallet => 'Switch';

  @override
  String get creatingSwap => 'Creating Swap...';

  @override
  String get approvingToken => 'Approving token...';

  @override
  String get creatingHtlc => 'Creating HTLC...';

  @override
  String get swapFundedSuccessfully => 'Swap funded successfully!';

  @override
  String get feedback => 'Feedback';

  @override
  String get continueButton => 'Continue';

  @override
  String get paste => 'Paste';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get youPay => 'You pay';

  @override
  String get totalFeesLabel => 'Total fees';

  @override
  String get beforeFees => 'before fees';

  @override
  String get networkFee => 'Network';

  @override
  String get protocolFee => 'Protocol';

  @override
  String get receivingAddress => 'Receiving address';

  @override
  String get waitingForDeposit => 'Waiting for Deposit';

  @override
  String get processing => 'Processing';

  @override
  String get completed => 'Completed';

  @override
  String get expired => 'Expired';

  @override
  String get refundable => 'Refundable';

  @override
  String get refundedStatus => 'Refunded';

  @override
  String get failed => 'Failed';

  @override
  String get confirmSwap => 'Confirm Swap';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sender => 'Sender';

  @override
  String get receiver => 'Receiver';

  @override
  String get scan => 'Scan';

  @override
  String get aboutLendasat => 'About LendaSat';

  @override
  String get lendasatInfoDescription =>
      'LendaSat is a Bitcoin peer-to-peer loan marketplace. We act as a platform that connects you with private lenders who provide the funds. Your Bitcoin is used as collateral, and you receive the loan amount directly. All transactions are secured through smart contracts on the Bitcoin network.';

  @override
  String get learnMoreAboutLendasat => 'Learn more about how LendaSat works';

  @override
  String get sendingStatus => 'Sending...';

  @override
  String get sentStatus => 'Sent!';

  @override
  String get failedStatus => 'Failed';

  @override
  String get chooseRecipient => 'Choose Recipient';

  @override
  String get searchRecipient => 'Search or paste address...';

  @override
  String get recent => 'Recent';

  @override
  String get pasteOrScanAddress => 'Paste or scan a Bitcoin address';

  @override
  String get supportedFormats =>
      'Supports Bitcoin, Lightning, Ark, and LNURL addresses';

  @override
  String get justNow => 'Just now';

  @override
  String get minuteAgo => 'minute ago';

  @override
  String get hourAgo => 'hour ago';

  @override
  String get dayAgo => 'day ago';

  @override
  String get monthAgo => 'month ago';

  @override
  String get monthsAgo => 'months ago';

  @override
  String get yearAgo => 'year ago';

  @override
  String get yearsAgo => 'years ago';

  @override
  String get selectNetwork => 'Select Network';

  @override
  String get copied => 'Copied';
}
