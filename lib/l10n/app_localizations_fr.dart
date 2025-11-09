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
  String get retry => 'RÉESSAYER';

  @override
  String get pendingBalance => 'Solde en attente';

  @override
  String get confirmedBalance => 'Solde confirmé';

  @override
  String get totalBalance => 'Solde total';

  @override
  String get errorLoadingBalance => 'Erreur lors du chargement du solde';

  @override
  String get send => 'ENVOYER';

  @override
  String get receive => 'RECEVOIR';

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
  String get share => 'PARTAGER';

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
  String get pendingConfirmation => 'En attente de confirmation';

  @override
  String get transactionId => 'ID de transaction';

  @override
  String get status => 'Statut';

  @override
  String get confirmed => 'Confirmé';

  @override
  String get pending => 'En attente';

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
  String get errorLoadingTransactions =>
      'Erreur lors du chargement des transactions';

  @override
  String get noTransactionHistoryYet =>
      'Aucun historique de transactions pour le moment';

  @override
  String get boardingTransaction => 'Transaction d\'embarquement';

  @override
  String get roundTransaction => 'Transaction d\'arrondi';

  @override
  String get redeemTransaction => 'Transaction de rachat';

  @override
  String get sent => 'Envoyé';

  @override
  String get received => 'Reçu';

  @override
  String get settled => 'Finalisé';

  @override
  String get sentSuccessfully => 'envoyé avec succès';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Retour au portefeuille après une transaction réussie';

  @override
  String get backToWallet => 'RETOUR AU PORTEFEUILLE';
}
