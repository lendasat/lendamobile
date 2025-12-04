import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';

class SearchFieldWidget extends StatefulWidget {
  final String hintText;
  final bool isSearchEnabled;
  final Function(String) handleSearch;
  final Function(String)? onChanged;
  final Widget? suffixIcon;
  final Function(TextEditingController)? onSuffixTap;
  final FocusNode? node;

  const SearchFieldWidget({
    super.key,
    required this.hintText,
    required this.isSearchEnabled,
    required this.handleSearch,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.node,
  });

  @override
  State<SearchFieldWidget> createState() => _SearchFieldWidgetState();
}

class _SearchFieldWidgetState extends State<SearchFieldWidget> {
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        height: AppTheme.paddingL * 1.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: TextFormField(
          enabled: widget.isSearchEnabled,
          controller: _textFieldController,
          onFieldSubmitted: widget.handleSearch,
          focusNode: widget.node,
          onChanged: (value) {
            setState(() {
              _textFieldController.text = value;
            });
            widget.onChanged?.call(value);
          },
          style: TextStyle(color: theme.primaryWhite),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(AppTheme.paddingL / 100),
            hintStyle: TextStyle(color: theme.mutedText),
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.search,
              color: theme.mutedText,
            ),
            suffixIcon: _textFieldController.text.isEmpty ||
                    _textFieldController.text == ''
                ? widget.suffixIcon ?? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(
                      Icons.cancel,
                      color: theme.mutedText,
                    ),
                    onPressed: () {
                      if (widget.onSuffixTap != null) {
                        widget.onSuffixTap!(_textFieldController);
                      } else {
                        _textFieldController.clear();
                        widget.handleSearch('');
                      }
                    },
                  ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(width: 0, style: BorderStyle.none),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        ),
      ),
    );
  }
}
