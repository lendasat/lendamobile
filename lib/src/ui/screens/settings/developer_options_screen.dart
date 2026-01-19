import 'package:ark_flutter/src/logger/hybrid_logger.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DeveloperOptionsScreen extends StatefulWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  State<DeveloperOptionsScreen> createState() => _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isExportingLogs = false;
  bool _isLoadingVtxoBalance = false;
  bool _isSettling = false;
  bool _isRecovering = false;

  // Environment info
  String _esploraUrl = '';
  String _arkServerUrl = '';
  String _arkNetwork = '';
  String _boltzUrl = '';
  String _backendUrl = '';
  String _websiteUrl = '';

  // VTXO Balance breakdown
  BigInt _pendingSats = BigInt.zero;
  BigInt _confirmedSats = BigInt.zero;
  BigInt _expiredSats = BigInt.zero;
  BigInt _recoverableSats = BigInt.zero;
  BigInt _totalSats = BigInt.zero;

  @override
  void initState() {
    super.initState();
    _loadEnvironmentInfo();
    _loadVtxoBalance();
  }

  Future<void> _loadVtxoBalance() async {
    if (_isLoadingVtxoBalance) return;
    setState(() => _isLoadingVtxoBalance = true);
    try {
      final balanceResult = await balance();
      debugPrint('VTXO Balance: pending=${balanceResult.offchain.pendingSats}, '
          'confirmed=${balanceResult.offchain.confirmedSats}, '
          'expired=${balanceResult.offchain.expiredSats}, '
          'recoverable=${balanceResult.offchain.recoverableSats}, '
          'total=${balanceResult.offchain.totalSats}');
      if (mounted) {
        setState(() {
          _pendingSats = balanceResult.offchain.pendingSats;
          _confirmedSats = balanceResult.offchain.confirmedSats;
          _expiredSats = balanceResult.offchain.expiredSats;
          _recoverableSats = balanceResult.offchain.recoverableSats;
          _totalSats = balanceResult.offchain.totalSats;
        });
      }
    } catch (e) {
      debugPrint('Error loading VTXO balance: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVtxoBalance = false);
      }
    }
  }

  Future<void> _manualSettle() async {
    if (_isSettling) return;
    setState(() => _isSettling = true);
    try {
      debugPrint('Manual settle triggered...');
      await settle();
      debugPrint('Manual settle completed!');
      // Refresh balance after settle
      await _loadVtxoBalance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settle completed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during manual settle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settle failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettling = false);
      }
    }
  }

  Future<void> _recoverSats() async {
    if (_isRecovering) return;

    final totalRecoverable = _recoverableSats + _expiredSats;
    if (totalRecoverable <= BigInt.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No recoverable sats found'),
          backgroundColor: AppTheme.colorBitcoin,
        ),
      );
      return;
    }

    setState(() => _isRecovering = true);
    try {
      debugPrint('Recovering $totalRecoverable sats...');
      await settle();
      debugPrint('Recovery completed!');
      // Refresh balance after recovery
      await _loadVtxoBalance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully recovered $totalRecoverable sats!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during recovery: $e');
      if (mounted) {
        final errorStr = e.toString();
        String userMessage;

        // Handle specific known errors
        if (errorStr.contains('INVALID_PSBT_INPUT') &&
            errorStr.contains('expires after')) {
          userMessage =
              'VTXOs not ready for recovery yet. They need to be closer to expiration.';
        } else if (errorStr.contains('minExpiryGap')) {
          userMessage =
              'VTXOs expire too far in the future. Wait until closer to expiration.';
        } else {
          userMessage = 'Recovery failed: $errorStr';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecovering = false);
      }
    }
  }

  Future<void> _loadEnvironmentInfo() async {
    final esploraUrl = await _settingsService.getEsploraUrl();
    final arkServerUrl = await _settingsService.getArkServerUrl();
    final arkNetwork = await _settingsService.getNetwork();
    final boltzUrl = await _settingsService.getBoltzUrl();
    final backendUrl = await _settingsService.getBackendUrl();
    final websiteUrl = await _settingsService.getWebsiteUrl();

    if (mounted) {
      setState(() {
        _esploraUrl = esploraUrl;
        _arkServerUrl = arkServerUrl;
        _arkNetwork = arkNetwork;
        _boltzUrl = boltzUrl;
        _backendUrl = backendUrl;
        _websiteUrl = websiteUrl;
      });
    }
  }

  Future<void> _exportLogs() async {
    setState(() => _isExportingLogs = true);
    try {
      final logFile = await HybridOutput.logFilePath();
      if (await logFile.exists()) {
        final fileSize = await logFile.length();
        final fileSizeKb = (fileSize / 1024).toStringAsFixed(1);

        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(logFile.path)],
          subject: 'Lenda App Logs',
          text: 'App logs (${fileSizeKb}KB) - Please attach to bug report',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 100),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No log file found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export logs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingLogs = false);
      }
    }
  }

  Widget _buildEnvInfoRow(String label, String value) {
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
              value.isEmpty ? '(not set)' : value,
              style: TextStyle(
                fontSize: 11,
                color: value.isEmpty
                    ? AppTheme.errorColor
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVtxoBalanceRow(String label, BigInt sats, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = sats > BigInt.zero;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              '$sats sats',
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                color: color ?? (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
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
        text: 'Developer Options',
        context: context,
        hasBackButton: true,
        onTap: () => controller.resetToMain(),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing * 0.25,
        ),
        child: ListView(
          children: [
            // Export Logs
            ArkListTile(
              leading: _isExportingLogs
                  ? SizedBox(
                      width: AppTheme.iconSize * 1.5,
                      height: AppTheme.iconSize * 1.5,
                      child: dotProgress(context, size: 14),
                    )
                  : RoundedButtonWidget(
                      iconData: Icons.description_outlined,
                      onTap: _exportLogs,
                      size: AppTheme.iconSize * 1.5,
                      buttonType: ButtonType.transparent,
                    ),
              text: 'Export Logs',
              trailing: Icon(
                Icons.share_rounded,
                size: AppTheme.iconSize * 0.75,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
              onTap: _isExportingLogs ? null : _exportLogs,
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Environment Info
            Container(
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
                    'Environment Info',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  _buildEnvInfoRow('ARK_NETWORK', _arkNetwork),
                  _buildEnvInfoRow('ARK_SERVER_URL', _arkServerUrl),
                  _buildEnvInfoRow('ESPLORA_URL', _esploraUrl),
                  _buildEnvInfoRow('BOLTZ_URL', _boltzUrl),
                  _buildEnvInfoRow('BACKEND_URL', _backendUrl),
                  _buildEnvInfoRow('WEBSITE_URL', _websiteUrl),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // VTXO Balance Breakdown
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VTXO Balance Breakdown',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: _loadVtxoBalance,
                        child: _isLoadingVtxoBalance
                            ? dotProgress(context, size: 14)
                            : Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: isDark
                                    ? AppTheme.white60
                                    : AppTheme.black60,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  _buildVtxoBalanceRow('Pending', _pendingSats),
                  _buildVtxoBalanceRow('Confirmed', _confirmedSats,
                      color: AppTheme.successColor),
                  _buildVtxoBalanceRow('Expired', _expiredSats,
                      color: _expiredSats > BigInt.zero
                          ? AppTheme.colorBitcoin
                          : null),
                  _buildVtxoBalanceRow('Recoverable', _recoverableSats,
                      color: _recoverableSats > BigInt.zero
                          ? AppTheme.colorBitcoin
                          : null),
                  const Divider(height: 12),
                  _buildVtxoBalanceRow('Total', _totalSats,
                      color: AppTheme.primaryColor),
                  if (_expiredSats > BigInt.zero ||
                      _recoverableSats > BigInt.zero ||
                      _pendingSats > BigInt.zero) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: Pending/Expired/Recoverable VTXOs can be consolidated via settle',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.colorBitcoin,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.elementSpacing),
                  // Recover Sats Button (only show when there are recoverable sats)
                  if (_recoverableSats > BigInt.zero ||
                      _expiredSats > BigInt.zero) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRecovering ? null : _recoverSats,
                        icon: _isRecovering
                            ? dotProgress(context, size: 14)
                            : const Icon(Icons.restore_rounded, size: 18),
                        label: Text(_isRecovering
                            ? 'Recovering...'
                            : 'Recover ${_recoverableSats + _expiredSats} sats'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.elementSpacing * 0.5),
                  ],
                  // Settle Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSettling ? null : _manualSettle,
                      icon: _isSettling
                          ? dotProgress(context, size: 14)
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(_isSettling ? 'Settling...' : 'Settle VTXOs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorBitcoin,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                      ),
                    ),
                  ),
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
