import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class DifficultyAdjustmentCard extends StatelessWidget {
  final DifficultyAdjustment difficultyAdjustment;

  const DifficultyAdjustmentCard({
    super.key,
    required this.difficultyAdjustment,
  });

  String _formatDate(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTimeRemaining(BigInt milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = difficultyAdjustment.progressPercent;
    final difficultyChange = difficultyAdjustment.difficultyChange;
    final isIncrease = difficultyChange >= 0;

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
              const Icon(
                Icons.bar_chart,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Difficulty Adjustment',
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
                    '${progressPercent.toStringAsFixed(1)}% complete',
                    style: const TextStyle(
                      color: const Color(0xFFC6C6C6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${isIncrease ? '+' : ''}${difficultyChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isIncrease ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  backgroundColor: const Color(0xFF0A0A0A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isIncrease ? Colors.green : Colors.red,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          _buildStatRow(
            'Remaining Blocks',
            '${difficultyAdjustment.remainingBlocks}',
          ),
          const SizedBox(height: 8.0),
          _buildStatRow(
            'Est. Time',
            _formatTimeRemaining(difficultyAdjustment.remainingTime),
          ),
          const SizedBox(height: 8.0),
          _buildStatRow(
            'Est. Date',
            _formatDate(difficultyAdjustment.estimatedRetargetDate),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: const Color(0xFFC6C6C6), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
