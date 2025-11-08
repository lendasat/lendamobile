import 'package:flutter/material.dart';

class BlockSizeWidget extends StatelessWidget {
  final BigInt sizeBytes;
  final BigInt weightUnits;
  final int txCount;

  const BlockSizeWidget({
    super.key,
    required this.sizeBytes,
    required this.weightUnits,
    required this.txCount,
  });

  String _formatSize(BigInt bytes) {
    final mb = bytes.toInt() / 1000000;
    if (mb >= 1) {
      return '${mb.toStringAsFixed(2)} MB';
    }
    final kb = bytes.toInt() / 1000;
    return '${kb.toStringAsFixed(2)} KB';
  }

  String _formatWeight(BigInt weight) {
    final mwu = weight.toInt() / 1000000;
    if (mwu >= 1) {
      return '${mwu.toStringAsFixed(2)} MWU';
    }
    final kwu = weight.toInt() / 1000;
    return '${kwu.toStringAsFixed(2)} KWU';
  }

  double _getFillPercentage() {
    const maxBlockSize = 4000000; // 4 MB in bytes
    final percentage = (sizeBytes.toInt() / maxBlockSize).clamp(0.0, 1.0);
    return percentage;
  }

  Color _getFillColor(double percentage) {
    if (percentage < 0.5) {
      return const Color(0xFF4CAF50);
    } else if (percentage < 0.8) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFFFF5252);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = _getFillPercentage();
    final fillColor = _getFillColor(fillPercentage);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.data_usage,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Block Size',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatSize(sizeBytes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(fillPercentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: fillColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fillPercentage,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              fillColor,
                              fillColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Weight', _formatWeight(weightUnits)),
              _buildStatItem('Transactions', txCount.toString()),
              _buildStatItem(
                'Avg Size',
                '${(sizeBytes.toInt() / txCount / 1000).toStringAsFixed(2)} KB',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: const Color(0xFFC6C6C6), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
