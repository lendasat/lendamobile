import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/loan_offer_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/contract_detail_screen.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Main Lendasat Loans screen with offers and contracts.
class LoansScreen extends StatefulWidget {
  final String aspId;

  const LoansScreen({super.key, required this.aspId});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final LendasatService _lendasatService = LendasatService();
  String _searchQuery = '';

  bool _isLoading = true;
  String? _errorMessage;

  // Debug info
  String? _debugPubkey;
  String? _debugDerivationPath;
  bool _showDebugInfo = false; // Debug info disabled for production

  @override
  void initState() {
    super.initState();
    _initializeLendasat();
  }

  Future<void> _initializeLendasat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _lendasatService.initialize();

      // Fetch debug info
      try {
        _debugPubkey = await _lendasatService.getPublicKey();
        _debugDerivationPath = await _lendasatService.getDerivationPath();
        logger.i('Lendasat pubkey: $_debugPubkey');
        logger.i('Lendasat derivation path: $_debugDerivationPath');
      } catch (e) {
        logger.w('Could not get debug info: $e');
      }

      // Try to authenticate with Lendasat using wallet pubkey
      if (!_lendasatService.isAuthenticated) {
        await _autoAuthenticate();
      }

      // Try to load data
      try {
        if (_lendasatService.isAuthenticated) {
          await Future.wait([
            _lendasatService.refreshOffers(),
            _lendasatService.refreshContracts(),
          ]);
        } else {
          // Try to load offers (may require auth depending on API)
          await _lendasatService.refreshOffers();
        }
      } catch (e) {
        // Check if this is a 401 error - token expired
        if (_isUnauthorizedError(e)) {
          logger.i('Token expired, re-authenticating...');
          await _autoAuthenticate();
          // Retry loading data after re-authentication
          if (_lendasatService.isAuthenticated) {
            try {
              await Future.wait([
                _lendasatService.refreshOffers(),
                _lendasatService.refreshContracts(),
              ]);
            } catch (retryError) {
              logger.w('Could not load data after re-auth: $retryError');
            }
          }
        } else {
          // Log but don't fail for other errors
          logger.w('Could not load initial data: $e');
        }
      }
    } catch (e) {
      logger.e('Error initializing Lendasat: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check if error is a 401 Unauthorized error (token expired).
  bool _isUnauthorizedError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') ||
           errorStr.contains('unauthorized') ||
           errorStr.contains('invalid token');
  }

  /// Auto-authenticate with Lendasat using the wallet keypair.
  /// User should have been registered during wallet signup.
  Future<void> _autoAuthenticate() async {
    try {
      final result = await _lendasatService.authenticate();

      if (result is AuthResult_NeedsRegistration) {
        // Pubkey not registered - user needs to create an account
        logger.w('Lendasat: Pubkey not registered, user needs to sign up');
        // Don't show error - user can still see offers
      } else if (result is AuthResult_Success) {
        logger.i('Lendasat: Auto-authentication successful');
      }
    } catch (e) {
      logger.e('Lendasat auto-auth error: $e');
      // Don't throw - user can still see offers without auth
    }
  }

  Future<void> _refresh() async {
    try {
      await Future.wait([
        _lendasatService.refreshOffers(),
        if (_lendasatService.isAuthenticated)
          _lendasatService.refreshContracts(),
      ]);
      if (mounted) setState(() {});
    } catch (e) {
      // Check if this is a 401 error - token expired
      if (_isUnauthorizedError(e)) {
        logger.i('Token expired during refresh, re-authenticating...');
        await _autoAuthenticate();
        // Retry refresh after re-authentication
        if (_lendasatService.isAuthenticated) {
          try {
            await Future.wait([
              _lendasatService.refreshOffers(),
              _lendasatService.refreshContracts(),
            ]);
            if (mounted) setState(() {});
          } catch (retryError) {
            logger.e('Error refreshing after re-auth: $retryError');
          }
        }
      } else {
        logger.e('Error refreshing: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      appBar: ArkAppBar(
        context: context,
        hasBackButton: false,
        text: 'Loans & Leverage',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    slivers: [
                      // Debug info (development only)
                      if (_showDebugInfo)
                        SliverToBoxAdapter(child: _buildDebugCard()),

                      // Auth banner (if not authenticated)
                      if (!_lendasatService.isAuthenticated)
                        SliverToBoxAdapter(child: _buildAuthBanner()),

                      // Offers section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.cardPadding,
                            AppTheme.cardPadding,
                            AppTheme.cardPadding,
                            AppTheme.elementSpacing,
                          ),
                          child: Text(
                            'Available Offers',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),

                      // Offers list
                      _buildOffersSliver(),

                      // My Contracts section with search
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.cardPadding,
                            AppTheme.cardPadding,
                            AppTheme.cardPadding,
                            AppTheme.elementSpacing,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Contracts',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.elementSpacing),
                              // Search bar
                              SearchFieldWidget(
                                hintText: 'Search contracts...',
                                isSearchEnabled: true,
                                handleSearch: (value) {
                                  setState(() {
                                    _searchQuery = value.toLowerCase();
                                  });
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.toLowerCase();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Contracts list
                      _buildContractsSliver(),

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppTheme.cardPadding * 2),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDebugCard() {
    return GlassContainer(
      margin: const EdgeInsets.all(AppTheme.cardPadding),
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report,
                size: 20,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Debug Info',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _showDebugInfo = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          _buildDebugRow('Derivation Path', _debugDerivationPath ?? 'Loading...'),
          const SizedBox(height: 4),
          _buildDebugRow('Public Key', _debugPubkey ?? 'Loading...', isMonospace: true),
          const SizedBox(height: 4),
          _buildDebugRow('Auth Status', _lendasatService.isAuthenticated ? 'Authenticated' : 'Not Authenticated'),
          if (_lendasatService.publicKey != null) ...[
            const SizedBox(height: 4),
            _buildDebugRow('Service PubKey', _lendasatService.publicKey!, isMonospace: true),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value, {bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          isMonospace && value.length > 20
              ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}'
              : value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildAuthBanner() {
    // Not authenticated - show info banner with retry option
    return GlassContainer(
      margin: const EdgeInsets.all(AppTheme.cardPadding),
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Text(
            'Sign In Required',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.elementSpacing / 2),
          Text(
            'Sign in to view your contracts and take loans. You can still browse available offers.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.cardPadding),
          LongButtonWidget(
            title: 'Retry Connection',
            buttonType: ButtonType.primary,
            onTap: _initializeLendasat,
            customHeight: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.cardPadding * 2),
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: 'Retry',
              buttonType: ButtonType.secondary,
              onTap: _initializeLendasat,
            ),
            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSliver() {
    // Filter offers to only show Arkade collateral (our wallet uses Arkade)
    final offers = _lendasatService.offers
        .where((offer) => offer.collateralAsset == CollateralAsset.arkadeBtc)
        .toList();

    if (offers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    'No Arkade offers available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final offer = offers[index];
            return _OfferCard(
              offer: offer,
              onTap: () => _openOfferDetail(offer),
            );
          },
          childCount: offers.length,
        ),
      ),
    );
  }

  Widget _buildContractsSliver() {
    if (!_lendasatService.isAuthenticated) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    'Sign in to view your contracts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filter contracts by search query
    var contracts = _lendasatService.contracts;
    if (_searchQuery.isNotEmpty) {
      contracts = contracts.where((contract) {
        final lenderName = contract.lender.name.toLowerCase();
        final amount = contract.loanAmount.toStringAsFixed(2);
        final status = contract.statusText.toLowerCase();
        return lenderName.contains(_searchQuery) ||
            amount.contains(_searchQuery) ||
            status.contains(_searchQuery);
      }).toList();
    }

    if (contracts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No contracts match your search'
                        : 'No contracts yet. Take an offer to get started!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final contract = contracts[index];
            return _ContractCard(
              contract: contract,
              onTap: () => _openContractDetail(contract),
            );
          },
          childCount: contracts.length,
        ),
      ),
    );
  }

  void _openOfferDetail(LoanOffer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanOfferDetailScreen(offer: offer),
      ),
    ).then((_) => _refresh());
  }

  void _openContractDetail(Contract contract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailScreen(contractId: contract.id),
      ),
    ).then((_) => _refresh());
  }
}

// =====================
// Offer Card Widget
// =====================

class _OfferCard extends StatelessWidget {
  final LoanOffer offer;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.cardRadiusSmall,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${offer.lender.name}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: AppTheme.cardPadding),

              // Details row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Interest',
                      offer.interestRatePercent,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Amount',
                      offer.loanAmountRange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Duration',
                      offer.durationRange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.elementSpacing),

              // Asset info
              Row(
                children: [
                  _buildAssetChip(context, offer.loanAssetDisplayName),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  _buildAssetChip(context, offer.collateralAssetDisplayName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    String text;

    if (offer.isAvailable) {
      badgeColor = AppTheme.successColor;
      text = 'Available';
    } else {
      badgeColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
      text = 'Unavailable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildAssetChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

// =====================
// Contract Card Widget
// =====================

class _ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback onTap;

  const _ContractCard({
    required this.contract,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.cardRadiusSmall,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${contract.loanAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'from ${contract.lender.name}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: AppTheme.cardPadding),

              // Progress bar (for active loans)
              if (contract.isActiveLoan) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: contract.repaymentProgress,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.successColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(contract.repaymentProgress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.elementSpacing),
              ],

              // Details row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Collateral',
                      '${contract.collateralBtc.toStringAsFixed(6)} BTC',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Interest',
                      '${(contract.interestRate * 100).toStringAsFixed(2)}%',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Expires',
                      _formatExpiry(contract.expiry),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;

    if (contract.isClosed) {
      badgeColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    } else if (contract.hasIssue) {
      badgeColor = AppTheme.errorColor;
    } else if (contract.canClaim || contract.canRecover) {
      badgeColor = AppTheme.successColor;
    } else if (contract.isAwaitingDeposit) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        contract.statusText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatExpiry(String expiry) {
    try {
      final date = DateTime.parse(expiry);
      final now = DateTime.now();
      final diff = date.difference(now);

      if (diff.isNegative) {
        return 'Expired';
      } else if (diff.inDays > 30) {
        return DateFormat('MMM d').format(date);
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d left';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h left';
      } else {
        return '<1h left';
      }
    } catch (_) {
      return expiry;
    }
  }
}
