import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ur'),
    Locale('zh')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Ark Flutter'**
  String get appTitle;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Note label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Add note placeholder
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// Apply button text
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Select button text
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// No description provided for @amountTooLow.
  ///
  /// In en, this message translates to:
  /// **'Amount Too Low'**
  String get amountTooLow;

  /// No description provided for @amountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Amount Too High'**
  String get amountTooHigh;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @skipAnyAmount.
  ///
  /// In en, this message translates to:
  /// **'SKIP (ANY AMOUNT)'**
  String get skipAnyAmount;

  /// No description provided for @contin.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get contin;

  /// No description provided for @currencyUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Currency updated successfully'**
  String get currencyUpdatedSuccessfully;

  /// No description provided for @changeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change Currency'**
  String get changeCurrency;

  /// No description provided for @languageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdatedSuccessfully;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @themeAppliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Theme applied successfully'**
  String get themeAppliedSuccessfully;

  /// No description provided for @chooseYourColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Color'**
  String get chooseYourColor;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get selectColor;

  /// No description provided for @selectColorShade.
  ///
  /// In en, this message translates to:
  /// **'Select color shade'**
  String get selectColorShade;

  /// No description provided for @changeYourStyle.
  ///
  /// In en, this message translates to:
  /// **'Change Your Style'**
  String get changeYourStyle;

  /// No description provided for @chooseYourPreferredTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme'**
  String get chooseYourPreferredTheme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @originalDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Original dark theme'**
  String get originalDarkTheme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @cleanLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Clean light theme'**
  String get cleanLightTheme;

  /// No description provided for @applyTheme.
  ///
  /// In en, this message translates to:
  /// **'Apply Theme'**
  String get applyTheme;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @createYourOwnTheme.
  ///
  /// In en, this message translates to:
  /// **'Create your own theme'**
  String get createYourOwnTheme;

  /// No description provided for @timezoneUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Timezone updated successfully'**
  String get timezoneUpdatedSuccessfully;

  /// No description provided for @changeTimezone.
  ///
  /// In en, this message translates to:
  /// **'Change Timezone'**
  String get changeTimezone;

  /// No description provided for @searchTimezone.
  ///
  /// In en, this message translates to:
  /// **'Search timezone...'**
  String get searchTimezone;

  /// No description provided for @couldntUpdateTransactions.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update transactions:'**
  String get couldntUpdateTransactions;

  /// No description provided for @couldntUpdateBalance.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update balance:'**
  String get couldntUpdateBalance;

  /// Message shown when toggling between balance types
  ///
  /// In en, this message translates to:
  /// **'Showing {balanceType} balance'**
  String showingBalanceType(String balanceType);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pendingBalance.
  ///
  /// In en, this message translates to:
  /// **'Pending Balance'**
  String get pendingBalance;

  /// No description provided for @confirmedBalance.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Balance'**
  String get confirmedBalance;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @errorLoadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Error loading balance'**
  String get errorLoadingBalance;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @failedToCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to create wallet'**
  String get failedToCreateWallet;

  /// Error message shown when wallet creation fails
  ///
  /// In en, this message translates to:
  /// **'There was an error creating your new wallet. Please try again.\n\nError: {error}'**
  String errorCreatingWallet(String error);

  /// No description provided for @failedToRestoreWallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore wallet'**
  String get failedToRestoreWallet;

  /// Error message shown when wallet restoration fails
  ///
  /// In en, this message translates to:
  /// **'There was an error restoring your wallet. Please check your nsec and try again.\n\nError: {error}'**
  String errorRestoringWallet(String error);

  /// App tagline
  ///
  /// In en, this message translates to:
  /// **'The first Bitcoin wallet that doesn\'t suck.'**
  String get appTagline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @chooseAnOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an option:'**
  String get chooseAnOption;

  /// No description provided for @createNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get createNewWallet;

  /// No description provided for @generateANewSecureWallet.
  ///
  /// In en, this message translates to:
  /// **'Generate a new secure wallet'**
  String get generateANewSecureWallet;

  /// No description provided for @restoreExistingWallet.
  ///
  /// In en, this message translates to:
  /// **'Restore Existing Wallet'**
  String get restoreExistingWallet;

  /// No description provided for @useYourSecretKeyToAccessYourWallet.
  ///
  /// In en, this message translates to:
  /// **'Use your secret key to access your wallet'**
  String get useYourSecretKeyToAccessYourWallet;

  /// No description provided for @enterYourNsec.
  ///
  /// In en, this message translates to:
  /// **'Enter your nsec:'**
  String get enterYourNsec;

  /// No description provided for @pasteYourRecoveryNsec.
  ///
  /// In en, this message translates to:
  /// **'Paste your recovery nsec...'**
  String get pasteYourRecoveryNsec;

  /// Error message shown when payment monitoring fails
  ///
  /// In en, this message translates to:
  /// **'Payment monitoring error: {error}'**
  String paymentMonitoringError(String error);

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received!'**
  String get paymentReceived;

  /// No description provided for @addressCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get addressCopiedToClipboard;

  /// No description provided for @shareWhichAddress.
  ///
  /// In en, this message translates to:
  /// **'Share Which Address?'**
  String get shareWhichAddress;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @lightningInvoice.
  ///
  /// In en, this message translates to:
  /// **'Lightning Invoice'**
  String get lightningInvoice;

  /// No description provided for @qrCodeImage.
  ///
  /// In en, this message translates to:
  /// **'QR Code Image'**
  String get qrCodeImage;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get errorSharing;

  /// No description provided for @myBitcoinAddressQrCode.
  ///
  /// In en, this message translates to:
  /// **'My Bitcoin Address QR Code'**
  String get myBitcoinAddressQrCode;

  /// No description provided for @requesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting: '**
  String get requesting;

  /// No description provided for @monitoringForIncomingPayment.
  ///
  /// In en, this message translates to:
  /// **'Monitoring for incoming payment...'**
  String get monitoringForIncomingPayment;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

  /// No description provided for @errorLoadingAddresses.
  ///
  /// In en, this message translates to:
  /// **'Error loading addresses'**
  String get errorLoadingAddresses;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @pleaseEnterBothAddressAndAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter both address and amount'**
  String get pleaseEnterBothAddressAndAmount;

  /// No description provided for @pleaseEnterAValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterAValidAmount;

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get insufficientFunds;

  /// No description provided for @sendLower.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendLower;

  /// No description provided for @receiveLower.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveLower;

  /// No description provided for @recipientAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get recipientAddress;

  /// No description provided for @bitcoinOrArkAddress.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin or Arkade address'**
  String get bitcoinOrArkAddress;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get available;

  /// No description provided for @esploraUrlSavedWillOnlyTakeEffectAfterARestart.
  ///
  /// In en, this message translates to:
  /// **'Esplora URL saved  - will only take effect after a restart'**
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart;

  /// No description provided for @failedToSaveEsploraUrl.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Esplora URL'**
  String get failedToSaveEsploraUrl;

  /// No description provided for @networkSavedWillOnlyTakeEffectAfterARestart.
  ///
  /// In en, this message translates to:
  /// **'Network saved - will only take effect after a restart'**
  String get networkSavedWillOnlyTakeEffectAfterARestart;

  /// No description provided for @arkServerUrlSavedWillOnlyTakeEffectAfterARestart.
  ///
  /// In en, this message translates to:
  /// **'Ark Server URL saved - will only take effect after a restart'**
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart;

  /// No description provided for @failedToSaveArkServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Ark Server URL'**
  String get failedToSaveArkServerUrl;

  /// No description provided for @boltzUrlSavedWillOnlyTakeEffectAfterARestart.
  ///
  /// In en, this message translates to:
  /// **'Boltz URL saved - will only take effect after a restart'**
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart;

  /// No description provided for @failedToSaveBoltzUrl.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Boltz URL'**
  String get failedToSaveBoltzUrl;

  /// No description provided for @securityWarning.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get securityWarning;

  /// No description provided for @neverShareYourRecoveryKeyWithAnyone.
  ///
  /// In en, this message translates to:
  /// **'Never share your recovery key with anyone!'**
  String get neverShareYourRecoveryKeyWithAnyone;

  /// No description provided for @anyoneWithThisKeyCan.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this key can access your wallet and steal your funds. Store it in a secure place.'**
  String get anyoneWithThisKeyCan;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND'**
  String get iUnderstand;

  /// No description provided for @yourRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Your Recovery Phrase'**
  String get yourRecoveryPhrase;

  /// No description provided for @recoveryPhraseCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase copied to clipboard'**
  String get recoveryPhraseCopiedToClipboard;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'COPY TO CLIPBOARD'**
  String get copyToClipboard;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// No description provided for @resetWallet.
  ///
  /// In en, this message translates to:
  /// **'Reset Wallet'**
  String get resetWallet;

  /// No description provided for @thisWillDeleteAllWalletData.
  ///
  /// In en, this message translates to:
  /// **'This will delete all wallet data from this device. Make sure you have backed up your recovery phrase before proceeding. This action cannot be undone.'**
  String get thisWillDeleteAllWalletData;

  /// No description provided for @restartingApp.
  ///
  /// In en, this message translates to:
  /// **'Restarting App'**
  String get restartingApp;

  /// No description provided for @pleaseTapHereToOpenTheAppAgain.
  ///
  /// In en, this message translates to:
  /// **'Please tap here to open the app again.'**
  String get pleaseTapHereToOpenTheAppAgain;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get reset;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @viewRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'View Recovery Key'**
  String get viewRecoveryKey;

  /// No description provided for @backupYourWalletWithTheseKey.
  ///
  /// In en, this message translates to:
  /// **'Backup your wallet with these key'**
  String get backupYourWalletWithTheseKey;

  /// No description provided for @appearancePreferences.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Preferences'**
  String get appearancePreferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @customizeAppAppearance.
  ///
  /// In en, this message translates to:
  /// **'Customize app appearance'**
  String get customizeAppAppearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectYourPreferredLanguage;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @chooseYourPreferredTimezone.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred timezone'**
  String get chooseYourPreferredTimezone;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @chooseYourPreferredCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred currency'**
  String get chooseYourPreferredCurrency;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @autoReadClipboard.
  ///
  /// In en, this message translates to:
  /// **'Auto-read clipboard'**
  String get autoReadClipboard;

  /// No description provided for @autoReadClipboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically check clipboard for Bitcoin addresses when sending'**
  String get autoReadClipboardDescription;

  /// No description provided for @serverConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Server Configuration'**
  String get serverConfiguration;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @esploraUrl.
  ///
  /// In en, this message translates to:
  /// **'Esplora URL'**
  String get esploraUrl;

  /// No description provided for @arkServer.
  ///
  /// In en, this message translates to:
  /// **'Ark Server'**
  String get arkServer;

  /// No description provided for @boltzUrl.
  ///
  /// In en, this message translates to:
  /// **'Boltz URL'**
  String get boltzUrl;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get loading;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAllWalletDataFromThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete all wallet data from this device'**
  String get deleteAllWalletDataFromThisDevice;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction failed:'**
  String get transactionFailed;

  /// No description provided for @signTransaction.
  ///
  /// In en, this message translates to:
  /// **'Sign transaction'**
  String get signTransaction;

  /// No description provided for @networkFees.
  ///
  /// In en, this message translates to:
  /// **'Network fees'**
  String get networkFees;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @tapToSign.
  ///
  /// In en, this message translates to:
  /// **'TAP TO SIGN'**
  String get tapToSign;

  /// No description provided for @settlingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Settling transaction...'**
  String get settlingTransaction;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @transactionSettledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transaction settled successfully!'**
  String get transactionSettledSuccessfully;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @failedToSettleTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to settle transaction:'**
  String get failedToSettleTransaction;

  /// No description provided for @pendingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pending Confirmation'**
  String get pendingConfirmation;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @spendable.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get spendable;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @transactionVolume.
  ///
  /// In en, this message translates to:
  /// **'Transaction Volume'**
  String get transactionVolume;

  /// No description provided for @confirmedAt.
  ///
  /// In en, this message translates to:
  /// **'Confirmed At'**
  String get confirmedAt;

  /// No description provided for @transactionPendingFundsWillBeNonReversibleAfterSettlement.
  ///
  /// In en, this message translates to:
  /// **'Transaction pending. Funds will be non-reversible after settlement.'**
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement;

  /// No description provided for @settle.
  ///
  /// In en, this message translates to:
  /// **'SETTLE'**
  String get settle;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @errorLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Error loading transactions'**
  String get errorLoadingTransactions;

  /// No description provided for @noTransactionHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No transaction history yet'**
  String get noTransactionHistoryYet;

  /// No description provided for @boardingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Onchain Transaction'**
  String get boardingTransaction;

  /// No description provided for @roundTransaction.
  ///
  /// In en, this message translates to:
  /// **'Round Transaction'**
  String get roundTransaction;

  /// No description provided for @redeemTransaction.
  ///
  /// In en, this message translates to:
  /// **'Redeem Transaction'**
  String get redeemTransaction;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @sentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'sent successfully'**
  String get sentSuccessfully;

  /// No description provided for @returningToWalletAfterSuccessfulTransaction.
  ///
  /// In en, this message translates to:
  /// **'Returning to wallet after successful transaction'**
  String get returningToWalletAfterSuccessfulTransaction;

  /// No description provided for @backToWallet.
  ///
  /// In en, this message translates to:
  /// **'BACK TO WALLET'**
  String get backToWallet;

  /// No description provided for @transactionFees.
  ///
  /// In en, this message translates to:
  /// **'Transaction Fees'**
  String get transactionFees;

  /// No description provided for @fastest10Min.
  ///
  /// In en, this message translates to:
  /// **'Fastest (~10 min)'**
  String get fastest10Min;

  /// No description provided for @halfHour.
  ///
  /// In en, this message translates to:
  /// **'Half Hour'**
  String get halfHour;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'One Hour'**
  String get oneHour;

  /// No description provided for @economy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get economy;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @oneDayAgo.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get oneDayAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @miningInformation.
  ///
  /// In en, this message translates to:
  /// **'Mining Information'**
  String get miningInformation;

  /// No description provided for @miningPool.
  ///
  /// In en, this message translates to:
  /// **'Mining Pool'**
  String get miningPool;

  /// No description provided for @mined.
  ///
  /// In en, this message translates to:
  /// **'Mined'**
  String get mined;

  /// No description provided for @blockReward.
  ///
  /// In en, this message translates to:
  /// **'Block Reward'**
  String get blockReward;

  /// No description provided for @totalFees.
  ///
  /// In en, this message translates to:
  /// **'Total Fees'**
  String get totalFees;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @networkHashrate.
  ///
  /// In en, this message translates to:
  /// **'Network Hashrate'**
  String get networkHashrate;

  /// No description provided for @currentNetworkHashrate.
  ///
  /// In en, this message translates to:
  /// **'Current Network Hashrate'**
  String get currentNetworkHashrate;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @dataPoints.
  ///
  /// In en, this message translates to:
  /// **'Data Points'**
  String get dataPoints;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @difficultyAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Adjustment'**
  String get difficultyAdjustment;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get complete;

  /// No description provided for @remainingBlocks.
  ///
  /// In en, this message translates to:
  /// **'Remaining Blocks'**
  String get remainingBlocks;

  /// No description provided for @estTime.
  ///
  /// In en, this message translates to:
  /// **'Est. Time'**
  String get estTime;

  /// No description provided for @estDate.
  ///
  /// In en, this message translates to:
  /// **'Est. Date'**
  String get estDate;

  /// No description provided for @mAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get mAgo;

  /// No description provided for @hAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hAgo;

  /// No description provided for @dAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get dAgo;

  /// No description provided for @blockSize.
  ///
  /// In en, this message translates to:
  /// **'Block Size'**
  String get blockSize;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @avgSize.
  ///
  /// In en, this message translates to:
  /// **'Avg Size'**
  String get avgSize;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @blockHealth.
  ///
  /// In en, this message translates to:
  /// **'Block Health'**
  String get blockHealth;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// No description provided for @actual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @setAmount.
  ///
  /// In en, this message translates to:
  /// **'Set Amount'**
  String get setAmount;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @errorSharingQrCode.
  ///
  /// In en, this message translates to:
  /// **'Error sharing QR code:'**
  String get errorSharingQrCode;

  /// No description provided for @qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get qr;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @sellBitcoin.
  ///
  /// In en, this message translates to:
  /// **'Sell Bitcoin'**
  String get sellBitcoin;

  /// No description provided for @errorLoadingSellScreen.
  ///
  /// In en, this message translates to:
  /// **'Error loading sell screen'**
  String get errorLoadingSellScreen;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @amountToSell.
  ///
  /// In en, this message translates to:
  /// **'Amount to Sell'**
  String get amountToSell;

  /// No description provided for @sellLimits.
  ///
  /// In en, this message translates to:
  /// **'Sell Limits'**
  String get sellLimits;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @payoutMethods.
  ///
  /// In en, this message translates to:
  /// **'Payout Methods'**
  String get payoutMethods;

  /// No description provided for @pendingBlock.
  ///
  /// In en, this message translates to:
  /// **'Pending Block'**
  String get pendingBlock;

  /// No description provided for @nextBlock.
  ///
  /// In en, this message translates to:
  /// **'Next Block'**
  String get nextBlock;

  /// No description provided for @medianFee.
  ///
  /// In en, this message translates to:
  /// **'Median Fee'**
  String get medianFee;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @feeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Fee Distribution'**
  String get feeDistribution;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @loadingMoreTransactions.
  ///
  /// In en, this message translates to:
  /// **'Loading more transactions...'**
  String get loadingMoreTransactions;

  /// No description provided for @scrollDownToLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Scroll down to load more'**
  String get scrollDownToLoadMore;

  /// No description provided for @med.
  ///
  /// In en, this message translates to:
  /// **'Med'**
  String get med;

  /// No description provided for @feeRate.
  ///
  /// In en, this message translates to:
  /// **'Fee Rate'**
  String get feeRate;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @errorLoadingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Error loading transaction'**
  String get errorLoadingTransaction;

  /// No description provided for @blockHeight.
  ///
  /// In en, this message translates to:
  /// **'Block Height'**
  String get blockHeight;

  /// No description provided for @blockTime.
  ///
  /// In en, this message translates to:
  /// **'Block Time'**
  String get blockTime;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @locktime.
  ///
  /// In en, this message translates to:
  /// **'Locktime'**
  String get locktime;

  /// No description provided for @inputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get inputs;

  /// No description provided for @outputs.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get outputs;

  /// No description provided for @searchBlockchain.
  ///
  /// In en, this message translates to:
  /// **'Search Blockchain'**
  String get searchBlockchain;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @enterBlockHeightOrBlockHash.
  ///
  /// In en, this message translates to:
  /// **'Enter block height or block hash'**
  String get enterBlockHeightOrBlockHash;

  /// No description provided for @enterTransactionIdTxid.
  ///
  /// In en, this message translates to:
  /// **'Enter transaction ID (TXID)'**
  String get enterTransactionIdTxid;

  /// No description provided for @blockchain.
  ///
  /// In en, this message translates to:
  /// **'Blockchain'**
  String get blockchain;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @yourTx.
  ///
  /// In en, this message translates to:
  /// **'Your TX'**
  String get yourTx;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @paymentProvider.
  ///
  /// In en, this message translates to:
  /// **'Payment Provider'**
  String get paymentProvider;

  /// No description provided for @chooseProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose Provider'**
  String get chooseProvider;

  /// No description provided for @buyLimits.
  ///
  /// In en, this message translates to:
  /// **'Buy Limits'**
  String get buyLimits;

  /// No description provided for @errorLoadingBuyScreen.
  ///
  /// In en, this message translates to:
  /// **'Error loading buy screen'**
  String get errorLoadingBuyScreen;

  /// No description provided for @buyBitcoin.
  ///
  /// In en, this message translates to:
  /// **'Buy Bitcoin'**
  String get buyBitcoin;

  /// No description provided for @failedToLaunchMoonpay.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch MoonPay'**
  String get failedToLaunchMoonpay;

  /// No description provided for @bitcoinPriceChart.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Price Chart'**
  String get bitcoinPriceChart;

  /// No description provided for @aboutBitcoin.
  ///
  /// In en, this message translates to:
  /// **'About Bitcoin'**
  String get aboutBitcoin;

  /// No description provided for @bitcoinDescription.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.'**
  String get bitcoinDescription;

  /// No description provided for @aboutBitcoinPriceData.
  ///
  /// In en, this message translates to:
  /// **'About Bitcoin Price Data'**
  String get aboutBitcoinPriceData;

  /// No description provided for @thePriceDataShown.
  ///
  /// In en, this message translates to:
  /// **'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.'**
  String get thePriceDataShown;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Data Source'**
  String get dataSource;

  /// No description provided for @liveBitcoinMarketData.
  ///
  /// In en, this message translates to:
  /// **'Live Bitcoin Market Data'**
  String get liveBitcoinMarketData;

  /// No description provided for @updateFrequency.
  ///
  /// In en, this message translates to:
  /// **'Update Frequency'**
  String get updateFrequency;

  /// No description provided for @realTime.
  ///
  /// In en, this message translates to:
  /// **'Real-time'**
  String get realTime;

  /// No description provided for @sendBitcoin.
  ///
  /// In en, this message translates to:
  /// **'Send Bitcoin'**
  String get sendBitcoin;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'SEND NOW'**
  String get sendNow;

  /// No description provided for @notEnoughFunds.
  ///
  /// In en, this message translates to:
  /// **'Not enough funds'**
  String get notEnoughFunds;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @fromClipboard.
  ///
  /// In en, this message translates to:
  /// **'from clipboard'**
  String get fromClipboard;

  /// No description provided for @walletAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Wallet address copied'**
  String get walletAddressCopied;

  /// No description provided for @hashrate.
  ///
  /// In en, this message translates to:
  /// **'Hashrate'**
  String get hashrate;

  /// No description provided for @fearAndGreedIndex.
  ///
  /// In en, this message translates to:
  /// **'Fear & Greed Index'**
  String get fearAndGreedIndex;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @positionQrCodeInFrame.
  ///
  /// In en, this message translates to:
  /// **'Position QR code in frame'**
  String get positionQrCodeInFrame;

  /// No description provided for @noQrCodeFoundInImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in image'**
  String get noQrCodeFoundInImage;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @flashOn.
  ///
  /// In en, this message translates to:
  /// **'Flash On'**
  String get flashOn;

  /// No description provided for @flashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash Off'**
  String get flashOff;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @reportBugFeedback.
  ///
  /// In en, this message translates to:
  /// **'Report Bug / Feedback'**
  String get reportBugFeedback;

  /// No description provided for @recoveryOptions.
  ///
  /// In en, this message translates to:
  /// **'Recovery Options'**
  String get recoveryOptions;

  /// No description provided for @securityStatus.
  ///
  /// In en, this message translates to:
  /// **'Security Status'**
  String get securityStatus;

  /// No description provided for @setupRecoveryWarning.
  ///
  /// In en, this message translates to:
  /// **'For your security, please set up as many recovery options as possible.'**
  String get setupRecoveryWarning;

  /// No description provided for @recoveryFullySetup.
  ///
  /// In en, this message translates to:
  /// **'Your wallet recovery is fully configured!'**
  String get recoveryFullySetup;

  /// No description provided for @recoveryMethods.
  ///
  /// In en, this message translates to:
  /// **'Recovery Methods'**
  String get recoveryMethods;

  /// No description provided for @wordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Word Recovery'**
  String get wordRecovery;

  /// No description provided for @wordRecoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Your 12-word recovery phrase'**
  String get wordRecoveryDescription;

  /// No description provided for @emailRecovery.
  ///
  /// In en, this message translates to:
  /// **'Email Recovery'**
  String get emailRecovery;

  /// No description provided for @emailRecoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Recover wallet via email and password'**
  String get emailRecoveryDescription;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @notSetUp.
  ///
  /// In en, this message translates to:
  /// **'Not Set Up'**
  String get notSetUp;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @emailRecoveryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Email recovery will be available in a future update. For now, please make sure to backup your recovery phrase.'**
  String get emailRecoveryComingSoon;

  /// No description provided for @recoverWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Recover with Email'**
  String get recoverWithEmail;

  /// No description provided for @recoverWithEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use email and password to restore your wallet'**
  String get recoverWithEmailSubtitle;

  /// No description provided for @emailRecoverySetup.
  ///
  /// In en, this message translates to:
  /// **'Email Recovery Setup'**
  String get emailRecoverySetup;

  /// No description provided for @emailRecoveryWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password encrypts your recovery phrase locally. The server only stores the encrypted version and cannot access your funds. If you forget your password, your backup cannot be recovered.'**
  String get emailRecoveryWarningMessage;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get passwordTooWeak;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @setupRecovery.
  ///
  /// In en, this message translates to:
  /// **'Setup Recovery'**
  String get setupRecovery;

  /// No description provided for @emailRecoverySetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email recovery has been set up successfully! You can now recover your wallet using your email and password.'**
  String get emailRecoverySetupSuccess;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @codeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email'**
  String get codeSentToEmail;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @recoveryPassword.
  ///
  /// In en, this message translates to:
  /// **'Recovery Password'**
  String get recoveryPassword;

  /// No description provided for @enterYourRecoveryPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery password'**
  String get enterYourRecoveryPassword;

  /// No description provided for @recoverWallet.
  ///
  /// In en, this message translates to:
  /// **'Recover Wallet'**
  String get recoverWallet;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit verification code'**
  String get pleaseEnterCode;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Please try again.'**
  String get wrongPassword;

  /// No description provided for @emailRecoveryLoginInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter the email and password you used when setting up email recovery. Your wallet will be restored securely.'**
  String get emailRecoveryLoginInfo;

  /// No description provided for @authenticateToViewRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to view your recovery phrase'**
  String get authenticateToViewRecoveryPhrase;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authenticationFailed;

  /// No description provided for @confirmRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Confirm Recovery Phrase'**
  String get confirmRecoveryPhrase;

  /// No description provided for @recoveryComplete.
  ///
  /// In en, this message translates to:
  /// **'Recovery Complete'**
  String get recoveryComplete;

  /// No description provided for @writeDownYourRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Write down your recovery phrase'**
  String get writeDownYourRecoveryPhrase;

  /// No description provided for @youWillNeedToConfirmIt.
  ///
  /// In en, this message translates to:
  /// **'You will need to confirm it in the next step'**
  String get youWillNeedToConfirmIt;

  /// No description provided for @continueToVerify.
  ///
  /// In en, this message translates to:
  /// **'Continue to Verify'**
  String get continueToVerify;

  /// No description provided for @verifyYourRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Verify your recovery phrase'**
  String get verifyYourRecoveryPhrase;

  /// No description provided for @enterTheFollowingWords.
  ///
  /// In en, this message translates to:
  /// **'Enter the following words from your phrase'**
  String get enterTheFollowingWords;

  /// No description provided for @enterWord.
  ///
  /// In en, this message translates to:
  /// **'Enter word'**
  String get enterWord;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @incorrectWordsPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Incorrect words. Please try again.'**
  String get incorrectWordsPleaseTryAgain;

  /// No description provided for @skipVerification.
  ///
  /// In en, this message translates to:
  /// **'Skip Verification?'**
  String get skipVerification;

  /// No description provided for @skipVerificationWarning.
  ///
  /// In en, this message translates to:
  /// **'Skipping verification means you haven\'t confirmed that you wrote down your recovery phrase correctly. If you lose access to your wallet, you may not be able to recover it.'**
  String get skipVerificationWarning;

  /// No description provided for @skipAtOwnRisk.
  ///
  /// In en, this message translates to:
  /// **'Skip at own risk'**
  String get skipAtOwnRisk;

  /// No description provided for @recoveryPhraseConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase Confirmed!'**
  String get recoveryPhraseConfirmed;

  /// No description provided for @yourRecoveryPhraseIsSecured.
  ///
  /// In en, this message translates to:
  /// **'Your recovery phrase has been verified and secured. Keep it safe!'**
  String get yourRecoveryPhraseIsSecured;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email'**
  String get enterYourEmail;

  /// No description provided for @emailSignupDescription.
  ///
  /// In en, this message translates to:
  /// **'Your email is used to create your Lendasat account for loans and other services.'**
  String get emailSignupDescription;

  /// No description provided for @emailUsageInfo.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this email for account verification and important updates. Your wallet remains secured by your recovery phrase.'**
  String get emailUsageInfo;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get createWallet;

  /// No description provided for @restoreWallet.
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet'**
  String get restoreWallet;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @registrationWarning.
  ///
  /// In en, this message translates to:
  /// **'Account registration had an issue. You can still use your wallet.'**
  String get registrationWarning;

  /// Legal information menu item in settings
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// No description provided for @termsAndConditionsTitle1.
  ///
  /// In en, this message translates to:
  /// **'Terms and'**
  String get termsAndConditionsTitle1;

  /// No description provided for @termsAndConditionsTitle2.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get termsAndConditionsTitle2;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: December 2025'**
  String get lastUpdated;

  /// No description provided for @alphaVersion.
  ///
  /// In en, this message translates to:
  /// **'Alpha Version'**
  String get alphaVersion;

  /// No description provided for @alphaVersionWarning.
  ///
  /// In en, this message translates to:
  /// **'This app is under development. Use at your own risk.'**
  String get alphaVersionWarning;

  /// No description provided for @agbScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scope of Application'**
  String get agbScopeTitle;

  /// No description provided for @agbScopeContent.
  ///
  /// In en, this message translates to:
  /// **'These terms and conditions govern the use of the Bitcoin wallet app (hereinafter Lenda), provided by COBLOX PTY LTD. By using the app, you agree to these terms and conditions.'**
  String get agbScopeContent;

  /// No description provided for @agbFunctionalityTitle.
  ///
  /// In en, this message translates to:
  /// **'Functionality'**
  String get agbFunctionalityTitle;

  /// No description provided for @agbFunctionalityContent.
  ///
  /// In en, this message translates to:
  /// **'The app allows users to receive, send, and manage Bitcoin. The app is not a bank and does not provide banking services.'**
  String get agbFunctionalityContent;

  /// No description provided for @agbUserResponsibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'User Responsibility'**
  String get agbUserResponsibilityTitle;

  /// No description provided for @agbUserResponsibilityContent.
  ///
  /// In en, this message translates to:
  /// **'The user is fully self-responsible for using the application and the security of their Bitcoin. The user acknowledges that loss of their recovery phrase (mnemonic) is equivalent to loss of their funds. COBLOX PTY LTD is not liable for any losses resulting from carelessness, loss of devices, or loss of the recovery phrase.'**
  String get agbUserResponsibilityContent;

  /// No description provided for @agbFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get agbFeesTitle;

  /// No description provided for @agbFeesContent.
  ///
  /// In en, this message translates to:
  /// **'Certain functions of the app may incur fees. These fees will be communicated to the user in advance and are visible in the app.'**
  String get agbFeesContent;

  /// No description provided for @agbBuyingSelling.
  ///
  /// In en, this message translates to:
  /// **'Buying and Selling Bitcoin'**
  String get agbBuyingSelling;

  /// No description provided for @agbBuyingSellingContent.
  ///
  /// In en, this message translates to:
  /// **'Buying and selling Bitcoin is facilitated through third-party providers. COBLOX PTY LTD is not involved in these transactions and bears no responsibility for them. Any issues, disputes, or inquiries related to buying or selling Bitcoin must be directed to and resolved with the respective third-party provider.'**
  String get agbBuyingSellingContent;

  /// No description provided for @agbLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Limitation of Liability'**
  String get agbLiabilityTitle;

  /// No description provided for @agbLiabilityContent.
  ///
  /// In en, this message translates to:
  /// **'COBLOX PTY LTD is only liable for damages caused by intentional or grossly negligent actions by COBLOX PTY LTD. COBLOX PTY LTD is not liable for damages resulting from the use of the app or the loss of Bitcoin.'**
  String get agbLiabilityContent;

  /// No description provided for @agbChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get agbChangesTitle;

  /// No description provided for @agbChangesContent.
  ///
  /// In en, this message translates to:
  /// **'COBLOX PTY LTD reserves the right to change these terms and conditions at any time. Continued use of the app constitutes acceptance of any updated terms.'**
  String get agbChangesContent;

  /// No description provided for @agbFinalProvisionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Provisions'**
  String get agbFinalProvisionsTitle;

  /// No description provided for @agbFinalProvisionsContent.
  ///
  /// In en, this message translates to:
  /// **'These terms and conditions represent the entire agreement between the user and COBLOX PTY LTD. Should any provision be invalid, the remaining provisions shall remain in effect.'**
  String get agbFinalProvisionsContent;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @responsibleForContent.
  ///
  /// In en, this message translates to:
  /// **'Responsible for Content'**
  String get responsibleForContent;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @disclaimerContent.
  ///
  /// In en, this message translates to:
  /// **'The provider assumes no liability for the accuracy, correctness, completeness, or quality of the information provided. Liability claims against the provider are generally excluded unless there is proven intentional or grossly negligent fault.'**
  String get disclaimerContent;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get allRightsReserved;

  /// No description provided for @loansAndLeverage.
  ///
  /// In en, this message translates to:
  /// **'Loans Marketplace'**
  String get loansAndLeverage;

  /// No description provided for @availableOffers.
  ///
  /// In en, this message translates to:
  /// **'Available Offers'**
  String get availableOffers;

  /// No description provided for @myContracts.
  ///
  /// In en, this message translates to:
  /// **'My Contracts'**
  String get myContracts;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get signInRequired;

  /// No description provided for @signInToViewContracts.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your contracts and take loans. You can still browse available offers.'**
  String get signInToViewContracts;

  /// No description provided for @noArkadeOffersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Arkade offers available'**
  String get noArkadeOffersAvailable;

  /// No description provided for @signInToViewYourContracts.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your contracts'**
  String get signInToViewYourContracts;

  /// No description provided for @noContractsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No contracts match your search'**
  String get noContractsMatchSearch;

  /// No description provided for @noContractsYet.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet. Take an offer to get started!'**
  String get noContractsYet;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @minLtv.
  ///
  /// In en, this message translates to:
  /// **'Min LTV'**
  String get minLtv;

  /// No description provided for @limitedTimeOffer.
  ///
  /// In en, this message translates to:
  /// **'Limited time offer — super cheap!'**
  String get limitedTimeOffer;

  /// No description provided for @interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interest;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @swapDetails.
  ///
  /// In en, this message translates to:
  /// **'Swap Details'**
  String get swapDetails;

  /// No description provided for @errorLoadingSwap.
  ///
  /// In en, this message translates to:
  /// **'Error loading swap'**
  String get errorLoadingSwap;

  /// No description provided for @refundAddress.
  ///
  /// In en, this message translates to:
  /// **'Refund Address'**
  String get refundAddress;

  /// No description provided for @fundSwap.
  ///
  /// In en, this message translates to:
  /// **'Fund Swap'**
  String get fundSwap;

  /// No description provided for @youSend.
  ///
  /// In en, this message translates to:
  /// **'You send'**
  String get youSend;

  /// No description provided for @youReceive.
  ///
  /// In en, this message translates to:
  /// **'You receive'**
  String get youReceive;

  /// No description provided for @walletConnected.
  ///
  /// In en, this message translates to:
  /// **'Wallet Connected'**
  String get walletConnected;

  /// No description provided for @switchWallet.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchWallet;

  /// No description provided for @creatingSwap.
  ///
  /// In en, this message translates to:
  /// **'Creating Swap...'**
  String get creatingSwap;

  /// No description provided for @approvingToken.
  ///
  /// In en, this message translates to:
  /// **'Approving token...'**
  String get approvingToken;

  /// No description provided for @creatingHtlc.
  ///
  /// In en, this message translates to:
  /// **'Creating HTLC...'**
  String get creatingHtlc;

  /// No description provided for @swapFundedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Swap funded successfully!'**
  String get swapFundedSuccessfully;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @youPay.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get youPay;

  /// No description provided for @totalFeesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total fees'**
  String get totalFeesLabel;

  /// No description provided for @beforeFees.
  ///
  /// In en, this message translates to:
  /// **'before fees'**
  String get beforeFees;

  /// No description provided for @networkFee.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkFee;

  /// No description provided for @protocolFee.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocolFee;

  /// No description provided for @receivingAddress.
  ///
  /// In en, this message translates to:
  /// **'Receiving address'**
  String get receivingAddress;

  /// No description provided for @waitingForDeposit.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Deposit'**
  String get waitingForDeposit;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get refundable;

  /// No description provided for @refundedStatus.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refundedStatus;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @confirmSwap.
  ///
  /// In en, this message translates to:
  /// **'Confirm Swap'**
  String get confirmSwap;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @aboutLendasat.
  ///
  /// In en, this message translates to:
  /// **'About LendaSat'**
  String get aboutLendasat;

  /// No description provided for @lendasatInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'LendaSat is a Bitcoin peer-to-peer loan marketplace. We act as a platform that connects you with private lenders who provide the funds. Your Bitcoin is used as collateral, and you receive the loan amount directly. All transactions are secured through smart contracts on the Bitcoin network.'**
  String get lendasatInfoDescription;

  /// No description provided for @learnMoreAboutLendasat.
  ///
  /// In en, this message translates to:
  /// **'Learn more about how LendaSat works'**
  String get learnMoreAboutLendasat;

  /// No description provided for @sendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingStatus;

  /// No description provided for @sentStatus.
  ///
  /// In en, this message translates to:
  /// **'Sent!'**
  String get sentStatus;

  /// No description provided for @failedStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedStatus;

  /// No description provided for @chooseRecipient.
  ///
  /// In en, this message translates to:
  /// **'Choose Recipient'**
  String get chooseRecipient;

  /// No description provided for @searchRecipient.
  ///
  /// In en, this message translates to:
  /// **'Search or paste address...'**
  String get searchRecipient;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @pasteOrScanAddress.
  ///
  /// In en, this message translates to:
  /// **'Paste or scan a Bitcoin address'**
  String get pasteOrScanAddress;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supports Bitcoin, Lightning, Ark, and LNURL addresses'**
  String get supportedFormats;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minuteAgo.
  ///
  /// In en, this message translates to:
  /// **'minute ago'**
  String get minuteAgo;

  /// No description provided for @hourAgo.
  ///
  /// In en, this message translates to:
  /// **'hour ago'**
  String get hourAgo;

  /// No description provided for @dayAgo.
  ///
  /// In en, this message translates to:
  /// **'day ago'**
  String get dayAgo;

  /// No description provided for @monthAgo.
  ///
  /// In en, this message translates to:
  /// **'month ago'**
  String get monthAgo;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'months ago'**
  String get monthsAgo;

  /// No description provided for @yearAgo.
  ///
  /// In en, this message translates to:
  /// **'year ago'**
  String get yearAgo;

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'years ago'**
  String get yearsAgo;

  /// No description provided for @selectNetwork.
  ///
  /// In en, this message translates to:
  /// **'Select Network'**
  String get selectNetwork;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'id',
        'it',
        'ja',
        'ur',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
