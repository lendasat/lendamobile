import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class MiningInfoCard extends StatelessWidget {
  final Block block;
  final Conversions? conversions;

  const MiningInfoCard({super.key, required this.block, this.conversions});

  String _formatTimestamp(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _formatReward(double rewardBtc) {
    if (conversions != null && conversions!.usd > 0) {
      final rewardUsd = rewardBtc * conversions!.usd;
      return '\$${rewardUsd.toStringAsFixed(2)} USD';
    }
    return '${rewardBtc.toStringAsFixed(8)} BTC';
  }

  @override
  Widget build(BuildContext context) {
    final pool = block.extras?.pool;
    final reward = block.extras?.reward;

    if (pool == null && reward == null) {
      return const SizedBox.shrink();
    }

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
                  Icons.architecture,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Mining Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          if (pool != null) ...[
            _buildInfoRow('Mining Pool', pool.name, Icons.groups),
            const SizedBox(height: 8.0),
          ],

          _buildInfoRow(
            'Mined',
            _formatTimestamp(block.timestamp),
            Icons.access_time,
          ),

          if (reward != null) ...[
            const SizedBox(height: 8.0),
            _buildInfoRow('Block Reward', _formatReward(reward), Icons.paid),
          ],

          if (block.extras?.totalFees != null) ...[
            const SizedBox(height: 8.0),
            _buildInfoRow(
              'Total Fees',
              '${(block.extras!.totalFees!.toInt() / 100000000).toStringAsFixed(8)} BTC',
              Icons.account_balance_wallet,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC6C6C6), size: 16),
        const SizedBox(width: 8.0),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: const Color(0xFFC6C6C6),
                  fontSize: 14,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
