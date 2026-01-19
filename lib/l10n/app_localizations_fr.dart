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
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get note => 'Note';

  @override
  String get addNote => 'Add a note';

  @override
  String get apply => 'Appliquer';

  @override
  String get done => 'Terminé';

  @override
  String get select => 'Sélectionner';

  @override
  String get search => 'Rechercher';

  @override
  String get enterAmount => 'Entrer le montant';

  @override
  String get amountTooLow => 'Amount Too Low';

  @override
  String get amountTooHigh => 'Amount Too High';

  @override
  String get amount => 'Montant';

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
  String get retry => 'Réessayer';

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
  String get addressCopiedToClipboard =>
      'Adresse copiée dans le presse-papiers';

  @override
  String get shareWhichAddress => 'Quelle adresse partager ?';

  @override
  String get address => 'Adresse';

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
      'Surveillance des paiements entrants...';

  @override
  String get copyAddress => 'Copier l\'adresse';

  @override
  String get errorLoadingAddresses => 'Erreur lors du chargement des adresses';

  @override
  String get share => 'Partager';

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
  String get available => 'disponible';

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
  String get currency => 'Devise';

  @override
  String get chooseYourPreferredCurrency => 'Choisissez votre devise préférée';

  @override
  String get preferences => 'Preferences';

  @override
  String get autoReadClipboard => 'Auto-read clipboard';

  @override
  String get autoReadClipboardDescription =>
      'Automatically check clipboard for Bitcoin addresses when sending';

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
  String get pendingConfirmation => 'Confirmation en attente';

  @override
  String get transactionId => 'ID de transaction';

  @override
  String get status => 'Statut';

  @override
  String get confirmed => 'Confirmé';

  @override
  String get pending => 'En attente';

  @override
  String get spendable => 'Disponible';

  @override
  String get date => 'Date';

  @override
  String get time => 'Heure';

  @override
  String get transactionVolume => 'Volume de Transaction';

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
  String get errorLoadingTransactions =>
      'Erreur lors du chargement des transactions';

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
  String get transactionFees => 'Frais de transaction';

  @override
  String get fastest10Min => 'Plus rapide (~10 min)';

  @override
  String get halfHour => 'Demi-heure';

  @override
  String get oneHour => 'Une heure';

  @override
  String get economy => 'Économique';

  @override
  String get minutesAgo => 'il y a minutes';

  @override
  String get hoursAgo => 'il y a heures';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String get daysAgo => 'il y a jours';

  @override
  String get miningInformation => 'Informations de minage';

  @override
  String get miningPool => 'Pool de minage';

  @override
  String get mined => 'Miné';

  @override
  String get blockReward => 'Récompense de bloc';

  @override
  String get totalFees => 'Frais totaux';

  @override
  String get min => 'Min';

  @override
  String get networkHashrate => 'Hashrate du réseau';

  @override
  String get currentNetworkHashrate => 'Hashrate actuel du réseau';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get difficulty => 'Difficulté';

  @override
  String get dataPoints => 'Points de données';

  @override
  String get days => 'jours';

  @override
  String get hours => 'heures';

  @override
  String get minutes => 'minutes';

  @override
  String get difficultyAdjustment => 'Ajustement de difficulté';

  @override
  String get complete => 'terminé';

  @override
  String get remainingBlocks => 'Blocs restants';

  @override
  String get estTime => 'Temps est.';

  @override
  String get estDate => 'Date est.';

  @override
  String get mAgo => 'min';

  @override
  String get hAgo => 'h';

  @override
  String get dAgo => 'j';

  @override
  String get blockSize => 'Taille du bloc';

  @override
  String get weight => 'Poids';

  @override
  String get transactions => 'Transactions';

  @override
  String get avgSize => 'Taille moy.';

  @override
  String get healthy => 'Sain';

  @override
  String get fair => 'Moyen';

  @override
  String get low => 'Faible';

  @override
  String get blockHealth => 'Santé du bloc';

  @override
  String get full => 'Plein';

  @override
  String get actual => 'Réel';

  @override
  String get expected => 'Attendu';

  @override
  String get difference => 'Différence';

  @override
  String get setAmount => 'Définir le montant';

  @override
  String get clear => 'Effacer';

  @override
  String get errorSharingQrCode => 'Erreur lors du partage du code QR :';

  @override
  String get qr => 'QR';

  @override
  String get type => 'Type';

  @override
  String get sellBitcoin => 'Vendre Bitcoin';

  @override
  String get errorLoadingSellScreen =>
      'Erreur lors du chargement de l\'écran de vente';

  @override
  String get availableBalance => 'Solde disponible';

  @override
  String get amountToSell => 'Montant à vendre';

  @override
  String get sellLimits => 'Limites de vente';

  @override
  String get insufficientBalance => 'Solde insuffisant';

  @override
  String get max => 'Max';

  @override
  String get payoutMethods => 'Méthodes de paiement';

  @override
  String get pendingBlock => 'Bloc en attente';

  @override
  String get nextBlock => 'Bloc suivant';

  @override
  String get medianFee => 'Frais médians';

  @override
  String get estimatedTime => 'Temps estimé';

  @override
  String get feeDistribution => 'Distribution des frais';

  @override
  String get noTransactionsYet => 'Aucune transaction pour le moment';

  @override
  String get loadingMoreTransactions => 'Chargement des transactions...';

  @override
  String get scrollDownToLoadMore => 'Défiler pour charger plus';

  @override
  String get med => 'Moy';

  @override
  String get feeRate => 'Taux de frais';

  @override
  String get size => 'Taille';

  @override
  String get value => 'Valeur';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get transactionDetails => 'Détails de la transaction';

  @override
  String get errorLoadingTransaction =>
      'Erreur lors du chargement de la transaction';

  @override
  String get blockHeight => 'Hauteur du bloc';

  @override
  String get blockTime => 'Temps du bloc';

  @override
  String get details => 'Détails';

  @override
  String get fee => 'Frais';

  @override
  String get version => 'Version';

  @override
  String get locktime => 'Temps de verrouillage';

  @override
  String get inputs => 'Entrées';

  @override
  String get outputs => 'Sorties';

  @override
  String get searchBlockchain => 'Rechercher dans la blockchain';

  @override
  String get transaction => 'Transaction';

  @override
  String get enterBlockHeightOrBlockHash =>
      'Entrer la hauteur ou le hash du bloc';

  @override
  String get enterTransactionIdTxid => 'Entrer l\'ID de transaction (TXID)';

  @override
  String get blockchain => 'Blockchain';

  @override
  String get errorLoadingData => 'Erreur lors du chargement des données';

  @override
  String get recentTransactions => 'Transactions récentes';

  @override
  String get block => 'Bloc';

  @override
  String get yourTx => 'Votre TX';

  @override
  String get paymentMethods => 'Méthodes de paiement';

  @override
  String get paymentProvider => 'Payment Provider';

  @override
  String get chooseProvider => 'Choose Provider';

  @override
  String get buyLimits => 'Limites d\'achat';

  @override
  String get errorLoadingBuyScreen =>
      'Erreur lors du chargement de l\'écran d\'achat';

  @override
  String get buyBitcoin => 'Acheter Bitcoin';

  @override
  String get failedToLaunchMoonpay => 'Échec du lancement de MoonPay';

  @override
  String get bitcoinPriceChart => 'Graphique du prix Bitcoin';

  @override
  String get aboutBitcoin => 'About Bitcoin';

  @override
  String get bitcoinDescription =>
      'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.';

  @override
  String get aboutBitcoinPriceData => 'À propos des données de prix Bitcoin';

  @override
  String get thePriceDataShown =>
      'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.';

  @override
  String get dataSource => 'Source des données';

  @override
  String get liveBitcoinMarketData => 'Données du marché Bitcoin en direct';

  @override
  String get updateFrequency => 'Fréquence de mise à jour';

  @override
  String get realTime => 'Temps réel';

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
  String get loansAndLeverage => 'Marché des Prêts';

  @override
  String get availableOffers => 'Offres Disponibles';

  @override
  String get myContracts => 'Mes Contrats';

  @override
  String get signInRequired => 'Connexion Requise';

  @override
  String get signInToViewContracts =>
      'Connectez-vous pour voir vos contrats et obtenir des prêts.';

  @override
  String get noArkadeOffersAvailable => 'Aucune offre Arkade disponible';

  @override
  String get signInToViewYourContracts =>
      'Connectez-vous pour voir vos contrats';

  @override
  String get noContractsMatchSearch =>
      'Aucun contrat ne correspond à votre recherche';

  @override
  String get noContractsYet =>
      'Pas encore de contrats. Acceptez une offre pour commencer!';

  @override
  String get duration => 'Durée';

  @override
  String get minLtv => 'LTV Min';

  @override
  String get limitedTimeOffer => 'Offre limitée — super bon marché!';

  @override
  String get interest => 'Intérêt';

  @override
  String get due => 'Échéance';

  @override
  String get overdue => 'En retard';

  @override
  String get swapDetails => 'Détails du Swap';

  @override
  String get errorLoadingSwap => 'Erreur lors du chargement du swap';

  @override
  String get refundAddress => 'Adresse de Remboursement';

  @override
  String get fundSwap => 'Financer le Swap';

  @override
  String get youSend => 'Vous envoyez';

  @override
  String get youReceive => 'Vous recevez';

  @override
  String get walletConnected => 'Portefeuille Connecté';

  @override
  String get switchWallet => 'Changer';

  @override
  String get creatingSwap => 'Création du Swap...';

  @override
  String get approvingToken => 'Approbation du token...';

  @override
  String get creatingHtlc => 'Création du HTLC...';

  @override
  String get swapFundedSuccessfully => 'Swap financé avec succès!';

  @override
  String get feedback => 'Commentaires';

  @override
  String get continueButton => 'Continuer';

  @override
  String get paste => 'Coller';

  @override
  String get scanQr => 'Scanner QR';

  @override
  String get youPay => 'Vous payez';

  @override
  String get totalFeesLabel => 'Frais totaux';

  @override
  String get beforeFees => 'avant frais';

  @override
  String get networkFee => 'Réseau';

  @override
  String get protocolFee => 'Protocole';

  @override
  String get receivingAddress => 'Adresse de réception';

  @override
  String get waitingForDeposit => 'En attente de Dépôt';

  @override
  String get processing => 'Traitement';

  @override
  String get completed => 'Terminé';

  @override
  String get expired => 'Expiré';

  @override
  String get refundable => 'Remboursable';

  @override
  String get refundedStatus => 'Remboursé';

  @override
  String get failed => 'Échoué';

  @override
  String get confirmSwap => 'Confirmer le Swap';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get sendFeedback => 'Envoyer des commentaires';

  @override
  String get sender => 'Expéditeur';

  @override
  String get receiver => 'Destinataire';

  @override
  String get scan => 'Scanner';

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
  String get copied => 'Copié';
}
