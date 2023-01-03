import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/platform_infos.dart';

class ThemeBuilder extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    ThemeMode themeMode,
    Color? primaryColor,
  ) builder;

  final String themeModeSettingsKey;
  final String primaryColorSettingsKey;

  const ThemeBuilder({
    required this.builder,
    this.themeModeSettingsKey = 'theme_mode',
    this.primaryColorSettingsKey = 'primary_color',
    Key? key,
  }) : super(key: key);

  @override
  State<ThemeBuilder> createState() => ThemeController();
}

class ThemeController extends State<ThemeBuilder> {
  SharedPreferences? _sharedPreferences;
  ThemeMode? _themeMode;
  Color? _primaryColor;

  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;

  Color? get primaryColor => _primaryColor;

  static ThemeController of(BuildContext context) =>
      Provider.of<ThemeController>(
        context,
        listen: false,
      );

  void _loadData(_) async {
    final preferences =
        _sharedPreferences ??= await SharedPreferences.getInstance();

    final rawThemeMode = preferences.getString(widget.themeModeSettingsKey);
    final rawColor = preferences.getInt(widget.primaryColorSettingsKey);

    setState(() {
      _themeMode = ThemeMode.values
          .singleWhereOrNull((value) => value.name == rawThemeMode);
      _primaryColor = rawColor == null ? null : Color(rawColor);
    });
  }

  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    final preferences =
        _sharedPreferences ??= await SharedPreferences.getInstance();
    await preferences.setString(widget.themeModeSettingsKey, newThemeMode.name);
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  Future<void> setPrimaryColor(Color? newPrimaryColor) async {
    final preferences =
        _sharedPreferences ??= await SharedPreferences.getInstance();
    if (newPrimaryColor == null) {
      await preferences.remove(widget.primaryColorSettingsKey);
    } else {
      await preferences.setInt(
        widget.primaryColorSettingsKey,
        newPrimaryColor.value,
      );
    }
    setState(() {
      _primaryColor = newPrimaryColor;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_loadData);
    super.initState();
  }

  Color get systemAccentColor {
    if (PlatformInfos.isLinux) return AppConfig.chatColor;
    try {
      // a bad plugin implementation
      // https://github.com/bdlukaa/system_theme/issues/10
      final accentColor = SystemTheme.accentColor;
      final color = accentColor.accent;
      if (color == kDefaultSystemAccentColor) return AppConfig.chatColor;
      return color;
    } catch (_) {
      return AppConfig.chatColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: widget.builder(
        context,
        themeMode,
        primaryColor ?? systemAccentColor,
      ),
    );
  }
}
