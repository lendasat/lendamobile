import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/email_signup_screen.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';

class MnemonicInputScreen extends StatefulWidget {
  const MnemonicInputScreen({super.key});

  @override
  State<MnemonicInputScreen> createState() => _MnemonicInputScreenState();
}

class _MnemonicInputScreenState extends State<MnemonicInputScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  bool _onLastPage = false;

  List<String> _bipWords = [];

  // 12 controllers for 12 words
  final List<TextEditingController> _textControllers = List.generate(
    12,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(12, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadBipWords();

    // Add focus listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => _onFocusChange(i));
    }

    // Add text change listeners for paste detection
    for (int i = 0; i < _textControllers.length; i++) {
      _textControllers[i].addListener(() => _onTextChanged(i));
    }
  }

  Future<void> _loadBipWords() async {
    try {
      final String bipWordsText = await rootBundle.loadString('assets/textfiles/bip_words.txt');
      setState(() {
        _bipWords = bipWordsText.split(' ');
      });
    } catch (e) {
      logger.e("Error loading BIP words: $e");
    }
  }

  void _onFocusChange(int index) {
    if (_focusNodes[index].hasFocus) {
      int pageIndex = index ~/ 4;
      if (_pageController.hasClients && _pageController.page?.round() != pageIndex) {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onTextChanged(int index) {
    String text = _textControllers[index].text.trim();

    // Check for pasted mnemonic (multiple words)
    List<String> words = text
        .split(RegExp(r'[,\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.trim().toLowerCase())
        .toList();

    if (words.length >= 12) {
      _autoFillMnemonic(words);
    }
  }

  void _autoFillMnemonic(List<String> words) async {
    int wordCount = words.length > 12 ? 12 : words.length;

    for (int i = 0; i < wordCount && i < _textControllers.length; i++) {
      if (_textControllers[i].text != words[i]) {
        _textControllers[i].text = words[i];
      }
    }

    for (int i = wordCount; i < _textControllers.length; i++) {
      if (_textControllers[i].text.isNotEmpty) {
        _textControllers[i].clear();
      }
    }

    setState(() {});

    await Future.delayed(const Duration(milliseconds: 100));

    if (wordCount == 12) {
      _pageController.animateToPage(
        2, // Last page (0, 1, 2)
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _onLastPage = true;
      });
    }

    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _moveToNext() {
    int currentFocusIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (currentFocusIndex == -1 || currentFocusIndex == _focusNodes.length - 1) {
      return;
    }

    if ((currentFocusIndex + 1) % 4 == 0) {
      _nextPage();
    }

    _focusNodes[currentFocusIndex].unfocus();
    FocusScope.of(context).requestFocus(_focusNodes[currentFocusIndex + 1]);
    setState(() {});
  }

  void _nextPage() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
    );
  }

  bool _isValidWord(String word) {
    return _bipWords.contains(word.toLowerCase());
  }

  void _handleRestore() {
    // Validate that all words are filled
    final emptyFields = _textControllers
        .asMap()
        .entries
        .where((entry) => entry.value.text.trim().isEmpty)
        .map((entry) => entry.key + 1)
        .toList();

    if (emptyFields.isNotEmpty) {
      _showErrorDialog(
        AppLocalizations.of(context)!.failedToRestoreWallet,
        'Please fill in all 12 words. Missing: ${emptyFields.join(", ")}',
      );
      return;
    }

    // Validate all words are valid BIP39 words
    final invalidWords = _textControllers
        .asMap()
        .entries
        .where((entry) => !_isValidWord(entry.value.text.trim()))
        .map((entry) => 'Word ${entry.key + 1}: ${entry.value.text.trim()}')
        .toList();

    if (invalidWords.isNotEmpty) {
      _showErrorDialog(
        AppLocalizations.of(context)!.failedToRestoreWallet,
        'Invalid words found:\n${invalidWords.join("\n")}',
      );
      return;
    }

    final String mnemonic = _textControllers
        .map((controller) => controller.text.trim().toLowerCase())
        .join(' ');

    logger.i('Navigating to email signup for wallet restore');

    // Navigate to email signup screen with mnemonic for restore
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmailSignupScreen(
          isRestore: true,
          mnemonicWords: mnemonic,
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.restoreExistingWallet,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Enter your 12-word recovery phrase',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the words in the correct order',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // PageView for mnemonic input
                SizedBox(
                  height: 320,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (val) {
                      setState(() {
                        _onLastPage = (val == 2);
                      });
                    },
                    children: [
                      _buildInputPage(0), // Words 1-4
                      _buildInputPage(1), // Words 5-8
                      _buildInputPage(2), // Words 9-12
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _pageController.hasClients &&
                             (_pageController.page?.round() ?? 0) == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _pageController.hasClients &&
                               (_pageController.page?.round() ?? 0) == index
                            ? Colors.orange
                            : Theme.of(context).hintColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // Action button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onLastPage ? _handleRestore : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _onLastPage
                          ? AppLocalizations.of(context)!.restoreExistingWallet
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputPage(int pageIndex) {
    int startIndex = pageIndex * 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          int wordIndex = startIndex + i;
          return _buildWordField(wordIndex);
        }),
      ),
    );
  }

  Widget _buildWordField(int index) {
    final controller = _textControllers[index];
    final focusNode = _focusNodes[index];
    final bool isValid = controller.text.isNotEmpty && _isValidWord(controller.text);
    final bool isInvalid = controller.text.isNotEmpty && !_isValidWord(controller.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          color: isValid
              ? AppTheme.successColor
              : (isInvalid ? AppTheme.errorColor : Theme.of(context).colorScheme.onSurface),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: '${index + 1}.',
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
          prefixIcon: Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              '${index + 1}.',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid
                  ? AppTheme.successColor.withOpacity(0.5)
                  : (isInvalid
                      ? AppTheme.errorColor.withOpacity(0.5)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid
                  ? AppTheme.successColor
                  : (isInvalid ? AppTheme.errorColor : Colors.orange),
              width: 2,
            ),
          ),
        ),
        textInputAction: index < 11 ? TextInputAction.next : TextInputAction.done,
        onChanged: (value) {
          setState(() {});
          // Auto-advance if valid word is complete
          if (_isValidWord(value.trim().toLowerCase())) {
            // Check if this is the longest possible match
            final matches = _bipWords.where((w) => w.startsWith(value.toLowerCase())).toList();
            final longestMatch = matches.isEmpty ? 0 : matches.map((w) => w.length).reduce((a, b) => a > b ? a : b);
            if (value.length == longestMatch) {
              _moveToNext();
            }
          }
        },
        onFieldSubmitted: (_) {
          if (index < 11) {
            _moveToNext();
          } else {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }
}
