// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'Einstellungen';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Speichern';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Fertig';

  @override
  String get select => 'Auswählen';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'Betrag eingeben';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'ÜBERSPRINGEN (BELIEBIGER BETRAG)';

  @override
  String get contin => 'FORTFAHREN';

  @override
  String get currencyUpdatedSuccessfully => 'Währung erfolgreich aktualisiert';

  @override
  String get changeCurrency => 'Währung ändern';

  @override
  String get languageUpdatedSuccessfully => 'Sprache erfolgreich aktualisiert';

  @override
  String get changeLanguage => 'Sprache ändern';

  @override
  String get themeAppliedSuccessfully => 'Design erfolgreich angewendet';

  @override
  String get chooseYourColor => 'Wähle deine Farbe';

  @override
  String get selectColor => 'Farbe auswählen';

  @override
  String get selectColorShade => 'Farbton auswählen';

  @override
  String get changeYourStyle => 'Ändere deinen Stil';

  @override
  String get chooseYourPreferredTheme => 'Wähle dein bevorzugtes Design';

  @override
  String get dark => 'Dunkel';

  @override
  String get originalDarkTheme => 'Original dunkles Design';

  @override
  String get light => 'Hell';

  @override
  String get cleanLightTheme => 'Klares helles Design';

  @override
  String get applyTheme => 'Design anwenden';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get createYourOwnTheme => 'Erstelle dein eigenes Design';

  @override
  String get timezoneUpdatedSuccessfully => 'Zeitzone erfolgreich aktualisiert';

  @override
  String get changeTimezone => 'Zeitzone ändern';

  @override
  String get searchTimezone => 'Zeitzone suchen...';

  @override
  String get couldntUpdateTransactions =>
      'Transaktionen konnten nicht aktualisiert werden:';

  @override
  String get couldntUpdateBalance =>
      'Kontostand konnte nicht aktualisiert werden:';

  @override
  String showingBalanceType(String balanceType) {
    return 'Angezeigter $balanceType-Kontostand';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'Ausstehender Kontostand';

  @override
  String get confirmedBalance => 'Bestätigter Kontostand';

  @override
  String get totalBalance => 'Gesamtkontostand';

  @override
  String get errorLoadingBalance => 'Fehler beim Laden des Kontostands';

  @override
  String get send => 'Senden';

  @override
  String get receive => 'Empfangen';

  @override
  String get failedToCreateWallet => 'Erstellen der Wallet fehlgeschlagen';

  @override
  String errorCreatingWallet(String error) {
    return 'Beim Erstellen deiner neuen Wallet ist ein Fehler aufgetreten. Bitte versuche es erneut.\n\nFehler: $error';
  }

  @override
  String get failedToRestoreWallet =>
      'Wiederherstellung der Wallet fehlgeschlagen';

  @override
  String errorRestoringWallet(String error) {
    return 'Beim Wiederherstellen deiner Wallet ist ein Fehler aufgetreten. Bitte überprüfe deinen nsec und versuche es erneut.\n\nFehler: $error';
  }

  @override
  String get appTagline => 'Die Wallet, die mit Ark fliegt';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'Wähle eine Option:';

  @override
  String get createNewWallet => 'Neue Wallet erstellen';

  @override
  String get generateANewSecureWallet => 'Erstelle eine neue sichere Wallet';

  @override
  String get restoreExistingWallet => 'Vorhandene Wallet wiederherstellen';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'Verwende deinen geheimen Schlüssel, um auf deine Wallet zuzugreifen';

  @override
  String get enterYourNsec => 'Gib deinen nsec ein:';

  @override
  String get pasteYourRecoveryNsec =>
      'Füge deinen Wiederherstellungs-nsec ein...';

  @override
  String paymentMonitoringError(String error) {
    return 'Fehler bei der Zahlungsüberwachung: $error';
  }

  @override
  String get paymentReceived => 'Zahlung empfangen!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'Welche Adresse teilen?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'Lightning-Rechnung';

  @override
  String get qrCodeImage => 'QR-Code-Bild';

  @override
  String get errorSharing => 'Fehler beim Teilen';

  @override
  String get myBitcoinAddressQrCode => 'Mein Bitcoin-QR-Code';

  @override
  String get requesting => 'Anfrage: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'Adresse kopieren';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'Bitte sowohl Adresse als auch Betrag eingeben';

  @override
  String get pleaseEnterAValidAmount => 'Bitte einen gültigen Betrag eingeben';

  @override
  String get insufficientFunds => 'Unzureichendes Guthaben';

  @override
  String get sendLower => 'Senden';

  @override
  String get receiveLower => 'Empfangen';

  @override
  String get recipientAddress => 'Empfängeradresse';

  @override
  String get bitcoinOrArkAddress => 'Bitcoin- oder Ark-Adresse';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Esplora-URL gespeichert – wird erst nach einem Neustart wirksam';

  @override
  String get failedToSaveEsploraUrl => 'Fehler beim Speichern der Esplora-URL';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'Netzwerk gespeichert – wird erst nach einem Neustart wirksam';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Ark-Server-URL gespeichert – wird erst nach einem Neustart wirksam';

  @override
  String get failedToSaveArkServerUrl =>
      'Fehler beim Speichern der Ark-Server-URL';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'Boltz-URL gespeichert – wird erst nach einem Neustart wirksam';

  @override
  String get failedToSaveBoltzUrl => 'Fehler beim Speichern der Boltz-URL';

  @override
  String get securityWarning => 'Sicherheitswarnung';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'Gib deinen Wiederherstellungsschlüssel niemals an andere weiter!';

  @override
  String get anyoneWithThisKeyCan =>
      'Jeder, der diesen Schlüssel besitzt, kann auf deine Wallet zugreifen und deine Gelder stehlen. Bewahre ihn sicher auf.';

  @override
  String get iUnderstand => 'ICH VERSTEHE';

  @override
  String get yourRecoveryPhrase => 'Deine Wiederherstellungsphrase';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'Wiederherstellungsphrase in Zwischenablage kopiert';

  @override
  String get copyToClipboard => 'IN ZWISCHENABLAGE KOPIEREN';

  @override
  String get close => 'SCHLIESSEN';

  @override
  String get resetWallet => 'Wallet zurücksetzen';

  @override
  String get thisWillDeleteAllWalletData =>
      'Dadurch werden alle Wallet-Daten von diesem Gerät gelöscht. Stelle sicher, dass du deine Wiederherstellungsphrase gesichert hast, bevor du fortfährst. Dieser Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get restartingApp => 'App wird neu gestartet';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'Tippe hier, um die App erneut zu öffnen.';

  @override
  String get reset => 'ZURÜCKSETZEN';

  @override
  String get wallet => 'Wallet';

  @override
  String get viewRecoveryKey => 'Wiederherstellungsschlüssel anzeigen';

  @override
  String get backupYourWalletWithTheseKey =>
      'Sichere deine Wallet mit diesem Schlüssel';

  @override
  String get appearancePreferences => 'Aussehen & Einstellungen';

  @override
  String get theme => 'Design';

  @override
  String get customizeAppAppearance => 'App-Aussehen anpassen';

  @override
  String get language => 'Sprache';

  @override
  String get selectYourPreferredLanguage => 'Wähle deine bevorzugte Sprache';

  @override
  String get timezone => 'Zeitzone';

  @override
  String get chooseYourPreferredTimezone => 'Wähle deine bevorzugte Zeitzone';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'Wähle deine bevorzugte Währung';

  @override
  String get preferences => 'Preferences';

  @override
  String get autoReadClipboard => 'Auto-read clipboard';

  @override
  String get autoReadClipboardDescription =>
      'Automatically check clipboard for Bitcoin addresses when sending';

  @override
  String get serverConfiguration => 'Serverkonfiguration';

  @override
  String get network => 'Netzwerk';

  @override
  String get esploraUrl => 'Esplora-URL';

  @override
  String get arkServer => 'Ark-Server';

  @override
  String get boltzUrl => 'Boltz-URL';

  @override
  String get about => 'Über';

  @override
  String get loading => 'wird geladen';

  @override
  String get dangerZone => 'Gefahrenbereich';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'Alle Wallet-Daten von diesem Gerät löschen';

  @override
  String get transactionFailed => 'Transaktion fehlgeschlagen:';

  @override
  String get signTransaction => 'Transaktion signieren';

  @override
  String get networkFees => 'Netzwerkgebühren';

  @override
  String get total => 'Gesamt';

  @override
  String get tapToSign => 'ZUM SIGNIEREN TIPpen';

  @override
  String get settlingTransaction => 'Transaktion wird abgewickelt...';

  @override
  String get success => 'Erfolg';

  @override
  String get transactionSettledSuccessfully =>
      'Transaktion erfolgreich abgeschlossen!';

  @override
  String get goToHome => 'Zur Startseite';

  @override
  String get error => 'Fehler';

  @override
  String get failedToSettleTransaction =>
      'Abwicklung der Transaktion fehlgeschlagen:';

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
  String get date => 'Datum';

  @override
  String get time => 'Uhrzeit';

  @override
  String get transactionVolume => 'Transaktionsvolumen';

  @override
  String get confirmedAt => 'Bestätigt am';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'Transaktion ausstehend. Nach der Abwicklung sind die Gelder nicht mehr rückgängig zu machen.';

  @override
  String get settle => 'ABWICKELN';

  @override
  String get transactionHistory => 'Transaktionsverlauf';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'Noch kein Transaktionsverlauf';

  @override
  String get boardingTransaction => 'Onchain-Transaktion';

  @override
  String get roundTransaction => 'Rundungs-Transaktion';

  @override
  String get redeemTransaction => 'Einlöse-Transaktion';

  @override
  String get sent => 'Gesendet';

  @override
  String get received => 'Empfangen';

  @override
  String get direction => 'Richtung';

  @override
  String get settled => 'Abgeschlossen';

  @override
  String get sentSuccessfully => 'Erfolgreich gesendet';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Rückkehr zur Wallet nach erfolgreicher Transaktion';

  @override
  String get backToWallet => 'ZURÜCK ZUR WALLET';

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
  String get minutesAgo => 'Minuten';

  @override
  String get hoursAgo => 'Stunden';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String get daysAgo => 'Tage';

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
  String get notEnoughFunds => 'Nicht genügend Guthaben';

  @override
  String get recipient => 'Recipient';

  @override
  String get unknown => 'Unknown';

  @override
  String get fromClipboard => 'aus Zwischenablage';

  @override
  String get walletAddressCopied => 'Wallet address copied';

  @override
  String get hashrate => 'Hashrate';

  @override
  String get fearAndGreedIndex => 'Fear & Greed Index';

  @override
  String get health => 'Health';

  @override
  String get scanQrCode => 'QR-Code scannen';

  @override
  String get positionQrCodeInFrame => 'QR-Code im Rahmen positionieren';

  @override
  String get noQrCodeFoundInImage => 'Kein QR-Code im Bild gefunden';

  @override
  String get switchCamera => 'Kamera wechseln';

  @override
  String get flashOn => 'Blitz an';

  @override
  String get flashOff => 'Blitz aus';

  @override
  String get pickFromGallery => 'Aus Galerie wählen';

  @override
  String get reportBugFeedback => 'Fehler melden / Feedback';

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
  String get legalInformation => 'Rechtliches';

  @override
  String get termsAndConditionsTitle1 => 'Allgemeine';

  @override
  String get termsAndConditionsTitle2 => 'Geschäftsbedingungen';

  @override
  String get lastUpdated => 'Stand: Dezember 2025';

  @override
  String get alphaVersion => 'Alpha-Version';

  @override
  String get alphaVersionWarning =>
      'Diese App befindet sich in der Entwicklung. Nutzung auf eigenes Risiko.';

  @override
  String get agbScopeTitle => 'Anwendungsbereich';

  @override
  String get agbScopeContent =>
      'Diese Geschäftsbedingungen regeln die Nutzung der Bitcoin-Wallet-App (im Folgenden Lenda), die von COBLOX PTY LTD bereitgestellt wird. Durch die Nutzung der App erklären Sie sich mit diesen Geschäftsbedingungen einverstanden.';

  @override
  String get agbFunctionalityTitle => 'Funktionalität';

  @override
  String get agbFunctionalityContent =>
      'Die App ermöglicht es Benutzern, Bitcoins zu empfangen, zu senden und zu verwalten. Die App ist keine Bank und bietet keine Bankdienstleistungen an.';

  @override
  String get agbUserResponsibilityTitle => 'Verantwortung des Benutzers';

  @override
  String get agbUserResponsibilityContent =>
      'Der Benutzer trägt die volle Eigenverantwortung für die Nutzung der Anwendung und die Sicherheit seiner Bitcoins. Der Benutzer erkennt an, dass der Verlust seiner Wiederherstellungsphrase (Mnemonic) einem Verlust seiner Guthaben gleichkommt. COBLOX PTY LTD haftet nicht für Verluste, die aufgrund von Unachtsamkeit, Verlust von Geräten oder Verlust der Wiederherstellungsphrase entstehen.';

  @override
  String get agbFeesTitle => 'Gebühren';

  @override
  String get agbFeesContent =>
      'Für bestimmte Funktionen der App können Gebühren anfallen. Diese Gebühren werden dem Benutzer im Vorfeld mitgeteilt und sind in der App ersichtlich.';

  @override
  String get agbBuyingSelling => 'Kauf und Verkauf von Bitcoin';

  @override
  String get agbBuyingSellingContent =>
      'Der Kauf und Verkauf von Bitcoin erfolgt über Drittanbieter. COBLOX PTY LTD ist an diesen Transaktionen nicht beteiligt und übernimmt keine Verantwortung dafür. Alle Probleme, Streitigkeiten oder Anfragen im Zusammenhang mit dem Kauf oder Verkauf von Bitcoin müssen an den jeweiligen Drittanbieter gerichtet und mit diesem geklärt werden.';

  @override
  String get agbLiabilityTitle => 'Haftungsbeschränkung';

  @override
  String get agbLiabilityContent =>
      'COBLOX PTY LTD haftet nur für Schäden, die durch vorsätzliches oder grob fahrlässiges Handeln von COBLOX PTY LTD verursacht werden. COBLOX PTY LTD haftet nicht für Schäden, die aus der Nutzung der App oder dem Verlust von Bitcoins resultieren.';

  @override
  String get agbChangesTitle => 'Änderungen';

  @override
  String get agbChangesContent =>
      'COBLOX PTY LTD behält sich das Recht vor, diese Geschäftsbedingungen jederzeit zu ändern. Die fortgesetzte Nutzung der App gilt als Zustimmung zu aktualisierten Bedingungen.';

  @override
  String get agbFinalProvisionsTitle => 'Schlussbestimmungen';

  @override
  String get agbFinalProvisionsContent =>
      'Diese Geschäftsbedingungen stellen die gesamte Vereinbarung zwischen dem Benutzer und COBLOX PTY LTD dar. Sollte eine Bestimmung unwirksam sein, bleiben die übrigen Bestimmungen in Kraft.';

  @override
  String get contact => 'Kontakt';

  @override
  String get responsibleForContent => 'Verantwortlich für den Inhalt';

  @override
  String get disclaimer => 'Haftungsausschluss';

  @override
  String get disclaimerContent =>
      'Der Anbieter übernimmt keinerlei Gewähr für die Aktualität, Korrektheit, Vollständigkeit oder Qualität der bereitgestellten Informationen. Haftungsansprüche gegen den Anbieter sind grundsätzlich ausgeschlossen, sofern kein nachweislich vorsätzliches oder grob fahrlässiges Verschulden vorliegt.';

  @override
  String get allRightsReserved => 'Alle Rechte vorbehalten';

  @override
  String get loansAndLeverage => 'Kredit-Marktplatz';

  @override
  String get availableOffers => 'Verfügbare Angebote';

  @override
  String get myContracts => 'Meine Verträge';

  @override
  String get signInRequired => 'Anmeldung erforderlich';

  @override
  String get signInToViewContracts =>
      'Melden Sie sich an, um Ihre Verträge anzuzeigen und Kredite aufzunehmen.';

  @override
  String get noArkadeOffersAvailable => 'Keine Arkade-Angebote verfügbar';

  @override
  String get signInToViewYourContracts =>
      'Melden Sie sich an, um Ihre Verträge anzuzeigen';

  @override
  String get noContractsMatchSearch => 'Keine Verträge entsprechen Ihrer Suche';

  @override
  String get noContractsYet =>
      'Noch keine Verträge. Nehmen Sie ein Angebot an!';

  @override
  String get duration => 'Dauer';

  @override
  String get minLtv => 'Min. LTV';

  @override
  String get limitedTimeOffer => 'Zeitlich begrenztes Angebot — super günstig!';

  @override
  String get interest => 'Zinsen';

  @override
  String get due => 'Fällig';

  @override
  String get overdue => 'Überfällig';

  @override
  String get swapDetails => 'Swap-Details';

  @override
  String get errorLoadingSwap => 'Fehler beim Laden des Swaps';

  @override
  String get refundAddress => 'Rückerstattungsadresse';

  @override
  String get fundSwap => 'Swap finanzieren';

  @override
  String get youSend => 'Sie senden';

  @override
  String get youReceive => 'Sie erhalten';

  @override
  String get walletConnected => 'Wallet verbunden';

  @override
  String get switchWallet => 'Wechseln';

  @override
  String get creatingSwap => 'Swap wird erstellt...';

  @override
  String get approvingToken => 'Token wird genehmigt...';

  @override
  String get creatingHtlc => 'HTLC wird erstellt...';

  @override
  String get swapFundedSuccessfully => 'Swap erfolgreich finanziert!';

  @override
  String get feedback => 'Feedback';

  @override
  String get continueButton => 'Weiter';

  @override
  String get paste => 'Einfügen';

  @override
  String get scanQr => 'QR scannen';

  @override
  String get youPay => 'Sie zahlen';

  @override
  String get totalFeesLabel => 'Gesamtgebühren';

  @override
  String get beforeFees => 'vor Gebühren';

  @override
  String get networkFee => 'Netzwerk';

  @override
  String get protocolFee => 'Protokoll';

  @override
  String get receivingAddress => 'Empfangsadresse';

  @override
  String get waitingForDeposit => 'Warte auf Einzahlung';

  @override
  String get processing => 'Wird verarbeitet';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get expired => 'Abgelaufen';

  @override
  String get refundable => 'Erstattungsfähig';

  @override
  String get refundedStatus => 'Erstattet';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get confirmSwap => 'Swap bestätigen';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get sender => 'Absender';

  @override
  String get receiver => 'Empfänger';

  @override
  String get scan => 'Scannen';

  @override
  String get aboutLendasat => 'Über LendaSat';

  @override
  String get lendasatInfoDescription =>
      'LendaSat ist ein Bitcoin Peer-to-Peer Kreditmarktplatz. Wir fungieren als Plattform, die Sie mit privaten Kreditgebern verbindet, die das Kapital bereitstellen. Ihr Bitcoin dient als Sicherheit und Sie erhalten den Kreditbetrag direkt. Alle Transaktionen werden durch Smart Contracts im Bitcoin-Netzwerk abgesichert.';

  @override
  String get learnMoreAboutLendasat => 'Erfahren Sie mehr über LendaSat';

  @override
  String get sendingStatus => 'Wird gesendet...';

  @override
  String get sentStatus => 'Gesendet!';

  @override
  String get failedStatus => 'Fehlgeschlagen';

  @override
  String get chooseRecipient => 'Empfänger wählen';

  @override
  String get searchRecipient => 'Adresse suchen oder einfügen...';

  @override
  String get recent => 'Zuletzt';

  @override
  String get pasteOrScanAddress => 'Bitcoin-Adresse einfügen oder scannen';

  @override
  String get supportedFormats =>
      'Unterstützt Bitcoin, Lightning, Ark und LNURL Adressen';

  @override
  String get justNow => 'Gerade eben';

  @override
  String get minuteAgo => 'Minute';

  @override
  String get hourAgo => 'Stunde';

  @override
  String get dayAgo => 'Tag';

  @override
  String get monthAgo => 'Monat';

  @override
  String get monthsAgo => 'Monate';

  @override
  String get yearAgo => 'Jahr';

  @override
  String get yearsAgo => 'Jahre';

  @override
  String get selectNetwork => 'Netzwerk wählen';

  @override
  String get copied => 'Kopiert';
}
