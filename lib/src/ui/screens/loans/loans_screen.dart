import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/loans/loan_offer_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/loans/contract_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/loans/loan_filter_screen.dart';
import 'package:ark_flutter/src/ui/widgets/loans/offer_card.dart';
import 'package:ark_flutter/src/ui/widgets/loans/contract_card.dart';
import 'package:flutter/material.dart';
import 'loans_config.dart';
import 'loans_controller.dart';
import 'loans_state.dart';

/// Main Lendasat Loans screen with offers and contracts.
class LoansScreen extends StatefulWidget {
  final String aspId;

  const LoansScreen({super.key, required this.aspId});

  @override
  State<LoansScreen> createState() => LoansScreenState();
}

class LoansScreenState extends State<LoansScreen> with WidgetsBindingObserver {
  late final LoansController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _wasKeyboardVisible = false;
  Timer? _keyboardDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = LoansController();
    _controller.initialize();
    _controller.startAutoRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _keyboardDebounceTimer?.cancel();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Unfocus search field - can be called from parent (e.g., bottom nav)
  void unfocusAll() {
    _searchFocusNode.unfocus();
  }

  /// Scrolls to the top of the loans screen with a smooth animation.
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: LoansConfig.scrollToTopDurationMs),
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.startAutoRefreshTimer();
        if (mounted && !_controller.state.isLoading) {
          _controller.refresh();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _controller.stopAutoRefreshTimer();
        break;
      default:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _keyboardDebounceTimer?.cancel();
    _keyboardDebounceTimer = Timer(
      const Duration(milliseconds: LoansConfig.keyboardDebounceMs),
      () {
        if (!mounted) return;
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        if (_wasKeyboardVisible && !keyboardVisible) {
          _searchFocusNode.unfocus();
        }
        _wasKeyboardVisible = keyboardVisible;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return ArkScaffoldUnsafe(
          context: context,
          body: GestureDetector(
            onTap: () => _searchFocusNode.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: state.isLoading
                ? dotProgress(context)
                : state.errorMessage != null
                    ? _LoansErrorView(
                        errorMessage: state.errorMessage,
                        onRetry: _controller.initialize,
                      )
                    : RefreshIndicator(
                        onRefresh: _controller.refresh,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            const SliverToBoxAdapter(
                              child:
                                  SizedBox(height: AppTheme.cardPadding * 2.5),
                            ),
                            if (state.showDebugInfo)
                              SliverToBoxAdapter(
                                child: _LoansDebugCard(
                                  state: state,
                                  onClose: _controller.hideDebugInfo,
                                ),
                              ),
                            if (!state.isAuthenticated)
                              SliverToBoxAdapter(
                                child: _LoansAuthBanner(
                                  isRegistering: state.isRegistering,
                                  onSignUp: () => _showSignupModal(context),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: _LoansOffersHeader(),
                            ),
                            _LoansOffersSliver(
                              offers: state.arkadeOffers,
                              onOfferTap: (offer) => _openOfferDetail(offer),
                            ),
                            _LoansStickyHeader(
                              searchFocusNode: _searchFocusNode,
                              filterOptions: state.filterOptions,
                              onSearchChanged: _controller.setSearchQuery,
                              onFilterTap: () =>
                                  _showFilterSheet(context, state),
                            ),
                            _LoansContractsSliver(
                              isAuthenticated: state.isAuthenticated,
                              contracts: state.filteredContracts,
                              hasActiveFilters: state.hasActiveFilters,
                              onContractTap: (contract) =>
                                  _openContractDetail(contract),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: AppTheme.cardPadding * 2),
                            ),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  void _showSignupModal(BuildContext context) {
    final emailController = TextEditingController();
    String? errorMessage;
    final l10n = AppLocalizations.of(context)!;

    arkBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              top: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.elementSpacing),
                Text(
                  'Enter your email to access loans and contracts.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      ),
                ),
                const SizedBox(height: AppTheme.cardPadding),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofocus: true,
                  enabled: !_controller.state.isRegistering,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: 'you@example.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.colorBitcoin, width: 2),
                    ),
                    errorText: errorMessage,
                  ),
                  onChanged: (_) {
                    if (errorMessage != null) {
                      setModalState(() => errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.cardPadding),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return LongButtonWidget(
                      title: 'Sign Up',
                      buttonType: ButtonType.solid,
                      customWidth: double.infinity,
                      isLoading: _controller.state.isRegistering,
                      onTap: () async {
                        final email = emailController.text.trim().toLowerCase();

                        if (email.isEmpty) {
                          setModalState(
                              () => errorMessage = l10n.pleaseEnterEmail);
                          return;
                        }

                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(email)) {
                          setModalState(() => errorMessage = l10n.invalidEmail);
                          return;
                        }

                        setModalState(() => errorMessage = null);

                        try {
                          await _controller.register(email: email);
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          setModalState(() => errorMessage = e.toString());
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context, LoansState state) async {
    _searchFocusNode.unfocus();
    await arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height *
          LoansConfig.filterSheetHeightRatio,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: LoanFilterScreen(
        initialFilters: state.filterOptions,
        onApply: _controller.setFilterOptions,
      ),
    );
  }

  void _openOfferDetail(LoanOffer offer) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanOfferDetailScreen(offer: offer),
      ),
    ).then((_) => _controller.refresh());
  }

  void _openContractDetail(Contract contract) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailScreen(contractId: contract.id),
      ),
    ).then((_) => _controller.refresh());
  }
}

// ============================================================================
// Private Widget Classes
// ============================================================================

class _LoansOffersHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.cardPadding,
        AppTheme.cardPadding,
        AppTheme.cardPadding,
        AppTheme.elementSpacing,
      ),
      child: Text(
        AppLocalizations.of(context)?.availableOffers ?? 'Available Offers',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _LoansErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _LoansErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              AppLocalizations.of(context)?.error ?? 'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              errorMessage ??
                  (AppLocalizations.of(context)?.unknownError ??
                      'Unknown error'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: AppLocalizations.of(context)?.retry ?? 'Retry',
              buttonType: ButtonType.secondary,
              onTap: onRetry,
            ),
            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }
}

class _LoansDebugCard extends StatelessWidget {
  final LoansState state;
  final VoidCallback onClose;

  const _LoansDebugCard({
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(AppTheme.cardPadding),
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Debug Info',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          _DebugRow(
            label: 'Derivation Path',
            value: state.debugDerivationPath ?? 'Loading...',
          ),
          const SizedBox(height: 4),
          _DebugRow(
            label: 'Public Key',
            value: state.debugPubkey ?? 'Loading...',
            isMonospace: true,
          ),
          const SizedBox(height: 4),
          _DebugRow(
            label: 'Auth Status',
            value:
                state.isAuthenticated ? 'Authenticated' : 'Not Authenticated',
          ),
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;

  const _DebugRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _LoansAuthBanner extends StatelessWidget {
  final bool isRegistering;
  final VoidCallback onSignUp;

  const _LoansAuthBanner({
    required this.isRegistering,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
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
            'Sign Up to Access Loans',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.elementSpacing / 2),
          Text(
            'Create an account to view your contracts and take loans. You can still browse available offers.',
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
            title: 'Sign Up',
            buttonType: ButtonType.primary,
            onTap: onSignUp,
          ),
        ],
      ),
    );
  }
}

class _LoansOffersSliver extends StatelessWidget {
  final List<LoanOffer> offers;
  final void Function(LoanOffer) onOfferTap;

  const _LoansOffersSliver({
    required this.offers,
    required this.onOfferTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.noArkadeOffersAvailable ??
                        'No Arkade offers available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
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
            return OfferCard(
              offer: offer,
              onTap: () => onOfferTap(offer),
            );
          },
          childCount: offers.length,
        ),
      ),
    );
  }
}

class _LoansStickyHeader extends StatelessWidget {
  final FocusNode searchFocusNode;
  final LoanFilterOptions filterOptions;
  final void Function(String) onSearchChanged;
  final VoidCallback onFilterTap;

  const _LoansStickyHeader({
    required this.searchFocusNode,
    required this.filterOptions,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const double headerHeight =
        LoansConfig.headerHeight + AppTheme.elementSpacing;

    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: headerHeight,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.black,
                Colors.black.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.92, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppTheme.cardPadding * 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding),
                child: Text(
                  l10n?.myContracts ?? 'My Contracts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding),
                child: SearchFieldWidget(
                  hintText: l10n?.search ?? 'Search',
                  isSearchEnabled: true,
                  node: searchFocusNode,
                  handleSearch: onSearchChanged,
                  onChanged: onSearchChanged,
                  suffixIcon: IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.tune,
                          color: filterOptions.hasFilter
                              ? AppTheme.colorBitcoin
                              : Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                          size: AppTheme.cardPadding * 0.75,
                        ),
                        if (filterOptions.hasFilter)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.colorBitcoin,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: onFilterTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoansContractsSliver extends StatelessWidget {
  final bool isAuthenticated;
  final List<Contract> contracts;
  final bool hasActiveFilters;
  final void Function(Contract) onContractTap;

  const _LoansContractsSliver({
    required this.isAuthenticated,
    required this.contracts,
    required this.hasActiveFilters,
    required this.onContractTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.signInToViewYourContracts ??
                        'Sign in to view your contracts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (contracts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.cardPadding * 2,
            right: AppTheme.cardPadding * 2,
            top: AppTheme.cardPadding,
          ),
          child: Row(
            children: [
              Icon(
                hasActiveFilters
                    ? Icons.search_off
                    : Icons.receipt_long_outlined,
                size: 32,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(width: AppTheme.elementSpacing),
              Expanded(
                child: Text(
                  hasActiveFilters
                      ? (AppLocalizations.of(context)?.noContractsMatchSearch ??
                          'No contracts match your filters')
                      : (AppLocalizations.of(context)?.noContractsYet ??
                          'No contracts yet. Take an offer to get started!'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ),
            ],
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
            return ContractCard(
              contract: contract,
              onTap: () => onContractTap(contract),
            );
          },
          childCount: contracts.length,
        ),
      ),
    );
  }
}
