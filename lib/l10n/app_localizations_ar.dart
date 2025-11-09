// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'آرك فلاتر';

  @override
  String get settings => 'الإعدادات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get apply => 'تطبيق';

  @override
  String get done => 'تم';

  @override
  String get select => 'اختيار';

  @override
  String get search => 'بحث';

  @override
  String get enterAmount => 'أدخل المبلغ';

  @override
  String get amount => 'المبلغ';

  @override
  String get skipAnyAmount => 'تخطي (أي مبلغ)';

  @override
  String get contin => 'استمرار';

  @override
  String get currencyUpdatedSuccessfully => 'تم تحديث العملة بنجاح';

  @override
  String get changeCurrency => 'تغيير العملة';

  @override
  String get languageUpdatedSuccessfully => 'تم تحديث اللغة بنجاح';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get themeAppliedSuccessfully => 'تم تطبيق السمة بنجاح';

  @override
  String get chooseYourColor => 'اختر لونك';

  @override
  String get selectColor => 'اختر اللون';

  @override
  String get selectColorShade => 'اختر درجة اللون';

  @override
  String get changeYourStyle => 'غيّر نمطك';

  @override
  String get chooseYourPreferredTheme => 'اختر السمة المفضلة لديك';

  @override
  String get dark => 'داكن';

  @override
  String get originalDarkTheme => 'السمة الداكنة الأصلية';

  @override
  String get light => 'فاتح';

  @override
  String get cleanLightTheme => 'السمة الفاتحة النظيفة';

  @override
  String get applyTheme => 'تطبيق السمة';

  @override
  String get custom => 'مخصص';

  @override
  String get createYourOwnTheme => 'أنشئ سمتك الخاصة';

  @override
  String get timezoneUpdatedSuccessfully => 'تم تحديث المنطقة الزمنية بنجاح';

  @override
  String get changeTimezone => 'تغيير المنطقة الزمنية';

  @override
  String get searchTimezone => 'ابحث عن المنطقة الزمنية...';

  @override
  String get couldntUpdateTransactions => 'تعذر تحديث المعاملات:';

  @override
  String get couldntUpdateBalance => 'تعذر تحديث الرصيد:';

  @override
  String showingBalanceType(String balanceType) {
    return 'عرض رصيد $balanceType';
  }

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get pendingBalance => 'الرصيد المعلق';

  @override
  String get confirmedBalance => 'الرصيد المؤكد';

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String get errorLoadingBalance => 'خطأ في تحميل الرصيد';

  @override
  String get send => 'إرسال';

  @override
  String get receive => 'استلام';

  @override
  String get failedToCreateWallet => 'فشل في إنشاء المحفظة';

  @override
  String errorCreatingWallet(String error) {
    return 'حدث خطأ أثناء إنشاء المحفظة الجديدة. يرجى المحاولة مرة أخرى.\n\nالخطأ: $error';
  }

  @override
  String get failedToRestoreWallet => 'فشل في استعادة المحفظة';

  @override
  String errorRestoringWallet(String error) {
    return 'حدث خطأ أثناء استعادة المحفظة. يرجى التحقق من nsec والمحاولة مرة أخرى.\n\nالخطأ: $error';
  }

  @override
  String get appTagline => 'محفظة تطير على آرك';

  @override
  String get ok => 'موافق';

  @override
  String get chooseAnOption => 'اختر خيارًا:';

  @override
  String get createNewWallet => 'إنشاء محفظة جديدة';

  @override
  String get generateANewSecureWallet => 'إنشاء محفظة جديدة آمنة';

  @override
  String get restoreExistingWallet => 'استعادة محفظة موجودة';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'استخدم مفتاحك السري للوصول إلى محفظتك';

  @override
  String get enterYourNsec => 'أدخل nsec الخاص بك:';

  @override
  String get pasteYourRecoveryNsec => 'الصق nsec الاسترداد...';

  @override
  String paymentMonitoringError(String error) {
    return 'خطأ في مراقبة الدفع: $error';
  }

  @override
  String get paymentReceived => 'تم استلام الدفعة!';

  @override
  String get addressCopiedToClipboard => 'تم نسخ العنوان إلى الحافظة';

  @override
  String get shareWhichAddress => 'أي عنوان ترغب بمشاركته؟';

  @override
  String get address => 'العنوان';

  @override
  String get lightningInvoice => 'فاتورة Lightning';

  @override
  String get qrCodeImage => 'صورة رمز QR';

  @override
  String get errorSharing => 'خطأ أثناء المشاركة';

  @override
  String get myBitcoinAddressQrCode => 'رمز QR لعنوان البيتكوين الخاص بي';

  @override
  String get requesting => 'جاري الطلب: ';

  @override
  String get monitoringForIncomingPayment => 'مراقبة المدفوعات الواردة...';

  @override
  String get copyAddress => 'نسخ العنوان';

  @override
  String get errorLoadingAddresses => 'خطأ في تحميل العناوين';

  @override
  String get share => 'مشاركة';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'يرجى إدخال العنوان والمبلغ معًا';

  @override
  String get pleaseEnterAValidAmount => 'يرجى إدخال مبلغ صالح';

  @override
  String get insufficientFunds => 'رصيد غير كافٍ';

  @override
  String get sendLower => 'إرسال';

  @override
  String get receiveLower => 'استلام';

  @override
  String get recipientAddress => 'عنوان المستلم';

  @override
  String get bitcoinOrArkAddress => 'عنوان بيتكوين أو آرك';

  @override
  String get available => 'متاح';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'تم حفظ عنوان Esplora - سيسري بعد إعادة التشغيل';

  @override
  String get failedToSaveEsploraUrl => 'فشل حفظ عنوان Esplora';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'تم حفظ الشبكة - سيسري بعد إعادة التشغيل';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'تم حفظ عنوان خادم آرك - سيسري بعد إعادة التشغيل';

  @override
  String get failedToSaveArkServerUrl => 'فشل حفظ عنوان خادم آرك';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'تم حفظ عنوان Boltz - سيسري بعد إعادة التشغيل';

  @override
  String get failedToSaveBoltzUrl => 'فشل حفظ عنوان Boltz';

  @override
  String get securityWarning => 'تحذير أمني';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'لا تشارك مفتاح الاسترداد الخاص بك مع أي شخص!';

  @override
  String get anyoneWithThisKeyCan =>
      'أي شخص يملك هذا المفتاح يمكنه الوصول إلى محفظتك وسرقة أموالك. احتفظ به في مكان آمن.';

  @override
  String get iUnderstand => 'أفهم';

  @override
  String get yourRecoveryPhrase => 'عبارة الاسترداد الخاصة بك';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'تم نسخ عبارة الاسترداد إلى الحافظة';

  @override
  String get copyToClipboard => 'نسخ إلى الحافظة';

  @override
  String get close => 'إغلاق';

  @override
  String get resetWallet => 'إعادة تعيين المحفظة';

  @override
  String get thisWillDeleteAllWalletData =>
      'سيؤدي هذا إلى حذف جميع بيانات المحفظة من هذا الجهاز. تأكد من نسخ عبارة الاسترداد قبل المتابعة. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get restartingApp => 'إعادة تشغيل التطبيق';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'يرجى النقر هنا لفتح التطبيق مرة أخرى.';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get wallet => 'المحفظة';

  @override
  String get viewRecoveryKey => 'عرض مفتاح الاسترداد';

  @override
  String get backupYourWalletWithTheseKey =>
      'قم بعمل نسخة احتياطية لمحفظتك باستخدام هذا المفتاح';

  @override
  String get appearancePreferences => 'المظهر والتفضيلات';

  @override
  String get theme => 'السمة';

  @override
  String get customizeAppAppearance => 'تخصيص مظهر التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get selectYourPreferredLanguage => 'اختر لغتك المفضلة';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get chooseYourPreferredTimezone => 'اختر منطقتك الزمنية المفضلة';

  @override
  String get currency => 'العملة';

  @override
  String get chooseYourPreferredCurrency => 'اختر عملتك المفضلة';

  @override
  String get serverConfiguration => 'إعدادات الخادم';

  @override
  String get network => 'الشبكة';

  @override
  String get esploraUrl => 'عنوان Esplora';

  @override
  String get arkServer => 'خادم آرك';

  @override
  String get boltzUrl => 'عنوان Boltz';

  @override
  String get about => 'حول';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'حذف جميع بيانات المحفظة من هذا الجهاز';

  @override
  String get transactionFailed => 'فشلت المعاملة:';

  @override
  String get signTransaction => 'توقيع المعاملة';

  @override
  String get networkFees => 'رسوم الشبكة';

  @override
  String get total => 'الإجمالي';

  @override
  String get tapToSign => 'اضغط للتوقيع';

  @override
  String get settlingTransaction => 'تسوية المعاملة...';

  @override
  String get success => 'نجاح';

  @override
  String get transactionSettledSuccessfully => 'تمت تسوية المعاملة بنجاح!';

  @override
  String get goToHome => 'العودة إلى الرئيسية';

  @override
  String get error => 'خطأ';

  @override
  String get failedToSettleTransaction => 'فشل في تسوية المعاملة:';

  @override
  String get pendingConfirmation => 'قيد التأكيد';

  @override
  String get transactionId => 'معرّف المعاملة';

  @override
  String get status => 'الحالة';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get pending => 'معلق';

  @override
  String get date => 'التاريخ';

  @override
  String get confirmedAt => 'تم التأكيد في';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'المعاملة معلقة. ستصبح الأموال غير قابلة للاسترجاع بعد التسوية.';

  @override
  String get settle => 'تسوية';

  @override
  String get transactionHistory => 'سجل المعاملات';

  @override
  String get errorLoadingTransactions => 'خطأ في تحميل المعاملات';

  @override
  String get noTransactionHistoryYet => 'لا يوجد سجل معاملات بعد';

  @override
  String get boardingTransaction => 'معاملة الانضمام';

  @override
  String get roundTransaction => 'معاملة التقريب';

  @override
  String get redeemTransaction => 'معاملة الاسترداد';

  @override
  String get sent => 'تم الإرسال';

  @override
  String get received => 'تم الاستلام';

  @override
  String get settled => 'تمت التسوية';

  @override
  String get sentSuccessfully => 'تم الإرسال بنجاح';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'العودة إلى المحفظة بعد المعاملة الناجحة';

  @override
  String get backToWallet => 'العودة إلى المحفظة';
}
