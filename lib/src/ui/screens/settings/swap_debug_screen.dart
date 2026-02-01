import 'package:ark_flutter/src/rust/api/lendaswap_api.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SwapDebugScreen extends StatefulWidget {
  const SwapDebugScreen({super.key});

  @override
  State<SwapDebugScreen> createState() => _SwapDebugScreenState();
}

class _LogEntry {
  final DateTime timestamp;
  final String message;
  final bool isError;

  _LogEntry({
    required this.timestamp,
    required this.message,
    this.isError = false,
  });
}

class _SwapDebugScreenState extends State<SwapDebugScreen> {
  final SettingsService _settingsService = SettingsService();
  final LendaSwapService _swapService = LendaSwapService();
  final TextEditingController _swapIdController = TextEditingController();
  final List<_LogEntry> _logs = [];

  // Service status
  bool _rustInitialized = false;
  String _configApiUrl = '';
  String _configArkadeUrl = '';
  String _configNetwork = '';

  // Loading states
  bool _isListingSwaps = false;
  bool _isRecovering = false;
  bool _isClearingAndRecovering = false;
  bool _isGettingSwap = false;
  bool _isReinitializing = false;
  bool _isHealthChecking = false;

  @override
  void initState() {
    super.initState();
    _loadServiceStatus();
  }

  @override
  void dispose() {
    _swapIdController.dispose();
    super.dispose();
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _logs.insert(
        0,
        _LogEntry(
          timestamp: DateTime.now(),
          message: message,
          isError: isError,
        ),
      );
    });
  }

  Future<void> _loadServiceStatus() async {
    try {
      _rustInitialized = lendaswapIsInitialized();
    } catch (e) {
      _rustInitialized = false;
    }

    final network = await _settingsService.getNetwork();
    final mappedNetwork = _mapNetwork(network);

    if (mounted) {
      setState(() {
        _configNetwork = mappedNetwork;
        _configApiUrl = _getApiUrl(mappedNetwork);
        _configArkadeUrl = _getArkadeUrl(mappedNetwork);
      });
    }
  }

  String _mapNetwork(String network) {
    switch (network.toLowerCase()) {
      case 'mainnet':
      case 'bitcoin':
        return 'bitcoin';
      case 'testnet':
      case 'testnet3':
        return 'testnet';
      case 'regtest':
        return 'regtest';
      default:
        return 'bitcoin';
    }
  }

  String _getApiUrl(String network) {
    switch (network) {
      case 'bitcoin':
        return 'https://apilendaswap.lendasat.com';
      case 'testnet':
        return 'https://apilendaswap.lendasat.com';
      default:
        return 'https://apilendaswap.lendasat.com';
    }
  }

  String _getArkadeUrl(String network) {
    switch (network) {
      case 'bitcoin':
        return 'https://arkade.computer';
      case 'testnet':
        return 'https://testnet.arkade.computer';
      default:
        return 'https://arkade.computer';
    }
  }

  Future<void> _listSwaps() async {
    if (_isListingSwaps) return;
    setState(() => _isListingSwaps = true);
    try {
      _addLog('Calling lendaswapListSwaps() directly...');
      final swaps = await lendaswapListSwaps();
      final buf = StringBuffer('List Swaps: ${swaps.length} found\n');
      for (final s in swaps) {
        buf.writeln(
          '  [${s.id}] status=${s.status.name}, '
          'direction=${s.direction}, '
          'detailed=${s.detailedStatus}, '
          'src=${s.sourceAmountSats} sats, '
          'tgt=\$${s.targetAmountUsd.toStringAsFixed(2)}',
        );
      }
      _addLog(buf.toString());
    } catch (e, st) {
      _addLog('List Swaps FAILED:\n$e\n\nStackTrace:\n$st', isError: true);
    } finally {
      if (mounted) setState(() => _isListingSwaps = false);
    }
  }

  Future<void> _recoverSwaps() async {
    if (_isRecovering) return;
    setState(() => _isRecovering = true);
    try {
      _addLog('Calling lendaswapRecoverSwaps() directly...');
      final swaps = await lendaswapRecoverSwaps();
      final buf = StringBuffer('Recover Swaps: ${swaps.length} recovered\n');
      for (final s in swaps) {
        buf.writeln(
          '  [${s.id}] status=${s.status.name}, '
          'direction=${s.direction}, '
          'detailed=${s.detailedStatus}',
        );
      }
      _addLog(buf.toString());
    } catch (e, st) {
      _addLog('Recover Swaps FAILED:\n$e\n\nStackTrace:\n$st', isError: true);
    } finally {
      if (mounted) setState(() => _isRecovering = false);
    }
  }

  Future<void> _clearAndRecover() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear & Recover'),
        content: const Text(
          'This will delete all local swap data and re-download from the server. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Clear & Recover',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (_isClearingAndRecovering) return;
    setState(() => _isClearingAndRecovering = true);
    try {
      _addLog('Calling lendaswapClearAndRecover() directly...');
      final swaps = await lendaswapClearAndRecover();
      _addLog('Clear & Recover: ${swaps.length} swaps recovered');
    } catch (e, st) {
      _addLog('Clear & Recover FAILED:\n$e\n\nStackTrace:\n$st', isError: true);
    } finally {
      if (mounted) setState(() => _isClearingAndRecovering = false);
    }
  }

  Future<void> _getSwap() async {
    final swapId = _swapIdController.text.trim();
    if (swapId.isEmpty) {
      _addLog('Get Swap: please enter a swap ID', isError: true);
      return;
    }
    if (_isGettingSwap) return;
    setState(() => _isGettingSwap = true);
    try {
      _addLog('Calling lendaswapGetSwap(swapId: $swapId)...');
      final s = await lendaswapGetSwap(swapId: swapId);
      final buf = StringBuffer('Get Swap result:\n');
      buf.writeln('  id: ${s.id}');
      buf.writeln('  status: ${s.status.name}');
      buf.writeln('  direction: ${s.direction}');
      buf.writeln('  detailedStatus: ${s.detailedStatus}');
      buf.writeln('  sourceToken: ${s.sourceToken}');
      buf.writeln('  targetToken: ${s.targetToken}');
      buf.writeln('  sourceAmountSats: ${s.sourceAmountSats}');
      buf.writeln('  targetAmountUsd: ${s.targetAmountUsd}');
      buf.writeln('  feeSats: ${s.feeSats}');
      buf.writeln('  createdAt: ${s.createdAt}');
      buf.writeln('  canClaimGelato: ${s.canClaimGelato}');
      buf.writeln('  canClaimVhtlc: ${s.canClaimVhtlc}');
      buf.writeln('  canRefund: ${s.canRefund}');
      buf.writeln('  lnInvoice: ${s.lnInvoice ?? "(null)"}');
      buf.writeln('  arkadeHtlcAddress: ${s.arkadeHtlcAddress ?? "(null)"}');
      buf.writeln('  evmHtlcAddress: ${s.evmHtlcAddress ?? "(null)"}');
      buf.writeln('  evmHtlcClaimTxid: ${s.evmHtlcClaimTxid ?? "(null)"}');
      buf.writeln('  refundLocktime: ${s.refundLocktime ?? "(null)"}');
      _addLog(buf.toString());
    } catch (e, st) {
      _addLog('Get Swap FAILED:\n$e\n\nStackTrace:\n$st', isError: true);
    } finally {
      if (mounted) setState(() => _isGettingSwap = false);
    }
  }

  Future<void> _reinitializeSdk() async {
    if (_isReinitializing) return;
    setState(() => _isReinitializing = true);
    try {
      _addLog('Resetting LendaSwapService...');
      _swapService.reset();
      _addLog('Calling LendaSwapService.initialize()...');
      await _swapService.initialize();
      _addLog(
        'Re-initialize SUCCESS. '
        'isInitialized=${_swapService.isInitialized}, '
        'swaps=${_swapService.swaps.length}, '
        'pairs=${_swapService.tradingPairs.length}',
      );
      await _loadServiceStatus();
    } catch (e, st) {
      _addLog('Re-initialize FAILED:\n$e\n\nStackTrace:\n$st', isError: true);
    } finally {
      if (mounted) setState(() => _isReinitializing = false);
    }
  }

  Future<void> _apiHealthCheck() async {
    if (_isHealthChecking) return;
    setState(() => _isHealthChecking = true);
    try {
      _addLog('Calling lendaswapGetAssetPairs() as health check...');
      final pairs = await lendaswapGetAssetPairs();
      final buf = StringBuffer('API Health: OK - ${pairs.length} pairs\n');
      for (final p in pairs) {
        buf.writeln(
          '  ${p.source.symbol} (${p.source.chain}) -> '
          '${p.target.symbol} (${p.target.chain})',
        );
      }
      _addLog(buf.toString());
    } catch (e, st) {
      _addLog('API Health FAILED:\n$e\n\nStackTrace:\n$st', isError: true);
    } finally {
      if (mounted) setState(() => _isHealthChecking = false);
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: valueColor ?? (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding * 0.5,
      ),
      padding: const EdgeInsets.all(AppTheme.elementSpacing),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required bool isLoading,
    IconData icon = Icons.play_arrow_rounded,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: LongButtonWidget(
        title: label,
        customWidth: double.infinity,
        customHeight: 44,
        buttonType: ButtonType.outlined,
        state: isLoading ? ButtonState.loading : ButtonState.idle,
        leadingIcon: isLoading
            ? null
            : Icon(icon, size: 18, color: color ?? Colors.white),
        onTap: isLoading ? () {} : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffoldUnsafe(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        text: 'Swap Debug',
        context: context,
        hasBackButton: true,
        onTap: () => controller.switchTab('developer_options'),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing * 0.25,
        ),
        child: ListView(
          children: [
            // Service Status
            _buildSection(
              title: 'Service Status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Service init',
                    _swapService.isInitialized ? 'YES' : 'NO',
                    valueColor: _swapService.isInitialized
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                  _buildInfoRow(
                    'Initializing',
                    _swapService.isInitializing ? 'YES' : 'NO',
                  ),
                  _buildInfoRow(
                    'Rust init',
                    _rustInitialized ? 'YES' : 'NO',
                    valueColor: _rustInitialized
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                  _buildInfoRow(
                    'Swap count',
                    '${_swapService.swaps.length}',
                  ),
                  _buildInfoRow(
                    'Pair count',
                    '${_swapService.tradingPairs.length}',
                  ),
                  const Divider(height: 12),
                  _buildInfoRow('Network', _configNetwork),
                  _buildInfoRow('API URL', _configApiUrl),
                  _buildInfoRow('Arkade URL', _configArkadeUrl),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // List Swaps (Local)
            _buildSection(
              title: 'List Swaps (Local)',
              child: _buildActionButton(
                label: 'List Swaps',
                onTap: _listSwaps,
                isLoading: _isListingSwaps,
                icon: Icons.list_rounded,
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Recover Swaps (Server)
            _buildSection(
              title: 'Recover Swaps (Server)',
              child: _buildActionButton(
                label: 'Recover Swaps',
                onTap: _recoverSwaps,
                isLoading: _isRecovering,
                icon: Icons.cloud_download_rounded,
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Clear & Recover
            _buildSection(
              title: 'Clear & Recover (Nuclear)',
              child: _buildActionButton(
                label: 'Clear & Recover',
                onTap: _clearAndRecover,
                isLoading: _isClearingAndRecovering,
                icon: Icons.delete_sweep_rounded,
                color: AppTheme.errorColor,
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Get Single Swap
            _buildSection(
              title: 'Get Single Swap',
              child: Column(
                children: [
                  TextField(
                    controller: _swapIdController,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter swap ID...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.white60 : AppTheme.black60,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste_rounded, size: 18),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _swapIdController.text = data!.text!;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    label: 'Get Swap',
                    onTap: _getSwap,
                    isLoading: _isGettingSwap,
                    icon: Icons.search_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Re-initialize SDK
            _buildSection(
              title: 'Re-initialize SDK',
              child: _buildActionButton(
                label: 'Reset & Re-initialize',
                onTap: _reinitializeSdk,
                isLoading: _isReinitializing,
                icon: Icons.refresh_rounded,
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // API Health Check
            _buildSection(
              title: 'API Health Check',
              child: _buildActionButton(
                label: 'Check API',
                onTap: _apiHealthCheck,
                isLoading: _isHealthChecking,
                icon: Icons.health_and_safety_rounded,
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Log Output
            _buildSection(
              title: 'Log Output (${_logs.length})',
              child: Column(
                children: [
                  if (_logs.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          final allText = _logs
                              .map((l) =>
                                  '[${l.timestamp.hour.toString().padLeft(2, '0')}:'
                                  '${l.timestamp.minute.toString().padLeft(2, '0')}:'
                                  '${l.timestamp.second.toString().padLeft(2, '0')}] '
                                  '${l.message}')
                              .join('\n\n');
                          Clipboard.setData(ClipboardData(text: allText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logs copied to clipboard'),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: isDark
                                    ? AppTheme.white60
                                    : AppTheme.black60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copy all',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppTheme.white60
                                      : AppTheme.black60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_logs.isEmpty)
                    Text(
                      'No log entries yet. Run an operation above.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ),
                  ..._logs.map((entry) {
                    final timeStr =
                        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                        '${entry.timestamp.second.toString().padLeft(2, '0')}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: entry.isError
                            ? AppTheme.errorColor.withValues(alpha: 0.1)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.03)),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                        border: Border.all(
                          color: entry.isError
                              ? AppTheme.errorColor.withValues(alpha: 0.3)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                              color:
                                  isDark ? AppTheme.white60 : AppTheme.black60,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            entry.message,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: entry.isError
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }
}
