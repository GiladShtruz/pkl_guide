// lib/screens/item_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pkl_guide/screens/card_swiper_game_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../services/lists_service.dart';
import '../screens/edit_item_screen.dart';
import '../dialogs/manage_list_dialog.dart';
import '../utils/category_helper.dart';
import '../utils/content_helper.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late ListsService _listsService;
  late StorageService _storageService;

  final Set<int> _selectedIndices = {};

  final ScrollController _scrollController = ScrollController();
  bool _showTitleInAppBar = false;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _storageService = context.read<StorageService>();

    _storageService.updateItemAccess(widget.item.id);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    // אם גללנו יותר מ-100 פיקסלים, הצג את השם ב-AppBar
    if (_scrollController.offset > 100 && !_showTitleInAppBar) {
      setState(() {
        _showTitleInAppBar = true;
      });
    } else if (_scrollController.offset <= 100 && _showTitleInAppBar) {
      setState(() {
        _showTitleInAppBar = false;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _openLink() async {
    if (widget.item.link != null && widget.item.link!.isNotEmpty) {
      final uri = Uri.parse(widget.item.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openListsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ManageListDialog(
        itemIds: [widget.item.id],
        itemName: widget.item.name,
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('עודכן ברשימות'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCardGame =
        widget.item.classification?.toLowerCase().contains("אינטראקטיבי") ??
        false;
    final hasModifications = widget.item.hasUserModifications;
    final originalCount = widget.item.originalElements.length;
    final userAddedCount = widget.item.userElements.length;

    final allElements = widget.item.elements;
    final totalItems = allElements.length;

    return Scaffold(
      appBar: AppBar(
        title: _showTitleInAppBar
            ? Column(
          children: [
            Text(widget.item.name),
            if (hasModifications)
              const Text(
                'עודכן',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        )
            : null,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _openListsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemScreen(item: widget.item),
                  ),
                ).then((_) {
                  setState(() {});
                }),
          ),
        ],
      ),

      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(  // הסר את ה-Expanded ותשאיר רק Text
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
                  const SizedBox(height: 16),

                  if (widget.item.isUserCreated)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'נוצר על ידך',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (widget.item.detail != null &&
                      widget.item.detail!.isNotEmpty)
                    _buildInfoCard(
                      title: ContentHelper.getDetailLabel(widget.item.category),
                      content: widget.item.detail!,
                      icon: Icons.description,
                    ),

                  if ((widget.item.equipment != null &&
                          widget.item.equipment!.isNotEmpty) ||
                      (widget.item.classification != null &&
                          widget.item.classification!.isNotEmpty))
                    _buildLocationEquipmentCards(),

                  if (widget.item.link != null && widget.item.link!.isNotEmpty)
                    _buildInfoCard(
                      title: 'קישור',
                      content: widget.item.link!,
                      icon: Icons.link,
                      isLink: true,
                    ),

                  if (totalItems > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ContentHelper.getContentTitle(widget.item.category),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CategoryHelper.getCategoryColor(
                                    widget.item.category,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$originalCount פריטים',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: CategoryHelper.getCategoryColor(
                                      widget.item.category,
                                    ),
                                  ),
                                ),
                              ),
                              if (userAddedCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+$userAddedCount נוספו',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                ],
              ),
            ),
          ),

          if (totalItems > 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  final element = allElements[index];
                  final itemText = element.text;
                  final isUserAdded = element.isUserElement;
                  final isSelected = _selectedIndices.contains(index);

                  if (widget.item.category == 'riddles') {
                    final isDarkMode =
                        Theme.of(context).brightness == Brightness.dark;

                    return GestureDetector(
                      onTap: () => _toggleSelection(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : (isDarkMode
                                          ? (isUserAdded
                                                ? Colors.blue[700]!
                                                : Colors.orange[700]!)
                                          : (isUserAdded
                                                ? Colors.blue[200]!
                                                : Colors.orange[200]!)),
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? (isUserAdded
                                              ? Colors.blue[400]
                                              : Colors.orange[400])
                                        : (isUserAdded
                                              ? Colors.blue
                                              : Colors.orange),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.black87
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    itemText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                if (isUserAdded)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.person,
                                      size: 16,
                                      color: isDarkMode
                                          ? Colors.blue[400]
                                          : Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _toggleSelection(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(color: Colors.green, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isUserAdded
                                      ? Colors.blue.withOpacity(0.15)
                                      : CategoryHelper.getCategoryColor(
                                          widget.item.category,
                                        ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isUserAdded
                                          ? Colors.blue
                                          : CategoryHelper.getCategoryColor(
                                              widget.item.category,
                                            ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  itemText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (isUserAdded)
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      floatingActionButton: isCardGame
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SwitchCardGameScreen(item: widget.item),
                  ),
                );
              },
              label: const Text('התחל משחק'),
              icon: const Icon(Icons.play_arrow),
              backgroundColor: Colors.green,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    bool isLink = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        subtitle: Text(
          content,
          style: isLink
              ? const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                )
              : const TextStyle(),
        ),
        trailing: isLink
            ? IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyToClipboard(widget.item.link!),
              )
            : null,
        onTap: isLink ? () => _launchURL(widget.item.link!) : null,
      ),
    );
  }

  Widget _buildLocationEquipmentCards() {
    final hasEquipment =
        widget.item.equipment != null && widget.item.equipment!.isNotEmpty;
    final hasClassification =
        widget.item.classification != null &&
        widget.item.classification!.isNotEmpty;

    final isEquipmentLong =
        hasEquipment &&
        (widget.item.equipment!.length > 50 ||
            widget.item.equipment!.contains('\n'));
    final isClassificationLong =
        hasClassification &&
        (widget.item.classification!.length > 50 ||
            widget.item.classification!.contains('\n'));

    final useVerticalLayout =
        (hasEquipment && hasClassification) &&
        (isEquipmentLong || isClassificationLong);

    if (!useVerticalLayout) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            if (hasEquipment)
              Expanded(
                child: _buildCompactInfoCard(
                  title: 'ציוד נדרש',
                  content: widget.item.equipment!,
                  icon: Icons.sports_soccer,
                  color: Colors.teal,
                  maxLines: isEquipmentLong ? null : 3,
                ),
              ),

            if (hasEquipment && hasClassification) const SizedBox(width: 8),

            if (hasClassification)
              Expanded(
                child: _buildCompactInfoCard(
                  title: 'סיווג',
                  content: widget.item.classification!,
                  icon: Icons.location_on,
                  color: Colors.deepOrange,
                  maxLines: isClassificationLong ? null : 3,
                ),
              ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          if (hasEquipment)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildExpandedInfoCard(
                title: 'ציוד נדרש',
                content: widget.item.equipment!,
                icon: Icons.sports_soccer,
                color: Colors.teal,
              ),
            ),

          if (hasClassification)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildExpandedInfoCard(
                title: 'סיווג',
                content: widget.item.classification!,
                icon: Icons.location_on,
                color: Colors.deepOrange,
              ),
            ),
        ],
      );
    }
  }

  Widget _buildExpandedInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    int? maxLines,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.3),
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הועתק ללוח'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _launchURL(String url) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('האם לפתוח את הקישור?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ביטול'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('פתח'),
              onPressed: () async {
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('לא ניתן לפתוח את הקישור')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
