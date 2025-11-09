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
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get apply => 'Anwenden';

  @override
  String get done => 'Fertig';

  @override
  String get select => 'Auswählen';

  @override
  String get search => 'Suchen';

  @override
  String get enterAmount => 'Betrag eingeben';

  @override
  String get amount => 'Betrag';

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
  String get retry => 'ERNEUT VERSUCHEN';

  @override
  String get pendingBalance => 'Ausstehender Kontostand';

  @override
  String get confirmedBalance => 'Bestätigter Kontostand';

  @override
  String get totalBalance => 'Gesamtkontostand';

  @override
  String get errorLoadingBalance => 'Fehler beim Laden des Kontostands';

  @override
  String get send => 'SENDEN';

  @override
  String get receive => 'EMPFANGEN';

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
  String get addressCopiedToClipboard => 'Adresse in Zwischenablage kopiert';

  @override
  String get shareWhichAddress => 'Welche Adresse teilen?';

  @override
  String get address => 'Adresse';

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
      'Überwachung eingehender Zahlungen...';

  @override
  String get copyAddress => 'Adresse kopieren';

  @override
  String get errorLoadingAddresses => 'Fehler beim Laden der Adressen';

  @override
  String get share => 'TEILEN';

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
  String get available => 'verfügbar';

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
  String get currency => 'Währung';

  @override
  String get chooseYourPreferredCurrency => 'Wähle deine bevorzugte Währung';

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
  String get pendingConfirmation => 'Ausstehende Bestätigung';

  @override
  String get transactionId => 'Transaktions-ID';

  @override
  String get status => 'Status';

  @override
  String get confirmed => 'Bestätigt';

  @override
  String get pending => 'Ausstehend';

  @override
  String get date => 'Datum';

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
  String get errorLoadingTransactions => 'Fehler beim Laden der Transaktionen';

  @override
  String get noTransactionHistoryYet => 'Noch kein Transaktionsverlauf';

  @override
  String get boardingTransaction => 'Einstiegs-Transaktion';

  @override
  String get roundTransaction => 'Rundungs-Transaktion';

  @override
  String get redeemTransaction => 'Einlöse-Transaktion';

  @override
  String get sent => 'Gesendet';

  @override
  String get received => 'Empfangen';

  @override
  String get settled => 'Abgeschlossen';

  @override
  String get sentSuccessfully => 'Erfolgreich gesendet';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Rückkehr zur Wallet nach erfolgreicher Transaktion';

  @override
  String get backToWallet => 'ZURÜCK ZUR WALLET';
}
