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
}
