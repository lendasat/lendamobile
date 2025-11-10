import 'package:flutter/material.dart';

class BlockHealthWidget extends StatelessWidget {
  final int actualTxCount;
  final int expectedTxCount;
  final BigInt timestamp;

  const BlockHealthWidget({
    super.key,
    required this.actualTxCount,
    required this.expectedTxCount,
    required this.timestamp,
  });

  double _calculateHealthScore() {
    final ratio = actualTxCount / expectedTxCount;

    if (ratio >= 1.0) {
      return 100.0;
    }

    return (ratio * 100).clamp(0.0, 100.0);
  }

  Color _getHealthColor(double score) {
    if (score >= 80) {
      return const Color(0xFF4CAF50);
    } else if (score >= 50) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFFFF5252);
    }
  }

  String _getHealthLabel(double score) {
    if (score >= 80) {
      return 'Healthy';
    } else if (score >= 50) {
      return 'Fair';
    } else {
      return 'Low';
    }
  }

  IconData _getHealthIcon(double score) {
    if (score >= 80) {
      return Icons.check_circle;
    } else if (score >= 50) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthScore = _calculateHealthScore();
    final healthColor = _getHealthColor(healthScore);
    final healthLabel = _getHealthLabel(healthScore);
    final healthIcon = _getHealthIcon(healthScore);

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
                  Icons.favorite,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Block Health',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(healthIcon, color: healthColor, size: 32),
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        healthLabel,
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${healthScore.toStringAsFixed(0)}% Full',
                        style: const TextStyle(
                          color: const Color(0xFFC6C6C6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFF0A0A0A),
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      ),
                    ),
                    Text(
                      healthScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: healthColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Actual',
                  actualTxCount.toString(),
                  Colors.white,
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                _buildStatColumn(
                  'Expected',
                  '~$expectedTxCount',
                  const Color(0xFFC6C6C6),
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                _buildStatColumn(
                  'Difference',
                  actualTxCount >= expectedTxCount
                      ? '+${actualTxCount - expectedTxCount}'
                      : '${actualTxCount - expectedTxCount}',
                  actualTxCount >= expectedTxCount
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: const Color(0xFFC6C6C6), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
