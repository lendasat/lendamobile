import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/ui/screens/receive_screen.dart';
import 'package:ark_flutter/app_theme.dart';

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
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.enterAmount,
          style: TextStyle(color: theme.primaryWhite),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.secondaryBlack,
            height: 1.0,
          ),
        ),
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
                          color: theme.mutedText,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _amount.isEmpty ? '0' : _amount,
                        style: TextStyle(
                          color: theme.primaryWhite,
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: theme.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _amount.isEmpty
                          ? AppLocalizations.of(context)!.skipAnyAmount
                          : AppLocalizations.of(context)!.contin,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
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
    final theme = AppTheme.of(context);

    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed ?? () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.tertiaryBlack,
          foregroundColor: theme.primaryWhite,
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
