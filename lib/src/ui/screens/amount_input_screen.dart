import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/receivescreen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:flutter/material.dart';

class AmountInputScreen extends StatefulWidget {
  final String aspId;

  const AmountInputScreen({
    super.key,
    required this.aspId,
  });

  @override
  AmountInputScreenState createState() => AmountInputScreenState();
}

class AmountInputScreenState extends State<AmountInputScreen> {
  String _amount = '';

  void _onNumberPressed(String number) {
    setState(() {
      _amount += number;
    });
  }

  void _onDeletePressed() {
    if (_amount.isNotEmpty) {
      setState(() {
        _amount = _amount.substring(0, _amount.length - 1);
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _amount = '';
    });
  }

  void _onContinue() {
    final amount = _amount.isEmpty ? 0 : int.tryParse(_amount) ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiveScreen(
          aspId: widget.aspId,
          amount: amount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BitNetAppBar(
        context: context,
        text: AppLocalizations.of(context)!.enterAmount,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Amount display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.amount} (sats)',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _amount.isEmpty ? '0' : _amount,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Number pad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildNumberRow(['1', '2', '3']),
                      const SizedBox(height: 12),
                      _buildNumberRow(['4', '5', '6']),
                      const SizedBox(height: 12),
                      _buildNumberRow(['7', '8', '9']),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('C', onPressed: _onClearPressed),
                          _buildNumberButton('0'),
                          _buildNumberButton('⌫', onPressed: _onDeletePressed),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LongButtonWidget(
              title: _amount.isEmpty
                  ? AppLocalizations.of(context)!.skipAnyAmount
                  : AppLocalizations.of(context)!.contin,
              customWidth: double.infinity,
              customHeight: 56,
              onTap: _onContinue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildNumberButton(String number, {VoidCallback? onPressed}) {
    

    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed ?? () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
