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
  String get send => 'INVIA';

  @override
  String get receive => 'RICEVI';

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
  String get date => 'Data';

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
  String get boardingTransaction => 'Transazione di Imbarco';

  @override
  String get roundTransaction => 'Transazione Arrotondata';

  @override
  String get redeemTransaction => 'Transazione di Riscatto';

  @override
  String get sent => 'Inviato';

  @override
  String get received => 'Ricevuto';

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
