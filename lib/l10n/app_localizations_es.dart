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
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get note => 'Note';

  @override
  String get addNote => 'Add a note';

  @override
  String get apply => 'Aplicar';

  @override
  String get done => 'Listo';

  @override
  String get select => 'Seleccionar';

  @override
  String get search => 'Buscar';

  @override
  String get enterAmount => 'Ingresar monto';

  @override
  String get amountTooLow => 'Amount Too Low';

  @override
  String get amountTooHigh => 'Amount Too High';

  @override
  String get amount => 'Monto';

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
  String get retry => 'Reintentar';

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
  String get addressCopiedToClipboard => 'Dirección copiada al portapapeles';

  @override
  String get shareWhichAddress => '¿Qué dirección deseas compartir?';

  @override
  String get address => 'Dirección';

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
  String get monitoringForIncomingPayment => 'Monitoreando pagos entrantes...';

  @override
  String get copyAddress => 'Copiar dirección';

  @override
  String get errorLoadingAddresses => 'Error al cargar direcciones';

  @override
  String get share => 'Compartir';

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
  String get available => 'disponible';

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
  String get currency => 'Moneda';

  @override
  String get chooseYourPreferredCurrency => 'Elige tu moneda preferida';

  @override
  String get preferences => 'Preferences';

  @override
  String get autoReadClipboard => 'Auto-read clipboard';

  @override
  String get autoReadClipboardDescription =>
      'Automatically check clipboard for Bitcoin addresses when sending';

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
  String get pendingConfirmation => 'Confirmación pendiente';

  @override
  String get transactionId => 'ID de transacción';

  @override
  String get status => 'Estado';

  @override
  String get confirmed => 'Confirmado';

  @override
  String get pending => 'Pendiente';

  @override
  String get spendable => 'Disponible';

  @override
  String get date => 'Fecha';

  @override
  String get time => 'Hora';

  @override
  String get transactionVolume => 'Volumen de Transacción';

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
  String get errorLoadingTransactions => 'Error al cargar transacciones';

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
  String get direction => 'Dirección';

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
  String get transactionFees => 'Comisiones de transacción';

  @override
  String get fastest10Min => 'Más rápida (~10 min)';

  @override
  String get halfHour => 'Media hora';

  @override
  String get oneHour => 'Una hora';

  @override
  String get economy => 'Económica';

  @override
  String get minutesAgo => 'hace minutos';

  @override
  String get hoursAgo => 'hace horas';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String get daysAgo => 'hace días';

  @override
  String get miningInformation => 'Información de minería';

  @override
  String get miningPool => 'Pool de minería';

  @override
  String get mined => 'Minado';

  @override
  String get blockReward => 'Recompensa de bloque';

  @override
  String get totalFees => 'Comisiones totales';

  @override
  String get min => 'Mín';

  @override
  String get networkHashrate => 'Hashrate de red';

  @override
  String get currentNetworkHashrate => 'Hashrate actual de red';

  @override
  String get noDataAvailable => 'Sin datos disponibles';

  @override
  String get difficulty => 'Dificultad';

  @override
  String get dataPoints => 'Puntos de datos';

  @override
  String get days => 'días';

  @override
  String get hours => 'horas';

  @override
  String get minutes => 'minutos';

  @override
  String get difficultyAdjustment => 'Ajuste de dificultad';

  @override
  String get complete => 'completo';

  @override
  String get remainingBlocks => 'Bloques restantes';

  @override
  String get estTime => 'Tiempo est.';

  @override
  String get estDate => 'Fecha est.';

  @override
  String get mAgo => 'min';

  @override
  String get hAgo => 'h';

  @override
  String get dAgo => 'días';

  @override
  String get blockSize => 'Tamaño de bloque';

  @override
  String get weight => 'Peso';

  @override
  String get transactions => 'Transacciones';

  @override
  String get avgSize => 'Tamaño prom.';

  @override
  String get healthy => 'Saludable';

  @override
  String get fair => 'Regular';

  @override
  String get low => 'Bajo';

  @override
  String get blockHealth => 'Salud del bloque';

  @override
  String get full => 'Lleno';

  @override
  String get actual => 'Real';

  @override
  String get expected => 'Esperado';

  @override
  String get difference => 'Diferencia';

  @override
  String get setAmount => 'Establecer monto';

  @override
  String get clear => 'Limpiar';

  @override
  String get errorSharingQrCode => 'Error al compartir código QR:';

  @override
  String get qr => 'QR';

  @override
  String get type => 'Tipo';

  @override
  String get sellBitcoin => 'Vender Bitcoin';

  @override
  String get errorLoadingSellScreen => 'Error al cargar pantalla de venta';

  @override
  String get availableBalance => 'Saldo disponible';

  @override
  String get amountToSell => 'Monto a vender';

  @override
  String get sellLimits => 'Límites de venta';

  @override
  String get insufficientBalance => 'Saldo insuficiente';

  @override
  String get max => 'Máx';

  @override
  String get payoutMethods => 'Métodos de pago';

  @override
  String get pendingBlock => 'Bloque pendiente';

  @override
  String get nextBlock => 'Siguiente bloque';

  @override
  String get medianFee => 'Comisión mediana';

  @override
  String get estimatedTime => 'Tiempo estimado';

  @override
  String get feeDistribution => 'Distribución de comisiones';

  @override
  String get noTransactionsYet => 'Sin transacciones aún';

  @override
  String get loadingMoreTransactions => 'Cargando más transacciones...';

  @override
  String get scrollDownToLoadMore => 'Desliza para cargar más';

  @override
  String get med => 'Med';

  @override
  String get feeRate => 'Tasa de comisión';

  @override
  String get size => 'Tamaño';

  @override
  String get value => 'Valor';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get transactionDetails => 'Detalles de transacción';

  @override
  String get errorLoadingTransaction => 'Error al cargar transacción';

  @override
  String get blockHeight => 'Altura de bloque';

  @override
  String get blockTime => 'Tiempo de bloque';

  @override
  String get details => 'Detalles';

  @override
  String get fee => 'Comisión';

  @override
  String get version => 'Versión';

  @override
  String get locktime => 'Tiempo de bloqueo';

  @override
  String get inputs => 'Entradas';

  @override
  String get outputs => 'Salidas';

  @override
  String get searchBlockchain => 'Buscar en blockchain';

  @override
  String get transaction => 'Transacción';

  @override
  String get enterBlockHeightOrBlockHash => 'Ingresa altura o hash de bloque';

  @override
  String get enterTransactionIdTxid => 'Ingresa ID de transacción (TXID)';

  @override
  String get blockchain => 'Blockchain';

  @override
  String get errorLoadingData => 'Error al cargar datos';

  @override
  String get recentTransactions => 'Transacciones recientes';

  @override
  String get block => 'Bloque';

  @override
  String get yourTx => 'Tu TX';

  @override
  String get paymentMethods => 'Métodos de pago';

  @override
  String get paymentProvider => 'Payment Provider';

  @override
  String get chooseProvider => 'Choose Provider';

  @override
  String get buyLimits => 'Límites de compra';

  @override
  String get errorLoadingBuyScreen => 'Error al cargar pantalla de compra';

  @override
  String get buyBitcoin => 'Comprar Bitcoin';

  @override
  String get failedToLaunchMoonpay => 'Error al iniciar MoonPay';

  @override
  String get bitcoinPriceChart => 'Gráfico de precio Bitcoin';

  @override
  String get aboutBitcoin => 'About Bitcoin';

  @override
  String get bitcoinDescription =>
      'Bitcoin is the world\'s first decentralized digital currency. It was created in 2009 by an unknown person or group of people using the name Satoshi Nakamoto. Bitcoin is a distributed, peer-to-peer network that keeps a record of all transactions in a public ledger called the blockchain.';

  @override
  String get aboutBitcoinPriceData => 'Sobre datos de precio Bitcoin';

  @override
  String get thePriceDataShown =>
      'The price data shown is sourced from our backend service and updated in real-time. Select different time ranges to view historical price trends.';

  @override
  String get dataSource => 'Fuente de datos';

  @override
  String get liveBitcoinMarketData => 'Datos de mercado Bitcoin en vivo';

  @override
  String get updateFrequency => 'Frecuencia de actualización';

  @override
  String get realTime => 'Tiempo real';

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
  String get reportBugFeedback => 'Reportar Error / Comentarios';

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
  String get loansAndLeverage => 'Mercado de Préstamos';

  @override
  String get availableOffers => 'Ofertas Disponibles';

  @override
  String get myContracts => 'Mis Contratos';

  @override
  String get signInRequired => 'Inicio de Sesión Requerido';

  @override
  String get signInToViewContracts =>
      'Inicia sesión para ver tus contratos y solicitar préstamos.';

  @override
  String get noArkadeOffersAvailable => 'No hay ofertas de Arkade disponibles';

  @override
  String get signInToViewYourContracts =>
      'Inicia sesión para ver tus contratos';

  @override
  String get noContractsMatchSearch =>
      'Ningún contrato coincide con tu búsqueda';

  @override
  String get noContractsYet =>
      'Aún no hay contratos. ¡Acepta una oferta para comenzar!';

  @override
  String get duration => 'Duración';

  @override
  String get minLtv => 'LTV Mínimo';

  @override
  String get limitedTimeOffer => 'Oferta por tiempo limitado — ¡super barata!';

  @override
  String get interest => 'Interés';

  @override
  String get due => 'Vence';

  @override
  String get overdue => 'Vencido';

  @override
  String get swapDetails => 'Detalles del Swap';

  @override
  String get errorLoadingSwap => 'Error al cargar el swap';

  @override
  String get refundAddress => 'Dirección de Reembolso';

  @override
  String get fundSwap => 'Financiar Swap';

  @override
  String get youSend => 'Envías';

  @override
  String get youReceive => 'Recibes';

  @override
  String get walletConnected => 'Billetera Conectada';

  @override
  String get switchWallet => 'Cambiar';

  @override
  String get creatingSwap => 'Creando Swap...';

  @override
  String get approvingToken => 'Aprobando token...';

  @override
  String get creatingHtlc => 'Creando HTLC...';

  @override
  String get swapFundedSuccessfully => '¡Swap financiado exitosamente!';

  @override
  String get feedback => 'Comentarios';

  @override
  String get continueButton => 'Continuar';

  @override
  String get paste => 'Pegar';

  @override
  String get scanQr => 'Escanear QR';

  @override
  String get youPay => 'Pagas';

  @override
  String get totalFeesLabel => 'Comisiones totales';

  @override
  String get beforeFees => 'antes de comisiones';

  @override
  String get networkFee => 'Red';

  @override
  String get protocolFee => 'Protocolo';

  @override
  String get receivingAddress => 'Dirección de recepción';

  @override
  String get waitingForDeposit => 'Esperando Depósito';

  @override
  String get processing => 'Procesando';

  @override
  String get completed => 'Completado';

  @override
  String get expired => 'Expirado';

  @override
  String get refundable => 'Reembolsable';

  @override
  String get refundedStatus => 'Reembolsado';

  @override
  String get failed => 'Fallido';

  @override
  String get confirmSwap => 'Confirmar Swap';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get sender => 'Remitente';

  @override
  String get receiver => 'Destinatario';

  @override
  String get scan => 'Escanear';

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
  String get copied => 'Copiado';
}
