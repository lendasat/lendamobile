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
  String get cancel => 'Cancel';

  @override
  String get save => 'حفظ';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'تم';

  @override
  String get select => 'اختيار';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'أدخل المبلغ';

  @override
  String get amount => 'Amount';

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
  String get retry => 'Retry';

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
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'أي عنوان ترغب بمشاركته؟';

  @override
  String get address => 'Address';

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
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'نسخ العنوان';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

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
  String get available => 'available';

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
  String get currency => 'Currency';

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
  String get errorLoadingTransactions => 'Error loading transactions';

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
