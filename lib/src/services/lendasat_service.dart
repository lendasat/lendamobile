import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/api/lendasat_api.dart' as lendasat_api;
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Re-export types needed by consumers
// This ensures all Lendasat interactions go through a single import
export 'package:ark_flutter/src/rust/api/lendasat_api.dart'
    show AuthResult, AuthResult_Success, AuthResult_NeedsRegistration;

/// Service for Lendasat Bitcoin-collateralized lending.
///
/// Handles authentication, loan offers, contracts, and collateral management.
class LendasatService extends ChangeNotifier {
  static final LendasatService _instance = LendasatService._internal();

  factory LendasatService() => _instance;

  LendasatService._internal();

  // State
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _publicKey;
  List<LoanOffer> _offers = [];
  List<Contract> _contracts = [];
  int _totalContracts = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get publicKey => _publicKey;
  List<LoanOffer> get offers => _offers;
  List<Contract> get contracts => _contracts;
  int get totalContracts => _totalContracts;

  /// Reset the service state. Call this when wallet is reset.
  void reset() {
    _isInitialized = false;
    _isInitializing = false;
    _isAuthenticated = false;
    _isAuthenticating = false;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _publicKey = null;
    _offers = [];
    _contracts = [];
    _totalContracts = 0;
    notifyListeners();
    logger.i('LendasatService reset');
  }

  /// Active contracts (not closed or cancelled).
  List<Contract> get activeContracts => _contracts
      .where((c) =>
          c.status != ContractStatus.closed &&
          c.status != ContractStatus.cancelled &&
          c.status != ContractStatus.rejected &&
          c.status != ContractStatus.requestExpired)
      .toList();

  /// Contracts awaiting collateral deposit.
  List<Contract> get pendingDepositContracts => _contracts
      .where((c) =>
          c.status == ContractStatus.approved ||
          c.status == ContractStatus.requested)
      .toList();

  /// Initialize Lendasat client.
  /// Should be called after wallet is initialized and mnemonic exists.
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      // IMPORTANT: Use getApplicationSupportDirectory - this is where the mnemonic is stored
      // All services must use the same directory to read the wallet's mnemonic
      // Do NOT use getApplicationDocumentsDirectory - that's a different path!
      final dataDir = await getApplicationSupportDirectory();
      final settingsService = SettingsService();
      final network = await settingsService.getNetwork();

      // Pass network directly to Rust - same as Ark does
      // Valid values: "bitcoin", "testnet", "signet", "regtest"
      // The Rust bitcoin crate will validate the network string

      // Get API URL based on network
      final apiUrl = _getApiUrl(network);

      // Get API key from .env based on network
      final apiKey = _getApiKey(network);

      await lendasat_api.lendasatInit(
        dataDir: dataDir.path,
        apiUrl: apiUrl,
        network: network,
        apiKey: apiKey,
      );

      _isInitialized = true;
      logger.i(
          'Lendasat initialized on network: $network (API key: ${apiKey != null ? "present" : "none"})');

      // Check if already authenticated
      _isAuthenticated = await lendasat_api.lendasatIsAuthenticated();
      if (_isAuthenticated) {
        logger.i('Lendasat: User already authenticated');
        // Get public key
        try {
          _publicKey = await lendasat_api.lendasatGetPublicKey();
        } catch (e) {
          logger.w('Failed to get public key: $e');
        }
      }
    } catch (e) {
      logger.e('Error initializing Lendasat: $e');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Authenticate with Lendasat API.
  ///
  /// Returns [AuthResult] which can be:
  /// - [AuthResult_Success] if authentication succeeds
  /// - [AuthResult_NeedsRegistration] if user needs to register first
  Future<lendasat_api.AuthResult> authenticate() async {
    if (_isAuthenticating) {
      throw Exception('Authentication already in progress');
    }

    _isAuthenticating = true;
    notifyListeners();

    try {
      final result = await lendasat_api.lendasatAuthenticate();

      if (result is lendasat_api.AuthResult_Success) {
        _isAuthenticated = true;
        _userId = result.userId;
        _userName = result.userName;
        _userEmail = result.userEmail;
        _publicKey = await lendasat_api.lendasatGetPublicKey();
        logger.i('Lendasat: Authenticated as ${result.userName}');
      } else if (result is lendasat_api.AuthResult_NeedsRegistration) {
        _publicKey = result.pubkey;
        logger.i(
            'Lendasat: User needs to register with pubkey: ${result.pubkey}');
      }

      notifyListeners();
      return result;
    } catch (e) {
      logger.e('Lendasat authentication error: $e');
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Register a new user.
  Future<String> register({
    required String email,
    required String name,
    String? inviteCode,
  }) async {
    try {
      final userId = await lendasat_api.lendasatRegister(
        email: email,
        name: name,
        inviteCode: inviteCode,
      );
      logger.i('Lendasat: User registered with ID: $userId');

      // Auto-authenticate after registration
      await authenticate();

      return userId;
    } catch (e) {
      logger.e('Lendasat registration error: $e');
      rethrow;
    }
  }

  /// Logout and clear stored credentials.
  Future<void> logout() async {
    try {
      await lendasat_api.lendasatLogout();
      _isAuthenticated = false;
      _userId = null;
      _userName = null;
      _userEmail = null;
      _publicKey = null;
      _contracts = [];
      _totalContracts = 0;
      logger.i('Lendasat: Logged out');
      notifyListeners();
    } catch (e) {
      logger.e('Lendasat logout error: $e');
      rethrow;
    }
  }

  /// Get the wallet's public key.
  Future<String> getPublicKey() async {
    try {
      final pubkey = await lendasat_api.lendasatGetPublicKey();
      _publicKey = pubkey;
      notifyListeners();
      return pubkey;
    } catch (e) {
      logger.e('Error getting public key: $e');
      rethrow;
    }
  }

  /// Get derivation path used for Lendasat keys.
  Future<String> getDerivationPath() async {
    try {
      return await lendasat_api.lendasatGetDerivationPath();
    } catch (e) {
      logger.e('Error getting derivation path: $e');
      rethrow;
    }
  }

  // =====================
  // Offers
  // =====================

  /// Refresh available loan offers.
  /// By default, only loads Arkade collateral offers (our wallet uses Arkade).
  Future<void> refreshOffers({OfferFilters? filters}) async {
    try {
      // Default to Arkade collateral filter if not specified
      // Our mobile wallet uses Arkade, so we only show compatible offers
      final effectiveFilters = filters ??
          const OfferFilters(
            collateralAssetType: 'Arkade',
          );

      _offers = await lendasat_api.lendasatGetOffers(filters: effectiveFilters);
      logger.i('Lendasat: Loaded ${_offers.length} Arkade offers');
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching offers: $e');
      rethrow;
    }
  }

  /// Get a single offer by ID.
  Future<LoanOffer> getOffer(String offerId) async {
    try {
      return await lendasat_api.lendasatGetOffer(offerId: offerId);
    } catch (e) {
      logger.e('Error getting offer: $e');
      rethrow;
    }
  }

  // =====================
  // Contracts
  // =====================

  /// Refresh user's contracts.
  /// Automatically re-authenticates if token is expired.
  Future<void> refreshContracts({ContractFilters? filters}) async {
    try {
      final response = await _withAutoReauth(
          () => lendasat_api.lendasatGetContracts(filters: filters));
      _contracts = response.data;
      _totalContracts = response.total;
      logger.i(
          'Lendasat: Loaded ${_contracts.length} contracts (total: $_totalContracts)');
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching contracts: $e');
      rethrow;
    }
  }

  /// Get a single contract by ID.
  /// Automatically re-authenticates if token is expired.
  Future<Contract> getContract(String contractId) async {
    try {
      final contract = await _withAutoReauth(
          () => lendasat_api.lendasatGetContract(contractId: contractId));

      // Update in local list if exists
      final index = _contracts.indexWhere((c) => c.id == contractId);
      if (index >= 0) {
        _contracts[index] = contract;
        notifyListeners();
      }

      return contract;
    } catch (e) {
      logger.e('Error getting contract: $e');
      rethrow;
    }
  }

  /// Helper that catches 401 errors, re-authenticates, and retries once.
  Future<T> _withAutoReauth<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('401') ||
          errorStr.contains('Unauthorized') ||
          errorStr.contains('Invalid token')) {
        logger.w('Lendasat: Token expired, attempting re-authentication...');
        try {
          await authenticate();
          logger.i('Lendasat: Re-authenticated, retrying request...');
          return await apiCall();
        } catch (reAuthError) {
          logger.e('Lendasat: Re-authentication failed: $reAuthError');
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Create a new loan contract by taking an offer.
  /// Automatically re-authenticates if token is expired.
  ///
  /// IMPORTANT: The Rust backend now uses the Ark identity public key as
  /// `borrower_pk` (not the Lendasat derivation path key). This is critical
  /// for claim operations to work correctly, as the collateral VTXO is locked
  /// to the Ark identity key.
  Future<Contract> createContract({
    required String offerId,
    required double loanAmount,
    required int durationDays,
    String? borrowerLoanAddress,
  }) async {
    try {
      logger.i('Lendasat: Creating contract for offer $offerId...');
      logger.i(
          'Lendasat: Loan amount: \$$loanAmount, Duration: $durationDays days');
      logger.d(
          'Lendasat: Note - borrower_pk will use Ark identity (not Lendasat derivation path)');

      final contract =
          await _withAutoReauth(() => lendasat_api.lendasatCreateContract(
                offerId: offerId,
                loanAmount: loanAmount,
                durationDays: durationDays,
                borrowerLoanAddress: borrowerLoanAddress,
              ));

      logger.i('Lendasat: Contract created successfully!');
      logger.i('Lendasat: Contract ID: ${contract.id}');
      logger.d(
          'Lendasat: Contract borrower_pk: ${contract.borrowerPk?.substring(0, 16) ?? "N/A"}...');
      logger.d(
          'Lendasat: Contract collateral address: ${contract.borrowerBtcAddress?.substring(0, 20) ?? "N/A"}...');

      // Refresh contracts list
      await refreshContracts();

      return contract;
    } catch (e) {
      logger.e('Error creating contract: $e');
      rethrow;
    }
  }

  /// Cancel a requested contract.
  Future<void> cancelContract(String contractId) async {
    try {
      await lendasat_api.lendasatCancelContract(contractId: contractId);
      logger.i('Lendasat: Cancelled contract $contractId');

      // Refresh contracts list
      await refreshContracts();
    } catch (e) {
      logger.e('Error cancelling contract: $e');
      rethrow;
    }
  }

  // =====================
  // Payments
  // =====================

  /// Mark an installment as paid.
  Future<void> markInstallmentPaid({
    required String contractId,
    required String installmentId,
    required String paymentTxid,
  }) async {
    try {
      await lendasat_api.lendasatMarkInstallmentPaid(
        contractId: contractId,
        installmentId: installmentId,
        paymentTxid: paymentTxid,
      );
      logger.i('Lendasat: Marked installment $installmentId as paid');

      // Refresh the contract
      await getContract(contractId);
    } catch (e) {
      logger.e('Error marking installment paid: $e');
      rethrow;
    }
  }

  // =====================
  // Ark Collateral Claim
  // =====================

  /// Get the PSBTs for claiming Ark collateral.
  Future<ArkClaimPsbtResponse> getClaimArkPsbt(String contractId) async {
    try {
      return await lendasat_api.lendasatGetClaimArkPsbt(
        contractId: contractId,
      );
    } catch (e) {
      logger.e('Error getting Ark claim PSBTs: $e');
      rethrow;
    }
  }

  /// Broadcast signed Ark claim transactions.
  Future<String> broadcastClaimArkTx({
    required String contractId,
    required String signedArkPsbt,
    required List<String> signedCheckpointPsbts,
  }) async {
    try {
      final txid = await lendasat_api.lendasatBroadcastClaimArkTx(
        contractId: contractId,
        signedArkPsbt: signedArkPsbt,
        signedCheckpointPsbts: signedCheckpointPsbts,
      );
      logger.i('Lendasat: Broadcast Ark claim tx $txid');

      // Refresh the contract
      await getContract(contractId);

      return txid;
    } catch (e) {
      logger.e('Error broadcasting Ark claim tx: $e');
      rethrow;
    }
  }

  /// Claim Ark collateral with automatic PSBT signing.
  ///
  /// This method automatically chooses the correct flow:
  /// - If contract.requiresArkSettlement is true: uses settlement flow
  /// - Otherwise: uses offchain claim flow
  ///
  /// Returns the broadcast transaction ID.
  Future<String> claimArkCollateral({
    required String contractId,
  }) async {
    try {
      // Get the contract to check if settlement is required
      final contract = await getContract(contractId);
      final requiresSettlement = contract.requiresArkSettlement ?? false;

      if (requiresSettlement) {
        // Settlement flow for recoverable VTXOs
        logger.i(
            'Lendasat: Contract requires Ark settlement (VTXOs are recoverable)');
        return await _claimArkViaSettlement(contractId);
      } else {
        // Offchain claim flow for non-recoverable VTXOs
        logger.i('Lendasat: Using offchain claim flow');
        return await _claimArkViaOffchain(contractId);
      }
    } catch (e) {
      logger.e('Error claiming Ark collateral: $e');
      rethrow;
    }
  }

  /// Claim Ark collateral via offchain spend (non-recoverable VTXOs).
  ///
  /// IMPORTANT: This flow requires that the contract was created with the Ark
  /// identity public key as `borrower_pk`. If a different key was used (e.g.,
  /// the Lendasat derivation path key), signing will fail because the PSBT's
  /// tap_internal_key won't match our Ark identity.
  Future<String> _claimArkViaOffchain(String contractId) async {
    logger.i('Lendasat: Starting offchain claim for contract $contractId');

    // Get the Ark claim PSBTs
    final arkResponse = await getClaimArkPsbt(contractId);

    logger.i(
        'Lendasat: Got Ark claim PSBTs - main PSBT length: ${arkResponse.arkPsbt.length}, checkpoint PSBTs: ${arkResponse.checkpointPsbts.length}');
    logger.d(
        'Lendasat: Main Ark PSBT (first 100 chars): ${arkResponse.arkPsbt.substring(0, arkResponse.arkPsbt.length > 100 ? 100 : arkResponse.arkPsbt.length)}...');

    // Log contract info for debugging
    logger.i('Lendasat: Contract borrower_pk: ${arkResponse.borrowerPk}');
    logger.i(
        'Lendasat: Contract derivation_path: ${arkResponse.derivationPath ?? "not set"}');

    logger.i('Lendasat: Signing main Ark PSBT with Ark identity...');

    // Sign using the Ark SDK's identity (same as Arkade wallet's identity.sign())
    // The collateral VTXO is locked to the Ark identity at m/83696968'/11811'/0/0.
    final signedArkPsbt = await ark_api.signPsbtWithArkIdentity(
      psbtHex: arkResponse.arkPsbt,
    );

    logger.i(
        'Lendasat: Main Ark PSBT signed, now signing ${arkResponse.checkpointPsbts.length} checkpoint PSBTs...');

    // Sign all checkpoint PSBTs with Ark identity
    final signedCheckpointPsbts = <String>[];
    for (int i = 0; i < arkResponse.checkpointPsbts.length; i++) {
      final checkpointPsbt = arkResponse.checkpointPsbts[i];
      logger.d(
          'Lendasat: Signing checkpoint PSBT ${i + 1}/${arkResponse.checkpointPsbts.length}...');

      final signedCheckpoint = await ark_api.signPsbtWithArkIdentity(
        psbtHex: checkpointPsbt,
      );
      signedCheckpointPsbts.add(signedCheckpoint);
    }

    logger.i(
        'Lendasat: All ${signedCheckpointPsbts.length + 1} PSBTs signed with Ark identity, broadcasting...');

    // Broadcast the signed transactions
    try {
      final txid = await broadcastClaimArkTx(
        contractId: contractId,
        signedArkPsbt: signedArkPsbt,
        signedCheckpointPsbts: signedCheckpointPsbts,
      );

      logger.i('Lendasat: Claim broadcast successful! TXID: $txid');
      return txid;
    } catch (e) {
      logger.e('Lendasat: Failed to broadcast Ark claim tx: $e');
      logger.e(
          'Lendasat: This may indicate the signing failed (wrong key) or network issues');
      rethrow;
    }
  }

  /// Claim Ark collateral via settlement (recoverable VTXOs).
  ///
  /// IMPORTANT: The settle-ark API returns PSBTs in BASE64 format,
  /// but our signing function expects HEX. After signing, we need to
  /// convert back to BASE64 for the finish-settle-ark API.
  ///
  /// NOTE: We use the Ark identity key for signing (not the Lendasat key),
  /// because the collateral VTXOs are locked to the Ark identity.
  /// This matches the offchain claim flow.
  Future<String> _claimArkViaSettlement(String contractId) async {
    logger.i('Lendasat: Starting settlement claim for contract $contractId');

    // Get the settle Ark PSBTs (returned in BASE64 format)
    final settleResponse = await lendasat_api.lendasatGetSettleArkPsbt(
      contractId: contractId,
    );

    logger.i(
        'Lendasat: Got settle Ark PSBTs (${settleResponse.forfeitPsbts.length} forfeits)');
    logger.i('Lendasat: Contract userPk: ${settleResponse.userPk}');

    // Convert intent proof from BASE64 to HEX for signing
    final intentProofHex = await lendasat_api.lendasatPsbtBase64ToHex(
      base64Psbt: settleResponse.intentProof,
    );

    // Sign the intent proof PSBT using Ark identity (same as Arkade wallet)
    final signedIntentHex = await ark_api.signPsbtWithArkIdentity(
      psbtHex: intentProofHex,
    );

    // Convert signed intent proof back to BASE64 for API
    final signedIntentBase64 = await lendasat_api.lendasatPsbtHexToBase64(
      hexPsbt: signedIntentHex,
    );

    logger.i(
        'Lendasat: Intent proof signed, now signing ${settleResponse.forfeitPsbts.length} forfeit PSBTs...');

    // Sign all forfeit PSBTs with Ark identity
    final signedForfeitPsbtsBase64 = <String>[];
    for (int i = 0; i < settleResponse.forfeitPsbts.length; i++) {
      final forfeitPsbtBase64 = settleResponse.forfeitPsbts[i];

      // Convert BASE64 to HEX
      final forfeitHex = await lendasat_api.lendasatPsbtBase64ToHex(
        base64Psbt: forfeitPsbtBase64,
      );

      // Sign with Ark identity (same as Arkade wallet)
      logger.d(
          'Lendasat: Signing forfeit PSBT ${i + 1}/${settleResponse.forfeitPsbts.length}...');
      final signedForfeitHex = await ark_api.signPsbtWithArkIdentity(
        psbtHex: forfeitHex,
      );

      // Convert back to BASE64
      final signedForfeitBase64 = await lendasat_api.lendasatPsbtHexToBase64(
        hexPsbt: signedForfeitHex,
      );

      signedForfeitPsbtsBase64.add(signedForfeitBase64);
    }

    logger.i('Lendasat: All settlement PSBTs signed, finishing settlement...');

    // Finish the settlement (API expects BASE64)
    final commitmentTxid = await lendasat_api.lendasatFinishSettleArk(
      contractId: contractId,
      signedIntentPsbt: signedIntentBase64,
      signedForfeitPsbts: signedForfeitPsbtsBase64,
    );

    logger.i('Lendasat: Settlement finished, commitment txid: $commitmentTxid');

    return commitmentTxid;
  }

  // =====================
  // Helper Methods
  // =====================

  /// Get API URL based on network.
  /// Network values come directly from ARK_NETWORK env var.
  /// Valid values: "bitcoin", "testnet", "signet", "regtest"
  String _getApiUrl(String network) {
    switch (network.toLowerCase()) {
      case 'bitcoin':
        return 'https://apiborrow.lendasat.com';
      case 'testnet':
      case 'signet':
      case 'regtest':
        // All test networks use the signet API
        return 'https://apiborrowersignet.lendasat.com';
      default:
        // Unknown network - let Rust fail with clear error
        return 'https://apiborrow.lendasat.com';
    }
  }

  // API keys from environment (injected via --dart-define)
  static const String _apiKeyMainnet =
      String.fromEnvironment('LENDASAT_API_KEY_MAINNET');
  static const String _apiKeySignet =
      String.fromEnvironment('LENDASAT_API_KEY_SIGNET');

  /// Get API key based on network.
  String? _getApiKey(String network) {
    switch (network.toLowerCase()) {
      case 'bitcoin':
        return _apiKeyMainnet.isNotEmpty ? _apiKeyMainnet : null;
      case 'testnet':
      case 'signet':
      case 'regtest':
        return _apiKeySignet.isNotEmpty ? _apiKeySignet : null;
      default:
        return _apiKeyMainnet.isNotEmpty ? _apiKeyMainnet : null;
    }
  }
}

// =====================
// Extensions
// =====================

/// Extension for Contract to provide convenient helper methods.
extension ContractExtension on Contract {
  /// Check if contract is in active loan state (loan disbursed, repayment ongoing).
  bool get isActiveLoan =>
      status == ContractStatus.principalGiven ||
      status == ContractStatus.repaymentProvided;

  /// Check if contract is awaiting collateral deposit.
  bool get isAwaitingDeposit =>
      status == ContractStatus.approved || status == ContractStatus.requested;

  /// Check if contract has collateral confirmed.
  bool get hasCollateralConfirmed =>
      status == ContractStatus.collateralConfirmed ||
      status == ContractStatus.principalGiven ||
      status == ContractStatus.repaymentProvided ||
      status == ContractStatus.repaymentConfirmed;

  /// Check if contract can be claimed (loan fully repaid).
  bool get canClaim =>
      status == ContractStatus.repaymentConfirmed ||
      status == ContractStatus.closingByClaim;

  /// Check if collateral can be recovered (contract expired/recoverable).
  bool get canRecover => status == ContractStatus.collateralRecoverable;

  /// Check if contract is closed.
  bool get isClosed =>
      status == ContractStatus.closed ||
      status == ContractStatus.closedByLiquidation ||
      status == ContractStatus.closedByDefaulting ||
      status == ContractStatus.closedByRecovery;

  /// Check if contract is in a problem state.
  bool get hasIssue =>
      status == ContractStatus.undercollateralized ||
      status == ContractStatus.defaulted ||
      status == ContractStatus.closingByLiquidation ||
      status == ContractStatus.closingByDefaulting;

  /// Get collateral in BTC (not sats).
  double get collateralBtc =>
      collateralSats.toInt() / BitcoinConstants.satsPerBtc;

  /// Get deposited amount in BTC.
  double get depositedBtc =>
      depositedSats.toInt() / BitcoinConstants.satsPerBtc;

  /// Get initial collateral in BTC.
  double get initialCollateralBtc =>
      initialCollateralSats.toInt() / BitcoinConstants.satsPerBtc;

  /// Get effective collateral in sats (uses initialCollateralSats as fallback).
  /// This is needed because the backend may populate initial_collateral_sats
  /// but leave collateral_sats as 0 for newly approved contracts.
  int get effectiveCollateralSats {
    final primary = collateralSats.toInt();
    if (primary > 0) return primary;
    return initialCollateralSats.toInt();
  }

  /// Get effective collateral in BTC.
  double get effectiveCollateralBtc =>
      effectiveCollateralSats / BitcoinConstants.satsPerBtc;

  /// Get origination fee in BTC.
  double get originationFeeBtc =>
      originationFeeSats.toInt() / BitcoinConstants.satsPerBtc;

  /// Get total amount to repay (principal + interest).
  double get totalRepayment => loanAmount + interest;

  /// Get pending installments.
  List<Installment> get pendingInstallments =>
      installments.where((i) => i.status == InstallmentStatus.pending).toList();

  /// Get the next due installment.
  Installment? get nextDueInstallment {
    final pending = pendingInstallments;
    if (pending.isEmpty) return null;
    // Sort by due date
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first;
  }

  /// Get paid installments.
  List<Installment> get paidInstallments => installments
      .where((i) =>
          i.status == InstallmentStatus.paid ||
          i.status == InstallmentStatus.confirmed)
      .toList();

  /// Get total amount paid so far.
  double get totalPaid {
    return paidInstallments.fold(
        0.0, (sum, i) => sum + i.principal + i.interest);
  }

  /// Get remaining balance.
  double get remainingBalance => balanceOutstanding;

  /// Get the SwapToken corresponding to this contract's loan asset.
  /// Returns null if the loan asset is not supported by Lendaswap (e.g., fiat).
  SwapToken? get repaymentSwapToken {
    switch (loanAsset) {
      case LoanAsset.usdcPol:
        return SwapToken.usdcPolygon;
      case LoanAsset.usdtPol:
        return SwapToken.usdtPolygon;
      case LoanAsset.usdcEth:
        return SwapToken.usdcEthereum;
      case LoanAsset.usdtEth:
        return SwapToken.usdtEthereum;
      // Fiat and other chains not supported by Lendaswap
      case LoanAsset.usdcStrk:
      case LoanAsset.usdtStrk:
      case LoanAsset.usdcSol:
      case LoanAsset.usdtSol:
      case LoanAsset.usdtLiquid:
      case LoanAsset.usd:
      case LoanAsset.eur:
      case LoanAsset.chf:
      case LoanAsset.mxn:
        return null;
    }
  }

  /// Check if this contract can be repaid via Lendaswap.
  /// Requires: active loan (not already sent repayment), supported stablecoin, and repayment address.
  bool get canRepayWithLendaswap {
    // Don't show repay if repayment already sent (waiting for lender confirmation)
    if (status == ContractStatus.repaymentProvided) return false;

    return isActiveLoan &&
        repaymentSwapToken != null &&
        loanRepaymentAddress != null &&
        loanRepaymentAddress!.isNotEmpty &&
        balanceOutstanding > 0;
  }

  /// Check if contract is awaiting repayment confirmation from lender.
  bool get isAwaitingRepaymentConfirmation =>
      status == ContractStatus.repaymentProvided;

  /// Get repayment progress (0.0 to 1.0).
  double get repaymentProgress {
    // If loan is fully repaid, return 100%
    if (status == ContractStatus.repaymentConfirmed ||
        status == ContractStatus.closingByClaim) {
      return 1.0;
    }

    // For closed contracts that were successfully repaid
    if (status == ContractStatus.closed && balanceOutstanding <= 0) {
      return 1.0;
    }

    if (totalRepayment <= 0) return 0;

    // Calculate from installments, clamped to handle floating point issues
    final progress = totalPaid / totalRepayment;
    return progress.clamp(0.0, 1.0);
  }

  /// Get status display text.
  String get statusText {
    switch (status) {
      case ContractStatus.requested:
        return 'Requested';
      case ContractStatus.approved:
        return 'Approved - Awaiting Deposit';
      case ContractStatus.collateralSeen:
        return 'Collateral Detected';
      case ContractStatus.collateralConfirmed:
        return 'Collateral Confirmed';
      case ContractStatus.principalGiven:
        return 'Loan Active';
      case ContractStatus.repaymentProvided:
        return 'Repayment Sent';
      case ContractStatus.repaymentConfirmed:
        return 'Repayment Confirmed';
      case ContractStatus.undercollateralized:
        return 'Undercollateralized';
      case ContractStatus.defaulted:
        return 'Defaulted';
      case ContractStatus.closingByClaim:
        return 'Claiming Collateral';
      case ContractStatus.closed:
        return 'Closed';
      case ContractStatus.closing:
        return 'Closing';
      case ContractStatus.closingByLiquidation:
        return 'Being Liquidated';
      case ContractStatus.closedByLiquidation:
        return 'Liquidated';
      case ContractStatus.closingByDefaulting:
        return 'Defaulting';
      case ContractStatus.closedByDefaulting:
        return 'Closed (Defaulted)';
      case ContractStatus.extended:
        return 'Extended';
      case ContractStatus.rejected:
        return 'Rejected';
      case ContractStatus.disputeBorrowerStarted:
        return 'Dispute Started';
      case ContractStatus.disputeLenderStarted:
        return 'Dispute Started';
      case ContractStatus.cancelled:
        return 'Cancelled';
      case ContractStatus.requestExpired:
        return 'Request Expired';
      case ContractStatus.approvalExpired:
        return 'Approval Expired';
      case ContractStatus.collateralRecoverable:
        return 'Collateral Recoverable';
      case ContractStatus.closingByRecovery:
        return 'Recovering Collateral';
      case ContractStatus.closedByRecovery:
        return 'Collateral Recovered';
    }
  }

  /// Get days until expiry.
  int get daysUntilExpiry {
    final expiryDate = DateTime.tryParse(expiry);
    if (expiryDate == null) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// Check if contract is using Ark collateral.
  bool get isArkCollateral => collateralAsset == CollateralAsset.arkadeBtc;

  /// Get display name for loan asset.
  String get loanAssetDisplayName {
    switch (loanAsset) {
      case LoanAsset.usdcPol:
        return 'USDC (Polygon)';
      case LoanAsset.usdtPol:
        return 'USDT (Polygon)';
      case LoanAsset.usdcEth:
        return 'USDC (Ethereum)';
      case LoanAsset.usdtEth:
        return 'USDT (Ethereum)';
      case LoanAsset.usdcStrk:
        return 'USDC (Starknet)';
      case LoanAsset.usdtStrk:
        return 'USDT (Starknet)';
      case LoanAsset.usdcSol:
        return 'USDC (Solana)';
      case LoanAsset.usdtSol:
        return 'USDT (Solana)';
      case LoanAsset.usdtLiquid:
        return 'USDT (Liquid)';
      case LoanAsset.usd:
        return 'USD';
      case LoanAsset.eur:
        return 'EUR';
      case LoanAsset.chf:
        return 'CHF';
      case LoanAsset.mxn:
        return 'MXN';
    }
  }

  /// Get short display name for loan asset (just the symbol).
  String get loanAssetSymbol {
    switch (loanAsset) {
      case LoanAsset.usdcPol:
      case LoanAsset.usdcEth:
      case LoanAsset.usdcStrk:
      case LoanAsset.usdcSol:
        return 'USDC';
      case LoanAsset.usdtPol:
      case LoanAsset.usdtEth:
      case LoanAsset.usdtStrk:
      case LoanAsset.usdtSol:
      case LoanAsset.usdtLiquid:
        return 'USDT';
      case LoanAsset.usd:
        return 'USD';
      case LoanAsset.eur:
        return 'EUR';
      case LoanAsset.chf:
        return 'CHF';
      case LoanAsset.mxn:
        return 'MXN';
    }
  }
}

/// Extension for LoanOffer to provide convenient helper methods.
extension LoanOfferExtension on LoanOffer {
  /// Get display name for loan asset.
  String get loanAssetDisplayName {
    switch (loanAsset) {
      case LoanAsset.usdcPol:
        return 'USDC (Polygon)';
      case LoanAsset.usdtPol:
        return 'USDT (Polygon)';
      case LoanAsset.usdcEth:
        return 'USDC (Ethereum)';
      case LoanAsset.usdtEth:
        return 'USDT (Ethereum)';
      case LoanAsset.usdcStrk:
        return 'USDC (Starknet)';
      case LoanAsset.usdtStrk:
        return 'USDT (Starknet)';
      case LoanAsset.usdcSol:
        return 'USDC (Solana)';
      case LoanAsset.usdtSol:
        return 'USDT (Solana)';
      case LoanAsset.usdtLiquid:
        return 'USDT (Liquid)';
      case LoanAsset.usd:
        return 'USD';
      case LoanAsset.eur:
        return 'EUR';
      case LoanAsset.chf:
        return 'CHF';
      case LoanAsset.mxn:
        return 'MXN';
    }
  }

  /// Get collateral asset display name.
  String get collateralAssetDisplayName {
    switch (collateralAsset) {
      case CollateralAsset.bitcoinBtc:
        return 'Bitcoin (On-chain)';
      case CollateralAsset.arkadeBtc:
        return 'Bitcoin (Arkade)';
    }
  }

  /// Get interest rate as percentage string.
  String get interestRatePercent =>
      '${(interestRate * 100).toStringAsFixed(2)}%';

  /// Get origination fee for a given duration.
  double getOriginationFee(int durationDays) {
    // Find the applicable fee tier
    double fee = 0;
    for (final tier in originationFee) {
      if (durationDays >= tier.fromDay) {
        fee = tier.fee;
      }
    }
    return fee;
  }

  /// Check if offer requires KYC.
  bool get requiresKyc => kycLink != null && kycLink!.isNotEmpty;

  /// Check if offer is available.
  bool get isAvailable => status == LoanOfferStatus.available;

  /// Get loan amount range as string.
  String get loanAmountRange =>
      '\$${loanAmountMin.toStringAsFixed(0)} - \$${loanAmountMax.toStringAsFixed(0)}';

  /// Get duration range as string.
  String get durationRange => '$durationDaysMin - $durationDaysMax days';
}

/// Extension for Installment.
extension InstallmentExtension on Installment {
  /// Total payment for this installment.
  double get totalPayment => principal + interest;

  /// Check if installment is overdue.
  bool get isOverdue {
    if (status != InstallmentStatus.pending) return false;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    return DateTime.now().isAfter(due);
  }

  /// Days until due (negative if overdue).
  int get daysUntilDue {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays;
  }

  /// Get status display text.
  String get statusText {
    switch (status) {
      case InstallmentStatus.pending:
        return isOverdue ? 'Overdue' : 'Pending';
      case InstallmentStatus.paid:
        return 'Paid';
      case InstallmentStatus.confirmed:
        return 'Confirmed';
      case InstallmentStatus.late_:
        return 'Late';
      case InstallmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
