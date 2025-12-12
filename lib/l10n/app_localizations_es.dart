// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Ark Flutter';

  @override
  String get settings => 'Configuración';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Guardar';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Listo';

  @override
  String get select => 'Seleccionar';

  @override
  String get search => 'Search';

  @override
  String get enterAmount => 'Ingresar monto';

  @override
  String get amount => 'Amount';

  @override
  String get skipAnyAmount => 'OMITIR (CUALQUIER MONTO)';

  @override
  String get contin => 'CONTINUAR';

  @override
  String get currencyUpdatedSuccessfully => 'Moneda actualizada con éxito';

  @override
  String get changeCurrency => 'Cambiar moneda';

  @override
  String get languageUpdatedSuccessfully => 'Idioma actualizado con éxito';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get themeAppliedSuccessfully => 'Tema aplicado con éxito';

  @override
  String get chooseYourColor => 'Elige tu color';

  @override
  String get selectColor => 'Seleccionar color';

  @override
  String get selectColorShade => 'Seleccionar tono de color';

  @override
  String get changeYourStyle => 'Cambia tu estilo';

  @override
  String get chooseYourPreferredTheme => 'Elige tu tema preferido';

  @override
  String get dark => 'Oscuro';

  @override
  String get originalDarkTheme => 'Tema oscuro original';

  @override
  String get light => 'Claro';

  @override
  String get cleanLightTheme => 'Tema claro limpio';

  @override
  String get applyTheme => 'Aplicar tema';

  @override
  String get custom => 'Personalizado';

  @override
  String get createYourOwnTheme => 'Crea tu propio tema';

  @override
  String get timezoneUpdatedSuccessfully =>
      'Zona horaria actualizada con éxito';

  @override
  String get changeTimezone => 'Cambiar zona horaria';

  @override
  String get searchTimezone => 'Buscar zona horaria...';

  @override
  String get couldntUpdateTransactions =>
      'No se pudieron actualizar las transacciones:';

  @override
  String get couldntUpdateBalance => 'No se pudo actualizar el saldo:';

  @override
  String showingBalanceType(String balanceType) {
    return 'Mostrando saldo $balanceType';
  }

  @override
  String get retry => 'Retry';

  @override
  String get pendingBalance => 'Saldo pendiente';

  @override
  String get confirmedBalance => 'Saldo confirmado';

  @override
  String get totalBalance => 'Saldo total';

  @override
  String get errorLoadingBalance => 'Error al cargar el saldo';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Recibir';

  @override
  String get failedToCreateWallet => 'Error al crear la billetera';

  @override
  String errorCreatingWallet(String error) {
    return 'Hubo un error al crear tu nueva billetera. Por favor, inténtalo de nuevo.\n\nError: $error';
  }

  @override
  String get failedToRestoreWallet => 'Error al restaurar la billetera';

  @override
  String errorRestoringWallet(String error) {
    return 'Hubo un error al restaurar tu billetera. Verifica tu nsec e inténtalo de nuevo.\n\nError: $error';
  }

  @override
  String get appTagline => 'La billetera que vuela en Ark';

  @override
  String get ok => 'OK';

  @override
  String get chooseAnOption => 'Elige una opción:';

  @override
  String get createNewWallet => 'Crear nueva billetera';

  @override
  String get generateANewSecureWallet => 'Generar una nueva billetera segura';

  @override
  String get restoreExistingWallet => 'Restaurar billetera existente';

  @override
  String get useYourSecretKeyToAccessYourWallet =>
      'Usa tu clave secreta para acceder a tu billetera';

  @override
  String get enterYourNsec => 'Introduce tu nsec:';

  @override
  String get pasteYourRecoveryNsec => 'Pega tu nsec de recuperación...';

  @override
  String paymentMonitoringError(String error) {
    return 'Error al monitorear el pago: $error';
  }

  @override
  String get paymentReceived => '¡Pago recibido!';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get shareWhichAddress => '¿Qué dirección deseas compartir?';

  @override
  String get address => 'Address';

  @override
  String get lightningInvoice => 'Factura Lightning';

  @override
  String get qrCodeImage => 'Imagen del código QR';

  @override
  String get errorSharing => 'Error al compartir';

  @override
  String get myBitcoinAddressQrCode => 'Código QR de mi dirección Bitcoin';

  @override
  String get requesting => 'Solicitando: ';

  @override
  String get monitoringForIncomingPayment =>
      'Monitoring for incoming payment...';

  @override
  String get copyAddress => 'Copiar dirección';

  @override
  String get errorLoadingAddresses => 'Error loading addresses';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterBothAddressAndAmount =>
      'Por favor, ingresa tanto la dirección como el monto';

  @override
  String get pleaseEnterAValidAmount => 'Por favor, ingresa un monto válido';

  @override
  String get insufficientFunds => 'Fondos insuficientes';

  @override
  String get sendLower => 'Enviar';

  @override
  String get receiveLower => 'Recibir';

  @override
  String get recipientAddress => 'Dirección del destinatario';

  @override
  String get bitcoinOrArkAddress => 'Dirección de Bitcoin o Ark';

  @override
  String get available => 'available';

  @override
  String get esploraUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL de Esplora guardada – surtirá efecto después de reiniciar';

  @override
  String get failedToSaveEsploraUrl => 'Error al guardar la URL de Esplora';

  @override
  String get networkSavedWillOnlyTakeEffectAfterARestart =>
      'Red guardada – surtirá efecto después de reiniciar';

  @override
  String get arkServerUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL del servidor Ark guardada – surtirá efecto después de reiniciar';

  @override
  String get failedToSaveArkServerUrl =>
      'Error al guardar la URL del servidor Ark';

  @override
  String get boltzUrlSavedWillOnlyTakeEffectAfterARestart =>
      'URL de Boltz guardada – surtirá efecto después de reiniciar';

  @override
  String get failedToSaveBoltzUrl => 'Error al guardar la URL de Boltz';

  @override
  String get securityWarning => 'Advertencia de seguridad';

  @override
  String get neverShareYourRecoveryKeyWithAnyone =>
      '¡Nunca compartas tu clave de recuperación con nadie!';

  @override
  String get anyoneWithThisKeyCan =>
      'Cualquiera con esta clave puede acceder a tu billetera y robar tus fondos. Guárdala en un lugar seguro.';

  @override
  String get iUnderstand => 'ENTIENDO';

  @override
  String get yourRecoveryPhrase => 'Tu frase de recuperación';

  @override
  String get recoveryPhraseCopiedToClipboard =>
      'Frase de recuperación copiada al portapapeles';

  @override
  String get copyToClipboard => 'COPIAR AL PORTAPAPELES';

  @override
  String get close => 'CERRAR';

  @override
  String get resetWallet => 'Restablecer billetera';

  @override
  String get thisWillDeleteAllWalletData =>
      'Esto eliminará todos los datos de la billetera de este dispositivo. Asegúrate de haber hecho una copia de seguridad de tu frase de recuperación antes de continuar. Esta acción no se puede deshacer.';

  @override
  String get restartingApp => 'Reiniciando aplicación';

  @override
  String get pleaseTapHereToOpenTheAppAgain =>
      'Toca aquí para abrir la aplicación nuevamente.';

  @override
  String get reset => 'RESTABLECER';

  @override
  String get wallet => 'Billetera';

  @override
  String get viewRecoveryKey => 'Ver clave de recuperación';

  @override
  String get backupYourWalletWithTheseKey =>
      'Haz una copia de seguridad de tu billetera con esta clave';

  @override
  String get appearancePreferences => 'Apariencia y preferencias';

  @override
  String get theme => 'Tema';

  @override
  String get customizeAppAppearance =>
      'Personaliza la apariencia de la aplicación';

  @override
  String get language => 'Idioma';

  @override
  String get selectYourPreferredLanguage => 'Selecciona tu idioma preferido';

  @override
  String get timezone => 'Zona horaria';

  @override
  String get chooseYourPreferredTimezone => 'Elige tu zona horaria preferida';

  @override
  String get currency => 'Currency';

  @override
  String get chooseYourPreferredCurrency => 'Elige tu moneda preferida';

  @override
  String get serverConfiguration => 'Configuración del servidor';

  @override
  String get network => 'Red';

  @override
  String get esploraUrl => 'URL de Esplora';

  @override
  String get arkServer => 'Servidor Ark';

  @override
  String get boltzUrl => 'URL de Boltz';

  @override
  String get about => 'Acerca de';

  @override
  String get loading => 'cargando';

  @override
  String get dangerZone => 'Zona de peligro';

  @override
  String get deleteAllWalletDataFromThisDevice =>
      'Eliminar todos los datos de la billetera de este dispositivo';

  @override
  String get transactionFailed => 'Transacción fallida:';

  @override
  String get signTransaction => 'Firmar transacción';

  @override
  String get networkFees => 'Comisiones de red';

  @override
  String get total => 'Total';

  @override
  String get tapToSign => 'TOCA PARA FIRMAR';

  @override
  String get settlingTransaction => 'Liquidando transacción...';

  @override
  String get success => 'Éxito';

  @override
  String get transactionSettledSuccessfully =>
      '¡Transacción liquidada con éxito!';

  @override
  String get goToHome => 'Ir al inicio';

  @override
  String get error => 'Error';

  @override
  String get failedToSettleTransaction => 'Error al liquidar la transacción:';

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
  String get date => 'Fecha';

  @override
  String get confirmedAt => 'Confirmado en';

  @override
  String get transactionPendingFundsWillBeNonReversibleAfterSettlement =>
      'Transacción pendiente. Los fondos no serán reversibles después de la liquidación.';

  @override
  String get settle => 'LIQUIDAR';

  @override
  String get transactionHistory => 'Historial de transacciones';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionHistoryYet => 'Aún no hay historial de transacciones';

  @override
  String get boardingTransaction => 'Transacción Onchain';

  @override
  String get roundTransaction => 'Transacción de redondeo';

  @override
  String get redeemTransaction => 'Transacción de canje';

  @override
  String get sent => 'Enviado';

  @override
  String get received => 'Recibido';

  @override
  String get settled => 'Liquidado';

  @override
  String get sentSuccessfully => 'enviado con éxito';

  @override
  String get returningToWalletAfterSuccessfulTransaction =>
      'Volviendo a la billetera después de una transacción exitosa';

  @override
  String get backToWallet => 'VOLVER A LA BILLETERA';

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
