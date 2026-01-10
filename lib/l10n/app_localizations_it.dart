// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'Impostazioni';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Salva';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Fatto';

  @override
  String get select => 'Seleziona';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'Inserisci Importo';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'SALTA (QUALSIASI IMPORTO)';

  @override
  String get contin => 'CONTINUA';

  @override
  String get currencyUpdatedSuccessfully => 'Valuta aggiornata con successo';

  @override
  String get changeCurrency => 'Cambia Valuta';

  @override
  String get languageUpdatedSuccessfully => 'Lingua aggiornata con successo';

  @override
  String get changeLanguage => 'Cambia Lingua';

  @override
  String get themeAppliedSuccessfully => 'Tema applicato con successo';

  @override
  String get chooseYourColor => 'Scegli il tuo colore';

  @override
  String get selectColor => 'Seleziona colore';

  @override
  String get selectColorShade => 'Seleziona tonalità colore';

  @override
  String get changeYourStyle => 'Cambia il tuo stile';

  @override
  String get chooseYourPreferredTheme => 'Scegli il tema preferito';

  @override
  String get dark => 'Scuro';

  @override
  String get originalDarkTheme => 'Tema scuro originale';

  @override
  String get light => 'Chiaro';

  @override
  String get cleanLightTheme => 'Tema chiaro pulito';

  @override
  String get applyTheme => 'Applica Tema';

  @override
  String get custom => 'Personalizzato';

  @override
  String get createYourOwnTheme => 'Crea il tuo tema';

  @override
  String get timezoneUpdatedSuccessfully =>
      'Fuso orario aggiornato con successo';

  @override
  String get changeTimezone => 'Cambia Fuso Orario';

  @override
  String get searchTimezone => 'Cerca fuso orario...';

  @override
  String get couldntUpdateTransactions =>
      'Impossibile aggiornare le transazioni:';

  @override
  String get couldntUpdateBalance => 'Impossibile aggiornare il saldo:';

  @override
  String showingBalanceType(String balanceType) {
    return 'Mostrando saldo $balanceType';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'Saldo in sospeso';

  @override
  String get confirmedBalance => 'Saldo confermato';

  @override
  String get totalBalance => 'Saldo totale';

  @override
  String get errorLoadingBalance => 'Errore nel caricamento del saldo';

  @override
  String get send => 'Invia';

  @override
  String get receive => 'Ricevi';

  @override
  String get failedToCreateWallet => 'Creazione del portafoglio non riuscita';

  @override
  String errorCreatingWallet(String error) {
    return 'Si è verificato un errore durante la creazione del nuovo portafoglio. Riprova.\n\nErrore: $error';
  }

  @override
  String get failedToRestoreWallet => 'Ripristino del portafoglio non riuscito';

  @override
  String errorRestoringWallet(String error) {
    return 'Si è verificato un errore durante il ripristino del portafoglio. Controlla il tuo nsec e riprova.\n\nErrore: $error';
  }

  @override
  String get appTagline => 'Il Portafoglio che Vola su Ark';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'Scegli un\'opzione:';

  @override
  String get createNewWallet => 'Crea Nuovo Portafoglio';

  @override
  String get generateANewSecureWallet => 'Genera un nuovo portafoglio sicuro';

  @override
  String get restoreExistingWallet => 'Ripristina Portafoglio Esistente';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'Usa la tua chiave segreta per accedere al portafoglio';

  @override
  String get enterYourNsec => 'Inserisci il tuo nsec:';

  @override
  String get pasteYourRecoveryNsec => 'Incolla il tuo nsec di recupero...';

  @override
  String paymentMonitoringError(String error) {
    return 'Errore monitoraggio pagamento: $error';
  }

  @override
  String get paymentReceived => 'Pagamento Ricevuto!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'Condividere quale indirizzo?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'Fattura Lightning';

  @override
  String get qrCodeImage => 'Immagine Codice QR';

  @override
  String get errorSharing => 'Errore nella condivisione';

  @override
  String get myBitcoinAddressQrCode => 'Codice QR del mio indirizzo Bitcoin';

  @override
  String get requesting => 'Richiesta: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'Copia indirizzo';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'Inserisci sia l\'indirizzo che l\'importo';

  @override
  String get pleaseEnterAValidAmount => 'Inserisci un importo valido';

  @override
  String get insufficientFunds => 'Fondi insufficienti';

  @override
  String get sendLower => 'Invia';

  @override
  String get receiveLower => 'Ricevi';

  @override
  String get recipientAddress => 'Indirizzo del destinatario';

  @override
  String get bitcoinOrArkAddress => 'Indirizzo Bitcoin o Ark';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Esplora salvato - avrà effetto dopo il riavvio';

  @override
  String get failedToSaveEsploraUrl => 'Salvataggio URL Esplora non riuscito';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'Rete salvata - avrà effetto dopo il riavvio';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Server Ark salvato - avrà effetto dopo il riavvio';

  @override
  String get failedToSaveArkServerUrl =>
      'Salvataggio URL Server Ark non riuscito';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Boltz salvato - avrà effetto dopo il riavvio';

  @override
  String get failedToSaveBoltzUrl => 'Salvataggio URL Boltz non riuscito';

  @override
  String get securityWarning => 'Avviso di Sicurezza';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'Non condividere mai la tua chiave di recupero con nessuno!';

  @override
  String get anyoneWithThisKeyCan =>
      'Chiunque abbia questa chiave può accedere al tuo portafoglio e rubare i tuoi fondi. Conservala in un luogo sicuro.';

  @override
  String get iUnderstand => 'HO CAPITO';

  @override
  String get yourRecoveryPhrase => 'La tua Frase di Recupero';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'Frase di recupero copiata negli appunti';

  @override
  String get copyToClipboard => 'COPIA NEGLI APPUNTI';

  @override
  String get close => 'CHIUDI';

  @override
  String get resetWallet => 'Reimposta Portafoglio';

  @override
  String get thisWillDeleteAllWalletData =>
      'Questo eliminerà tutti i dati del portafoglio da questo dispositivo. Assicurati di aver eseguito il backup della frase di recupero prima di procedere. Questa azione non può essere annullata.';

  @override
  String get restartingApp => 'Riavvio dell\'app';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'Tocca qui per aprire di nuovo l\'app.';

  @override
  String get reset => 'REIMPOSTA';

  @override
  String get wallet => 'Portafoglio';

  @override
  String get viewRecoveryKey => 'Visualizza Chiave di Recupero';

  @override
  String get backupYourWalletWithTheseKey =>
      'Esegui il backup del portafoglio con questa chiave';

  @override
  String get appearancePreferences => 'Aspetto e Preferenze';

  @override
  String get theme => 'Tema';

  @override
  String get customizeAppAppearance => 'Personalizza l\'aspetto dell\'app';

  @override
  String get language => 'Lingua';

  @override
  String get selectYourPreferredLanguage => 'Seleziona la lingua preferita';

  @override
  String get timezone => 'Fuso Orario';

  @override
  String get chooseYourPreferredTimezone => 'Scegli il fuso orario preferito';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'Scegli la valuta preferita';

  @override
  String get preferences => 'Preferences';

  @override
  String get autoReadClipboard => 'Auto-read clipboard';

  @override
  String get autoReadClipboardDescription =>
      'Automatically check clipboard for Bitcoin addresses when sending';

  @override
  String get serverConfiguration => 'Configurazione Server';

  @override
  String get network => 'Rete';

  @override
  String get esploraUrl => 'URL Esplora';

  @override
  String get arkServer => 'Server Ark';

  @override
  String get boltzUrl => 'URL Boltz';

  @override
  String get about => 'Informazioni';

  @override
  String get loading => 'caricamento';

  @override
  String get dangerZone => 'Zona Pericolosa';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'Elimina tutti i dati del portafoglio da questo dispositivo';

  @override
  String get transactionFailed => 'Transazione fallita:';

  @override
  String get signTransaction => 'Firma transazione';

  @override
  String get networkFees => 'Commissioni di rete';

  @override
  String get total => 'Totale';

  @override
  String get tapToSign => 'TOCCA PER FIRMARE';

  @override
  String get settlingTransaction => 'Elaborazione transazione...';

  @override
  String get success => 'Successo';

  @override
  String get transactionSettledSuccessfully =>
      'Transazione completata con successo!';

  @override
  String get goToHome => 'Vai alla Home';

  @override
  String get error => 'Errore';

  @override
  String get failedToSettleTransaction =>
      'Impossibile completare la transazione:';

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
  String get date => 'Data';

  @override
  String get time => 'Ora';

  @override
  String get transactionVolume => 'Volume della Transazione';

  @override
  String get confirmedAt => 'Confermato il';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'Transazione in sospeso. I fondi non saranno reversibili dopo il completamento.';

  @override
  String get settle => 'COMPLETA';

  @override
  String get transactionHistory => 'Storico Transazioni';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'Nessuna cronologia transazioni';

  @override
  String get boardingTransaction => 'Transazione Onchain';

  @override
  String get roundTransaction => 'Transazione Arrotondata';

  @override
  String get redeemTransaction => 'Transazione di Riscatto';

  @override
  String get sent => 'Inviato';

  @override
  String get received => 'Ricevuto';

  @override
  String get direction => 'Direzione';

  @override
  String get settled => 'Completato';

  @override
  String get sentSuccessfully => 'inviato con successo';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Ritorno al portafoglio dopo una transazione riuscita';

  @override
  String get backToWallet => 'TORNA AL PORTAFOGLIO';

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
  String get reportBugFeedback => 'Segnala Bug / Feedback';

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
  String get loansAndLeverage => 'Mercato dei Prestiti';

  @override
  String get availableOffers => 'Offerte Disponibili';

  @override
  String get myContracts => 'I Miei Contratti';

  @override
  String get signInRequired => 'Accesso Richiesto';

  @override
  String get signInToViewContracts =>
      'Accedi per vedere i tuoi contratti e ottenere prestiti.';

  @override
  String get noArkadeOffersAvailable => 'Nessuna offerta Arkade disponibile';

  @override
  String get signInToViewYourContracts => 'Accedi per vedere i tuoi contratti';

  @override
  String get noContractsMatchSearch =>
      'Nessun contratto corrisponde alla tua ricerca';

  @override
  String get noContractsYet =>
      'Nessun contratto ancora. Accetta un\'offerta per iniziare!';

  @override
  String get duration => 'Durata';

  @override
  String get minLtv => 'LTV Min';

  @override
  String get limitedTimeOffer =>
      'Offerta a tempo limitato — super conveniente!';

  @override
  String get interest => 'Interesse';

  @override
  String get due => 'Scadenza';

  @override
  String get overdue => 'Scaduto';

  @override
  String get swapDetails => 'Dettagli Swap';

  @override
  String get errorLoadingSwap => 'Errore nel caricamento dello swap';

  @override
  String get refundAddress => 'Indirizzo di Rimborso';

  @override
  String get fundSwap => 'Finanzia Swap';

  @override
  String get youSend => 'Invii';

  @override
  String get youReceive => 'Ricevi';

  @override
  String get walletConnected => 'Wallet Connesso';

  @override
  String get switchWallet => 'Cambia';

  @override
  String get creatingSwap => 'Creazione Swap...';

  @override
  String get approvingToken => 'Approvazione token...';

  @override
  String get creatingHtlc => 'Creazione HTLC...';

  @override
  String get swapFundedSuccessfully => 'Swap finanziato con successo!';

  @override
  String get feedback => 'Feedback';

  @override
  String get continueButton => 'Continua';

  @override
  String get paste => 'Incolla';

  @override
  String get scanQr => 'Scansiona QR';

  @override
  String get youPay => 'Paghi';

  @override
  String get totalFeesLabel => 'Commissioni totali';

  @override
  String get beforeFees => 'prima delle commissioni';

  @override
  String get networkFee => 'Rete';

  @override
  String get protocolFee => 'Protocollo';

  @override
  String get receivingAddress => 'Indirizzo di ricezione';

  @override
  String get waitingForDeposit => 'In attesa di Deposito';

  @override
  String get processing => 'Elaborazione';

  @override
  String get completed => 'Completato';

  @override
  String get expired => 'Scaduto';

  @override
  String get refundable => 'Rimborsabile';

  @override
  String get refundedStatus => 'Rimborsato';

  @override
  String get failed => 'Fallito';

  @override
  String get confirmSwap => 'Conferma Swap';

  @override
  String get unknownError => 'Errore sconosciuto';

  @override
  String get sendFeedback => 'Invia feedback';

  @override
  String get sender => 'Mittente';

  @override
  String get receiver => 'Destinatario';

  @override
  String get scan => 'Scansiona';

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
  String get copied => 'Copiato';
}
