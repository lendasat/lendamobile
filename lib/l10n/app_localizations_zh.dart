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
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

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
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Esplora URL 已保存 - 重新启动后生效';

  @override
  String get failedToSaveEsploraUrl => '保存 Esplora URL 失败';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart => '网络已保存 - 重新启动后生效';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Ark 服务器 URL 已保存 - 重新启动后生效';

  @override
  String get failedToSaveArkServerUrl => '保存 Ark 服务器 URL 失败';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Boltz URL 已保存 - 重新启动后生效';

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
  String get thisWillDeleteAllWalletData =>
      '这将删除此设备上的所有钱包数据。继续前请确保已备份恢复短语。此操作无法撤销。';

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
  String get date => '日期';

  @override
  String get confirmedAt => '确认时间';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      '交易待处理。结算后资金将不可撤销。';

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
