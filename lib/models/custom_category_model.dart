import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'custom_category_model.g.dart';

@HiveType(typeId: 3)
class CustomCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nameKey;

  @HiveField(2)
  int iconCode;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  bool isPredefined;

  @HiveField(5)  // ✅ new field
  String? type;  // 'Income' or 'Expense'

  CustomCategory({
    required this.id,
    required this.nameKey,
    required this.iconCode,
    required this.colorValue,
    this.isPredefined = false,
    this.type,
  });
}