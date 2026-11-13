/// One food or beverage order line belonging to a participant.
///
/// Price and quantity are kept as the raw text the user typed so that the
/// calculation service can validate them and report precise error messages.
class FoodItem {
  FoodItem({
    required this.id,
    this.name = '',
    this.priceText = '',
    this.quantityText = '1',
  });

  /// Stable identifier, unique for the lifetime of the app session.
  final int id;
  String name;
  String priceText;
  String quantityText;
}
