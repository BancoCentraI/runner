part of '../theme.dart';

ThemeData _buildDarkTheme(ColorScheme cs, {String? fontFamily}) => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: cs,
  textTheme: _buildTextTheme(fontFamily: fontFamily),
  scaffoldBackgroundColor: Colors.transparent,
  appBarTheme: _appBarTheme,
  cardTheme: _darkCardTheme,
  inputDecorationTheme: _buildInputDecorationTheme(cs, Brightness.dark),
  elevatedButtonTheme: _buildElevatedButtonTheme(cs),
  filledButtonTheme: _buildFilledButtonTheme(cs),
  outlinedButtonTheme: _buildOutlinedButtonTheme(cs),
  chipTheme: _buildChipTheme(cs),
  sliderTheme: _buildSliderTheme(cs),
  switchTheme: _buildSwitchTheme(cs),
  dialogTheme: _dialogTheme,
  extensions: const [AppThemeColors.dark],
);
