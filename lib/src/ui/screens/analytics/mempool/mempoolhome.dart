import 'dart:async';

import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/api/mempool_ws.dart' as mempool_ws;
import 'package:ark_flutter/src/rust/api/mempool_block_tracker.dart'
    as block_tracker;
import 'package:ark_flutter/src/rust/models/mempool.dart'
    hide FearGreedData, FearGreedValue;
import 'package:ark_flutter/src/models/mempool_new/chartline.dart';
import 'package:ark_flutter/src/models/mempool_new/hash_chart_model.dart'
    as chart_models;
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/blocks_list_view.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/block_header.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/block_health_widget.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/block_size_widget.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/block_transactions_search.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/fee_distribution_widget.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/mining_info_card.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/transaction_fee_card.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/difficulty_adjustment_card.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/hashrate_card_optimized.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/fear_and_greed_card.dart';
import 'package:ark_flutter/src/ui/screens/analytics/mempool/fear_gear_chart_model.dart';
import 'package:ark_flutter/src/ui/screens/analytics/mempool/block_transactions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main mempool home screen displaying blockchain data
class MempoolHome extends StatefulWidget {
  final bool isFromHome;

  const MempoolHome({
    super.key,
    this.isFromHome = false,
  });

  @override
  State<MempoolHome> createState() => _MempoolHomeState();
}

class _MempoolHomeState extends State<MempoolHome> {
  // Controllers
  final ScrollController _scrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  // Loading states
  bool _isLoading = true;
  bool _socketLoading = true;
  bool _loadingDetail = false;
  bool _transactionLoading = true;
  bool _daLoading = true;
  bool _hashrateLoading = true;
  bool _fearGreedLoading = true;

  // Data
  List<MempoolBlock> _mempoolBlocks = [];
  List<Block> _confirmedBlocks = [];
  DifficultyAdjustment? _difficultyAdjustment;
  RecommendedFees? _fees;
  Block? _selectedBlock;
  double _currentUSD = 0;
  String? _days;

  // Selection state
  int _selectedMempoolIndex = -1;
  int _selectedConfirmedIndex = -1;
  bool _showMempoolBlockDetails = false;
  bool _showConfirmedBlockDetails = false;

  // Hashrate data
  List<ChartLine> _hashrateChartData = [];
  List<chart_models.Difficulty> _hashrateChartDifficulty = [];
  String _currentHashrate = '';
  String _hashrateChangePercentage = '';
  bool _hashrateIsPositive = true;
  String _selectedTimePeriod = '1M';

  // Fear & Greed data
  FearGearChartModel? _fearGreedData;

  // WebSocket subscription
  StreamSubscription<MempoolWsMessage>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listScrollController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  /// Initialize all data
  Future<void> _initializeData() async {
    await Future.wait([
      _loadBlocks(),
      _loadFees(),
      _loadDifficultyAdjustment(),
      _loadHashrateData(),
      _loadFearGreedData(),
    ]);

    _subscribeToMempoolUpdates();

    if (mounted) {
      setState(() {
        _socketLoading = false;
      });

      // Scroll to divider after a short delay so user can see both mempool and confirmed blocks
      Future.delayed(const Duration(seconds: 2), () {
        _scrollToDivider();
      });
    }
  }

  /// Scroll to the divider between mempool and confirmed blocks
  void _scrollToDivider() {
    if (!mounted || !_scrollController.hasClients) return;

    // Calculate scroll position based on mempool blocks count
    // Each block is approximately 140 pixels wide (cardPadding * 5.75 + margins)
    const blockWidth = AppTheme.cardPadding * 7;
    final scrollPosition = _mempoolBlocks.length * blockWidth;

    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Load confirmed blocks from Rust API
  Future<void> _loadBlocks() async {
    try {
      final blocks = await mempool_api.getBlocks();
      if (mounted) {
        setState(() {
          _confirmedBlocks = blocks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading blocks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load recommended fees
  Future<void> _loadFees() async {
    try {
      final fees = await mempool_api.getRecommendedFees();
      if (mounted) {
        setState(() {
          _fees = fees;
          _transactionLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading fees: $e');
      if (mounted) {
        setState(() {
          _transactionLoading = false;
        });
      }
    }
  }

  /// Load difficulty adjustment data
  Future<void> _loadDifficultyAdjustment() async {
    try {
      // Difficulty adjustment is included in websocket updates
      // For now, we'll wait for the websocket to provide it
      if (mounted) {
        setState(() {
          _daLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading difficulty adjustment: $e');
      if (mounted) {
        setState(() {
          _daLoading = false;
        });
      }
    }
  }

  /// Load hashrate data
  Future<void> _loadHashrateData([String period = '1M']) async {
    try {
      setState(() {
        _hashrateLoading = true;
        _selectedTimePeriod = period;
      });

      final data = await mempool_api.getHashrateData(period: period);

      if (mounted) {
        // Convert hashrate points to ChartLine
        final chartData = data.hashrates.map((point) {
          return ChartLine(
            time: point.timestamp.toDouble(),
            price: point.avgHashrate / 1e18, // Convert to EH/s
          );
        }).toList();

        // Convert difficulty points
        final difficultyData = data.difficulty.map((point) {
          return chart_models.Difficulty(
            time: point.timestamp?.toInt(),
            difficulty: point.difficulty,
            height: point.height?.toInt(),
          );
        }).toList();

        // Calculate current hashrate string with smart formatting
        String hashrateStr;
        if (chartData.isNotEmpty) {
          final hashrateValue = chartData.last.price;
          if (hashrateValue >= 1000) {
            // Convert to ZH/s with 1 decimal place
            hashrateStr = '${(hashrateValue / 1000).toStringAsFixed(1)} ZH/s';
          } else if (hashrateValue >= 100) {
            // Show without decimals for 3-digit values
            hashrateStr = '${hashrateValue.toInt()} EH/s';
          } else {
            // Show with 1 decimal for smaller values
            hashrateStr = '${hashrateValue.toStringAsFixed(1)} EH/s';
          }
        } else {
          final currentEH = (data.currentHashrate ?? 0) / 1e18;
          hashrateStr = '${currentEH.toStringAsFixed(2)} EH/s';
        }

        // Calculate change percentage - compare with point ~10 data points ago
        String changeStr = '';
        bool isPositive = true;
        if (chartData.length > 10) {
          final lastPoint = chartData.last;
          final previousPoint = chartData[chartData.length - 10];
          if (previousPoint.price > 0) {
            final change = (lastPoint.price - previousPoint.price) /
                previousPoint.price *
                100;
            isPositive = change >= 0;
            changeStr = '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%';
          }
        }

        setState(() {
          _hashrateChartData = chartData;
          _hashrateChartDifficulty = difficultyData;
          _currentHashrate = hashrateStr;
          _hashrateChangePercentage = changeStr;
          _hashrateIsPositive = isPositive;
          _hashrateLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hashrate data: $e');
      if (mounted) {
        setState(() {
          _hashrateLoading = false;
        });
      }
    }
  }

  // RapidAPI key from environment (injected via --dart-define)
  static const String _rapidApiKey = String.fromEnvironment('RAPIDAPI_KEY');

  /// Load Fear & Greed data from RapidAPI
  Future<void> _loadFearGreedData() async {
    try {
      if (_rapidApiKey.isEmpty) {
        debugPrint('RAPIDAPI_KEY not found');
        return;
      }
      final fgiResponse =
          await mempool_api.getFearGreedIndex(apiKey: _rapidApiKey);

      if (mounted) {
        setState(() {
          _fearGreedData = FearGearChartModel(
            lastUpdated: fgiResponse.lastUpdated != null
                ? LastUpdated(
                    epochUnixSeconds:
                        fgiResponse.lastUpdated!.epochUnixSeconds?.toInt(),
                    humanDate: fgiResponse.lastUpdated!.humanDate,
                  )
                : null,
            fgi: fgiResponse.fgi != null
                ? Fgi(
                    now: fgiResponse.fgi!.now != null
                        ? Now(
                            value: fgiResponse.fgi!.now!.value,
                            valueText: fgiResponse.fgi!.now!.valueText,
                          )
                        : null,
                    previousClose: fgiResponse.fgi!.previousClose != null
                        ? Now(
                            value: fgiResponse.fgi!.previousClose!.value,
                            valueText:
                                fgiResponse.fgi!.previousClose!.valueText,
                          )
                        : null,
                    oneWeekAgo: fgiResponse.fgi!.oneWeekAgo != null
                        ? Now(
                            value: fgiResponse.fgi!.oneWeekAgo!.value,
                            valueText: fgiResponse.fgi!.oneWeekAgo!.valueText,
                          )
                        : null,
                    oneMonthAgo: fgiResponse.fgi!.oneMonthAgo != null
                        ? Now(
                            value: fgiResponse.fgi!.oneMonthAgo!.value,
                            valueText: fgiResponse.fgi!.oneMonthAgo!.valueText,
                          )
                        : null,
                    oneYearAgo: fgiResponse.fgi!.oneYearAgo != null
                        ? Now(
                            value: fgiResponse.fgi!.oneYearAgo!.value,
                            valueText: fgiResponse.fgi!.oneYearAgo!.valueText,
                          )
                        : null,
                  )
                : null,
          );
          _fearGreedLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading fear & greed data: $e');
      if (mounted) {
        setState(() {
          // Set default neutral value on error
          _fearGreedData = FearGearChartModel(
            fgi: Fgi(
              now: Now(value: 50, valueText: 'Neutral'),
            ),
          );
          _fearGreedLoading = false;
        });
      }
    }
  }

  /// Subscribe to mempool websocket updates
  void _subscribeToMempoolUpdates() {
    mempool_ws.subscribeMempoolUpdates().listen((message) {
      if (!mounted) return;

      setState(() {
        // Update mempool blocks
        if (message.mempoolBlocks != null) {
          _mempoolBlocks = message.mempoolBlocks!;
        }

        // Update difficulty adjustment
        if (message.da != null) {
          _difficultyAdjustment = message.da;
          _calculateDays();
        }

        // Update conversions (USD price)
        if (message.conversions != null) {
          _currentUSD = message.conversions!.usd;
        }

        // Update recommended fees
        if (message.fees != null) {
          _fees = message.fees;
        }

        // Update confirmed blocks if available
        if (message.blocks != null && message.blocks!.isNotEmpty) {
          // Add new block to the beginning
          _confirmedBlocks.insert(0, message.blocks!.first);
          if (_confirmedBlocks.length > 15) {
            _confirmedBlocks.removeLast();
          }
        }
      });
    }, onError: (e) {
      debugPrint('WebSocket error: $e');
    });
  }

  /// Calculate days until next difficulty adjustment
  void _calculateDays() {
    if (_difficultyAdjustment == null) return;

    final remainingMs = _difficultyAdjustment!.remainingTime.toInt();
    final days = remainingMs / (1000 * 60 * 60 * 24);
    final hours = (remainingMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60);

    if (days >= 1) {
      _days = '${days.floor()} ${AppLocalizations.of(context)!.days}';
    } else {
      _days = '${hours.floor()} ${AppLocalizations.of(context)!.hours}';
    }
  }

  /// Format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${AppLocalizations.of(context)!.mAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${AppLocalizations.of(context)!.hAgo}';
    } else {
      return '${difference.inDays} ${AppLocalizations.of(context)!.dAgo}';
    }
  }

  /// Check if block contains user transactions
  bool _hasUserTxs(String blockHash) {
    // TODO: Implement user transaction lookup
    return false;
  }

  /// Handle mempool block tap
  void _onMempoolBlockTap(int index) {
    setState(() {
      _selectedMempoolIndex = index;
      _selectedConfirmedIndex = -1;
      _showMempoolBlockDetails = true;
      _showConfirmedBlockDetails = false;
    });

    // Track this mempool block
    block_tracker.trackMempoolBlock(blockIndex: index);
  }

  /// Handle confirmed block tap
  void _onConfirmedBlockTap(int index) async {
    setState(() {
      _selectedConfirmedIndex = index;
      _selectedMempoolIndex = -1;
      _showConfirmedBlockDetails = true;
      _showMempoolBlockDetails = false;
      _loadingDetail = true;
    });

    try {
      final block = _confirmedBlocks[index];
      debugPrint('Fetching block details for: ${block.id}');
      final blockDetails = await mempool_api.getBlockByHash(hash: block.id);
      debugPrint('Block extras: ${blockDetails.extras}');
      debugPrint('Pool: ${blockDetails.extras?.pool?.name}');
      debugPrint('Reward: ${blockDetails.extras?.reward}');
      debugPrint('Total fees: ${blockDetails.extras?.totalFees}');
      debugPrint('Median fee: ${blockDetails.extras?.medianFee}');

      if (mounted) {
        setState(() {
          _selectedBlock = blockDetails;
          _loadingDetail = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading block details: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _loadingDetail = false;
        });
      }
    }
  }

  /// Close block details
  void _closeBlockDetails() {
    setState(() {
      _showMempoolBlockDetails = false;
      _showConfirmedBlockDetails = false;
      _selectedMempoolIndex = -1;
      _selectedConfirmedIndex = -1;
      _selectedBlock = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timezoneService =
        Provider.of<TimezoneService>(context, listen: false);
    final loc = timezoneService.location;

    return PopScope(
      canPop: true,
      child: SafeArea(
        child: ArkScaffold(
          context: context,
          extendBodyBehindAppBar: false,
          appBar: widget.isFromHome
              ? const PreferredSize(
                  preferredSize: Size(0, 0),
                  child: SizedBox(),
                )
              : BitNetAppBar(
                  context: context,
                  text: AppLocalizations.of(context)!.blockchain,
                  onTap: () => Navigator.of(context).pop(),
                ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_socketLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: AppTheme.cardPadding * 15),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.colorBitcoin,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: AppTheme.cardPadding * 0.1),

                      // Blocks list view
                      BlocksListView(
                        scrollController: _scrollController,
                        isLoading: _isLoading,
                        hasUserTxs: _hasUserTxs,
                        mempoolBlocks: _mempoolBlocks,
                        confirmedBlocks: _confirmedBlocks,
                        difficultyAdjustment: _difficultyAdjustment,
                        selectedMempoolIndex: _selectedMempoolIndex,
                        selectedConfirmedIndex: _selectedConfirmedIndex,
                        currentUSD: _currentUSD,
                        formatTimeAgo: _formatTimeAgo,
                        onMempoolBlockTap: _onMempoolBlockTap,
                        onConfirmedBlockTap: _onConfirmedBlockTap,
                      ),

                      // Block details
                      if (_loadingDetail)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.colorBitcoin,
                          ),
                        )
                      else
                        Column(
                          children: [
                            // Mempool block details
                            _buildMempoolBlockDetails(context),

                            // Confirmed block details
                            _buildConfirmedBlockDetails(context, loc),
                          ],
                        ),

                      // Main content (when no block details shown)
                      _buildMainContent(context),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build mempool block details section
  Widget _buildMempoolBlockDetails(BuildContext context) {
    if (!_showMempoolBlockDetails || _selectedMempoolIndex < 0) {
      return const SizedBox.shrink();
    }

    final mempoolBlock = _mempoolBlocks[_selectedMempoolIndex];

    return Column(
      children: [
        // Header
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.cardPadding,
              bottom: AppTheme.elementSpacing,
            ),
            child: Row(
              children: [
                Text(
                  _selectedMempoolIndex == 0
                      ? 'Next Block'
                      : 'Mempool Block ${_selectedMempoolIndex + 1}',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _closeBlockDetails,
                  icon: const Icon(Icons.cancel),
                ),
              ],
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.cardPadding),

              // Fee distribution
              FeeDistributionWidget(
                medianFee: mempoolBlock.medianFee,
                totalFees: mempoolBlock.totalFees.toInt(),
                feeRange: [
                  mempoolBlock.feeRange.first,
                  mempoolBlock.feeRange.last
                ],
                currentUSD: _currentUSD,
              ),

              const SizedBox(height: AppTheme.elementSpacing),

              // Block size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BlockSizeWidget(
                    sizeInBytes: mempoolBlock.blockSize.toDouble(),
                    weightInBytes: mempoolBlock.blockVsize,
                    isAccepted: false,
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.cardPadding * 3),
            ],
          ),
        ),
      ],
    );
  }

  /// Build confirmed block details section
  Widget _buildConfirmedBlockDetails(BuildContext context, dynamic loc) {
    if (!_showConfirmedBlockDetails || _selectedBlock == null) {
      return const SizedBox.shrink();
    }

    final block = _selectedBlock!;

    return Column(
      children: [
        // Block header
        BlockHeader(
          blockHeight: block.height.toString(),
          blockId: block.id,
          onClose: _closeBlockDetails,
          onCopied: () {
            OverlayService()
                .showSuccess(AppLocalizations.of(context)!.copiedToClipboard);
          },
        ),

        // Transaction count search
        BlockTransactionsSearch(
          transactionCount: block.txCount,
          handleSearch: (query) => query,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlockTransactions(
                  isConfirmed: true,
                  blockHash: block.id,
                  txCount: block.txCount,
                ),
              ),
            );
          },
          isEnabled: true,
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.elementSpacing),

              // Mining info card
              MiningInfoCard(
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  block.timestamp.toInt() * 1000,
                ).toUtc().add(
                      Duration(milliseconds: loc.currentTimeZone.offset),
                    ),
                poolName: block.extras?.pool?.name ?? 'Unknown',
                rewardAmount: (block.extras?.reward?.toDouble() ?? 0) /
                    BitcoinConstants.satsPerBtc *
                    _currentUSD,
              ),

              const SizedBox(height: AppTheme.elementSpacing),

              // Fee distribution
              FeeDistributionWidget(
                medianFee: block.extras?.medianFee ?? 0,
                totalFees: block.extras?.totalFees?.toInt() ?? 0,
                feeRange: const [1, 100], // Default range
                currentUSD: _currentUSD,
              ),

              const SizedBox(height: AppTheme.elementSpacing),

              // Block size and health
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: BlockSizeWidget(
                        sizeInBytes: block.size.toDouble(),
                        weightInBytes: block.weight.toDouble(),
                        isAccepted: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: BlockHealthWidget(
                        matchRate: block.extras?.matchRate ?? 100.0,
                        isAccepted: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.cardPadding * 2.5),
      ],
    );
  }

  /// Build main content section
  Widget _buildMainContent(BuildContext context) {
    if (_showMempoolBlockDetails || _showConfirmedBlockDetails) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: AppTheme.cardPadding),

        // Transaction fees card
        TransactionFeeCard(
          fees: _fees,
          currentUSD: _currentUSD,
          isLoading: _transactionLoading,
        ),

        const SizedBox(height: AppTheme.cardPadding),

        // Difficulty adjustment card
        DifficultyAdjustmentCard(
          da: _difficultyAdjustment,
          days: _days,
          isLoading: _daLoading,
        ),

        const SizedBox(height: AppTheme.cardPadding),

        // Hashrate card
        HashrateCardOptimized(
          hashrateChartData: _hashrateChartData,
          isLoading: _hashrateLoading,
          currentHashrate: _currentHashrate,
          changePercentage: _hashrateChangePercentage,
          isPositive: _hashrateIsPositive,
        ),

        const SizedBox(height: AppTheme.cardPadding),

        // Fear & Greed card
        FearAndGreedCard(
          data: FearGreedData(
            currentValue: _fearGreedData?.fgi?.now?.value,
            valueText: _fearGreedData?.fgi?.now?.valueText,
            previousClose: _fearGreedData?.fgi?.previousClose?.value,
            oneWeekAgo: _fearGreedData?.fgi?.oneWeekAgo?.value,
            oneMonthAgo: _fearGreedData?.fgi?.oneMonthAgo?.value,
            formattedDate: _fearGreedData?.lastUpdated?.humanDate,
          ),
          isLoading: _fearGreedLoading,
        ),

        const SizedBox(height: AppTheme.cardPadding * 2),
      ],
    );
  }
}
