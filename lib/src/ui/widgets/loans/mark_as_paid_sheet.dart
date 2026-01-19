import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet for marking an installment as paid with transaction ID.
/// Allows user to select an installment and enter the payment transaction ID.
class MarkAsPaidSheet extends StatefulWidget {
  final List<Installment> unpaidInstallments;
  final String Function(String) formatDate;
  final Future<void> Function(Installment installment, String txid) onConfirm;

  const MarkAsPaidSheet({
    super.key,
    required this.unpaidInstallments,
    required this.formatDate,
    required this.onConfirm,
  });

  @override
  State<MarkAsPaidSheet> createState() => _MarkAsPaidSheetState();
}

class _MarkAsPaidSheetState extends State<MarkAsPaidSheet> {
  late Installment _selectedInstallment;
  final TextEditingController _txidController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _selectedInstallment = widget.unpaidInstallments.first;
  }

  @override
  void dispose() {
    _txidController.dispose();
    super.dispose();
  }

  void _onTxidChanged(String value) {
    setState(() {
      _isValid = value.trim().isNotEmpty;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _txidController.text = data!.text!.trim();
      _onTxidChanged(_txidController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Confirm Payment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Info text
          Text(
            'Enter the transaction ID of your payment to confirm repayment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Installment selector (if multiple)
          if (widget.unpaidInstallments.length > 1) ...[
            Text(
              'SELECT INSTALLMENT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<Installment>(
                  value: _selectedInstallment,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: widget.unpaidInstallments.map((i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        '\$${i.totalPayment.toStringAsFixed(2)} - Due ${widget.formatDate(i.dueDate)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedInstallment = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ] else ...[
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${_selectedInstallment.totalPayment.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Due ${widget.formatDate(_selectedInstallment.dueDate)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDarkMode
                                          ? AppTheme.white60
                                          : AppTheme.black60,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ],

          // Transaction ID input
          Text(
            'TRANSACTION ID',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 8),
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _txidController,
                      onChanged: _onTxidChanged,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter transaction ID or hash',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  // Paste button
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    icon: Icon(
                      Icons.paste_rounded,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      size: 20,
                    ),
                    tooltip: 'Paste',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Confirm button
          LongButtonWidget(
            title: 'Confirm Payment',
            customWidth: double.infinity,
            state: _isValid ? ButtonState.idle : ButtonState.disabled,
            onTap: _isValid
                ? () => widget.onConfirm(
                      _selectedInstallment,
                      _txidController.text.trim(),
                    )
                : null,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
        ],
      ),
    );
  }
}
