import 'package:flutter/material.dart';
import '../../models/wrapped_data.dart';
import '../../services/wrapped_service.dart';

class RecentItemsQuizPage extends StatefulWidget {
  final List<RecentItemData> recentItems;
  final WrappedService wrappedService;
  final VoidCallback onSubmit;

  const RecentItemsQuizPage({
    super.key,
    required this.recentItems,
    required this.wrappedService,
    required this.onSubmit,
  });

  @override
  State<RecentItemsQuizPage> createState() => _RecentItemsQuizPageState();
}

class _RecentItemsQuizPageState extends State<RecentItemsQuizPage> {
  List<RecentItemData> _userOrder = [];
  List<RecentItemData> _availableItems = [];
  bool _hasSubmitted = false;
  List<bool> _correctnessMap = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Check if already answered
    final savedOrder = widget.wrappedService.getRecentItemsOrder();
    if (savedOrder != null && savedOrder.length == 3) {
      _hasSubmitted = true;
      _userOrder = savedOrder.map((id) {
        return widget.recentItems.firstWhere((item) => item.itemId == id);
      }).toList();
      _calculateCorrectness();
    } else {
      // Shuffle items for quiz
      _availableItems = List.from(widget.recentItems)..shuffle();
    }
  }

  void _calculateCorrectness() {
    _correctnessMap = List.generate(3, (index) {
      return _userOrder[index].itemId == widget.recentItems[index].itemId;
    });
  }

  void _addToOrder(RecentItemData item) {
    if (_userOrder.length >= 3 || _hasSubmitted) return;

    setState(() {
      _userOrder.add(item);
      _availableItems.remove(item);
    });
  }

  void _removeFromOrder(int index) {
    if (_hasSubmitted) return;

    setState(() {
      final item = _userOrder.removeAt(index);
      _availableItems.add(item);
    });
  }

  void _submitOrder() {
    if (_userOrder.length != 3 || _hasSubmitted) return;

    setState(() {
      _hasSubmitted = true;
      _calculateCorrectness();
    });

    // Save order
    final orderIds = _userOrder.map((e) => e.itemId).toList();
    widget.wrappedService.saveRecentItemsOrder(orderIds);

    // Don't auto-advance - user can swipe when ready
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
            Color(0xFF475569),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Text(
                'האתגר האחרון! 🎯',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'סדר את 3 התכנים האחרונים\nשצפית בהם לפי סדר הצפייה',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // User's order area
              const Text(
                'הסדר שלך:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _userOrder.isEmpty
                      ? const Center(
                          child: Text(
                            'בחר פריטים מהרשימה למטה',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _userOrder.length,
                          itemBuilder: (context, index) {
                            final item = _userOrder[index];
                            final isCorrect = _hasSubmitted && _correctnessMap[index];
                            final isWrong = _hasSubmitted && !_correctnessMap[index];

                            return Container(
                              key: ValueKey(item.itemId),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green.withOpacity(0.3)
                                    : isWrong
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!_hasSubmitted)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _removeFromOrder(index),
                                    ),
                                  if (_hasSubmitted)
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Available items
              if (!_hasSubmitted && _availableItems.isNotEmpty) ...[
                const Text(
                  'בחר מכאן:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: _availableItems.length,
                    itemBuilder: (context, index) {
                      final item = _availableItems[index];
                      return GestureDetector(
                        onTap: () => _addToOrder(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Submit button
              if (!_hasSubmitted && _userOrder.length == 3)
                ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'אישור',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Result summary with correct order
              if (_hasSubmitted)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              final correctItem = widget.recentItems[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        correctItem.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'החלק למטה להמשך',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
