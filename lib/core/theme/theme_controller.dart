import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _storageKey = 'pi_project_theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_storageKey);

    themeMode.value = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    Get.changeThemeMode(themeMode.value);
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();

    themeMode.value = nextMode;
    await prefs.setString(
      _storageKey,
      nextMode == ThemeMode.dark ? 'dark' : 'light',
    );
    Get.changeThemeMode(nextMode);
    update();
  }
}
