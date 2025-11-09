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
  String get monitoringForIncomingPayment =>
      'موصول ہونے والی ادائیگی کی نگرانی...';

  @override
  String get copyAddress => 'پتہ کاپی کریں';

  @override
  String get errorLoadingAddresses => 'پتوں کو لوڈ کرنے میں خرابی';

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
  String get pendingConfirmation => 'تصدیق زیر التواء';

  @override
  String get transactionId => 'ٹرانزیکشن آئی ڈی';

  @override
  String get status => 'حالت';

  @override
  String get confirmed => 'تصدیق شدہ';

  @override
  String get pending => 'زیر التواء';

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
  String get errorLoadingTransactions => 'ٹرانزیکشن لوڈ کرنے میں خرابی';

  @override
  String get noTransactionHistoryYet => 'ابھی تک کوئی ٹرانزیکشن تاریخ نہیں';

  @override
  String get boardingTransaction => 'بورڈنگ ٹرانزیکشن';

  @override
  String get roundTransaction => 'راؤنڈ ٹرانزیکشن';

  @override
  String get redeemTransaction => 'ری ڈیم ٹرانزیکشن';

  @override
  String get sent => 'بھیجی گئی';

  @override
  String get received => 'وصول شدہ';

  @override
  String get settled => 'مکمل شدہ';

  @override
  String get sentSuccessfully => 'کامیابی سے بھیجا گیا';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'کامیاب ٹرانزیکشن کے بعد والیٹ پر واپس جا رہے ہیں';

  @override
  String get backToWallet => 'والیٹ پر واپس جائیں';
}
