/// Font size setting enum.
/// 
/// Spec: docs/design/data-model/entities.md - Settings.FontSize
enum FontSize {
  /// Small font size (16sp)
  small(16),

  /// Medium font size (20sp) - default
  medium(20),

  /// Large font size (24sp)
  large(24),

  /// Extra large font size (28sp)
  extraLarge(28);

  const FontSize(this.size);

  /// The actual font size in sp
  final double size;

  /// Gets the scale factor relative to medium (default).
  double get scaleFactor {
    switch (this) {
      case FontSize.small:
        return 0.85;
      case FontSize.medium:
        return 1.0;
      case FontSize.large:
        return 1.2;
      case FontSize.extraLarge:
        return 1.4;
    }
  }

  /// Gets display name in Japanese.
  String get displayName {
    switch (this) {
      case FontSize.small:
        return '小';
      case FontSize.medium:
        return '中';
      case FontSize.large:
        return '大';
      case FontSize.extraLarge:
        return '特大';
    }
  }
}
