import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:flutter/material.dart';

/// Debug screen for viewing websocket data
class ViewSockets extends StatelessWidget {
  const ViewSockets({
    super.key,
    required this.socketsData,
  });

  final List<String> socketsData;

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: 'Socket Data',
        onTap: () => Navigator.pop(context),
      ),
      body: socketsData.isEmpty
          ? const Center(
              child: Text('No socket data available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: AppTheme.cardPadding * 3,
                left: AppTheme.cardPadding,
                right: AppTheme.cardPadding,
              ),
              itemCount: socketsData.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SelectableText(
                  '${socketsData[index]}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
    );
  }
}
