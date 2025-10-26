import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';

class CategoryService {
  static final CategoryService instance = CategoryService._init();
  CategoryService._init();

  static const String _categoriesKey = 'custom_categories';
  SharedPreferences? _prefs;
  List<EventCategory> _customCategories = [];

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<EventCategory>> getAllCategories() async {
    await _ensureInitialized();
    await _loadCustomCategories();

    // Combinar categorías predefinidas con personalizadas
    return [...DefaultCategories.categories, ..._customCategories];
  }

  Future<List<EventCategory>> getCustomCategories() async {
    await _ensureInitialized();
    await _loadCustomCategories();
    return List.from(_customCategories);
  }

  Future<void> _loadCustomCategories() async {
    final String? categoriesJson = _prefs?.getString(_categoriesKey);
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      final List<dynamic> categoriesList = json.decode(categoriesJson);
      _customCategories = categoriesList
          .map((e) => EventCategory.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveCustomCategories() async {
    final categoriesList = _customCategories.map((e) => e.toMap()).toList();
    await _prefs?.setString(_categoriesKey, json.encode(categoriesList));
  }

  Future<void> createCategory(EventCategory category) async {
    await _ensureInitialized();
    await _loadCustomCategories();

    final customCategory = category.copyWith(isCustom: true);
    _customCategories.add(customCategory);
    await _saveCustomCategories();
  }

  Future<void> updateCategory(EventCategory category) async {
    await _ensureInitialized();
    await _loadCustomCategories();

    final index = _customCategories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _customCategories[index] = category;
      await _saveCustomCategories();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    await _ensureInitialized();
    await _loadCustomCategories();

    _customCategories.removeWhere((c) => c.id == categoryId);
    await _saveCustomCategories();
  }

  Future<EventCategory?> getCategoryById(String id) async {
    final allCategories = await getAllCategories();
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
