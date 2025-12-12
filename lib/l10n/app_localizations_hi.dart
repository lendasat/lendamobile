// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'सहेजें';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'पूर्ण';

  @override
  String get select => 'चुनें';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'राशि दर्ज करें';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'छोड़ें (कोई भी राशि)';

  @override
  String get contin => 'जारी रखें';

  @override
  String get currencyUpdatedSuccessfully => 'मुद्रा सफलतापूर्वक अपडेट की गई';

  @override
  String get changeCurrency => 'मुद्रा बदलें';

  @override
  String get languageUpdatedSuccessfully => 'भाषा सफलतापूर्वक अपडेट की गई';

  @override
  String get changeLanguage => 'भाषा बदलें';

  @override
  String get themeAppliedSuccessfully => 'थीम सफलतापूर्वक लागू की गई';

  @override
  String get chooseYourColor => 'अपना रंग चुनें';

  @override
  String get selectColor => 'रंग चुनें';

  @override
  String get selectColorShade => 'रंग की छाया चुनें';

  @override
  String get changeYourStyle => 'अपनी शैली बदलें';

  @override
  String get chooseYourPreferredTheme => 'अपनी पसंदीदा थीम चुनें';

  @override
  String get dark => 'गहरा';

  @override
  String get originalDarkTheme => 'मूल गहरा थीम';

  @override
  String get light => 'हल्का';

  @override
  String get cleanLightTheme => 'साफ हल्का थीम';

  @override
  String get applyTheme => 'थीम लागू करें';

  @override
  String get custom => 'कस्टम';

  @override
  String get createYourOwnTheme => 'अपनी खुद की थीम बनाएं';

  @override
  String get timezoneUpdatedSuccessfully =>
      'समय क्षेत्र सफलतापूर्वक अपडेट किया गया';

  @override
  String get changeTimezone => 'समय क्षेत्र बदलें';

  @override
  String get searchTimezone => 'समय क्षेत्र खोजें...';

  @override
  String get couldntUpdateTransactions => 'लेनदेन अपडेट नहीं कर सका:';

  @override
  String get couldntUpdateBalance => 'बैलेंस अपडेट नहीं कर सका:';

  @override
  String showingBalanceType(String balanceType) {
    return '$balanceType बैलेंस दिखा रहा है';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'लंबित बैलेंस';

  @override
  String get confirmedBalance => 'पुष्ट बैलेंस';

  @override
  String get totalBalance => 'कुल बैलेंस';

  @override
  String get errorLoadingBalance => 'बैलेंस लोड करने में त्रुटि';

  @override
  String get send => 'भेजें';

  @override
  String get receive => 'प्राप्त करें';

  @override
  String get failedToCreateWallet => 'वॉलेट बनाने में विफल';

  @override
  String errorCreatingWallet(String error) {
    return 'आपका नया वॉलेट बनाते समय एक त्रुटि हुई। कृपया पुनः प्रयास करें।\n\nत्रुटि: $error';
  }

  @override
  String get failedToRestoreWallet => 'वॉलेट पुनर्स्थापित करने में विफल';

  @override
  String errorRestoringWallet(String error) {
    return 'आपका वॉलेट पुनर्स्थापित करते समय एक त्रुटि हुई। कृपया अपना nsec जांचें और पुनः प्रयास करें।\n\nत्रुटि: $error';
  }

  @override
  String get appTagline => 'Ark पर उड़ने वाला वॉलेट';

  @override
  String get ok => 'ठीक है';

  @override
  String get chooseAnOption => 'एक विकल्प चुनें:';

  @override
  String get createNewWallet => 'नया वॉलेट बनाएं';

  @override
  String get generateANewSecureWallet => 'एक नया सुरक्षित वॉलेट बनाएं';

  @override
  String get restoreExistingWallet => 'मौजूदा वॉलेट पुनर्स्थापित करें';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'अपने वॉलेट तक पहुंचने के लिए अपनी गुप्त कुंजी का उपयोग करें';

  @override
  String get enterYourNsec => 'अपना nsec दर्ज करें:';

  @override
  String get pasteYourRecoveryNsec => 'अपना रिकवरी nsec पेस्ट करें...';

  @override
  String paymentMonitoringError(String error) {
    return 'भुगतान मॉनिटरिंग त्रुटि: $error';
  }

  @override
  String get paymentReceived => 'भुगतान प्राप्त हुआ!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'कौन सा पता साझा करें?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'लाइटनिंग इनवॉइस';

  @override
  String get qrCodeImage => 'QR कोड छवि';

  @override
  String get errorSharing => 'साझा करते समय त्रुटि';

  @override
  String get myBitcoinAddressQrCode => 'मेरा बिटकॉइन पता QR कोड';

  @override
  String get requesting => 'अनुरोध कर रहे हैं: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'पता कॉपी करें';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'कृपया पता और राशि दोनों दर्ज करें';

  @override
  String get pleaseEnterAValidAmount => 'कृपया एक मान्य राशि दर्ज करें';

  @override
  String get insufficientFunds => 'पर्याप्त धन नहीं';

  @override
  String get sendLower => 'भेजें';

  @override
  String get receiveLower => 'प्राप्त करें';

  @override
  String get recipientAddress => 'प्राप्तकर्ता का पता';

  @override
  String get bitcoinOrArkAddress => 'बिटकॉइन या Ark पता';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Esplora URL सहेजा गया - पुनः प्रारंभ के बाद प्रभावी होगा';

  @override
  String get failedToSaveEsploraUrl => 'Esplora URL सहेजने में विफल';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'नेटवर्क सहेजा गया - पुनः प्रारंभ के बाद प्रभावी होगा';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Ark सर्वर URL सहेजा गया - पुनः प्रारंभ के बाद प्रभावी होगा';

  @override
  String get failedToSaveArkServerUrl => 'Ark सर्वर URL सहेजने में विफल';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Boltz URL सहेजा गया - पुनः प्रारंभ के बाद प्रभावी होगा';

  @override
  String get failedToSaveBoltzUrl => 'Boltz URL सहेजने में विफल';

  @override
  String get securityWarning => 'सुरक्षा चेतावनी';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'अपनी रिकवरी कुंजी किसी के साथ साझा न करें!';

  @override
  String get anyoneWithThisKeyCan =>
      'इस कुंजी के साथ कोई भी व्यक्ति आपके वॉलेट तक पहुंच सकता है और आपके धन को चुरा सकता है। इसे सुरक्षित स्थान पर रखें।';

  @override
  String get iUnderstand => 'मैं समझ गया';

  @override
  String get yourRecoveryPhrase => 'आपका रिकवरी वाक्यांश';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'रिकवरी वाक्यांश क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get copyToClipboard => 'क्लिपबोर्ड पर कॉपी करें';

  @override
  String get close => 'बंद करें';

  @override
  String get resetWallet => 'वॉलेट रीसेट करें';

  @override
  String get thisWillDeleteAllWalletData =>
      'यह इस डिवाइस से सभी वॉलेट डेटा हटा देगा। आगे बढ़ने से पहले सुनिश्चित करें कि आपने अपना रिकवरी वाक्यांश सहेजा है। यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get restartingApp => 'ऐप पुनः प्रारंभ हो रहा है';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'कृपया ऐप को फिर से खोलने के लिए यहाँ टैप करें।';

  @override
  String get reset => 'रीसेट करें';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get viewRecoveryKey => 'रिकवरी कुंजी देखें';

  @override
  String get backupYourWalletWithTheseKey =>
      'इन कुंजियों के साथ अपना वॉलेट बैकअप करें';

  @override
  String get appearancePreferences => 'दिखावट और प्राथमिकताएँ';

  @override
  String get theme => 'थीम';

  @override
  String get customizeAppAppearance => 'ऐप की दिखावट को अनुकूलित करें';

  @override
  String get language => 'भाषा';

  @override
  String get selectYourPreferredLanguage => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get timezone => 'समय क्षेत्र';

  @override
  String get chooseYourPreferredTimezone => 'अपना पसंदीदा समय क्षेत्र चुनें';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'अपनी पसंदीदा मुद्रा चुनें';

  @override
  String get serverConfiguration => 'सर्वर कॉन्फ़िगरेशन';

  @override
  String get network => 'नेटवर्क';

  @override
  String get esploraUrl => 'Esplora URL';

  @override
  String get arkServer => 'Ark सर्वर';

  @override
  String get boltzUrl => 'Boltz URL';

  @override
  String get about => 'के बारे में';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get dangerZone => 'खतरे का क्षेत्र';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'इस डिवाइस से सभी वॉलेट डेटा हटाएँ';

  @override
  String get transactionFailed => 'लेनदेन विफल:';

  @override
  String get signTransaction => 'लेनदेन पर हस्ताक्षर करें';

  @override
  String get networkFees => 'नेटवर्क शुल्क';

  @override
  String get total => 'कुल';

  @override
  String get tapToSign => 'हस्ताक्षर करने के लिए टैप करें';

  @override
  String get settlingTransaction => 'लेनदेन निपटाया जा रहा है...';

  @override
  String get success => 'सफलता';

  @override
  String get transactionSettledSuccessfully => 'लेनदेन सफलतापूर्वक पूरा हुआ!';

  @override
  String get goToHome => 'होम पर जाएँ';

  @override
  String get error => 'त्रुटि';

  @override
  String get failedToSettleTransaction => 'लेनदेन पूरा करने में विफल:';

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
  String get date => 'तारीख';

  @override
  String get confirmedAt => 'पुष्ट किया गया समय';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'लेनदेन लंबित है। निपटान के बाद धन अपरिवर्तनीय होगा।';

  @override
  String get settle => 'निपटाएं';

  @override
  String get transactionHistory => 'लेनदेन इतिहास';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'अभी तक कोई लेनदेन इतिहास नहीं';

  @override
  String get boardingTransaction => 'ऑनचेन लेनदेन';

  @override
  String get roundTransaction => 'राउंड लेनदेन';

  @override
  String get redeemTransaction => 'रिडीम लेनदेन';

  @override
  String get sent => 'भेजा गया';

  @override
  String get received => 'प्राप्त हुआ';

  @override
  String get settled => 'निपटाया गया';

  @override
  String get sentSuccessfully => 'सफलतापूर्वक भेजा गया';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'सफल लेनदेन के बाद वॉलेट पर लौट रहे हैं';

  @override
  String get backToWallet => 'वॉलेट पर वापस जाएँ';

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
