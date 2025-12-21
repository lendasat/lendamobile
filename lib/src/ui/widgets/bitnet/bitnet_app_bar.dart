import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Standard BitNet app bar with a background gradient effect.
/// Supports custom title, back button, and actions.
class BitNetAppBar extends StatefulWidget implements PreferredSizeWidget {
  final BuildContext context;
  final Function()? onTap;
  final bool hasBackButton;
  final List<Widget>? actions;
  final String? text;
  final Widget? customTitle;
  final Widget? customLeading;
  final IconData? customIcon;
  final ButtonType? buttonType;

  const BitNetAppBar({
    super.key,
    required this.context,
    this.onTap,
    this.hasBackButton = true,
    this.actions,
    this.text = "",
    this.customTitle,
    this.customLeading,
    this.customIcon,
    this.buttonType = ButtonType.solid,
  });

  @override
  State<BitNetAppBar> createState() => _BitNetAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BitNetAppBarState extends State<BitNetAppBar> {
  bool _animateText = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());

    final double width = MediaQuery.of(context).size.width;

    // Define breakpoint values for responsive layout
    final bool isSuperSmallScreen = width < AppTheme.isSuperSmallScreen;
    final bool isSmallScreen = width < AppTheme.isSmallScreen;
    final bool isMidScreen = width < AppTheme.isMidScreen;
    final bool isIntermediateScreen = width < AppTheme.isIntermediateScreen;

    // Check if we should use Bitcoin gradient
    final bool useBitcoinGradient =
        Theme.of(context).colorScheme.primary == AppTheme.colorBitcoin;

    final double centerSpacing = kIsWeb
        ? AppTheme.columnWidth * 0.075
        : isMidScreen
            ? isIntermediateScreen
                ? isSmallScreen
                    ? isSuperSmallScreen
                        ? AppTheme.columnWidth * 0.075
                        : AppTheme.columnWidth * 0.15
                    : AppTheme.columnWidth * 0.35
                : AppTheme.columnWidth * 0.65
            : AppTheme.columnWidth;

    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      bottomOpacity: 0,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.colorBackground.withOpacity(0.9),
              AppTheme.colorBackground.withOpacity(0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
      title: widget.customTitle ??
          (widget.text != null && widget.text!.isNotEmpty
              ? _animateText
                  ? SizedBox(
                      width: AppTheme.cardPadding * 10,
                      height: AppTheme.cardPadding,
                      child: _AnimatedText(text: widget.text!),
                    )
                  : Container(
                      key: _textKey,
                      padding: EdgeInsets.symmetric(horizontal: centerSpacing),
                      child: Text(
                        widget.text!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
              : const SizedBox.shrink()),
      leading: widget.hasBackButton
          ? widget.customLeading ??
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: AppTheme.elementSpacing * 1.5,
                      right: AppTheme.elementSpacing * 0.5,
                      top: AppTheme.elementSpacing,
                      bottom: AppTheme.elementSpacing,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (widget.onTap != null) {
                          widget.onTap!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: RoundedButtonWidget(
                        buttonType: widget.buttonType ?? ButtonType.solid,
                        iconData: widget.customIcon ?? Icons.arrow_back,
                        iconColor: useBitcoinGradient
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        onTap: null,
                      ),
                    ),
                  ),
                ),
              )
          : null,
      actions: widget.actions,
    );
  }

  void _checkOverflow() {
    final RenderBox? renderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final double textWidth = renderBox.size.width;

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: widget.text,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      if (textPainter.size.width > textWidth) {
        if (!_animateText) {
          setState(() {
            _animateText = true;
          });
        }
      } else {
        if (_animateText) {
          setState(() {
            _animateText = false;
          });
        }
      }
    }
  }
}

/// Simple animated text widget that scrolls horizontally when text overflows
class _AnimatedText extends StatefulWidget {
  final String text;

  const _AnimatedText({required this.text});

  @override
  State<_AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<_AnimatedText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Start scrolling animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrollAnimation();
    });
  }

  void _startScrollAnimation() {
    if (!mounted) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent > 0) {
      _animationController.addListener(() {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _animationController.value * maxScrollExtent,
          );
        }
      });

      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.1, 0.9, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
