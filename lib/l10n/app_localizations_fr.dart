// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'Paramètres';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Enregistrer';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Terminé';

  @override
  String get select => 'Sélectionner';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'Entrer le montant';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'PASSER (N\'IMPORTE QUEL MONTANT)';

  @override
  String get contin => 'CONTINUER';

  @override
  String get currencyUpdatedSuccessfully => 'Devise mise à jour avec succès';

  @override
  String get changeCurrency => 'Changer la devise';

  @override
  String get languageUpdatedSuccessfully => 'Langue mise à jour avec succès';

  @override
  String get changeLanguage => 'Changer la langue';

  @override
  String get themeAppliedSuccessfully => 'Thème appliqué avec succès';

  @override
  String get chooseYourColor => 'Choisissez votre couleur';

  @override
  String get selectColor => 'Sélectionner une couleur';

  @override
  String get selectColorShade => 'Sélectionner une nuance de couleur';

  @override
  String get changeYourStyle => 'Changez votre style';

  @override
  String get chooseYourPreferredTheme => 'Choisissez votre thème préféré';

  @override
  String get dark => 'Sombre';

  @override
  String get originalDarkTheme => 'Thème sombre original';

  @override
  String get light => 'Clair';

  @override
  String get cleanLightTheme => 'Thème clair épuré';

  @override
  String get applyTheme => 'Appliquer le thème';

  @override
  String get custom => 'Personnalisé';

  @override
  String get createYourOwnTheme => 'Créez votre propre thème';

  @override
  String get timezoneUpdatedSuccessfully =>
      'Fuseau horaire mis à jour avec succès';

  @override
  String get changeTimezone => 'Changer le fuseau horaire';

  @override
  String get searchTimezone => 'Rechercher un fuseau horaire...';

  @override
  String get couldntUpdateTransactions =>
      'Impossible de mettre à jour les transactions :';

  @override
  String get couldntUpdateBalance => 'Impossible de mettre à jour le solde :';

  @override
  String showingBalanceType(String balanceType) {
    return 'Affichage du solde $balanceType';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'Solde en attente';

  @override
  String get confirmedBalance => 'Solde confirmé';

  @override
  String get totalBalance => 'Solde total';

  @override
  String get errorLoadingBalance => 'Erreur lors du chargement du solde';

  @override
  String get send => 'Envoyer';

  @override
  String get receive => 'Recevoir';

  @override
  String get failedToCreateWallet => 'Échec de la création du portefeuille';

  @override
  String errorCreatingWallet(String error) {
    return 'Une erreur est survenue lors de la création de votre nouveau portefeuille. Veuillez réessayer.\n\nErreur : $error';
  }

  @override
  String get failedToRestoreWallet =>
      'Échec de la restauration du portefeuille';

  @override
  String errorRestoringWallet(String error) {
    return 'Une erreur est survenue lors de la restauration de votre portefeuille. Veuillez vérifier votre nsec et réessayer.\n\nErreur : $error';
  }

  @override
  String get appTagline => 'Le portefeuille qui vole sur Ark';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'Choisissez une option :';

  @override
  String get createNewWallet => 'Créer un nouveau portefeuille';

  @override
  String get generateANewSecureWallet =>
      'Générer un nouveau portefeuille sécurisé';

  @override
  String get restoreExistingWallet => 'Restaurer un portefeuille existant';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'Utilisez votre clé secrète pour accéder à votre portefeuille';

  @override
  String get enterYourNsec => 'Entrez votre nsec :';

  @override
  String get pasteYourRecoveryNsec => 'Collez votre nsec de récupération...';

  @override
  String paymentMonitoringError(String error) {
    return 'Erreur de surveillance du paiement : $error';
  }

  @override
  String get paymentReceived => 'Paiement reçu !';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'Quelle adresse partager ?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'Facture Lightning';

  @override
  String get qrCodeImage => 'Image du code QR';

  @override
  String get errorSharing => 'Erreur lors du partage';

  @override
  String get myBitcoinAddressQrCode => 'Code QR de mon adresse Bitcoin';

  @override
  String get requesting => 'Demande : ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'Copier l\'adresse';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'Veuillez entrer à la fois l\'adresse et le montant';

  @override
  String get pleaseEnterAValidAmount => 'Veuillez entrer un montant valide';

  @override
  String get insufficientFunds => 'Fonds insuffisants';

  @override
  String get sendLower => 'Envoyer';

  @override
  String get receiveLower => 'Recevoir';

  @override
  String get recipientAddress => 'Adresse du destinataire';

  @override
  String get bitcoinOrArkAddress => 'Adresse Bitcoin ou Ark';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Esplora enregistrée – prendra effet après un redémarrage';

  @override
  String get failedToSaveEsploraUrl =>
      'Échec de l\'enregistrement de l\'URL Esplora';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'Réseau enregistré – prendra effet après un redémarrage';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL du serveur Ark enregistrée – prendra effet après un redémarrage';

  @override
  String get failedToSaveArkServerUrl =>
      'Échec de l\'enregistrement de l\'URL du serveur Ark';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Boltz enregistrée – prendra effet après un redémarrage';

  @override
  String get failedToSaveBoltzUrl =>
      'Échec de l\'enregistrement de l\'URL Boltz';

  @override
  String get securityWarning => 'Avertissement de sécurité';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'Ne partagez jamais votre clé de récupération avec qui que ce soit !';

  @override
  String get anyoneWithThisKeyCan =>
      'Toute personne possédant cette clé peut accéder à votre portefeuille et voler vos fonds. Conservez-la dans un endroit sûr.';

  @override
  String get iUnderstand => 'JE COMPRENDS';

  @override
  String get yourRecoveryPhrase => 'Votre phrase de récupération';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'Phrase de récupération copiée dans le presse-papiers';

  @override
  String get copyToClipboard => 'COPIER DANS LE PRESSE-PAPIERS';

  @override
  String get close => 'FERMER';

  @override
  String get resetWallet => 'Réinitialiser le portefeuille';

  @override
  String get thisWillDeleteAllWalletData =>
      'Cela supprimera toutes les données du portefeuille de cet appareil. Assurez-vous d\'avoir sauvegardé votre phrase de récupération avant de continuer. Cette action est irréversible.';

  @override
  String get restartingApp => 'Redémarrage de l\'application';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'Appuyez ici pour rouvrir l\'application.';

  @override
  String get reset => 'RÉINITIALISER';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get viewRecoveryKey => 'Afficher la clé de récupération';

  @override
  String get backupYourWalletWithTheseKey =>
      'Sauvegardez votre portefeuille avec cette clé';

  @override
  String get appearancePreferences => 'Apparence et préférences';

  @override
  String get theme => 'Thème';

  @override
  String get customizeAppAppearance =>
      'Personnaliser l\'apparence de l\'application';

  @override
  String get language => 'Langue';

  @override
  String get selectYourPreferredLanguage =>
      'Sélectionnez votre langue préférée';

  @override
  String get timezone => 'Fuseau horaire';

  @override
  String get chooseYourPreferredTimezone =>
      'Choisissez votre fuseau horaire préféré';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'Choisissez votre devise préférée';

  @override
  String get serverConfiguration => 'Configuration du serveur';

  @override
  String get network => 'Réseau';

  @override
  String get esploraUrl => 'URL Esplora';

  @override
  String get arkServer => 'Serveur Ark';

  @override
  String get boltzUrl => 'URL Boltz';

  @override
  String get about => 'À propos';

  @override
  String get loading => 'chargement';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'Supprimer toutes les données du portefeuille de cet appareil';

  @override
  String get transactionFailed => 'Échec de la transaction :';

  @override
  String get signTransaction => 'Signer la transaction';

  @override
  String get networkFees => 'Frais de réseau';

  @override
  String get total => 'Total';

  @override
  String get tapToSign => 'APPUYEZ POUR SIGNER';

  @override
  String get settlingTransaction => 'Finalisation de la transaction...';

  @override
  String get success => 'Succès';

  @override
  String get transactionSettledSuccessfully =>
      'Transaction finalisée avec succès !';

  @override
  String get goToHome => 'Aller à l\'accueil';

  @override
  String get error => 'Erreur';

  @override
  String get failedToSettleTransaction =>
      'Échec de la finalisation de la transaction :';

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
  String get date => 'Date';

  @override
  String get confirmedAt => 'Confirmé le';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'Transaction en attente. Les fonds seront irréversibles après la finalisation.';

  @override
  String get settle => 'FINALISER';

  @override
  String get transactionHistory => 'Historique des transactions';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet =>
      'Aucun historique de transactions pour le moment';

  @override
  String get boardingTransaction => 'Transaction Onchain';

  @override
  String get roundTransaction => 'Transaction d\'arrondi';

  @override
  String get redeemTransaction => 'Transaction de rachat';

  @override
  String get sent => 'Envoyé';

  @override
  String get received => 'Reçu';

  @override
  String get direction => 'Direction';

  @override
  String get settled => 'Finalisé';

  @override
  String get sentSuccessfully => 'envoyé avec succès';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Retour au portefeuille après une transaction réussie';

  @override
  String get backToWallet => 'RETOUR AU PORTEFEUILLE';

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
  String get reportBugFeedback => 'Signaler un bug / Feedback';

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
      'These terms and conditions govern the use of the Bitcoin wallet app (hereinafter Lenda), provided by Lendasat Inc. By using the app, you agree to these terms and conditions.';

  @override
  String get agbFunctionalityTitle => 'Functionality';

  @override
  String get agbFunctionalityContent =>
      'The app allows users to receive, send, and manage Bitcoin. The app is not a bank and does not provide banking services. Additionally, Taproot Assets, also known as digital assets, are offered and sold as a service platform.';

  @override
  String get agbUserResponsibilityTitle => 'User Responsibility';

  @override
  String get agbUserResponsibilityContent =>
      'The user is solely responsible for the security of their Bitcoin. The app provides security features such as password protection and two-factor authentication, but it is the user\'s responsibility to use these features carefully. Lendasat Inc. is not liable for losses resulting from carelessness, loss of devices, or user credentials.';

  @override
  String get agbFeesTitle => 'Fees';

  @override
  String get agbFeesContent =>
      'Certain functions of the app may incur fees. These fees will be communicated to the user in advance and are visible in the app.';

  @override
  String get agbLiabilityTitle => 'Limitation of Liability';

  @override
  String get agbLiabilityContent =>
      'Lendasat Inc. is only liable for damages caused by intentional or grossly negligent actions by Lendasat Inc. Lendasat Inc. is not liable for damages resulting from the use of the app or the loss of Bitcoin.';

  @override
  String get agbChangesTitle => 'Changes';

  @override
  String get agbChangesContent =>
      'Lendasat Inc. reserves the right to change these terms and conditions at any time. The user will be informed of such changes and must agree to them in order to continue using the app.';

  @override
  String get agbFinalProvisionsTitle => 'Final Provisions';

  @override
  String get agbFinalProvisionsContent =>
      'These terms and conditions represent the entire agreement between the user and Lendasat Inc. Should any provision be invalid, the remaining provisions shall remain in effect.';

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
}
