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
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get note => 'Note';

  @override
  String get addNote => 'Add a note';

  @override
  String get apply => 'Applica';

  @override
  String get done => 'Fatto';

  @override
  String get select => 'Seleziona';

  @override
  String get search => 'Cerca';

  @override
  String get enterAmount => 'Inserisci Importo';

  @override
  String get amountTooLow => 'Amount Too Low';

  @override
  String get amountTooHigh => 'Amount Too High';

  @override
  String get amount => 'Importo';

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
  String get retry => 'Riprova';

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
  String get addressCopiedToClipboard => 'Indirizzo copiato negli appunti';

  @override
  String get shareWhichAddress => 'Condividere quale indirizzo?';

  @override
  String get address => 'Indirizzo';

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
      'Monitoraggio pagamenti in arrivo...';

  @override
  String get copyAddress => 'Copia indirizzo';

  @override
  String get errorLoadingAddresses => 'Errore nel caricamento degli indirizzi';

  @override
  String get share => 'Condividi';

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
  String get available => 'disponibile';

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
  String get currency => 'Valuta';

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
  String get pendingConfirmation => 'Conferma in attesa';

  @override
  String get transactionId => 'ID transazione';

  @override
  String get status => 'Stato';

  @override
  String get confirmed => 'Confermato';

  @override
  String get pending => 'In attesa';

  @override
  String get spendable => 'Disponibile';

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
  String get errorLoadingTransactions =>
      'Errore nel caricamento delle transazioni';

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
  String get transactionFees => 'Commissioni di transazione';

  @override
  String get fastest10Min => 'Più veloce (~10 min)';

  @override
  String get halfHour => 'Mezz\'ora';

  @override
  String get oneHour => 'Un\'ora';

  @override
  String get economy => 'Economica';

  @override
  String get minutesAgo => 'minuti fa';

  @override
  String get hoursAgo => 'ore fa';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String get daysAgo => 'giorni fa';

  @override
  String get miningInformation => 'Informazioni sul Mining';

  @override
  String get miningPool => 'Pool di Mining';

  @override
  String get mined => 'Minato';

  @override
  String get blockReward => 'Ricompensa Blocco';

  @override
  String get totalFees => 'Commissioni Totali';

  @override
  String get min => 'Min';

  @override
  String get networkHashrate => 'Hashrate della Rete';

  @override
  String get currentNetworkHashrate => 'Hashrate Rete Attuale';

  @override
  String get noDataAvailable => 'Nessun dato disponibile';

  @override
  String get difficulty => 'Difficoltà';

  @override
  String get dataPoints => 'Punti Dati';

  @override
  String get days => 'giorni';

  @override
  String get hours => 'ore';

  @override
  String get minutes => 'minuti';

  @override
  String get difficultyAdjustment => 'Regolazione Difficoltà';

  @override
  String get complete => 'completato';

  @override
  String get remainingBlocks => 'Blocchi Rimanenti';

  @override
  String get estTime => 'Tempo stimato';

  @override
  String get estDate => 'Data stimata';

  @override
  String get mAgo => 'min fa';

  @override
  String get hAgo => 'ore fa';

  @override
  String get dAgo => 'g fa';

  @override
  String get blockSize => 'Dimensione Blocco';

  @override
  String get weight => 'Peso';

  @override
  String get transactions => 'Transazioni';

  @override
  String get avgSize => 'Dim. Media';

  @override
  String get healthy => 'Sano';

  @override
  String get fair => 'Discreto';

  @override
  String get low => 'Basso';

  @override
  String get blockHealth => 'Stato del Blocco';

  @override
  String get full => 'Pieno';

  @override
  String get actual => 'Attuale';

  @override
  String get expected => 'Previsto';

  @override
  String get difference => 'Differenza';

  @override
  String get setAmount => 'Imposta Importo';

  @override
  String get clear => 'Cancella';

  @override
  String get errorSharingQrCode => 'Errore condivisione codice QR:';

  @override
  String get qr => 'QR';

  @override
  String get type => 'Tipo';

  @override
  String get sellBitcoin => 'Vendi Bitcoin';

  @override
  String get errorLoadingSellScreen =>
      'Errore nel caricamento della schermata di vendita';

  @override
  String get availableBalance => 'Saldo Disponibile';

  @override
  String get amountToSell => 'Importo da Vendere';

  @override
  String get sellLimits => 'Limiti di Vendita';

  @override
  String get insufficientBalance => 'Saldo insufficiente';

  @override
  String get max => 'Max';

  @override
  String get payoutMethods => 'Metodi di Pagamento';

  @override
  String get pendingBlock => 'Blocco in Attesa';

  @override
  String get nextBlock => 'Prossimo Blocco';

  @override
  String get medianFee => 'Commissione Mediana';

  @override
  String get estimatedTime => 'Tempo Stimato';

  @override
  String get feeDistribution => 'Distribuzione Commissioni';

  @override
  String get noTransactionsYet => 'Nessuna transazione';

  @override
  String get loadingMoreTransactions => 'Caricamento altre transazioni...';

  @override
  String get scrollDownToLoadMore => 'Scorri verso il basso per caricare altro';

  @override
  String get med => ', \"Med\", ';

  @override
  String get feeRate => 'Tasso Commissione';

  @override
  String get size => 'Dimensione';

  @override
  String get value => 'Valore';

  @override
  String get copiedToClipboard => 'Copiato negli appunti';

  @override
  String get transactionDetails => 'Dettagli transazione';

  @override
  String get errorLoadingTransaction =>
      'Errore nel caricamento della transazione';

  @override
  String get blockHeight => 'Altezza Blocco';

  @override
  String get blockTime => 'Ora del Blocco';

  @override
  String get details => 'Dettagli';

  @override
  String get fee => 'Commissione';

  @override
  String get version => 'Versione';

  @override
  String get locktime => 'Locktime';

  @override
  String get inputs => 'Input';

  @override
  String get outputs => 'Output';

  @override
  String get searchBlockchain => 'Cerca nella Blockchain';

  @override
  String get transaction => 'Transazione';

  @override
  String get enterBlockHeightOrBlockHash =>
      'Inserisci altezza blocco o hash del blocco';

  @override
  String get enterTransactionIdTxid => 'Inserisci ID transazione (TXID)';

  @override
  String get blockchain => 'Blockchain';

  @override
  String get errorLoadingData => 'Errore nel caricamento dei dati';

  @override
  String get recentTransactions => 'Transazioni recenti';

  @override
  String get block => 'Blocco';

  @override
  String get yourTx => 'La tua TX';

  @override
  String get paymentMethods => 'Metodi di Pagamento';

  @override
  String get paymentProvider => 'Payment Provider';

  @override
  String get chooseProvider => 'Choose Provider';

  @override
  String get buyLimits => 'Limiti di Acquisto';

  @override
  String get errorLoadingBuyScreen =>
      'Errore nel caricamento della schermata di acquisto';

  @override
  String get buyBitcoin => 'Compra Bitcoin';

  @override
  String get failedToLaunchMoonpay => 'Impossibile avviare MoonPay';

  @override
  String get bitcoinPriceChart => 'Grafico Prezzo Bitcoin';

  @override
  String get aboutBitcoin => 'About Bitcoin';

  @override
  String get bitcoinDescription =>
      'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.';

  @override
  String get aboutBitcoinPriceData => 'Informazioni sui Dati Prezzo Bitcoin';

  @override
  String get thePriceDataShown =>
      'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.';

  @override
  String get dataSource => 'Fonte Dati';

  @override
  String get liveBitcoinMarketData => 'Dati di Mercato Bitcoin in Tempo Reale';

  @override
  String get updateFrequency => 'Frequenza Aggiornamento';

  @override
  String get realTime => 'Tempo reale';

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
      'The app allows users to receive, send, and manage Bitcoin. The app is not a bank and does not provide banking services.';

  @override
  String get agbUserResponsibilityTitle => 'User Responsibility';

  @override
  String get agbUserResponsibilityContent =>
      'The user is fully self-responsible for using the application and the security of their Bitcoin. The user acknowledges that loss of their recovery phrase (mnemonic) is equivalent to loss of their funds. COBLOX PTY LTD is not liable for any losses resulting from carelessness, loss of devices, or loss of the recovery phrase.';

  @override
  String get agbFeesTitle => 'Fees';

  @override
  String get agbFeesContent =>
      'Certain functions of the app may incur fees. These fees will be communicated to the user in advance and are visible in the app.';

  @override
  String get agbBuyingSelling => 'Buying and Selling Bitcoin';

  @override
  String get agbBuyingSellingContent =>
      'Buying and selling Bitcoin is facilitated through third-party providers. COBLOX PTY LTD is not involved in these transactions and bears no responsibility for them. Any issues, disputes, or inquiries related to buying or selling Bitcoin must be directed to and resolved with the respective third-party provider.';

  @override
  String get agbLiabilityTitle => 'Limitation of Liability';

  @override
  String get agbLiabilityContent =>
      'COBLOX PTY LTD is only liable for damages caused by intentional or grossly negligent actions by COBLOX PTY LTD. COBLOX PTY LTD is not liable for damages resulting from the use of the app or the loss of Bitcoin.';

  @override
  String get agbChangesTitle => 'Changes';

  @override
  String get agbChangesContent =>
      'COBLOX PTY LTD reserves the right to change these terms and conditions at any time. Continued use of the app constitutes acceptance of any updated terms.';

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
