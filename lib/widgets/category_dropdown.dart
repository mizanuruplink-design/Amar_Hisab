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
  final String? editCategoryText;
  final String? deleteCategoryText;
  final String? deleteConfirmText;
  final String? categoryExistsText;

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
    this.editCategoryText,
    this.deleteCategoryText,
    this.deleteConfirmText,
    this.categoryExistsText,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = true;

  // Category type mapping for predefined keys
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

  // ==================== ICON SUGGESTION ENGINE ====================
  IconData _suggestIcon(String name) {
    final lower = name.toLowerCase();
    // Food & Drink
    if (lower.contains('fish') || lower.contains('মাছ') || lower.contains('سمك')) return Icons.set_meal;
    if (lower.contains('meat') || lower.contains('মাংস') || lower.contains('لحم')) return Icons.kebab_dining;
    if (lower.contains('veg') || lower.contains('শাক') || lower.contains('সবজি') || lower.contains('خضار')) return Icons.eco;
    if (lower.contains('fruit') || lower.contains('ফল') || lower.contains('فاكهة')) return Icons.apple;
    if (lower.contains('rice') || lower.contains('ভাত') || lower.contains('أرز')) return Icons.restaurant;
    if (lower.contains('bread') || lower.contains('রুটি') || lower.contains('خبز')) return Icons.bakery_dining;
    if (lower.contains('coffee') || lower.contains('কফি') || lower.contains('قهوة')) return Icons.coffee;
    if (lower.contains('cake') || lower.contains('কেক') || lower.contains('كعكة')) return Icons.cake;
    if (lower.contains('ice') || lower.contains('আইসক্রিম') || lower.contains('آيس')) return Icons.icecream;
    // Medicine & Health
    if (lower.contains('medicine') || lower.contains('ঔষধ') || lower.contains('دواء') ||
        lower.contains('medical') || lower.contains('health') || lower.contains('স্বাস্থ্য') || lower.contains('صحة')) {
      return Icons.local_pharmacy;
    }
    // Clothing
    if (lower.contains('cloth') || lower.contains('কাপড়') || lower.contains('ملابس') ||
        lower.contains('dress') || lower.contains('জামা') || lower.contains('ثوب')) {
      return Icons.checkroom;
    }
    // Work & Salary
    if (lower.contains('salary') || lower.contains('বেতন') || lower.contains('راتب') ||
        lower.contains('income') || lower.contains('আয়') || lower.contains('دخل')) {
      return Icons.work;
    }
    if (lower.contains('business') || lower.contains('ব্যবসা') || lower.contains('أعمال')) return Icons.store;
    // Home
    if (lower.contains('rent') || lower.contains('ভাড়া') || lower.contains('إيجار')) return Icons.house;
    if (lower.contains('home') || lower.contains('বাড়ি') || lower.contains('منزل')) return Icons.home;
    // Transport
    if (lower.contains('bus') || lower.contains('বাস') || lower.contains('حافلة')) return Icons.directions_bus;
    if (lower.contains('car') || lower.contains('গাড়ি') || lower.contains('سيارة')) return Icons.directions_car;
    if (lower.contains('bike') || lower.contains('বাইক') || lower.contains('دراجة')) return Icons.directions_bike;
    if (lower.contains('train') || lower.contains('ট্রেন') || lower.contains('قطار')) return Icons.directions_railway;
    // Education
    if (lower.contains('school') || lower.contains('স্কুল') || lower.contains('مدرسة') ||
        lower.contains('education') || lower.contains('শিক্ষা') || lower.contains('تعليم')) {
      return Icons.school;
    }
    // Shopping
    if (lower.contains('grocery') || lower.contains('মুদি') || lower.contains('بقالة')) return Icons.shopping_cart;
    if (lower.contains('market') || lower.contains('বাজার') || lower.contains('سوق')) return Icons.storefront;
    // Entertainment
    if (lower.contains('movie') || lower.contains('সিনেমা') || lower.contains('فيلم')) return Icons.movie;
    if (lower.contains('music') || lower.contains('গান') || lower.contains('موسيقى')) return Icons.music_note;
    if (lower.contains('game') || lower.contains('গেম') || lower.contains('لعبة')) return Icons.gamepad;
    // Pets
    if (lower.contains('pet') || lower.contains('পোষা') || lower.contains('حيوان')) return Icons.pets;
    // Default
    return Icons.category;
  }

  // ==================== EDIT / DELETE ====================
  void _showEditDeleteDialog(Map<String, dynamic> category) {
    final isCustom = category['isCustom'] == true;
    if (!isCustom) return;

    final catId = category['id'] as String;
    final currentName = category['key'] as String;
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.editCategoryText ?? 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: widget.categoryNameLabel ?? 'Category Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (newName == currentName) {
                      Navigator.pop(context);
                      return;
                    }
                    try {
                      await _categoryService.updateCustomCategory(catId, newName);
                      await _loadCategories();
                      Navigator.pop(context);
                      widget.onChanged(newName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category updated'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.categoryExistsText ?? 'Category already exists!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(widget.addButtonText ?? 'Save'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteCategory(catId, currentName);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(widget.deleteCategoryText ?? 'Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelButtonText ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.deleteCategoryText ?? 'Delete Category'),
        content: Text('${widget.deleteConfirmText ?? 'Are you sure you want to delete'} "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelButtonText ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _categoryService.deleteCustomCategory(id);
              await _loadCategories();
              Navigator.pop(context);
              if (widget.selectedValue == name) {
                if (_filteredCategories.isNotEmpty) {
                  widget.onChanged(_filteredCategories.first['key'] as String);
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Category deleted'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==================== ADD CATEGORY DIALOG (with smaller icons + suggestion) ====================
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = Colors.blue;

    // Full icon list (all new icons included)
    List<IconData> iconList = [
      // Common
      Icons.category, Icons.label, Icons.bookmark, Icons.star, Icons.favorite,
      // Work & Business
      Icons.work, Icons.business, Icons.business_center, Icons.store, Icons.storefront,
      // Shopping
      Icons.shopping_bag, Icons.shopping_cart, Icons.shopping_basket,
      // Food & Drink (fish, meat, vegetable)
      Icons.fastfood, Icons.restaurant, Icons.lunch_dining, Icons.dinner_dining,
      Icons.icecream, Icons.cake, Icons.coffee,
      Icons.ramen_dining, Icons.takeout_dining, Icons.kebab_dining, // meat
      Icons.eco, Icons.local_florist, Icons.grass, // vegetable
      Icons.bakery_dining, Icons.set_meal, // fish & bakery
      // Home & Living
      Icons.home, Icons.house, Icons.apartment, Icons.cottage, Icons.garage,
      // Transport
      Icons.directions_bus, Icons.directions_car, Icons.directions_bike,
      Icons.directions_railway, Icons.flight, Icons.directions_boat, Icons.local_taxi,
      // Education
      Icons.school, Icons.book, Icons.library_books, Icons.menu_book, Icons.auto_stories,
      // Health & Medicine
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
      // Clothing
      Icons.checkroom, Icons.face_retouching_natural,
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
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category name with auto‑suggestion
                  TextField(
                    controller: nameController,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        final suggested = _suggestIcon(value.trim());
                        if (suggested != selectedIcon) {
                          setDialogState(() => selectedIcon = suggested);
                        }
                      }
                    },
                    decoration: InputDecoration(
                      labelText: widget.categoryNameLabel ?? 'Category Name',
                      hintText: 'e.g., Fish, Salary, Medicine...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(selectedIcon, color: Colors.blue),
                        onPressed: null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text('Select Icon', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Small icon grid (8 columns)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: iconList.length,
                    itemBuilder: (context, index) {
                      final icon = iconList[index];
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              size: 20,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.cancelButtonText ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a name'), backgroundColor: Colors.red),
                  );
                  return;
                }
                try {
                  await _categoryService.addCustomCategory(
                    name,
                    selectedIcon,
                    selectedColor,
                    type: widget.filterType,
                  );
                  await _loadCategories();
                  Navigator.pop(context);
                  widget.onChanged(name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category added'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.categoryExistsText ?? 'Category already exists!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text(widget.addButtonText ?? 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DROPDOWN ITEMS (with pencil icon for custom) ====================
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    for (var cat in _filteredCategories) {
      final isCustom = cat['isCustom'] == true;
      final childWidget = Row(
        children: [
          Icon(cat['icon'] as IconData, size: 20, color: cat['color'] as Color),
          const SizedBox(width: 10),
          Expanded(child: Text(_getDisplayName(cat))),
          if (isCustom) ...[
            GestureDetector(
              onTap: () => _showEditDeleteDialog(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 2),
                    Text(
                      '✎',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
      final wrappedChild = isCustom
          ? GestureDetector(
              onLongPress: () => _showEditDeleteDialog(cat),
              child: childWidget,
            )
          : childWidget;
      items.add(DropdownMenuItem<String>(
        value: cat['key'] as String,
        child: wrappedChild,
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