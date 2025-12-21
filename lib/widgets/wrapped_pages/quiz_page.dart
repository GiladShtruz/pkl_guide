import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/wrapped_data.dart';
import '../../services/wrapped_service.dart';

class QuizPage extends StatefulWidget {
  final CategoryType category;
  final TopItemData topItem;
  final WrappedService wrappedService;
  final Function(bool) onAnswered;
  final Function(bool)? onScrollStateChanged;

  const QuizPage({
    super.key,
    required this.category,
    required this.topItem,
    required this.wrappedService,
    required this.onAnswered,
    this.onScrollStateChanged,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<int>? _options;
  int? _selectedId;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() {
    // Check if already answered
    final savedAnswer = widget.wrappedService.getQuizAnswer(widget.category.name);
    if (savedAnswer != null) {
      setState(() {
        _options = savedAnswer.options;
        _selectedId = savedAnswer.selectedItemId;
        _hasAnswered = true;
      });
      // Allow scrolling since already answered - do this after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onScrollStateChanged?.call(true);
      });
    } else {
      // Generate new quiz
      final options = widget.wrappedService.generateQuizOptions(
        widget.category.name,
        widget.topItem.itemId,
      );
      setState(() {
        _options = options;
      });
      // Block scrolling until answered - do this after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onScrollStateChanged?.call(false);
      });
    }
  }

  void _selectOption(int itemId) {
    if (_hasAnswered) {
      // If already answered, allow moving to next page
      widget.onAnswered(_selectedId == widget.topItem.itemId);
      return;
    }

    setState(() {
      _selectedId = itemId;
    });

    // Save answer
    final isCorrect = itemId == widget.topItem.itemId;
    final answer = WrappedQuizAnswer(
      category: widget.category.name,
      selectedItemId: itemId,
      correctItemId: widget.topItem.itemId,
      isCorrect: isCorrect,
      options: _options!,
    );

    widget.wrappedService.saveQuizAnswer(widget.category.name, answer);

    setState(() {
      _hasAnswered = true;
    });

    // Allow scrolling now that user has answered
    widget.onScrollStateChanged?.call(true);

    // Don't auto-advance - user needs to tap to continue
  }

  @override
  Widget build(BuildContext context) {
    if (_options == null) {
      return Container(
        color: widget.category.categoryColor,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.category.categoryColor.withOpacity(0.7),
            widget.category.categoryColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Question
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.category.icon,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'מה ${widget.category.wrappedName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'שהכי ${widget.category.viewedName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Options - Fixed without scrolling
              ..._options!.map((itemId) {
                final item = widget.wrappedService.getItemById(itemId);
                if (item == null) return const SizedBox.shrink();

                final isSelected = _selectedId == itemId;
                final isCorrect = itemId == widget.topItem.itemId;
                final showResult = _hasAnswered;

                Color? backgroundColor;
                IconData? resultIcon;

                if (showResult) {
                  if (isCorrect) {
                    backgroundColor = Colors.green;
                    resultIcon = Icons.check_circle;
                  } else if (isSelected) {
                    backgroundColor = Colors.red;
                    resultIcon = Icons.cancel;
                  }
                }

                return GestureDetector(
                  onTap: () => _selectOption(itemId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (showResult && resultIcon != null)
                          Icon(
                            resultIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              }),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _hasAnswered ? 'החלק למטה להמשך' : 'בחר תשובה',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
