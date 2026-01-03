// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'Pengaturan';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Simpan';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Selesai';

  @override
  String get select => 'Pilih';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'Masukkan Jumlah';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'LEWATI (JUMLAH APA SAJA)';

  @override
  String get contin => 'LANJUTKAN';

  @override
  String get currencyUpdatedSuccessfully => 'Mata uang berhasil diperbarui';

  @override
  String get changeCurrency => 'Ubah Mata Uang';

  @override
  String get languageUpdatedSuccessfully => 'Bahasa berhasil diperbarui';

  @override
  String get changeLanguage => 'Ubah Bahasa';

  @override
  String get themeAppliedSuccessfully => 'Tema berhasil diterapkan';

  @override
  String get chooseYourColor => 'Pilih Warna Anda';

  @override
  String get selectColor => 'Pilih warna';

  @override
  String get selectColorShade => 'Pilih gradasi warna';

  @override
  String get changeYourStyle => 'Ubah Gaya Anda';

  @override
  String get chooseYourPreferredTheme => 'Pilih tema yang Anda sukai';

  @override
  String get dark => 'Gelap';

  @override
  String get originalDarkTheme => 'Tema gelap asli';

  @override
  String get light => 'Terang';

  @override
  String get cleanLightTheme => 'Tema terang bersih';

  @override
  String get applyTheme => 'Terapkan Tema';

  @override
  String get custom => 'Kustom';

  @override
  String get createYourOwnTheme => 'Buat tema Anda sendiri';

  @override
  String get timezoneUpdatedSuccessfully => 'Zona waktu berhasil diperbarui';

  @override
  String get changeTimezone => 'Ubah Zona Waktu';

  @override
  String get searchTimezone => 'Cari zona waktu...';

  @override
  String get couldntUpdateTransactions => 'Tidak dapat memperbarui transaksi:';

  @override
  String get couldntUpdateBalance => 'Tidak dapat memperbarui saldo:';

  @override
  String showingBalanceType(String balanceType) {
    return 'Menampilkan saldo $balanceType';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'Saldo Tertunda';

  @override
  String get confirmedBalance => 'Saldo Terkonfirmasi';

  @override
  String get totalBalance => 'Total Saldo';

  @override
  String get errorLoadingBalance => 'Kesalahan saat memuat saldo';

  @override
  String get send => 'Kirim';

  @override
  String get receive => 'Terima';

  @override
  String get failedToCreateWallet => 'Gagal membuat dompet';

  @override
  String errorCreatingWallet(String error) {
    return 'Terjadi kesalahan saat membuat dompet baru Anda. Silakan coba lagi.\n\nKesalahan: $error';
  }

  @override
  String get failedToRestoreWallet => 'Gagal memulihkan dompet';

  @override
  String errorRestoringWallet(String error) {
    return 'Terjadi kesalahan saat memulihkan dompet Anda. Silakan periksa nsec Anda dan coba lagi.\n\nKesalahan: $error';
  }

  @override
  String get appTagline => 'Dompet yang Terbang di Ark';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'Pilih opsi:';

  @override
  String get createNewWallet => 'Buat Dompet Baru';

  @override
  String get generateANewSecureWallet => 'Buat dompet baru yang aman';

  @override
  String get restoreExistingWallet => 'Pulihkan Dompet yang Ada';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'Gunakan kunci rahasia Anda untuk mengakses dompet Anda';

  @override
  String get enterYourNsec => 'Masukkan nsec Anda:';

  @override
  String get pasteYourRecoveryNsec => 'Tempel nsec pemulihan Anda...';

  @override
  String paymentMonitoringError(String error) {
    return 'Kesalahan pemantauan pembayaran: $error';
  }

  @override
  String get paymentReceived => 'Pembayaran Diterima!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => 'Bagikan alamat yang mana?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'Faktur Lightning';

  @override
  String get qrCodeImage => 'Gambar Kode QR';

  @override
  String get errorSharing => 'Kesalahan saat berbagi';

  @override
  String get myBitcoinAddressQrCode => 'Kode QR Alamat Bitcoin Saya';

  @override
  String get requesting => 'Meminta: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'Salin alamat';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'Silakan masukkan alamat dan jumlah';

  @override
  String get pleaseEnterAValidAmount => 'Silakan masukkan jumlah yang valid';

  @override
  String get insufficientFunds => 'Dana tidak mencukupi';

  @override
  String get sendLower => 'Kirim';

  @override
  String get receiveLower => 'Terima';

  @override
  String get recipientAddress => 'Alamat penerima';

  @override
  String get bitcoinOrArkAddress => 'Alamat Bitcoin atau Ark';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Esplora disimpan - akan berlaku setelah restart';

  @override
  String get failedToSaveEsploraUrl => 'Gagal menyimpan URL Esplora';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'Jaringan disimpan - akan berlaku setelah restart';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Server Ark disimpan - akan berlaku setelah restart';

  @override
  String get failedToSaveArkServerUrl => 'Gagal menyimpan URL Server Ark';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL Boltz disimpan - akan berlaku setelah restart';

  @override
  String get failedToSaveBoltzUrl => 'Gagal menyimpan URL Boltz';

  @override
  String get securityWarning => 'Peringatan Keamanan';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      'Jangan pernah membagikan kunci pemulihan Anda kepada siapa pun!';

  @override
  String get anyoneWithThisKeyCan =>
      'Siapa pun yang memiliki kunci ini dapat mengakses dompet Anda dan mencuri dana Anda. Simpan di tempat yang aman.';

  @override
  String get iUnderstand => 'SAYA MENGERTI';

  @override
  String get yourRecoveryPhrase => 'Frasa Pemulihan Anda';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'Frasa pemulihan disalin ke clipboard';

  @override
  String get copyToClipboard => 'SALIN KE CLIPBOARD';

  @override
  String get close => 'TUTUP';

  @override
  String get resetWallet => 'Atur Ulang Dompet';

  @override
  String get thisWillDeleteAllWalletData =>
      'Ini akan menghapus semua data dompet dari perangkat ini. Pastikan Anda telah mencadangkan frasa pemulihan Anda sebelum melanjutkan. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get restartingApp => 'Memulai ulang aplikasi';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'Ketuk di sini untuk membuka aplikasi lagi.';

  @override
  String get reset => 'ATUR ULANG';

  @override
  String get wallet => 'Dompet';

  @override
  String get viewRecoveryKey => 'Lihat Kunci Pemulihan';

  @override
  String get backupYourWalletWithTheseKey =>
      'Cadangkan dompet Anda dengan kunci ini';

  @override
  String get appearancePreferences => 'Tampilan & Preferensi';

  @override
  String get theme => 'Tema';

  @override
  String get customizeAppAppearance => 'Sesuaikan tampilan aplikasi';

  @override
  String get language => 'Bahasa';

  @override
  String get selectYourPreferredLanguage => 'Pilih bahasa yang Anda sukai';

  @override
  String get timezone => 'Zona Waktu';

  @override
  String get chooseYourPreferredTimezone => 'Pilih zona waktu yang Anda sukai';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'Pilih mata uang yang Anda sukai';

  @override
  String get serverConfiguration => 'Konfigurasi Server';

  @override
  String get network => 'Jaringan';

  @override
  String get esploraUrl => 'URL Esplora';

  @override
  String get arkServer => 'Server Ark';

  @override
  String get boltzUrl => 'URL Boltz';

  @override
  String get about => 'Tentang';

  @override
  String get loading => 'memuat';

  @override
  String get dangerZone => 'Zona Bahaya';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'Hapus semua data dompet dari perangkat ini';

  @override
  String get transactionFailed => 'Transaksi gagal:';

  @override
  String get signTransaction => 'Tandatangani transaksi';

  @override
  String get networkFees => 'Biaya jaringan';

  @override
  String get total => 'Total';

  @override
  String get tapToSign => 'KETUK UNTUK TANDA TANGAN';

  @override
  String get settlingTransaction => 'Menyelesaikan transaksi...';

  @override
  String get success => 'Berhasil';

  @override
  String get transactionSettledSuccessfully =>
      'Transaksi berhasil diselesaikan!';

  @override
  String get goToHome => 'Kembali ke Beranda';

  @override
  String get error => 'Kesalahan';

  @override
  String get failedToSettleTransaction => 'Gagal menyelesaikan transaksi:';

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
  String get date => 'Tanggal';

  @override
  String get time => 'Waktu';

  @override
  String get transactionVolume => 'Volume Transaksi';

  @override
  String get confirmedAt => 'Dikonfirmasi Pada';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'Transaksi tertunda. Dana tidak dapat dibatalkan setelah penyelesaian.';

  @override
  String get settle => 'SELESAIKAN';

  @override
  String get transactionHistory => 'Riwayat Transaksi';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'Belum ada riwayat transaksi';

  @override
  String get boardingTransaction => 'Transaksi Onchain';

  @override
  String get roundTransaction => 'Transaksi Pembulatan';

  @override
  String get redeemTransaction => 'Transaksi Penebusan';

  @override
  String get sent => 'Dikirim';

  @override
  String get received => 'Diterima';

  @override
  String get direction => 'Arah';

  @override
  String get settled => 'Selesai';

  @override
  String get sentSuccessfully => 'berhasil dikirim';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Kembali ke dompet setelah transaksi berhasil';

  @override
  String get backToWallet => 'KEMBALI KE DOMPET';

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
  String get reportBugFeedback => 'Laporkan Bug / Umpan Balik';

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
  String get loansAndLeverage => 'Pasar Pinjaman';

  @override
  String get availableOffers => 'Penawaran Tersedia';

  @override
  String get myContracts => 'Kontrak Saya';

  @override
  String get signInRequired => 'Diperlukan Masuk';

  @override
  String get signInToViewContracts =>
      'Masuk untuk melihat kontrak dan mengambil pinjaman.';

  @override
  String get noArkadeOffersAvailable => 'Tidak ada penawaran Arkade tersedia';

  @override
  String get signInToViewYourContracts => 'Masuk untuk melihat kontrak Anda';

  @override
  String get noContractsMatchSearch =>
      'Tidak ada kontrak yang cocok dengan pencarian Anda';

  @override
  String get noContractsYet =>
      'Belum ada kontrak. Terima penawaran untuk memulai!';

  @override
  String get duration => 'Durasi';

  @override
  String get minLtv => 'LTV Min';

  @override
  String get limitedTimeOffer => 'Penawaran terbatas — super murah!';

  @override
  String get interest => 'Bunga';

  @override
  String get due => 'Jatuh Tempo';

  @override
  String get overdue => 'Terlambat';

  @override
  String get swapDetails => 'Detail Swap';

  @override
  String get errorLoadingSwap => 'Error memuat swap';

  @override
  String get refundAddress => 'Alamat Pengembalian';

  @override
  String get fundSwap => 'Danai Swap';

  @override
  String get youSend => 'Anda kirim';

  @override
  String get youReceive => 'Anda terima';

  @override
  String get walletConnected => 'Dompet Terhubung';

  @override
  String get switchWallet => 'Ganti';

  @override
  String get creatingSwap => 'Membuat Swap...';

  @override
  String get approvingToken => 'Menyetujui token...';

  @override
  String get creatingHtlc => 'Membuat HTLC...';

  @override
  String get swapFundedSuccessfully => 'Swap berhasil didanai!';

  @override
  String get feedback => 'Umpan Balik';

  @override
  String get continueButton => 'Lanjutkan';

  @override
  String get paste => 'Tempel';

  @override
  String get scanQr => 'Pindai QR';

  @override
  String get youPay => 'Anda bayar';

  @override
  String get totalFeesLabel => 'Total biaya';

  @override
  String get beforeFees => 'sebelum biaya';

  @override
  String get networkFee => 'Jaringan';

  @override
  String get protocolFee => 'Protokol';

  @override
  String get receivingAddress => 'Alamat penerima';

  @override
  String get waitingForDeposit => 'Menunggu Deposit';

  @override
  String get processing => 'Memproses';

  @override
  String get completed => 'Selesai';

  @override
  String get expired => 'Kadaluarsa';

  @override
  String get refundable => 'Dapat dikembalikan';

  @override
  String get refundedStatus => 'Dikembalikan';

  @override
  String get failed => 'Gagal';

  @override
  String get confirmSwap => 'Konfirmasi Swap';

  @override
  String get unknownError => 'Error tidak diketahui';

  @override
  String get sendFeedback => 'Kirim Umpan Balik';

  @override
  String get sender => 'Pengirim';

  @override
  String get receiver => 'Penerima';

  @override
  String get scan => 'Pindai';

  @override
  String get aboutLendasat => 'About LendaSat';

  @override
  String get lendasatInfoDescription =>
      'LendaSat is a Bitcoin peer-to-peer loan marketplace. We act as a platform that connects you with private lenders who provide the funds. Your Bitcoin is used as collateral, and you receive the loan amount directly. All transactions are secured through smart contracts on the Bitcoin network.';

  @override
  String get learnMoreAboutLendasat => 'Learn more about how LendaSat works';
}
