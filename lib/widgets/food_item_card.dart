import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../services/bill_calculation_service.dart';
import '../utils/money.dart';
import 'auto_id.dart';
import 'input_field.dart';

/// Editable order line: name, unit price, quantity, live subtotal, remove.
class FoodItemCard extends StatefulWidget {
  const FoodItemCard({
    super.key,
    required this.item,
    required this.showErrors,
    required this.onChanged,
    required this.onRemove,
  });

  final FoodItem item;

  /// When true, empty/required fields also show their error.
  final bool showErrors;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _quantity;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _price = TextEditingController(text: widget.item.priceText);
    _quantity = TextEditingController(text: widget.item.quantityText);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  String? _visible(String raw, String? error) =>
      (raw.trim().isNotEmpty || widget.showErrors) ? error : null;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final id = item.id;
    final subtotal = BillCalculationService.liveItemSubtotalCents(item);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D5D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputField(
            id: 'item_name_$id',
            label: 'Item name',
            controller: _name,
            textInputAction: TextInputAction.next,
            errorText:
                _visible(item.name, BillCalculationService.validateItemName(item.name)),
            onChanged: (v) {
              item.name = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: InputField(
                  id: 'item_price_$id',
                  label: 'Unit price',
                  prefixText: 'Rp ',
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  inputFormatters: InputFormats.numeric,
                  errorText: _visible(item.priceText,
                      BillCalculationService.validateUnitPrice(item.priceText)),
                  onChanged: (v) {
                    item.priceText = v;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InputField(
                  id: 'item_quantity_$id',
                  label: 'Qty',
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  inputFormatters: InputFormats.numeric,
                  errorText: _visible(item.quantityText,
                      BillCalculationService.validateQuantity(item.quantityText)),
                  onChanged: (v) {
                    item.quantityText = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Subtotal: '),
              AutoId(
                id: 'item_subtotal_$id',
                child: Text(
                  Money.formatRupiah(subtotal),
                  key: Key('item_subtotal_$id'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              AutoId(
                id: 'remove_item_$id',
                child: IconButton(
                  key: Key('remove_item_$id'),
                  tooltip: 'Remove item',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onRemove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
