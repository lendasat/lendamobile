import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

class TimeChooserButton extends StatelessWidget {
  final String timeperiod;
  final String? timespan;
  final VoidCallback onPressed;

  const TimeChooserButton({
    super.key,
    required this.timeperiod,
    this.timespan,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = timespan == timeperiod;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 12,
            ),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      width: 1.5,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(12),
                    ),
                    color:
                        Theme.of(context).colorScheme.secondary.withAlpha(25),
                  )
                : null,
            child: Text(
              _getDisplayText(timeperiod),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153), // 0.6 opacity
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Convert internal timeframe keys to user-friendly display text
  String _getDisplayText(String timeframe) {
    switch (timeframe) {
      case '1J':
        return '1Y'; // Show "1Y" to user instead of internal "1J"
      default:
        return timeframe;
    }
  }
}

class CustomizableTimeChooser extends StatefulWidget {
  final List<String> timePeriods;
  final Function(String) onTimePeriodSelected;
  final String initialSelectedPeriod;
  final Widget Function(BuildContext, String, bool, VoidCallback) buttonBuilder;

  const CustomizableTimeChooser({
    super.key,
    required this.timePeriods,
    required this.onTimePeriodSelected,
    required this.initialSelectedPeriod,
    required this.buttonBuilder,
  });

  @override
  State<CustomizableTimeChooser> createState() =>
      _CustomizableTimeChooserState();
}

class _CustomizableTimeChooserState extends State<CustomizableTimeChooser> {
  late String selectedPeriod;

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.initialSelectedPeriod;
  }

  @override
  void didUpdateWidget(CustomizableTimeChooser oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with external changes
    if (widget.initialSelectedPeriod != oldWidget.initialSelectedPeriod) {
      selectedPeriod = widget.initialSelectedPeriod;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            widget.timePeriods.map((period) => _buildButton(period)).toList(),
      ),
    );
  }

  Widget _buildButton(String period) {
    return Expanded(
      child: widget.buttonBuilder(
        context,
        period,
        selectedPeriod == period,
        () => _handleButtonPress(period),
      ),
    );
  }

  void _handleButtonPress(String period) {
    // Update UI immediately
    setState(() {
      selectedPeriod = period;
    });
    // Call parent callback after UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTimePeriodSelected(period);
    });
  }
}
