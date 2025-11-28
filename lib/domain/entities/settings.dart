import 'font_size.dart';

/// Application settings entity.
/// 
/// Spec: docs/design/data-model/entities.md - Settings
class Settings {
  /// Creates a new Settings instance.
  const Settings({
    this.fontSize = FontSize.medium,
    this.notificationEnabled = true,
    this.recentMemoCount = 5,
  }) : assert(
         recentMemoCount >= 1 && recentMemoCount <= 20,
         'recentMemoCount must be between 1 and 20',
       );

  /// Font size setting
  final FontSize fontSize;

  /// Whether notifications are enabled
  final bool notificationEnabled;

  /// Number of recent memos to display on home screen
  /// MUST be between 1 and 20
  final int recentMemoCount;

  /// Default settings
  static const Settings defaultSettings = Settings();

  /// Creates a copy with updated fields.
  Settings copyWith({
    FontSize? fontSize,
    bool? notificationEnabled,
    int? recentMemoCount,
  }) {
    return Settings(
      fontSize: fontSize ?? this.fontSize,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      recentMemoCount: recentMemoCount ?? this.recentMemoCount,
    );
  }
}
