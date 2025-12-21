import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/wrapped_data.dart';
import '../../models/category.dart';
import '../../services/wrapped_service.dart';

class ResultsSummaryPage extends StatefulWidget {
  final WrappedData wrappedData;
  final WrappedService wrappedService;
  final VoidCallback onNext;

  const ResultsSummaryPage({
    super.key,
    required this.wrappedData,
    required this.wrappedService,
    required this.onNext,
  });

  @override
  State<ResultsSummaryPage> createState() => _ResultsSummaryPageState();
}

class _ResultsSummaryPageState extends State<ResultsSummaryPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryType category,
    List<TopItemData> topItems,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: category.categoryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.categoryColor.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            category.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topItems.length,
              itemBuilder: (context, index) {
                final item = topItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.clickCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareScreenshot() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/wrapped_summary.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'סיכום שנה - פק"ל למדריך 2025 🎉',
        );
      }
    } catch (e) {
      // Handle error
      print('Error sharing screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF6366F1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [


                    Column(
                      children: [
                        const Text(
                          'סיכום שנה',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'פק"ל למדריך 2025',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        ]
                    ),
                    Image.asset(
                      'assets/logoShare.png',
                      height: 80,
                      width: 80,
                    ),
                    ]
                ),
                // Header with logo

                const SizedBox(height: 24),

              // 2x2 Grid - Using Expanded to fill available space
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Top right: Games (but in RTL, it's visually on the right)
                    _buildCategoryCard(
                      context,
                      CategoryType.games,
                      widget.wrappedService.getTop3ItemsByCategory('games'),
                    ),

                    // Top left: Activities
                    _buildCategoryCard(
                      context,
                      CategoryType.activities,
                      widget.wrappedService.getTop3ItemsByCategory('activities'),
                    ),

                    // Bottom right: Riddles
                    _buildCategoryCard(
                      context,
                      CategoryType.riddles,
                      widget.wrappedService.getTop3ItemsByCategory('riddles'),
                    ),

                    // Bottom left: Texts
                    _buildCategoryCard(
                      context,
                      CategoryType.texts,
                      widget.wrappedService.getTop3ItemsByCategory('texts'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Total views
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'סה"כ צפיות:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.wrappedData.totalClicks}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Share button
              ElevatedButton.icon(
                onPressed: _shareScreenshot,
                icon: const Icon(Icons.share),
                label: const Text('שתף'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Swipe hint
              const Text(
                'החלק למטה להמשך',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
