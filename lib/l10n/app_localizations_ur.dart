// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'ترتیبات';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'مکمل';

  @override
  String get select => 'منتخب کریں';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'رقم درج کریں';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'چھوڑیں (کوئی بھی رقم)';

  @override
  String get contin => 'جاری رکھیں';

  @override
  String get currencyUpdatedSuccessfully => 'کرنسی کامیابی سے اپ ڈیٹ ہو گئی';

  @override
  String get changeCurrency => 'کرنسی تبدیل کریں';

  @override
  String get languageUpdatedSuccessfully => 'زبان کامیابی سے اپ ڈیٹ ہو گئی';

  @override
  String get changeLanguage => 'زبان تبدیل کریں';

  @override
  String get themeAppliedSuccessfully => 'تھیم کامیابی سے لاگو ہو گیا';

  @override
  String get chooseYourColor => 'اپنا رنگ منتخب کریں';

  @override
  String get selectColor => 'رنگ منتخب کریں';

  @override
  String get selectColorShade => 'رنگ کی شیڈ منتخب کریں';

  @override
  String get changeYourStyle => 'اپنا انداز تبدیل کریں';

  @override
  String get chooseYourPreferredTheme => 'اپنی پسندیدہ تھیم منتخب کریں';

  @override
  String get dark => 'تاریک';

  @override
  String get originalDarkTheme => 'اصل تاریک تھیم';

  @override
  String get light => 'روشن';

  @override
  String get cleanLightTheme => 'صاف روشن تھیم';

  @override
  String get applyTheme => 'تھیم لاگو کریں';

  @override
  String get custom => 'مرضی کے مطابق';

  @override
  String get createYourOwnTheme => 'اپنی تھیم بنائیں';

  @override
  String get timezoneUpdatedSuccessfully => 'ٹائم زون کامیابی سے اپ ڈیٹ ہو گیا';

  @override
  String get changeTimezone => 'ٹائم زون تبدیل کریں';

  @override
  String get searchTimezone => 'ٹائم زون تلاش کریں...';

  @override
  String get couldntUpdateTransactions => 'ٹرانزیکشنز اپ ڈیٹ نہیں ہو سکیں:';

  @override
  String get couldntUpdateBalance => 'بیلنس اپ ڈیٹ نہیں ہو سکا:';

  @override
  String showingBalanceType(String balanceType) {
    return '$balanceType بیلنس دکھایا جا رہا ہے';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'زیر التواء بیلنس';

  @override
  String get confirmedBalance => 'تصدیق شدہ بیلنس';

  @override
  String get totalBalance => 'کل بیلنس';

  @override
  String get errorLoadingBalance => 'بیلنس لوڈ کرنے میں خرابی';

  @override
  String get send => 'بھیجیں';

  @override
  String get receive => 'وصول کریں';

  @override
  String get failedToCreateWallet => 'والیٹ بنانے میں ناکامی';

  @override
  String errorCreatingWallet(String error) {
    return 'آپ کا نیا والیٹ بنانے میں خرابی پیش آئی۔ براہ کرم دوبارہ کوشش کریں۔\n\nغلطی: $error';
  }

  @override
  String get failedToRestoreWallet => 'والیٹ بحال کرنے میں ناکامی';

  @override
  String errorRestoringWallet(String error) {
    return 'والیٹ بحال کرنے میں خرابی پیش آئی۔ براہ کرم اپنا nsec چیک کریں اور دوبارہ کوشش کریں۔\n\nغلطی: $error';
  }

  @override
  String get appTagline => 'Ark پر اڑنے والا والیٹ';

  @override
  String get ok => 'ٹھیک ہے';

  @override
  String get chooseAnOption => 'ایک آپشن منتخب کریں:';

  @override
  String get createNewWallet => 'نیا والیٹ بنائیں';

  @override
  String get generateANewSecureWallet => 'نیا محفوظ والیٹ تیار کریں';

  @override
  String get restoreExistingWallet => 'موجودہ والیٹ بحال کریں';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'اپنی خفیہ کلید سے والیٹ تک رسائی حاصل کریں';

  @override
  String get enterYourNsec => 'اپنا nsec درج کریں:';

  @override
  String get pasteYourRecoveryNsec => 'اپنا بحالی nsec چسپاں کریں...';

  @override
  String paymentMonitoringError(String error) {
    return 'ادائیگی کی نگرانی میں خرابی: $error';
  }

  @override
  String get paymentReceived => 'ادائیگی موصول ہو گئی!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'کون سا پتہ شیئر کریں؟';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'لائٹننگ انوائس';

  @override
  String get qrCodeImage => 'QR کوڈ تصویر';

  @override
  String get errorSharing => 'شیئر کرنے میں خرابی';

  @override
  String get myBitcoinAddressQrCode => 'میرا بٹ کوائن پتہ QR کوڈ';

  @override
  String get requesting => 'درخواست کر رہے ہیں: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'پتہ کاپی کریں';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'براہ کرم پتہ اور رقم دونوں درج کریں';

  @override
  String get pleaseEnterAValidAmount => 'براہ کرم درست رقم درج کریں';

  @override
  String get insufficientFunds => 'ناکافی رقم';

  @override
  String get sendLower => 'بھیجیں';

  @override
  String get receiveLower => 'وصول کریں';

  @override
  String get recipientAddress => 'وصول کنندہ کا پتہ';

  @override
  String get bitcoinOrArkAddress => 'بٹ کوائن یا Ark پتہ';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Esplora URL محفوظ ہو گیا - دوبارہ شروع کرنے کے بعد مؤثر ہوگا';

  @override
  String get failedToSaveEsploraUrl => 'Esplora URL محفوظ کرنے میں ناکامی';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'نیٹ ورک محفوظ ہو گیا - دوبارہ شروع کرنے کے بعد مؤثر ہوگا';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Ark سرور URL محفوظ ہو گیا - دوبارہ شروع کرنے کے بعد مؤثر ہوگا';

  @override
  String get failedToSaveArkServerUrl => 'Ark سرور URL محفوظ کرنے میں ناکامی';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Boltz URL محفوظ ہو گیا - دوبارہ شروع کرنے کے بعد مؤثر ہوگا';

  @override
  String get failedToSaveBoltzUrl => 'Boltz URL محفوظ کرنے میں ناکامی';

  @override
  String get securityWarning => 'سیکیورٹی انتباہ';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'اپنی بحالی کلید کسی کے ساتھ شیئر نہ کریں!';

  @override
  String get anyoneWithThisKeyCan =>
      'جس کے پاس یہ کلید ہوگی وہ آپ کے والیٹ تک رسائی حاصل کر سکتا ہے اور رقم چرا سکتا ہے۔ اسے محفوظ جگہ پر رکھیں۔';

  @override
  String get iUnderstand => 'میں سمجھ گیا';

  @override
  String get yourRecoveryPhrase => 'آپ کا بحالی فقرہ';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'بحالی فقرہ کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get copyToClipboard => 'کلپ بورڈ پر کاپی کریں';

  @override
  String get close => 'بند کریں';

  @override
  String get resetWallet => 'والیٹ ری سیٹ کریں';

  @override
  String get thisWillDeleteAllWalletData =>
      'اس سے اس آلہ سے تمام والیٹ ڈیٹا حذف ہو جائے گا۔ جاری رکھنے سے پہلے اپنا بحالی فقرہ محفوظ کر لیں۔ یہ عمل واپس نہیں ہو سکتا۔';

  @override
  String get restartingApp => 'ایپ دوبارہ شروع ہو رہی ہے';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'ایپ دوبارہ کھولنے کے لیے یہاں ٹیپ کریں۔';

  @override
  String get reset => 'ری سیٹ';

  @override
  String get wallet => 'والیٹ';

  @override
  String get viewRecoveryKey => 'بحالی کلید دیکھیں';

  @override
  String get backupYourWalletWithTheseKey =>
      'ان کلیدوں سے اپنا والیٹ بیک اپ کریں';

  @override
  String get appearancePreferences => 'ظاہری شکل اور ترجیحات';

  @override
  String get theme => 'تھیم';

  @override
  String get customizeAppAppearance => 'ایپ کی ظاہری شکل حسب ضرورت بنائیں';

  @override
  String get language => 'زبان';

  @override
  String get selectYourPreferredLanguage => 'اپنی پسندیدہ زبان منتخب کریں';

  @override
  String get timezone => 'ٹائم زون';

  @override
  String get chooseYourPreferredTimezone => 'اپنا پسندیدہ ٹائم زون منتخب کریں';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'اپنی پسندیدہ کرنسی منتخب کریں';

  @override
  String get serverConfiguration => 'سرور کی ترتیب';

  @override
  String get network => 'نیٹ ورک';

  @override
  String get esploraUrl => 'Esplora URL';

  @override
  String get arkServer => 'Ark سرور';

  @override
  String get boltzUrl => 'Boltz URL';

  @override
  String get about => 'کے بارے میں';

  @override
  String get loading => 'لوڈ ہو رہا ہے';

  @override
  String get dangerZone => 'خطرناک زون';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'اس آلے سے تمام والیٹ ڈیٹا حذف کریں';

  @override
  String get transactionFailed => 'ٹرانزیکشن ناکام ہوئی:';

  @override
  String get signTransaction => 'ٹرانزیکشن پر دستخط کریں';

  @override
  String get networkFees => 'نیٹ ورک فیس';

  @override
  String get total => 'کل';

  @override
  String get tapToSign => 'دستخط کرنے کے لیے ٹیپ کریں';

  @override
  String get settlingTransaction => 'ٹرانزیکشن مکمل کی جا رہی ہے...';

  @override
  String get success => 'کامیابی';

  @override
  String get transactionSettledSuccessfully =>
      'ٹرانزیکشن کامیابی سے مکمل ہو گئی!';

  @override
  String get goToHome => 'ہوم پر جائیں';

  @override
  String get error => 'خرابی';

  @override
  String get failedToSettleTransaction => 'ٹرانزیکشن مکمل کرنے میں ناکامی:';

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
  String get date => 'تاریخ';

  @override
  String get confirmedAt => 'تصدیق کی گئی تاریخ';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'ٹرانزیکشن زیر التواء ہے۔ مکمل ہونے کے بعد رقم واپس نہیں کی جا سکے گی۔';

  @override
  String get settle => 'مکمل کریں';

  @override
  String get transactionHistory => 'ٹرانزیکشن کی تاریخ';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'ابھی تک کوئی ٹرانزیکشن تاریخ نہیں';

  @override
  String get boardingTransaction => 'آن چین ٹرانزیکشن';

  @override
  String get roundTransaction => 'راؤنڈ ٹرانزیکشن';

  @override
  String get redeemTransaction => 'ری ڈیم ٹرانزیکشن';

  @override
  String get sent => 'بھیجی گئی';

  @override
  String get received => 'وصول شدہ';

  @override
  String get direction => 'سمت';

  @override
  String get settled => 'مکمل شدہ';

  @override
  String get sentSuccessfully => 'کامیابی سے بھیجا گیا';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'کامیاب ٹرانزیکشن کے بعد والیٹ پر واپس جا رہے ہیں';

  @override
  String get backToWallet => 'والیٹ پر واپس جائیں';

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
  String get med => ', \"Med\", ';

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
  String get reportBugFeedback => 'بگ رپورٹ / فیڈبیک';

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
  String get loansAndLeverage => 'قرضوں کا بازار';

  @override
  String get availableOffers => 'دستیاب پیشکشیں';

  @override
  String get myContracts => 'میرے معاہدے';

  @override
  String get signInRequired => 'سائن ان ضروری ہے';

  @override
  String get signInToViewContracts =>
      'اپنے معاہدے دیکھنے اور قرض لینے کے لیے سائن ان کریں۔';

  @override
  String get noArkadeOffersAvailable => 'کوئی Arkade پیشکش دستیاب نہیں';

  @override
  String get signInToViewYourContracts =>
      'اپنے معاہدے دیکھنے کے لیے سائن ان کریں';

  @override
  String get noContractsMatchSearch => 'کوئی معاہدہ آپ کی تلاش سے مماثل نہیں';

  @override
  String get noContractsYet =>
      'ابھی کوئی معاہدہ نہیں۔ شروع کرنے کے لیے پیشکش قبول کریں!';

  @override
  String get duration => 'مدت';

  @override
  String get minLtv => 'کم از کم LTV';

  @override
  String get limitedTimeOffer => 'محدود وقت کی پیشکش — بہت سستی!';

  @override
  String get interest => 'سود';

  @override
  String get due => 'واجب الادا';

  @override
  String get overdue => 'تاخیر';

  @override
  String get swapDetails => 'سواپ کی تفصیلات';

  @override
  String get errorLoadingSwap => 'سواپ لوڈ کرنے میں خرابی';

  @override
  String get refundAddress => 'واپسی کا پتہ';

  @override
  String get fundSwap => 'سواپ فنڈ کریں';

  @override
  String get youSend => 'آپ بھیجیں';

  @override
  String get youReceive => 'آپ وصول کریں';

  @override
  String get walletConnected => 'والیٹ منسلک';

  @override
  String get switchWallet => 'تبدیل';

  @override
  String get creatingSwap => 'سواپ بنایا جا رہا ہے...';

  @override
  String get approvingToken => 'ٹوکن منظور کیا جا رہا ہے...';

  @override
  String get creatingHtlc => 'HTLC بنایا جا رہا ہے...';

  @override
  String get swapFundedSuccessfully => 'سواپ کامیابی سے فنڈ ہو گیا!';

  @override
  String get feedback => 'فیڈبیک';

  @override
  String get continueButton => 'جاری رکھیں';

  @override
  String get paste => 'چسپاں';

  @override
  String get scanQr => 'QR اسکین';

  @override
  String get youPay => 'آپ ادا کریں';

  @override
  String get totalFeesLabel => 'کل فیس';

  @override
  String get beforeFees => 'فیس سے پہلے';

  @override
  String get networkFee => 'نیٹ ورک';

  @override
  String get protocolFee => 'پروٹوکول';

  @override
  String get receivingAddress => 'وصول کرنے کا پتہ';

  @override
  String get waitingForDeposit => 'ڈپازٹ کا انتظار';

  @override
  String get processing => 'پراسیس ہو رہا ہے';

  @override
  String get completed => 'مکمل';

  @override
  String get expired => 'ختم ہو گیا';

  @override
  String get refundable => 'واپسی قابل';

  @override
  String get refundedStatus => 'واپس';

  @override
  String get failed => 'ناکام';

  @override
  String get confirmSwap => 'سواپ کی تصدیق';

  @override
  String get unknownError => 'نامعلوم خرابی';

  @override
  String get sendFeedback => 'فیڈبیک بھیجیں';
}
