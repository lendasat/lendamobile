// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => '設定';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => '保存';

  @override
  String get apply => 'Apply';

  @override
  String get done => '完了';

  @override
  String get select => '選択';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => '金額を入力';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'スキップ（任意の金額）';

  @override
  String get contin => '続行';

  @override
  String get currencyUpdatedSuccessfully => '通貨が正常に更新されました';

  @override
  String get changeCurrency => '通貨を変更';

  @override
  String get languageUpdatedSuccessfully => '言語が正常に更新されました';

  @override
  String get changeLanguage => '言語を変更';

  @override
  String get themeAppliedSuccessfully => 'テーマが正常に適用されました';

  @override
  String get chooseYourColor => '色を選択';

  @override
  String get selectColor => '色を選択';

  @override
  String get selectColorShade => '色の濃淡を選択';

  @override
  String get changeYourStyle => 'スタイルを変更';

  @override
  String get chooseYourPreferredTheme => 'お好みのテーマを選択';

  @override
  String get dark => 'ダーク';

  @override
  String get originalDarkTheme => 'オリジナルダークテーマ';

  @override
  String get light => 'ライト';

  @override
  String get cleanLightTheme => 'クリーンライトテーマ';

  @override
  String get applyTheme => 'テーマを適用';

  @override
  String get custom => 'カスタム';

  @override
  String get createYourOwnTheme => '独自のテーマを作成';

  @override
  String get timezoneUpdatedSuccessfully => 'タイムゾーンが正常に更新されました';

  @override
  String get changeTimezone => 'タイムゾーンを変更';

  @override
  String get searchTimezone => 'タイムゾーンを検索...';

  @override
  String get couldntUpdateTransactions => 'トランザクションを更新できませんでした:';

  @override
  String get couldntUpdateBalance => '残高を更新できませんでした:';

  @override
  String showingBalanceType(String balanceType) {
    return '$balanceType 残高を表示中';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => '保留中の残高';

  @override
  String get confirmedBalance => '確認済み残高';

  @override
  String get totalBalance => '合計残高';

  @override
  String get errorLoadingBalance => '残高の読み込みエラー';

  @override
  String get send => '送金';

  @override
  String get receive => '受取';

  @override
  String get failedToCreateWallet => 'ウォレットの作成に失敗しました';

  @override
  String errorCreatingWallet(String error) {
    return '新しいウォレットの作成中にエラーが発生しました。もう一度お試しください。\n\nエラー: $error';
  }

  @override
  String get failedToRestoreWallet => 'ウォレットの復元に失敗しました';

  @override
  String errorRestoringWallet(String error) {
    return 'ウォレットの復元中にエラーが発生しました。nsecを確認して再試行してください。\n\nエラー: $error';
  }

  @override
  String get appTagline => 'Arkで飛ぶウォレット';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'オプションを選択:';

  @override
  String get createNewWallet => '新しいウォレットを作成';

  @override
  String get generateANewSecureWallet => '新しい安全なウォレットを生成';

  @override
  String get restoreExistingWallet => '既存のウォレットを復元';

  @override
  String get useYourSecretKeyToAccessYourWallet => '秘密キーを使用してウォレットにアクセス';

  @override
  String get enterYourNsec => 'nsecを入力:';

  @override
  String get pasteYourRecoveryNsec => '復元用nsecを貼り付け...';

  @override
  String paymentMonitoringError(String error) {
    return '支払い監視エラー: $error';
  }

  @override
  String get paymentReceived => '支払いを受け取りました！';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'どのアドレスを共有しますか？';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'ライトニング請求書';

  @override
  String get qrCodeImage => 'QRコード画像';

  @override
  String get errorSharing => '共有エラー';

  @override
  String get myBitcoinAddressQrCode => '自分のビットコインアドレスQRコード';

  @override
  String get requesting => 'リクエスト中: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'アドレスをコピー';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount => 'アドレスと金額の両方を入力してください';

  @override
  String get pleaseEnterAValidAmount => '有効な金額を入力してください';

  @override
  String get insufficientFunds => '残高不足';

  @override
  String get sendLower => '送る';

  @override
  String get receiveLower => '受け取る';

  @override
  String get recipientAddress => '受取人のアドレス';

  @override
  String get bitcoinOrArkAddress => 'ビットコインまたはArkアドレス';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Esplora URLが保存されました - 再起動後に有効になります';

  @override
  String get failedToSaveEsploraUrl => 'Esplora URLの保存に失敗しました';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'ネットワークが保存されました - 再起動後に有効になります';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'ArkサーバーURLが保存されました - 再起動後に有効になります';

  @override
  String get failedToSaveArkServerUrl => 'ArkサーバーURLの保存に失敗しました';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Boltz URLが保存されました - 再起動後に有効になります';

  @override
  String get failedToSaveBoltzUrl => 'Boltz URLの保存に失敗しました';

  @override
  String get securityWarning => 'セキュリティ警告';

  @override
  String get neverShareYourRecoveryKeyWithAnyone => 'リカバリーキーを他人と共有しないでください！';

  @override
  String get anyoneWithThisKeyCan =>
      'このキーを持つ人はウォレットにアクセスし、資金を盗むことができます。安全な場所に保管してください。';

  @override
  String get iUnderstand => '理解しました';

  @override
  String get yourRecoveryPhrase => 'リカバリーフレーズ';

  @override
  String get recoveryPhraseCopiedToClipboard => 'リカバリーフレーズをコピーしました';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get close => '閉じる';

  @override
  String get resetWallet => 'ウォレットをリセット';

  @override
  String get thisWillDeleteAllWalletData =>
      'これにより、このデバイスからすべてのウォレットデータが削除されます。続行する前にリカバリーフレーズをバックアップしてください。この操作は元に戻せません。';

  @override
  String get restartingApp => 'アプリを再起動中';

  @override
  String get pleaseTapHereToOpenTheAppAgain => 'ここをタップしてアプリを再度開いてください。';

  @override
  String get reset => 'リセット';

  @override
  String get wallet => 'ウォレット';

  @override
  String get viewRecoveryKey => 'リカバリーキーを表示';

  @override
  String get backupYourWalletWithTheseKey => 'このキーでウォレットをバックアップ';

  @override
  String get appearancePreferences => '外観と設定';

  @override
  String get theme => 'テーマ';

  @override
  String get customizeAppAppearance => 'アプリの外観をカスタマイズ';

  @override
  String get language => '言語';

  @override
  String get selectYourPreferredLanguage => '希望する言語を選択';

  @override
  String get timezone => 'タイムゾーン';

  @override
  String get chooseYourPreferredTimezone => '希望するタイムゾーンを選択';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => '希望する通貨を選択';

  @override
  String get serverConfiguration => 'サーバー設定';

  @override
  String get network => 'ネットワーク';

  @override
  String get esploraUrl => 'Esplora URL';

  @override
  String get arkServer => 'Arkサーバー';

  @override
  String get boltzUrl => 'Boltz URL';

  @override
  String get about => '情報';

  @override
  String get loading => '読み込み中';

  @override
  String get dangerZone => '危険ゾーン';

  @override
  String get deleteAllWalletDataFromThisDevice => 'このデバイスからすべてのウォレットデータを削除';

  @override
  String get transactionFailed => 'トランザクション失敗:';

  @override
  String get signTransaction => 'トランザクションに署名';

  @override
  String get networkFees => 'ネットワーク手数料';

  @override
  String get total => '合計';

  @override
  String get tapToSign => 'タップして署名';

  @override
  String get settlingTransaction => 'トランザクションを処理中...';

  @override
  String get success => '成功';

  @override
  String get transactionSettledSuccessfully => 'トランザクションが正常に完了しました！';

  @override
  String get goToHome => 'ホームに戻る';

  @override
  String get error => 'エラー';

  @override
  String get failedToSettleTransaction => 'トランザクションの完了に失敗しました:';

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
  String get date => '日付';

  @override
  String get confirmedAt => '確認日時';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'トランザクションは保留中です。完了後は資金を取り消すことはできません。';

  @override
  String get settle => '完了';

  @override
  String get transactionHistory => 'トランザクション履歴';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'まだトランザクション履歴がありません';

  @override
  String get boardingTransaction => 'ボーディングトランザクション';

  @override
  String get roundTransaction => 'ラウンドトランザクション';

  @override
  String get redeemTransaction => '引換トランザクション';

  @override
  String get sent => '送信済み';

  @override
  String get received => '受信済み';

  @override
  String get settled => '完了';

  @override
  String get sentSuccessfully => '送信に成功しました';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'トランザクション成功後にウォレットへ戻ります';

  @override
  String get backToWallet => 'ウォレットに戻る';

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
}
