import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class HashrateCard extends StatelessWidget {
  final HashrateData hashrateData;

  const HashrateCard({super.key, required this.hashrateData});

  String _formatHashrate(double hashrate) {
    final eh = hashrate / 1000000000000000000;
    return '${eh.toStringAsFixed(2)} EH/s';
  }

  String _formatDifficulty(double difficulty) {
    return '${(difficulty / 1000000000000).toStringAsFixed(2)}T';
  }

  @override
  Widget build(BuildContext context) {
    final currentHashrate = hashrateData.currentHashrate ?? 0.0;
    final currentDifficulty = hashrateData.currentDifficulty ?? 0.0;

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
              const Icon(Icons.speed, color: Colors.white, size: 20),
              const SizedBox(width: 8.0),
              const Text(
                'Network Hashrate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          Center(
            child: Column(
              children: [
                Text(
                  _formatHashrate(currentHashrate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Current Network Hashrate',
                  style: TextStyle(color: const Color(0xFFC6C6C6), fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          _buildStatRow('Difficulty', _formatDifficulty(currentDifficulty)),

          const SizedBox(height: 8.0),

          _buildStatRow('Data Points', '${hashrateData.hashrates.length}'),
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
