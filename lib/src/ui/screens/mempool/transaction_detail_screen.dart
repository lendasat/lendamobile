import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String txid;

  const TransactionDetailScreen({super.key, required this.txid});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  BitcoinTransaction? _transaction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction = await rust_api.getTransaction(txid: widget.txid);
      if (mounted) {
        setState(() {
          _transaction = transaction;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading transaction: $e');
    }
  }

  void _copyToClipboard(String text, AppTheme theme) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.tertiaryBlack,
        content: Text(AppLocalizations.of(context)!.copiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatSats(int sats) {
    final btc = sats / 100000000;
    return '${btc.toStringAsFixed(8)} BTC';
  }

  Widget _buildSection(String title, Widget child, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: theme.primaryWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child,
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildInfoCard(List<Map<String, String>> items, AppTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBlack,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.primaryWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label']!,
                      style: TextStyle(
                        color: theme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        item['value']!,
                        style: TextStyle(
                          color: item['highlight'] == 'true'
                              ? const Color(0xFF4CAF50)
                              : theme.primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputOutput(
    String type,
    List<TxInput>? inputs,
    List<TxOutput>? outputs,
    AppTheme theme,
  ) {
    final items = type == 'inputs'
        ? (inputs ?? []).asMap().entries.map((entry) {
            final i = entry.key;
            final input = entry.value;
            return {
              'index': i.toString(),
              'address': input.prevout?.scriptpubkeyAddress ?? 'Unknown',
              'amount': input.prevout?.value != null
                  ? _formatSats(input.prevout!.value.toInt())
                  : 'Unknown',
            };
          }).toList()
        : (outputs ?? []).asMap().entries.map((entry) {
            final i = entry.key;
            final output = entry.value;
            return {
              'index': i.toString(),
              'address': output.scriptpubkeyAddress ?? 'Unknown',
              'amount': _formatSats(output.value.toInt()),
            };
          }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBlack,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.primaryWhite.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
            height: 1, color: theme.primaryWhite.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${type == 'inputs' ? 'Input' : 'Output'} #${item['index']}',
                      style: TextStyle(
                        color: theme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item['amount']!,
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                GestureDetector(
                  onTap: () => _copyToClipboard(item['address']!, theme),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['address']!,
                          style: TextStyle(
                            color: theme.primaryWhite,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: theme.mutedText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: theme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.transactionDetails,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          AppLocalizations.of(context)!.errorLoadingTransaction,
                          style: TextStyle(
                            color: theme.primaryWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: theme.mutedText,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16.0),
                      _buildSection(
                        AppLocalizations.of(context)!.transactionId,
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.secondaryBlack,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                                color:
                                    theme.primaryWhite.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.txid,
                                  style: TextStyle(
                                    color: theme.primaryWhite,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  color: theme.primaryWhite,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _copyToClipboard(widget.txid, theme),
                              ),
                            ],
                          ),
                        ),
                        theme,
                      ),
                      _buildSection(
                        AppLocalizations.of(context)!.status,
                        _buildInfoCard([
                          {
                            'label': AppLocalizations.of(context)!.confirmed,
                            'value': _transaction!.status.confirmed
                                ? 'Yes'
                                : 'Pending',
                            'highlight':
                                _transaction!.status.confirmed.toString(),
                          },
                          if (_transaction!.status.blockHeight != null)
                            {
                              'label':
                                  AppLocalizations.of(context)!.blockHeight,
                              'value':
                                  _transaction!.status.blockHeight.toString(),
                            },
                          if (_transaction!.status.blockTime != null)
                            {
                              'label': AppLocalizations.of(context)!.blockTime,
                              'value': context
                                  .watch<TimezoneService>()
                                  .toSelectedTimezone(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      _transaction!.status.blockTime!.toInt() *
                                          1000,
                                      isUtc: true,
                                    ),
                                  )
                                  .toString()
                                  .split('.')[0],
                            },
                        ], theme),
                        theme,
                      ),
                      _buildSection(
                        AppLocalizations.of(context)!.details,
                        _buildInfoCard([
                          {
                            'label': AppLocalizations.of(context)!.fee,
                            'value': _formatSats(_transaction!.fee.toInt()),
                          },
                          {
                            'label': AppLocalizations.of(context)!.size,
                            'value': '${_transaction!.size} bytes',
                          },
                          {
                            'label': AppLocalizations.of(context)!.weight,
                            'value': '${_transaction!.weight} WU',
                          },
                          {
                            'label': AppLocalizations.of(context)!.version,
                            'value': _transaction!.version.toString(),
                          },
                          {
                            'label': AppLocalizations.of(context)!.locktime,
                            'value': _transaction!.locktime.toString(),
                          },
                        ], theme),
                        theme,
                      ),
                      _buildSection(
                        '${AppLocalizations.of(context)!.inputs} (${_transaction!.vin.length})',
                        _buildInputOutput(
                            'inputs', _transaction!.vin, null, theme),
                        theme,
                      ),
                      _buildSection(
                        '${AppLocalizations.of(context)!.outputs} (${_transaction!.vout.length})',
                        _buildInputOutput(
                            'outputs', null, _transaction!.vout, theme),
                        theme,
                      ),
                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
    );
  }
}
