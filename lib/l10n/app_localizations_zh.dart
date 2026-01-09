// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => '设置';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => '保存';

  @override
  String get apply => 'Apply';

  @override
  String get done => '完成';

  @override
  String get select => '选择';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => '输入金额';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => '跳过（任意金额）';

  @override
  String get contin => '继续';

  @override
  String get currencyUpdatedSuccessfully => '货币更新成功';

  @override
  String get changeCurrency => '更改货币';

  @override
  String get languageUpdatedSuccessfully => '语言更新成功';

  @override
  String get changeLanguage => '更改语言';

  @override
  String get themeAppliedSuccessfully => '主题应用成功';

  @override
  String get chooseYourColor => '选择颜色';

  @override
  String get selectColor => '选择颜色';

  @override
  String get selectColorShade => '选择颜色深浅';

  @override
  String get changeYourStyle => '更改样式';

  @override
  String get chooseYourPreferredTheme => '选择您喜欢的主题';

  @override
  String get dark => '深色';

  @override
  String get originalDarkTheme => '原始深色主题';

  @override
  String get light => '浅色';

  @override
  String get cleanLightTheme => '清新浅色主题';

  @override
  String get applyTheme => '应用主题';

  @override
  String get custom => '自定义';

  @override
  String get createYourOwnTheme => '创建您自己的主题';

  @override
  String get timezoneUpdatedSuccessfully => '时区更新成功';

  @override
  String get changeTimezone => '更改时区';

  @override
  String get searchTimezone => '搜索时区...';

  @override
  String get couldntUpdateTransactions => '无法更新交易：';

  @override
  String get couldntUpdateBalance => '无法更新余额：';

  @override
  String showingBalanceType(String balanceType) {
    return '正在显示 $balanceType 余额';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => '待处理余额';

  @override
  String get confirmedBalance => '已确认余额';

  @override
  String get totalBalance => '总余额';

  @override
  String get errorLoadingBalance => '加载余额时出错';

  @override
  String get send => '发送';

  @override
  String get receive => '接收';

  @override
  String get failedToCreateWallet => '创建钱包失败';

  @override
  String errorCreatingWallet(String error) {
    return '创建新钱包时出错。请重试。\n\n错误: $error';
  }

  @override
  String get failedToRestoreWallet => '恢复钱包失败';

  @override
  String errorRestoringWallet(String error) {
    return '恢复钱包时出错。请检查您的 nsec 并重试。\n\n错误: $error';
  }

  @override
  String get appTagline => '在 Ark 上飞翔的钱包';

  @override
  String get ok => '确定';

  @override
  String get chooseAnOption => '选择一个选项：';

  @override
  String get createNewWallet => '创建新钱包';

  @override
  String get generateANewSecureWallet => '生成新的安全钱包';

  @override
  String get restoreExistingWallet => '恢复现有钱包';

  @override
  String get useYourSecretKeyToAccessYourWallet => '使用您的密钥访问钱包';

  @override
  String get enterYourNsec => '输入您的 nsec：';

  @override
  String get pasteYourRecoveryNsec => '粘贴您的恢复 nsec...';

  @override
  String paymentMonitoringError(String error) {
    return '支付监控错误：$error';
  }

  @override
  String get paymentReceived => '收到付款！';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => '要分享哪个地址？';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => '闪电发票';

  @override
  String get qrCodeImage => '二维码图片';

  @override
  String get errorSharing => '分享出错';

  @override
  String get myBitcoinAddressQrCode => '我的比特币地址二维码';

  @override
  String get requesting => '请求中：';

  @override
  String get monitoringForIncomingPayment => 'Monitoring for incoming payment...';

  @override
  String get copyAddress => '复制地址';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount => '请输入地址和金额';

  @override
  String get pleaseEnterAValidAmount => '请输入有效金额';

  @override
  String get insufficientFunds => '资金不足';

  @override
  String get sendLower => '发送';

  @override
  String get receiveLower => '接收';

  @override
  String get recipientAddress => '收款地址';

  @override
  String get bitcoinOrArkAddress => '比特币或 Ark 地址';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart => 'Esplora URL 已保存 - 重新启动后生效';

  @override
  String get failedToSaveEsploraUrl => '保存 Esplora URL 失败';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart => '网络已保存 - 重新启动后生效';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart => 'Ark 服务器 URL 已保存 - 重新启动后生效';

  @override
  String get failedToSaveArkServerUrl => '保存 Ark 服务器 URL 失败';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart => 'Boltz URL 已保存 - 重新启动后生效';

  @override
  String get failedToSaveBoltzUrl => '保存 Boltz URL 失败';

  @override
  String get securityWarning => '安全警告';

  @override
  String get neverShareYourRecoveryKeyWithAnyone => '请勿与任何人分享您的恢复密钥！';

  @override
  String get anyoneWithThisKeyCan => '任何拥有此密钥的人都可以访问您的钱包并窃取资金。请将其保存在安全的地方。';

  @override
  String get iUnderstand => '我明白';

  @override
  String get yourRecoveryPhrase => '您的恢复短语';

  @override
  String get recoveryPhraseCopiedToClipboard => '恢复短语已复制到剪贴板';

  @override
  String get copyToClipboard => '复制到剪贴板';

  @override
  String get close => '关闭';

  @override
  String get resetWallet => '重置钱包';

  @override
  String get thisWillDeleteAllWalletData => '这将删除此设备上的所有钱包数据。继续前请确保已备份恢复短语。此操作无法撤销。';

  @override
  String get restartingApp => '正在重新启动应用';

  @override
  String get pleaseTapHereToOpenTheAppAgain => '请点击此处再次打开应用。';

  @override
  String get reset => '重置';

  @override
  String get wallet => '钱包';

  @override
  String get viewRecoveryKey => '查看恢复密钥';

  @override
  String get backupYourWalletWithTheseKey => '使用这些密钥备份您的钱包';

  @override
  String get appearancePreferences => '外观与偏好设置';

  @override
  String get theme => '主题';

  @override
  String get customizeAppAppearance => '自定义应用外观';

  @override
  String get language => '语言';

  @override
  String get selectYourPreferredLanguage => '选择您偏好的语言';

  @override
  String get timezone => '时区';

  @override
  String get chooseYourPreferredTimezone => '选择您偏好的时区';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => '选择您偏好的货币';

  @override
  String get serverConfiguration => '服务器配置';

  @override
  String get network => '网络';

  @override
  String get esploraUrl => 'Esplora URL';

  @override
  String get arkServer => 'Ark 服务器';

  @override
  String get boltzUrl => 'Boltz URL';

  @override
  String get about => '关于';

  @override
  String get loading => '加载中';

  @override
  String get dangerZone => '危险区域';

  @override
  String get deleteAllWalletDataFromThisDevice => '删除此设备上的所有钱包数据';

  @override
  String get transactionFailed => '交易失败：';

  @override
  String get signTransaction => '签署交易';

  @override
  String get networkFees => '网络费用';

  @override
  String get total => '总计';

  @override
  String get tapToSign => '点击签署';

  @override
  String get settlingTransaction => '正在结算交易...';

  @override
  String get success => '成功';

  @override
  String get transactionSettledSuccessfully => '交易结算成功！';

  @override
  String get goToHome => '返回主页';

  @override
  String get error => '错误';

  @override
  String get failedToSettleTransaction => '结算交易失败：';

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
  String get spendable => 'Spendable';

  @override
  String get date => '日期';

  @override
  String get time => '时间';

  @override
  String get transactionVolume => '交易金额';

  @override
  String get confirmedAt => '确认时间';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement => '交易待处理。结算后资金将不可撤销。';

  @override
  String get settle => '结算';

  @override
  String get transactionHistory => '交易记录';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => '暂无交易记录';

  @override
  String get boardingTransaction => '链上交易';

  @override
  String get roundTransaction => '循环交易';

  @override
  String get redeemTransaction => '兑换交易';

  @override
  String get sent => '已发送';

  @override
  String get received => '已接收';

  @override
  String get direction => '方向';

  @override
  String get settled => '已结算';

  @override
  String get sentSuccessfully => '发送成功';

  @override
  String get returningToWalletAfterSuccessfulTransaction => '交易成功后返回钱包';

  @override
  String get backToWallet => '返回钱包';

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
  String get bitcoinDescription => 'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.';

  @override
  String get aboutBitcoinPriceData => 'About Bitcoin Price Data';

  @override
  String get thePriceDataShown => 'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.';

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
  String get reportBugFeedback => '报告问题 / 反馈';

  @override
  String get recoveryOptions => 'Recovery Options';

  @override
  String get securityStatus => 'Security Status';

  @override
  String get setupRecoveryWarning => 'For your security, please set up as many recovery options as possible.';

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
  String get emailRecoveryDescription => 'Recover wallet via email and password';

  @override
  String get enabled => 'Enabled';

  @override
  String get notSetUp => 'Not Set Up';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get emailRecoveryComingSoon => 'Email recovery will be available in a future update. For now, please make sure to backup your recovery phrase.';

  @override
  String get recoverWithEmail => 'Recover with Email';

  @override
  String get recoverWithEmailSubtitle => 'Use email and password to restore your wallet';

  @override
  String get emailRecoverySetup => 'Email Recovery Setup';

  @override
  String get emailRecoveryWarningMessage => 'Your password encrypts your recovery phrase locally. The server only stores the encrypted version and cannot access your funds. If you forget your password, your backup cannot be recovered.';

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
  String get emailRecoverySetupSuccess => 'Email recovery has been set up successfully! You can now recover your wallet using your email and password.';

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
  String get emailRecoveryLoginInfo => 'Enter the email and password you used when setting up email recovery. Your wallet will be restored securely.';

  @override
  String get authenticateToViewRecoveryPhrase => 'Authenticate to view your recovery phrase';

  @override
  String get authenticationFailed => 'Authentication failed. Please try again.';

  @override
  String get confirmRecoveryPhrase => 'Confirm Recovery Phrase';

  @override
  String get recoveryComplete => 'Recovery Complete';

  @override
  String get writeDownYourRecoveryPhrase => 'Write down your recovery phrase';

  @override
  String get youWillNeedToConfirmIt => 'You will need to confirm it in the next step';

  @override
  String get continueToVerify => 'Continue to Verify';

  @override
  String get verifyYourRecoveryPhrase => 'Verify your recovery phrase';

  @override
  String get enterTheFollowingWords => 'Enter the following words from your phrase';

  @override
  String get enterWord => 'Enter word';

  @override
  String get verify => 'Verify';

  @override
  String get incorrectWordsPleaseTryAgain => 'Incorrect words. Please try again.';

  @override
  String get skipVerification => 'Skip Verification?';

  @override
  String get skipVerificationWarning => 'Skipping verification means you haven\'t confirmed that you wrote down your recovery phrase correctly. If you lose access to your wallet, you may not be able to recover it.';

  @override
  String get skipAtOwnRisk => 'Skip at own risk';

  @override
  String get recoveryPhraseConfirmed => 'Recovery Phrase Confirmed!';

  @override
  String get yourRecoveryPhraseIsSecured => 'Your recovery phrase has been verified and secured. Keep it safe!';

  @override
  String get enterYourEmail => 'Enter Your Email';

  @override
  String get emailSignupDescription => 'Your email is used to create your Lendasat account for loans and other services.';

  @override
  String get emailUsageInfo => 'We\'ll use this email for account verification and important updates. Your wallet remains secured by your recovery phrase.';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get restoreWallet => 'Restore Wallet';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get registrationWarning => 'Account registration had an issue. You can still use your wallet.';

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
  String get alphaVersionWarning => 'This app is under development. Use at your own risk.';

  @override
  String get agbScopeTitle => 'Scope of Application';

  @override
  String get agbScopeContent => 'These terms and conditions govern the use of the Bitcoin wallet app (hereinafter Lenda), provided by COBLOX PTY LTD. By using the app, you agree to these terms and conditions.';

  @override
  String get agbFunctionalityTitle => 'Functionality';

  @override
  String get agbFunctionalityContent => 'The app allows users to receive, send, and manage Bitcoin. The app is not a bank and does not provide banking services. Additionally, Taproot Assets, also known as digital assets, are offered and sold as a service platform.';

  @override
  String get agbUserResponsibilityTitle => 'User Responsibility';

  @override
  String get agbUserResponsibilityContent => 'The user is solely responsible for the security of their Bitcoin. The app provides security features such as password protection and two-factor authentication, but it is the user\'s responsibility to use these features carefully. COBLOX PTY LTD is not liable for losses resulting from carelessness, loss of devices, or user credentials.';

  @override
  String get agbFeesTitle => 'Fees';

  @override
  String get agbFeesContent => 'Certain functions of the app may incur fees. These fees will be communicated to the user in advance and are visible in the app.';

  @override
  String get agbLiabilityTitle => 'Limitation of Liability';

  @override
  String get agbLiabilityContent => 'COBLOX PTY LTD is only liable for damages caused by intentional or grossly negligent actions by COBLOX PTY LTD. COBLOX PTY LTD is not liable for damages resulting from the use of the app or the loss of Bitcoin.';

  @override
  String get agbChangesTitle => 'Changes';

  @override
  String get agbChangesContent => 'COBLOX PTY LTD reserves the right to change these terms and conditions at any time. The user will be informed of such changes and must agree to them in order to continue using the app.';

  @override
  String get agbFinalProvisionsTitle => 'Final Provisions';

  @override
  String get agbFinalProvisionsContent => 'These terms and conditions represent the entire agreement between the user and COBLOX PTY LTD. Should any provision be invalid, the remaining provisions shall remain in effect.';

  @override
  String get contact => 'Contact';

  @override
  String get responsibleForContent => 'Responsible for Content';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get disclaimerContent => 'The provider assumes no liability for the accuracy, correctness, completeness, or quality of the information provided. Liability claims against the provider are generally excluded unless there is proven intentional or grossly negligent fault.';

  @override
  String get allRightsReserved => 'All rights reserved';

  @override
  String get loansAndLeverage => '贷款市场';

  @override
  String get availableOffers => '可用报价';

  @override
  String get myContracts => '我的合约';

  @override
  String get signInRequired => '需要登录';

  @override
  String get signInToViewContracts => '登录以查看您的合约并获取贷款。';

  @override
  String get noArkadeOffersAvailable => '没有可用的 Arkade 报价';

  @override
  String get signInToViewYourContracts => '登录以查看您的合约';

  @override
  String get noContractsMatchSearch => '没有合约匹配您的搜索';

  @override
  String get noContractsYet => '暂无合约。接受报价以开始！';

  @override
  String get duration => '期限';

  @override
  String get minLtv => '最低 LTV';

  @override
  String get limitedTimeOffer => '限时优惠 — 超级便宜！';

  @override
  String get interest => '利息';

  @override
  String get due => '到期';

  @override
  String get overdue => '逾期';

  @override
  String get swapDetails => '兑换详情';

  @override
  String get errorLoadingSwap => '加载兑换时出错';

  @override
  String get refundAddress => '退款地址';

  @override
  String get fundSwap => '为兑换注资';

  @override
  String get youSend => '您发送';

  @override
  String get youReceive => '您接收';

  @override
  String get walletConnected => '钱包已连接';

  @override
  String get switchWallet => '切换';

  @override
  String get creatingSwap => '正在创建兑换...';

  @override
  String get approvingToken => '正在批准代币...';

  @override
  String get creatingHtlc => '正在创建 HTLC...';

  @override
  String get swapFundedSuccessfully => '兑换注资成功！';

  @override
  String get feedback => '反馈';

  @override
  String get continueButton => '继续';

  @override
  String get paste => '粘贴';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get youPay => '您支付';

  @override
  String get totalFeesLabel => '总费用';

  @override
  String get beforeFees => '费用前';

  @override
  String get networkFee => '网络';

  @override
  String get protocolFee => '协议';

  @override
  String get receivingAddress => '接收地址';

  @override
  String get waitingForDeposit => '等待存款';

  @override
  String get processing => '处理中';

  @override
  String get completed => '已完成';

  @override
  String get expired => '已过期';

  @override
  String get refundable => '可退款';

  @override
  String get refundedStatus => '已退款';

  @override
  String get failed => '失败';

  @override
  String get confirmSwap => '确认兑换';

  @override
  String get unknownError => '未知错误';

  @override
  String get sendFeedback => '发送反馈';

  @override
  String get sender => '发送者';

  @override
  String get receiver => '接收者';

  @override
  String get scan => '扫描';

  @override
  String get aboutLendasat => 'About LendaSat';

  @override
  String get lendasatInfoDescription => 'LendaSat is a Bitcoin peer-to-peer loan marketplace. We act as a platform that connects you with private lenders who provide the funds. Your Bitcoin is used as collateral, and you receive the loan amount directly. All transactions are secured through smart contracts on the Bitcoin network.';

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
  String get supportedFormats => 'Supports Bitcoin, Lightning, Ark, and LNURL addresses';

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
  String get copied => '已复制';
}
