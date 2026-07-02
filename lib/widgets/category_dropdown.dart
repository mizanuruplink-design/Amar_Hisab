import 'package:flutter/material.dart';
import '../services/category_service.dart';

class CategoryDropdown extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool showAddNew;
  final List<String>? allowedKeys;
  final String? filterType;
  final Function(String)? getTranslatedName;
  final String? addNewCategoryText;
  final String? dialogTitle;
  final String? categoryNameLabel;
  final String? addButtonText;
  final String? cancelButtonText;

  const CategoryDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.hintText = 'Select Category',
    this.showAddNew = true,
    this.allowedKeys,
    this.filterType,
    this.getTranslatedName,
    this.addNewCategoryText,
    this.dialogTitle,
    this.categoryNameLabel,
    this.addButtonText,
    this.cancelButtonText,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = true;

  final Map<String, String> _categoryTypeMap = {
    'gas_bill': 'Expense', 'house_rent': 'Expense', 'internet_bill': 'Expense',
    'water_bill': 'Expense', 'transport': 'Expense', 'grocery': 'Expense',
    'education': 'Expense', 'medical': 'Expense', 'food': 'Expense',
    'mobile_bill': 'Expense', 'entertainment': 'Expense', 'electricity_bill': 'Expense',
    'salary': 'Income', 'business': 'Income',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didUpdateWidget(CategoryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allowedKeys != widget.allowedKeys ||
        oldWidget.filterType != widget.filterType) {
      _filterCategories();
    }
  }

  Future<void> _loadCategories() async {
    await _categoryService.init();
    _filterCategories();
  }

  void _filterCategories() {
    final all = _categoryService.allCategories;
    setState(() {
      if (widget.allowedKeys != null) {
        _filteredCategories = all.where((cat) {
          if (cat['isCustom'] == true) return true;
          return widget.allowedKeys!.contains(cat['key'] as String);
        }).toList();
      } else if (widget.filterType != null) {
        _filteredCategories = all.where((cat) {
          if (cat['isCustom'] == true) return cat['type'] == widget.filterType;
          return _categoryTypeMap[cat['key']] == widget.filterType;
        }).toList();
      } else {
        _filteredCategories = all;
      }
      _isLoading = false;
    });
  }

  String _getDisplayName(Map<String, dynamic> cat) {
    final key = cat['key'] as String;
    if (cat['isCustom'] == true) return key;
    if (widget.getTranslatedName != null) {
      return widget.getTranslatedName!(key);
    }
    return key;
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = Colors.blue;

    // 🆕 Expanded icon list – all safe for web/Flutter stable
    List<IconData> iconList = [
      // Common
      Icons.category, Icons.label, Icons.bookmark, Icons.star, Icons.favorite,
      // Work & Business
      Icons.work, Icons.business, Icons.business_center, Icons.store, Icons.storefront,
      // Shopping
      Icons.shopping_bag, Icons.shopping_cart, Icons.shopping_basket,
      // Food & Drink
      Icons.fastfood, Icons.restaurant, Icons.lunch_dining, Icons.dinner_dining,
      Icons.icecream, Icons.cake, Icons.coffee,
      // Home & Living
      Icons.home, Icons.house, Icons.apartment, Icons.cottage, Icons.garage,
      // Transport
      Icons.directions_bus, Icons.directions_car, Icons.directions_bike,
      Icons.directions_railway, Icons.flight, Icons.directions_boat, // ✅ fixed ferry -> directions_boat
      Icons.local_taxi,
      // Education
      Icons.school, Icons.book, Icons.library_books, Icons.menu_book, Icons.auto_stories,
      // Health
      Icons.health_and_safety, Icons.local_hospital, Icons.local_pharmacy,
      Icons.medical_services, Icons.healing, Icons.fitness_center,
      // Entertainment
      Icons.tv, Icons.movie, Icons.music_note, Icons.theater_comedy,
      Icons.sports_soccer, Icons.sports_basketball, Icons.sports_cricket,
      Icons.videogame_asset, Icons.gamepad,
      // Money & Finance
      Icons.money, Icons.attach_money, Icons.money_off, Icons.credit_card,
      Icons.payment, Icons.account_balance, Icons.account_balance_wallet,
      Icons.savings, Icons.trending_up, Icons.trending_down, Icons.bar_chart,
      // Communication
      Icons.phone_android, Icons.phone_iphone, Icons.laptop, Icons.computer,
      Icons.wifi, Icons.router, Icons.signal_cellular_alt,
      // Miscellaneous
      Icons.pets, Icons.emoji_emotions, Icons.beach_access, Icons.pool,
      Icons.casino, Icons.more_horiz,
    ];

    List<Color> colorList = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(widget.dialogTitle ?? 'Add New Category'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: widget.categoryNameLabel ?? 'Category Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 15),
                Text('Select Icon', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconList.map((icon) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon ? Colors.blue.shade100 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedIcon == icon ? Colors.blue : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(icon, color: selectedIcon == icon ? Colors.blue : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                Text('Select Color', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorList.map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.cancelButtonText ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _categoryService.addCustomCategory(
                    nameController.text,
                    selectedIcon,
                    selectedColor,
                    type: widget.filterType,
                  );
                  await _loadCategories();
                  Navigator.pop(context);
                  widget.onChanged(nameController.text);
                }
              },
              child: Text(widget.addButtonText ?? 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    for (var cat in _filteredCategories) {
      items.add(DropdownMenuItem<String>(
        value: cat['key'] as String,
        child: Row(
          children: [
            Icon(cat['icon'] as IconData, size: 20, color: cat['color'] as Color),
            const SizedBox(width: 10),
            Text(_getDisplayName(cat)),
          ],
        ),
      ));
    }
    if (widget.showAddNew) {
      items.add(DropdownMenuItem<String>(
        value: '_add_new_',
        child: Text(
          widget.addNewCategoryText ?? 'Add New Category',
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 50,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final bool isValueInList = _filteredCategories.any((cat) => cat['key'] == widget.selectedValue);
    final String? safeValue = isValueInList ? widget.selectedValue : (_filteredCategories.isNotEmpty ? _filteredCategories.first['key'] : null);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: Text(widget.hintText),
          items: _buildDropdownItems(),
          onChanged: (String? v) {
            if (v == '_add_new_') {
              _showAddCategoryDialog();
            } else if (v != null) {
              widget.onChanged(v);
            }
          },
        ),
      ),
    );
  }
}