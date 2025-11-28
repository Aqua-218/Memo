/// Category enum for dictionary entries.
/// 
/// Spec: docs/design/data-model/entities.md - DictionaryEntry.Category
enum Category {
  /// Person name (家族、友人、知人など)
  person,

  /// Place name (住所、お店、施設など)
  place,

  /// Event or schedule (イベント、約束など)
  event,

  /// Medical (薬、病院、症状など)
  medical,

  /// Other category
  other,
}

/// Extension for Category enum.
extension CategoryExtension on Category {
  /// Converts category to storage string.
  String toStorageString() {
    switch (this) {
      case Category.person:
        return 'person';
      case Category.place:
        return 'place';
      case Category.event:
        return 'event';
      case Category.medical:
        return 'medical';
      case Category.other:
        return 'other';
    }
  }

  /// Converts storage string to category.
  static Category fromStorageString(String value) {
    switch (value) {
      case 'person':
        return Category.person;
      case 'place':
        return Category.place;
      case 'event':
        return Category.event;
      case 'medical':
        return Category.medical;
      case 'other':
      default:
        return Category.other;
    }
  }

  /// Gets display name in Japanese.
  String get displayName {
    switch (this) {
      case Category.person:
        return '人物';
      case Category.place:
        return '場所';
      case Category.event:
        return '予定';
      case Category.medical:
        return '医療';
      case Category.other:
        return 'その他';
    }
  }

  /// Converts display name to category.
  static Category fromDisplayName(String name) {
    switch (name) {
      case '人物':
        return Category.person;
      case '場所':
        return Category.place;
      case '予定':
        return Category.event;
      case '医療':
        return Category.medical;
      case 'その他':
      default:
        return Category.other;
    }
  }
}
