import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/custom_category_model.dart';

extension ListExt<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  Box<CustomCategory>? _customBox;

  Future<void> init() async {
    if (_customBox == null || !(_customBox?.isOpen ?? false)) {
      _customBox = await Hive.openBox<CustomCategory>('custom_categories');
    }
  }

  // ✅ Removed 'other' from predefined list (user wants to delete it)
  List<Map<String, dynamic>> get predefinedCategories => const [
    // Expense categories
    {'key': 'gas_bill', 'icon': Icons.electric_bolt, 'color': Colors.red},
    {'key': 'electricity_bill', 'icon': Icons.electric_bolt, 'color': Colors.amber},
    {'key': 'house_rent', 'icon': Icons.house, 'color': Colors.orange},
    {'key': 'internet_bill', 'icon': Icons.wifi, 'color': Colors.blue},
    {'key': 'water_bill', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {'key': 'transport', 'icon': Icons.directions_bus, 'color': Colors.green},
    {'key': 'grocery', 'icon': Icons.shopping_cart, 'color': Colors.deepOrange},
    {'key': 'education', 'icon': Icons.school, 'color': Colors.purple},
    {'key': 'medical', 'icon': Icons.medical_services, 'color': Colors.redAccent},
    {'key': 'food', 'icon': Icons.restaurant, 'color': Colors.amber},
    {'key': 'mobile_bill', 'icon': Icons.phone_android, 'color': Colors.indigo},
    {'key': 'entertainment', 'icon': Icons.tv, 'color': Colors.pink},
    // Income categories
    {'key': 'salary', 'icon': Icons.work, 'color': Colors.green},
    {'key': 'business', 'icon': Icons.store, 'color': Colors.blue},
    // 'other' removed → user requested delete
  ];

  List<Map<String, dynamic>> get allCategories {
    final result = <Map<String, dynamic>>[];
    result.addAll(predefinedCategories);

    if (_customBox != null && _customBox!.isOpen) {
      for (var cat in _customBox!.values) {
        result.add({
          'key': cat.nameKey,
          'icon': IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
          'color': Color(cat.colorValue),
          'isCustom': true,
          'id': cat.id,
          'type': cat.type,    // ✅ pass the stored type
        });
      }
    }
    return result;
  }

  // ✅ Accept type parameter
  Future<void> addCustomCategory(String name, IconData icon, Color color, {String? type}) async {
    await init();
    final newCat = CustomCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nameKey: name,
      iconCode: icon.codePoint,
      colorValue: color.value,
      isPredefined: false,
      type: type,   // ✅ store type
    );
    await _customBox!.add(newCat);
  }

  Future<void> updateCustomCategory(String id, String newName) async {
    await init();
    final cat = _customBox!.values.firstWhereOrNull((c) => c.id == id);
    if (cat != null) {
      cat.nameKey = newName;
      await cat.save();
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    await init();
    final cat = _customBox!.values.firstWhereOrNull((c) => c.id == id);
    if (cat != null) {
      await cat.delete();
    }
  }
}