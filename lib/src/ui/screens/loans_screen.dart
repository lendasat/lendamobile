import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/email_recovery_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/rust/api/lendasat_api.dart' as lendasat_api;
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/loan_offer_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/contract_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Main Lendasat Loans screen with offers and contracts.
class LoansScreen extends StatefulWidget {
  final String aspId;

  const LoansScreen({super.key, required this.aspId});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final LendasatService _lendasatService = LendasatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  bool _isEmailRecoverySetUp = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLendasat();
    _checkEmailRecoveryStatus();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _checkEmailRecoveryStatus() async {
    final isSetUp = await EmailRecoveryService.isSetUp();
    if (mounted) {
      setState(() {
        _isEmailRecoverySetUp = isSetUp;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLendasat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check email recovery status
      final isEmailRecoverySetUp = await EmailRecoveryService.isSetUp();

      if (mounted) {
        setState(() {
          _isEmailRecoverySetUp = isEmailRecoverySetUp;
        });
      }

      await _lendasatService.initialize();

      // Auto-authenticate if email recovery is set up
      if (isEmailRecoverySetUp && !_lendasatService.isAuthenticated) {
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
        // Log but don't fail
        logger.w('Could not load initial data: $e');
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

  /// Auto-authenticate with Lendasat using the wallet keypair.
  /// Email recovery setup should have already registered the user.
  /// If not (legacy account), we'll try to register the pubkey now.
  Future<void> _autoAuthenticate() async {
    try {
      final result = await _lendasatService.authenticate();

      if (result is lendasat_api.AuthResult_NeedsRegistration) {
        // Pubkey not registered - this can happen for accounts created
        // before we added pubkey registration to email recovery setup.
        // Try to register the pubkey now using the recovery email.
        logger.w('Lendasat: Pubkey not registered, attempting migration...');

        final recoveryEmail = await EmailRecoveryService.getRecoveryEmail();
        if (recoveryEmail != null) {
          try {
            // Register pubkey with the recovery email
            await _lendasatService.register(
              email: recoveryEmail,
              name: 'Lendasat User',
              inviteCode: 'LAS-651K4',
            );
            logger.i('Lendasat: Pubkey registration successful (migration)');
            // Authentication happens automatically in register()
          } catch (e) {
            logger.e('Lendasat: Pubkey migration failed: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Could not link wallet to your account. Please try again.';
              });
            }
          }
        } else {
          logger.e('Lendasat: No recovery email found for migration');
          if (mounted) {
            setState(() {
              _errorMessage = 'Account sync issue. Please set up email recovery again.';
            });
          }
        }
      } else if (result is lendasat_api.AuthResult_Success) {
        logger.i('Lendasat: Auto-authentication successful');
      }
    } catch (e) {
      logger.e('Lendasat auto-auth error: $e');
      // Don't throw - user can still see offers without auth
    }
  }

  /// Open the settings bottom sheet directly to the email recovery screen.
  void _openEmailRecoverySettings() {
    final settingsController = context.read<SettingsController>();
    settingsController.switchTab('emergency_recovery');

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Settings(aspId: widget.aspId),
    ).then((_) {
      // Reset settings to main tab for next time
      settingsController.resetToMain();
      // Re-check email recovery status and re-initialize
      _checkEmailRecoveryStatus();
      _initializeLendasat();
    });
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
      logger.e('Error refreshing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      appBar: ArkAppBar(
        context: context,
        hasBackButton: false,
        text: 'Loans',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    slivers: [
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
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search contracts...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
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

  Widget _buildAuthBanner() {
    // If email recovery is not set up, show recovery requirement banner
    if (!_isEmailRecoverySetUp) {
      return GlassContainer(
        margin: const EdgeInsets.all(AppTheme.cardPadding),
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          children: [
            const Icon(
              Icons.security_rounded,
              size: 48,
              color: AppTheme.colorBitcoin,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              'Email Recovery Required',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing / 2),
            Text(
              'You must set up email recovery before you can take a loan. This ensures you can recover your wallet and access your collateral.',
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
              title: 'Set Up Email Recovery',
              buttonType: ButtonType.primary,
              onTap: () => _openEmailRecoverySettings(),
              customHeight: 48,
            ),
          ],
        ),
      );
    }

    // Email recovery is set up but auth failed - show retry option
    return GlassContainer(
      margin: const EdgeInsets.all(AppTheme.cardPadding),
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        children: [
          Icon(
            Icons.refresh_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Text(
            'Connection Issue',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.elementSpacing / 2),
          Text(
            'Could not connect to the lending service. Please try again.',
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
            title: 'Retry',
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
      // Show appropriate message based on email recovery status
      final message = _isEmailRecoverySetUp
          ? 'Connecting to view your contracts...'
          : 'Set up email recovery to view contracts';

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
                    message,
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
