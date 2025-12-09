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
  String get send => 'SEND';

  @override
  String get receive => 'RECEIVE';

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
  String get bitcoinOrArkAddress => 'Bitcoin or Ark address';

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
  String get boardingTransaction => 'Boarding Transaction';

  @override
  String get roundTransaction => 'Round Transaction';

  @override
  String get redeemTransaction => 'Redeem Transaction';

  @override
  String get sent => 'Sent';

  @override
  String get received => 'Received';

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
  String get recipient => 'Recipient';

  @override
  String get unknown => 'Unknown';

  @override
  String get walletAddressCopied => 'Wallet address copied';

  @override
  String get hashrate => 'Hashrate';

  @override
  String get fearAndGreedIndex => 'Fear & Greed Index';

  @override
  String get health => 'Health';
}
