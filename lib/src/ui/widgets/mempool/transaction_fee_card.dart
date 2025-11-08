import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class TransactionFeeCard extends StatelessWidget {
  final RecommendedFees fees;

  const TransactionFeeCard({
    super.key,
    required this.fees,
  });

  @override
  Widget build(BuildContext context) {
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
                Icons.paid,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Transaction Fees',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildFeeRow('Fastest (~10 min)', fees.fastestFee, Colors.green),
          const SizedBox(height: 8.0),
          _buildFeeRow('Half Hour', fees.halfHourFee, Colors.blue),
          const SizedBox(height: 8.0),
          _buildFeeRow('One Hour', fees.hourFee, Colors.orange),
          const SizedBox(height: 8.0),
          _buildFeeRow('Economy', fees.economyFee, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, int feeRate, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: const TextStyle(
                color: const Color(0xFFC6C6C6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          '$feeRate sat/vB',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
