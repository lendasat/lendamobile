import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  // Focus nodes for the editable cards
  final FocusNode onchainFocusNode = FocusNode();
  final FocusNode lightningFocusNode = FocusNode();

  // Card type tracking
  CardType topCardType = CardType.onchain;
  CardType bottomCardType = CardType.lightning;

  // Direction: true = onchain->lightning (loop in), false = lightning->onchain (loop out)
  bool isLoopIn = true;

  // Text controllers for amount input
  late TextEditingController topAmountController;
  late TextEditingController bottomAmountController;
  late TextEditingController topFiatController;
  late TextEditingController bottomFiatController;

  // Toggle for showing fiat as main input
  bool showFiatAsMain = false;

  // Scroll controller
  final ScrollController scrollController = ScrollController();

  // Loading state
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    topAmountController = TextEditingController(text: "0");
    bottomAmountController = TextEditingController(text: "0");
    topFiatController = TextEditingController(text: "0.00");
    bottomFiatController = TextEditingController(text: "0.00");
  }

  @override
  void dispose() {
    topAmountController.dispose();
    bottomAmountController.dispose();
    topFiatController.dispose();
    bottomFiatController.dispose();
    onchainFocusNode.dispose();
    lightningFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _toggleFiatMode() {
    setState(() {
      showFiatAsMain = !showFiatAsMain;
    });
  }

  void _toggleDirection() {
    setState(() {
      isLoopIn = !isLoopIn;
      // Also swap the card types when direction changes
      CardType temp = topCardType;
      topCardType = bottomCardType;
      bottomCardType = temp;
    });
  }

  String _getButtonTitle() {
    return isLoopIn ? "On-Chain → Lightning" : "Lightning → On-Chain";
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: ArkAppBar(
        text: "Swap",
        context: context,
        hasBackButton: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.cardPadding * 3.5),
                SizedBox(
                  height: AppTheme.cardPadding * (6.5 * 2 + 1),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // TOP CARD
                          Container(
                            height: AppTheme.cardPadding * 6.5,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.cardPadding,
                            ),
                            child: EditableBalanceCard(
                              balance: "1000000",
                              confirmedBalance: "1000000",
                              cardType: topCardType,
                              cardTitle: isLoopIn ? "You Sell" : "You Buy",
                              focusNode: topCardType == CardType.onchain
                                  ? onchainFocusNode
                                  : lightningFocusNode,
                              amountController: topAmountController,
                              fiatController: topFiatController,
                              showFiatAsMain: showFiatAsMain,
                              onToggleFiatMode: _toggleFiatMode,
                              showAvailableBalance: true,
                              onChanged: (value) {
                                // Sync to other card
                                bottomAmountController.text = value;
                              },
                              handleCurrencySelection: (type) {
                                if (type != topCardType) {
                                  _toggleDirection();
                                }
                              },
                            ),
                          ),
                          Container(height: AppTheme.cardPadding * 1),
                          // BOTTOM CARD
                          Container(
                            height: AppTheme.cardPadding * 6.5,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.cardPadding,
                            ),
                            child: EditableBalanceCard(
                              balance: "500000",
                              confirmedBalance: "500000",
                              cardType: bottomCardType,
                              cardTitle: isLoopIn ? "You Buy" : "You Sell",
                              focusNode: bottomCardType == CardType.onchain
                                  ? onchainFocusNode
                                  : lightningFocusNode,
                              amountController: bottomAmountController,
                              fiatController: bottomFiatController,
                              showFiatAsMain: showFiatAsMain,
                              onToggleFiatMode: _toggleFiatMode,
                              showAvailableBalance: true,
                              onChanged: (value) {
                                // Sync to other card
                                topAmountController.text = value;
                              },
                              handleCurrencySelection: (type) {
                                if (type != bottomCardType) {
                                  _toggleDirection();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      // CONTROL BUTTON IN THE MIDDLE
                      Align(
                        alignment: Alignment.center,
                        child: Material(
                          color: AppTheme.colorBitcoin,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                          child: InkWell(
                            onTap: _toggleDirection,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusSmall,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Transform.rotate(
                                angle: isLoopIn
                                    ? 0
                                    : 3.14159, // 180 degrees in radians
                                child: Icon(
                                  Icons.arrow_downward,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.cardPadding * 5.5),
              ],
            ),
          ),
          // Bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: AppTheme.cardPadding,
            child: Center(
              child: LongButtonWidget(
                title: _getButtonTitle(),
                customWidth: MediaQuery.of(context).size.width -
                    AppTheme.cardPadding * 2,
                state: isLoading ? ButtonState.loading : ButtonState.idle,
                onTap: () {
                  // TODO: Implement swap logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CardType { onchain, lightning }

class EditableBalanceCard extends StatefulWidget {
  final String balance;
  final String confirmedBalance;
  final CardType cardType;
  final String cardTitle;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final TextEditingController amountController;
  final TextEditingController fiatController;
  final Function(CardType) handleCurrencySelection;
  final bool showFiatAsMain;
  final VoidCallback onToggleFiatMode;
  final bool showAvailableBalance;

  const EditableBalanceCard({
    super.key,
    required this.balance,
    required this.confirmedBalance,
    required this.cardType,
    required this.cardTitle,
    required this.focusNode,
    required this.onChanged,
    required this.amountController,
    required this.fiatController,
    required this.handleCurrencySelection,
    required this.showFiatAsMain,
    required this.onToggleFiatMode,
    this.showAvailableBalance = true,
  });

  @override
  State<EditableBalanceCard> createState() => _EditableBalanceCardState();
}

class _EditableBalanceCardState extends State<EditableBalanceCard> {
  String _getAvailableBalance(CardType cardType) {
    final balance = double.tryParse(widget.confirmedBalance) ?? 0.0;
    return '${balance.toStringAsFixed(0)} sats';
  }

  void _showCurrencySelectionSheet(BuildContext context, bool isOnchain) {
    arkBottomSheet(
      context: context,
      child: ArkScaffold(
        context: context,
        extendBodyBehindAppBar: true,
        appBar: ArkAppBar(
          context: context,
          text: "Select Currency",
          hasBackButton: false,
        ),
        body: Column(
          children: [
            const SizedBox(height: AppTheme.cardPadding * 2),
            ArkListTile(
              text: "Bitcoin (On-Chain)",
              leading: Image.asset(
                'assets/images/bitcoin.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.currency_bitcoin,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              selected: isOnchain,
              isActive: isOnchain,
              trailing: isOnchain
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                widget.handleCurrencySelection(CardType.onchain);
                Navigator.pop(context);
              },
            ),
            ArkListTile(
              text: "Lightning",
              leading: Image.asset(
                'assets/images/lightning.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              selected: !isOnchain,
              isActive: !isOnchain,
              trailing: !isOnchain
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                widget.handleCurrencySelection(CardType.lightning);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyIcon(bool isOnchain) {
    return Container(
      width: AppTheme.cardPadding * 1.25,
      height: AppTheme.cardPadding * 1.25,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: isOnchain
            ? Image.asset(
                'assets/images/bitcoin.png',
                width: AppTheme.cardPadding * 1.25,
                height: AppTheme.cardPadding * 1.25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: AppTheme.cardPadding * 1.25,
                  height: AppTheme.cardPadding * 1.25,
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.currency_bitcoin,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              )
            : Image.asset(
                'assets/images/lightning.png',
                width: AppTheme.cardPadding * 1.25,
                height: AppTheme.cardPadding * 1.25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: AppTheme.cardPadding * 1.25,
                  height: AppTheme.cardPadding * 1.25,
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnchain = widget.cardType == CardType.onchain;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get the current amount value
    final double currentAmount =
        double.tryParse(widget.amountController.text) ?? 0;
    final double currentFiatAmount =
        double.tryParse(widget.fiatController.text) ?? 0;

    // Determine which controller to use as main input based on mode
    final TextEditingController mainController =
        widget.showFiatAsMain ? widget.fiatController : widget.amountController;
    final TextEditingController secondaryController =
        widget.showFiatAsMain ? widget.amountController : widget.fiatController;

    // Main display value check
    final double mainValue = widget.showFiatAsMain ? currentFiatAmount : currentAmount;

    // Labels
    final String mainSuffix = widget.showFiatAsMain ? " USD" : " sats";
    final String secondarySuffix = widget.showFiatAsMain ? " sats" : " USD";
    final String secondaryPrefix = widget.showFiatAsMain ? "≈ " : "≈ \$";

    return GlassContainer(
      borderRadius: BorderRadius.circular(24),
      boxShadow: isDarkMode
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      child: Stack(
        children: [
          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card title ("You Sell" or "You Buy")
                Text(
                  widget.cardTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                // Editable amount field - main input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (widget.showFiatAsMain)
                      Text(
                        "\$",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    Flexible(
                      child: TextField(
                        controller: mainController,
                        focusNode: widget.focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintText: widget.showFiatAsMain ? "0.00" : "0",
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          widget.onChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.elementSpacing * 0.25),
                // Secondary value - tappable to swap
                GestureDetector(
                  onTap: widget.onToggleFiatMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.showFiatAsMain
                              ? "≈ ${secondaryController.text} sats"
                              : "≈ \$${secondaryController.text}",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_vert,
                          size: 14,
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Currency Selector with balance - vertically centered on right
          Positioned(
            right: AppTheme.cardPadding * 0.75,
            top: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _showCurrencySelectionSheet(context, isOnchain),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(500),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppTheme.elementSpacing * 0.5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: AppTheme.elementSpacing * 0.5),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: AppTheme.elementSpacing * 0.5),
                          _buildCurrencyIcon(isOnchain),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.showAvailableBalance) ...[
                  const SizedBox(height: 6),
                  Text(
                    _getAvailableBalance(widget.cardType),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
