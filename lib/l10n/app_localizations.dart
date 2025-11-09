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
  /// **'RETRY'**
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
  /// **'SEND'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'RECEIVE'**
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

  /// App tagline with first letter of each word bolded
  ///
  /// In en, this message translates to:
  /// **'Wallet That Flies on Ark'**
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
  /// **' address copied to clipboard'**
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
  /// **'SHARE'**
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
  /// **'Bitcoin or Ark address'**
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
  /// **'Pending confirmation'**
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

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

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
  /// **'Boarding Transaction'**
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
