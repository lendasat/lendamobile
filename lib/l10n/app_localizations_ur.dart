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
  String get cancel => 'منسوخ کریں';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get note => 'Note';

  @override
  String get addNote => 'Add a note';

  @override
  String get apply => 'لاگو کریں';

  @override
  String get done => 'مکمل';

  @override
  String get select => 'منتخب کریں';

  @override
  String get search => 'تلاش کریں';

  @override
  String get enterAmount => 'رقم درج کریں';

  @override
  String get amountTooLow => 'Amount Too Low';

  @override
  String get amountTooHigh => 'Amount Too High';

  @override
  String get amount => 'رقم';

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
  String get retry => 'دوبارہ کوشش کریں';

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
  String get addressCopiedToClipboard => 'پتہ کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get shareWhichAddress => 'کون سا پتہ شیئر کریں؟';

  @override
  String get address => 'پتہ';

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
  String get monitoringForIncomingPayment => 'آنے والی ادائیگی کی نگرانی...';

  @override
  String get copyAddress => 'پتہ کاپی کریں';

  @override
  String get errorLoadingAddresses => 'پتے لوڈ کرنے میں خرابی';

  @override
  String get share => 'شیئر کریں';

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
  String get available => 'دستیاب';

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
  String get currency => 'کرنسی';

  @override
  String get chooseYourPreferredCurrency => 'اپنی پسندیدہ کرنسی منتخب کریں';

  @override
  String get preferences => 'Preferences';

  @override
  String get autoReadClipboard => 'Auto-read clipboard';

  @override
  String get autoReadClipboardDescription =>
      'Automatically check clipboard for Bitcoin addresses when sending';

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
  String get pendingConfirmation => 'تصدیق زیر التوا';

  @override
  String get transactionId => 'ٹرانزیکشن آئی ڈی';

  @override
  String get status => 'حیثیت';

  @override
  String get confirmed => 'تصدیق شدہ';

  @override
  String get pending => 'زیر التوا';

  @override
  String get spendable => 'خرچ کے قابل';

  @override
  String get date => 'تاریخ';

  @override
  String get time => 'وقت';

  @override
  String get transactionVolume => 'ٹرانزیکشن کی مقدار';

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
  String get errorLoadingTransactions => 'ٹرانزیکشنز لوڈ کرنے میں خرابی';

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
  String get transactionFees => 'ٹرانزیکشن فیس';

  @override
  String get fastest10Min => 'تیز ترین (~10 منٹ)';

  @override
  String get halfHour => 'آدھا گھنٹہ';

  @override
  String get oneHour => 'ایک گھنٹہ';

  @override
  String get economy => 'اقتصادی';

  @override
  String get minutesAgo => 'منٹ پہلے';

  @override
  String get hoursAgo => 'گھنٹے پہلے';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String get daysAgo => 'دن پہلے';

  @override
  String get miningInformation => 'مائننگ معلومات';

  @override
  String get miningPool => 'مائننگ پول';

  @override
  String get mined => 'مائن شدہ';

  @override
  String get blockReward => 'بلاک انعام';

  @override
  String get totalFees => 'کل فیس';

  @override
  String get min => 'کم سے کم';

  @override
  String get networkHashrate => 'نیٹ ورک ہیش ریٹ';

  @override
  String get currentNetworkHashrate => 'موجودہ نیٹ ورک ہیش ریٹ';

  @override
  String get noDataAvailable => 'کوئی ڈیٹا دستیاب نہیں';

  @override
  String get difficulty => 'مشکل';

  @override
  String get dataPoints => 'ڈیٹا پوائنٹس';

  @override
  String get days => 'دن';

  @override
  String get hours => 'گھنٹے';

  @override
  String get minutes => 'منٹ';

  @override
  String get difficultyAdjustment => 'مشکل ایڈجسٹمنٹ';

  @override
  String get complete => 'مکمل';

  @override
  String get remainingBlocks => 'باقی بلاکس';

  @override
  String get estTime => 'تخمینی وقت';

  @override
  String get estDate => 'تخمینی تاریخ';

  @override
  String get mAgo => 'م پہلے';

  @override
  String get hAgo => 'گھ پہلے';

  @override
  String get dAgo => 'د پہلے';

  @override
  String get blockSize => 'بلاک سائز';

  @override
  String get weight => 'وزن';

  @override
  String get transactions => 'ٹرانزیکشنز';

  @override
  String get avgSize => 'اوسط سائز';

  @override
  String get healthy => 'صحت مند';

  @override
  String get fair => 'معقول';

  @override
  String get low => 'کم';

  @override
  String get blockHealth => 'بلاک صحت';

  @override
  String get full => 'مکمل';

  @override
  String get actual => 'اصل';

  @override
  String get expected => 'متوقع';

  @override
  String get difference => 'فرق';

  @override
  String get setAmount => 'رقم مقرر کریں';

  @override
  String get clear => 'صاف کریں';

  @override
  String get errorSharingQrCode => 'QR کوڈ شیئر کرنے میں خرابی:';

  @override
  String get qr => 'QR';

  @override
  String get type => 'قسم';

  @override
  String get sellBitcoin => 'بٹ کوائن بیچیں';

  @override
  String get errorLoadingSellScreen => 'فروخت کی سکرین لوڈ کرنے میں خرابی';

  @override
  String get availableBalance => 'دستیاب بیلنس';

  @override
  String get amountToSell => 'فروخت کی رقم';

  @override
  String get sellLimits => 'فروخت کی حدود';

  @override
  String get insufficientBalance => 'ناکافی بیلنس';

  @override
  String get max => 'زیادہ سے زیادہ';

  @override
  String get payoutMethods => 'ادائیگی کے طریقے';

  @override
  String get pendingBlock => 'زیر التوا بلاک';

  @override
  String get nextBlock => 'اگلا بلاک';

  @override
  String get medianFee => 'درمیانی فیس';

  @override
  String get estimatedTime => 'تخمینی وقت';

  @override
  String get feeDistribution => 'فیس کی تقسیم';

  @override
  String get noTransactionsYet => 'ابھی تک کوئی ٹرانزیکشن نہیں';

  @override
  String get loadingMoreTransactions => 'مزید ٹرانزیکشنز لوڈ ہو رہی ہیں...';

  @override
  String get scrollDownToLoadMore => 'مزید لوڈ کرنے کے لیے نیچے سکرول کریں';

  @override
  String get med => 'درمیانی';

  @override
  String get feeRate => 'فیس کی شرح';

  @override
  String get size => 'سائز';

  @override
  String get value => 'قیمت';

  @override
  String get copiedToClipboard => 'کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get transactionDetails => 'ٹرانزیکشن کی تفصیلات';

  @override
  String get errorLoadingTransaction => 'ٹرانزیکشن لوڈ کرنے میں خرابی';

  @override
  String get blockHeight => 'بلاک کی اونچائی';

  @override
  String get blockTime => 'بلاک کا وقت';

  @override
  String get details => 'تفصیلات';

  @override
  String get fee => 'فیس';

  @override
  String get version => 'ورژن';

  @override
  String get locktime => 'لاک ٹائم';

  @override
  String get inputs => 'ان پٹس';

  @override
  String get outputs => 'آؤٹ پٹس';

  @override
  String get searchBlockchain => 'بلاک چین تلاش کریں';

  @override
  String get transaction => 'ٹرانزیکشن';

  @override
  String get enterBlockHeightOrBlockHash =>
      'بلاک کی اونچائی یا بلاک ہیش درج کریں';

  @override
  String get enterTransactionIdTxid => 'ٹرانزیکشن آئی ڈی (TXID) درج کریں';

  @override
  String get blockchain => 'بلاک چین';

  @override
  String get errorLoadingData => 'ڈیٹا لوڈ کرنے میں خرابی';

  @override
  String get recentTransactions => 'حالیہ ٹرانزیکشنز';

  @override
  String get block => 'بلاک';

  @override
  String get yourTx => 'آپ کی TX';

  @override
  String get paymentMethods => 'ادائیگی کے طریقے';

  @override
  String get paymentProvider => 'Payment Provider';

  @override
  String get chooseProvider => 'Choose Provider';

  @override
  String get buyLimits => 'خریداری کی حدود';

  @override
  String get errorLoadingBuyScreen => 'خریداری کی سکرین لوڈ کرنے میں خرابی';

  @override
  String get buyBitcoin => 'بٹ کوائن خریدیں';

  @override
  String get failedToLaunchMoonpay => 'MoonPay شروع کرنے میں ناکامی';

  @override
  String get bitcoinPriceChart => 'بٹ کوائن قیمت چارٹ';

  @override
  String get aboutBitcoin => 'About Bitcoin';

  @override
  String get bitcoinDescription =>
      'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.';

  @override
  String get aboutBitcoinPriceData => 'بٹ کوائن قیمت ڈیٹا کے بارے میں';

  @override
  String get thePriceDataShown =>
      'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.';

  @override
  String get dataSource => 'ڈیٹا ماخذ';

  @override
  String get liveBitcoinMarketData => 'لائیو بٹ کوائن مارکیٹ ڈیٹا';

  @override
  String get updateFrequency => 'اپ ڈیٹ کی تعداد';

  @override
  String get realTime => 'ریئل ٹائم';

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
      'The app allows users to receive, send, and manage Bitcoin. The app is not a bank and does not provide banking services.';

  @override
  String get agbUserResponsibilityTitle => 'User Responsibility';

  @override
  String get agbUserResponsibilityContent =>
      'The user is fully self-responsible for using the application and the security of their Bitcoin. The user acknowledges that loss of their recovery phrase (mnemonic) is equivalent to loss of their funds. COBLOX PTY LTD is not liable for any losses resulting from carelessness, loss of devices, or loss of the recovery phrase.';

  @override
  String get agbFeesTitle => 'Fees';

  @override
  String get agbFeesContent =>
      'Certain functions of the app may incur fees. These fees will be communicated to the user in advance and are visible in the app.';

  @override
  String get agbBuyingSelling => 'Buying and Selling Bitcoin';

  @override
  String get agbBuyingSellingContent =>
      'Buying and selling Bitcoin is facilitated through third-party providers. COBLOX PTY LTD is not involved in these transactions and bears no responsibility for them. Any issues, disputes, or inquiries related to buying or selling Bitcoin must be directed to and resolved with the respective third-party provider.';

  @override
  String get agbLiabilityTitle => 'Limitation of Liability';

  @override
  String get agbLiabilityContent =>
      'COBLOX PTY LTD is only liable for damages caused by intentional or grossly negligent actions by COBLOX PTY LTD. COBLOX PTY LTD is not liable for damages resulting from the use of the app or the loss of Bitcoin.';

  @override
  String get agbChangesTitle => 'Changes';

  @override
  String get agbChangesContent =>
      'COBLOX PTY LTD reserves the right to change these terms and conditions at any time. Continued use of the app constitutes acceptance of any updated terms.';

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
  String get loansAndContracts => 'قرضے اور معاہدے';

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

  @override
  String get sender => 'بھیجنے والا';

  @override
  String get receiver => 'وصول کنندہ';

  @override
  String get scan => 'اسکین';

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
  String get copied => 'کاپی ہو گیا';
}
