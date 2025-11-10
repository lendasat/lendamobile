import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;

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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: const Color(0xFF585858),
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatSats(int sats) {
    final btc = sats / 100000000;
    return '${btc.toStringAsFixed(8)} BTC';
  }

  Widget _buildSection(String title, Widget child) {
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
            style: const TextStyle(
              color: Colors.white,
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

  Widget _buildInfoCard(List<Map<String, String>> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children:
            items
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
                            color: const Color(0xFFC6C6C6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          child: Text(
                            item['value']!,
                            style: TextStyle(
                              color:
                                  item['highlight'] == 'true'
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white,
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
  ) {
    final items =
        type == 'inputs'
            ? (inputs ?? []).asMap().entries.map((entry) {
              final i = entry.key;
              final input = entry.value;
              return {
                'index': i.toString(),
                'address': input.prevout?.scriptpubkeyAddress ?? 'Unknown',
                'amount':
                    input.prevout?.value != null
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder:
            (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.1)),
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
                        color: const Color(0xFFC6C6C6),
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
                  onTap: () => _copyToClipboard(item['address']!),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['address']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        Icons.copy,
                        size: 16,
                        color: const Color(0xFFC6C6C6),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
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
                        'Error loading transaction',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: const Color(0xFFC6C6C6),
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
                      'Transaction ID',
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.txid,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _copyToClipboard(widget.txid),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _buildSection(
                      'Status',
                      _buildInfoCard([
                        {
                          'label': 'Confirmed',
                          'value':
                              _transaction!.status.confirmed
                                  ? 'Yes'
                                  : 'Pending',
                          'highlight':
                              _transaction!.status.confirmed.toString(),
                        },
                        if (_transaction!.status.blockHeight != null)
                          {
                            'label': 'Block Height',
                            'value':
                                _transaction!.status.blockHeight.toString(),
                          },
                        if (_transaction!.status.blockTime != null)
                          {
                            'label': 'Block Time',
                            'value':
                                DateTime.fromMillisecondsSinceEpoch(
                                  _transaction!.status.blockTime!.toInt() *
                                      1000,
                                ).toLocal().toString().split('.')[0],
                          },
                      ]),
                    ),

                    _buildSection(
                      'Details',
                      _buildInfoCard([
                        {
                          'label': 'Fee',
                          'value': _formatSats(_transaction!.fee.toInt()),
                        },
                        {
                          'label': 'Size',
                          'value': '${_transaction!.size} bytes',
                        },
                        {
                          'label': 'Weight',
                          'value': '${_transaction!.weight} WU',
                        },
                        {
                          'label': 'Version',
                          'value': _transaction!.version.toString(),
                        },
                        {
                          'label': 'Locktime',
                          'value': _transaction!.locktime.toString(),
                        },
                      ]),
                    ),

                    _buildSection(
                      'Inputs (${_transaction!.vin.length})',
                      _buildInputOutput('inputs', _transaction!.vin, null),
                    ),

                    _buildSection(
                      'Outputs (${_transaction!.vout.length})',
                      _buildInputOutput('outputs', null, _transaction!.vout),
                    ),

                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
    );
  }
}
