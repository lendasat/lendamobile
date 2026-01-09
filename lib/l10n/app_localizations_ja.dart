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
  String get time => '時間';

  @override
  String get transactionVolume => '取引量';

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
  String get boardingTransaction => 'オンチェーントランザクション';

  @override
  String get roundTransaction => 'ラウンドトランザクション';

  @override
  String get redeemTransaction => '引換トランザクション';

  @override
  String get sent => '送信済み';

  @override
  String get received => '受信済み';

  @override
  String get direction => '方向';

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
  String get reportBugFeedback => 'バグ報告 / フィードバック';

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
  String get loansAndLeverage => 'ローンマーケット';

  @override
  String get availableOffers => '利用可能なオファー';

  @override
  String get myContracts => 'マイ契約';

  @override
  String get signInRequired => 'サインインが必要';

  @override
  String get signInToViewContracts => '契約を表示してローンを取得するにはサインインしてください。';

  @override
  String get noArkadeOffersAvailable => 'Arkadeオファーはありません';

  @override
  String get signInToViewYourContracts => '契約を表示するにはサインイン';

  @override
  String get noContractsMatchSearch => '検索に一致する契約はありません';

  @override
  String get noContractsYet => 'まだ契約はありません。オファーを受けて始めましょう！';

  @override
  String get duration => '期間';

  @override
  String get minLtv => '最小LTV';

  @override
  String get limitedTimeOffer => '期間限定オファー — 超お得！';

  @override
  String get interest => '利息';

  @override
  String get due => '期限';

  @override
  String get overdue => '延滞';

  @override
  String get swapDetails => 'スワップ詳細';

  @override
  String get errorLoadingSwap => 'スワップの読み込みエラー';

  @override
  String get refundAddress => '返金アドレス';

  @override
  String get fundSwap => 'スワップに資金提供';

  @override
  String get youSend => '送金';

  @override
  String get youReceive => '受取';

  @override
  String get walletConnected => 'ウォレット接続済み';

  @override
  String get switchWallet => '切替';

  @override
  String get creatingSwap => 'スワップを作成中...';

  @override
  String get approvingToken => 'トークンを承認中...';

  @override
  String get creatingHtlc => 'HTLCを作成中...';

  @override
  String get swapFundedSuccessfully => 'スワップの資金提供が完了しました！';

  @override
  String get feedback => 'フィードバック';

  @override
  String get continueButton => '続ける';

  @override
  String get paste => '貼り付け';

  @override
  String get scanQr => 'QRスキャン';

  @override
  String get youPay => '支払い';

  @override
  String get totalFeesLabel => '合計手数料';

  @override
  String get beforeFees => '手数料前';

  @override
  String get networkFee => 'ネットワーク';

  @override
  String get protocolFee => 'プロトコル';

  @override
  String get receivingAddress => '受取アドレス';

  @override
  String get waitingForDeposit => '入金待ち';

  @override
  String get processing => '処理中';

  @override
  String get completed => '完了';

  @override
  String get expired => '期限切れ';

  @override
  String get refundable => '返金可能';

  @override
  String get refundedStatus => '返金済み';

  @override
  String get failed => '失敗';

  @override
  String get confirmSwap => 'スワップを確認';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get sendFeedback => 'フィードバックを送信';

  @override
  String get sender => '送信者';

  @override
  String get receiver => '受信者';

  @override
  String get scan => 'スキャン';

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
  String get copied => 'コピーしました';
}
