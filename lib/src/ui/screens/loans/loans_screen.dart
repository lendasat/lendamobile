import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
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
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';

/// Main Lendasat Loans screen with offers and contracts.
class LoansScreen extends StatefulWidget {
  final String aspId;

  const LoansScreen({super.key, required this.aspId});

  @override
  State<LoansScreen> createState() => LoansScreenState();
}

class LoansScreenState extends State<LoansScreen> with WidgetsBindingObserver {
  final LendasatService _lendasatService = LendasatService();
  final SettingsService _settingsService = SettingsService();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();
  bool _wasKeyboardVisible = false;
  Timer? _keyboardDebounceTimer;

  bool _isLoading = true;
  bool _isRegistering = false;
  String? _errorMessage;
  Timer? _autoRefreshTimer;

  // Filter state
  LoanFilterOptions _filterOptions = const LoanFilterOptions();

  // Debug info
  String? _debugPubkey;
  String? _debugDerivationPath;
  bool _showDebugInfo = false; // Debug info disabled for production

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLendasat();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    _keyboardDebounceTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Unfocus search field - can be called from parent (e.g., bottom nav)
  void unfocusAll() {
    _searchFocusNode.unfocus();
  }

  /// Scrolls to the top of the loans screen with a smooth animation
  /// Called when user taps the loans tab while already on the loans screen
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // Restart auto-refresh timer and refresh data
        _startAutoRefreshTimer();
        if (mounted && !_isLoading) {
          _refresh();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Stop auto-refresh timer to save battery
        _autoRefreshTimer?.cancel();
        _autoRefreshTimer = null;
        break;
      default:
        break;
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _lendasatService.activeContracts.isNotEmpty) {
        _refresh();
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Debounce keyboard detection to avoid ~60 callbacks during animation
    _keyboardDebounceTimer?.cancel();
    _keyboardDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (_wasKeyboardVisible && !keyboardVisible) {
        // Keyboard was just dismissed - unfocus search field
        _searchFocusNode.unfocus();
      }
      _wasKeyboardVisible = keyboardVisible;
    });
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
      await _loadData();

      // If data is empty after initial load, retry after a short delay
      // This handles the case where Ark keypair derivation is still in progress
      if ((_lendasatService.offers.isEmpty ||
              (_lendasatService.isAuthenticated &&
                  _lendasatService.contracts.isEmpty)) &&
          mounted) {
        logger.i('Lendasat: Initial data empty, retrying after delay...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _loadData();
        }

        // If contracts are still empty after retry, try one more time
        // This handles slow network or auth token propagation delays
        if (_lendasatService.isAuthenticated &&
            _lendasatService.contracts.isEmpty &&
            mounted) {
          logger.i('Lendasat: Contracts still empty, retrying once more...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            try {
              await _lendasatService.refreshContracts();
            } catch (e) {
              logger.w('Could not load contracts on retry: $e');
            }
          }
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

  /// Load offers and contracts data.
  Future<void> _loadData() async {
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
        logger.w('Could not load data: $e');
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
        // Immediately load contracts after successful auth
        try {
          await _lendasatService.refreshContracts();
          logger.i('Lendasat: Contracts loaded after auth');
        } catch (e) {
          logger.w('Could not load contracts after auth: $e');
        }
      }
    } catch (e) {
      logger.e('Lendasat auto-auth error: $e');
      // Don't throw - user can still see offers without auth
    }
  }

  /// Show signup modal to register with Lendasat.
  void _showSignupModal() {
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
                  enabled: !_isRegistering,
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
                LongButtonWidget(
                  title: 'Sign Up',
                  buttonType: ButtonType.solid,
                  customWidth: double.infinity,
                  isLoading: _isRegistering,
                  onTap: () async {
                    final email = emailController.text.trim().toLowerCase();

                    // Validate email
                    if (email.isEmpty) {
                      setModalState(() => errorMessage = l10n.pleaseEnterEmail);
                      return;
                    }

                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(email)) {
                      setModalState(() => errorMessage = l10n.invalidEmail);
                      return;
                    }

                    setModalState(() => errorMessage = null);
                    setState(() => _isRegistering = true);
                    setModalState(() {});

                    try {
                      // Register with Lendasat
                      logger.i('[SIGNUP] Registering with Lendasat...');
                      await _lendasatService.register(
                        email: email,
                        name: 'Lendasat User',
                        inviteCode: 'LAS-651K4',
                      );

                      // Save email
                      await _settingsService.setUserEmail(email);
                      logger.i('[SIGNUP] Registration successful');

                      // Authenticate
                      await _autoAuthenticate();

                      // Refresh data
                      await _loadData();

                      if (mounted) {
                        Navigator.of(context).pop();
                        OverlayService()
                            .showSuccess('Registration successful!');
                        setState(() => _isRegistering = false);
                      }
                    } catch (e) {
                      logger.e('[SIGNUP] Registration failed: $e');
                      setState(() => _isRegistering = false);

                      // Check if already registered
                      if (e.toString().toLowerCase().contains('already') ||
                          e.toString().toLowerCase().contains('exists')) {
                        // Try to authenticate anyway
                        await _autoAuthenticate();
                        if (_lendasatService.isAuthenticated) {
                          await _loadData();
                          if (mounted) {
                            Navigator.of(context).pop();
                            setState(() {});
                          }
                          return;
                        }
                      }

                      setModalState(() => errorMessage = e.toString());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
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
    return ArkScaffoldUnsafe(
      context: context,
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _isLoading
            ? dotProgress(context)
            : _errorMessage != null
                ? _buildErrorView()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Top padding
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppTheme.cardPadding * 2.5),
                        ),

                        // Debug info (development only)
                        if (_showDebugInfo)
                          SliverToBoxAdapter(child: _buildDebugCard(context)),

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
                              AppLocalizations.of(context)?.availableOffers ??
                                  'Available Offers',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),

                        // Offers list
                        _buildOffersSliver(),

                        // My Contracts section with sticky header
                        _buildStickyContractsHeader(),

                        // Contracts list
                        _buildContractsSliver(),

                        // Bottom padding
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppTheme.cardPadding * 2),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDebugCard(BuildContext context) {
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
                onPressed: () => setState(() => _showDebugInfo = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          _buildDebugRow(
              'Derivation Path', _debugDerivationPath ?? 'Loading...'),
          const SizedBox(height: 4),
          _buildDebugRow('Public Key', _debugPubkey ?? 'Loading...',
              isMonospace: true),
          const SizedBox(height: 4),
          _buildDebugRow(
              'Auth Status',
              _lendasatService.isAuthenticated
                  ? 'Authenticated'
                  : 'Not Authenticated'),
          if (_lendasatService.publicKey != null) ...[
            const SizedBox(height: 4),
            _buildDebugRow('Service PubKey', _lendasatService.publicKey!,
                isMonospace: true),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value,
      {bool isMonospace = false}) {
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

  Widget _buildAuthBanner() {
    // Not authenticated - show info banner with signup option
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
            onTap: _showSignupModal,
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
              AppLocalizations.of(context)?.error ?? 'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              _errorMessage ??
                  (AppLocalizations.of(context)?.unknownError ??
                      'Unknown error'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: AppLocalizations.of(context)?.retry ?? 'Retry',
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
              onTap: () => _openOfferDetail(offer),
            );
          },
          childCount: offers.length,
        ),
      ),
    );
  }

  /// Builds the sticky "My Contracts" header with gradient fade
  Widget _buildStickyContractsHeader() {
    final l10n = AppLocalizations.of(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // Match wallet screen pattern: 112 + cardPadding for search bar visible
    const double headerHeight = 112.0 + AppTheme.elementSpacing;

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
              // Match wallet screen top spacing
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
                  node: _searchFocusNode,
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.white60
                          : AppTheme.black60,
                      size: AppTheme.cardPadding * 0.75,
                    ),
                    onPressed: () async {
                      _searchFocusNode.unfocus();
                      await arkBottomSheet(
                        context: context,
                        height: MediaQuery.of(context).size.height * 0.6,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        child: LoanFilterScreen(
                          initialFilters: _filterOptions,
                          onApply: (filters) {
                            setState(() {
                              _filterOptions = filters;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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

    // Filter contracts by search query and status filter in a single pass
    final hasSearchFilter = _searchQuery.isNotEmpty;
    final hasStatusFilter = _filterOptions.hasFilter;

    final contracts = (!hasSearchFilter && !hasStatusFilter)
        ? _lendasatService.contracts
        : _lendasatService.contracts.where((contract) {
            // Apply search filter
            if (hasSearchFilter) {
              final lenderName = contract.lender.name.toLowerCase();
              final amount = contract.loanAmount.toStringAsFixed(2);
              final statusText = contract.statusText.toLowerCase();
              final matchesSearch = lenderName.contains(_searchQuery) ||
                  amount.contains(_searchQuery) ||
                  statusText.contains(_searchQuery);
              if (!matchesSearch) return false;
            }

            // Apply status filter
            if (hasStatusFilter) {
              final status = contract.status;
              final expiryDate = DateTime.parse(contract.expiry);
              final isOverdue = DateTime.now().isAfter(expiryDate) &&
                  status != ContractStatus.repaymentConfirmed &&
                  status != ContractStatus.closed &&
                  status != ContractStatus.closing &&
                  status != ContractStatus.closingByClaim;

              bool matchesStatus = false;
              for (final filter in _filterOptions.selectedStatuses) {
                switch (filter) {
                  case 'Active':
                    if (status == ContractStatus.principalGiven ||
                        status == ContractStatus.extended) matchesStatus = true;
                    break;
                  case 'Pending':
                    if (status == ContractStatus.requested ||
                        status == ContractStatus.approved ||
                        status == ContractStatus.collateralSeen ||
                        status == ContractStatus.collateralConfirmed)
                      matchesStatus = true;
                    break;
                  case 'Repayment Confirmed':
                    if (status == ContractStatus.repaymentConfirmed)
                      matchesStatus = true;
                    break;
                  case 'Closed':
                    if (status == ContractStatus.closed ||
                        status == ContractStatus.closing ||
                        status == ContractStatus.closingByClaim)
                      matchesStatus = true;
                    break;
                  case 'Overdue':
                    if (isOverdue) matchesStatus = true;
                    break;
                }
                if (matchesStatus) break;
              }
              if (!matchesStatus) return false;
            }

            return true;
          }).toList();

    final hasActiveFilters =
        _searchQuery.isNotEmpty || _filterOptions.hasFilter;

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
              onTap: () => _openContractDetail(contract),
            );
          },
          childCount: contracts.length,
        ),
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
    ).then((_) => _refresh());
  }

  void _openContractDetail(Contract contract) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailScreen(contractId: contract.id),
      ),
    ).then((_) => _refresh());
  }
}
