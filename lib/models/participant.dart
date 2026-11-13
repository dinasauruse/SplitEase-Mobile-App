import 'food_item.dart';

/// A person sharing the bill, with their own orders.
class Participant {
  Participant({
    required this.id,
    required this.name,
    List<FoodItem>? items,
  }) : items = items ?? <FoodItem>[];

  /// Stable identifier, unique for the lifetime of the app session.
  final int id;
  final String name;
  final List<FoodItem> items;
}
