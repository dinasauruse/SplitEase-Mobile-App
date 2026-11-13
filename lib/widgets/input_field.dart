import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auto_id.dart';

/// Shared input formatters.
class InputFormats {
  InputFormats._();

  /// Digits, a dot and a minus sign. The minus sign and dot are deliberately
  /// allowed so that negative / decimal input can reach validation (and be
  /// covered by automated negative tests); letters are blocked.
  static final List<TextInputFormatter> numeric = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
    LengthLimitingTextInputFormatter(14),
  ];
}

/// Rounded text field with a stable automation id and a separately
/// identifiable error message (`<id>_error`).
class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.id,
    required this.label,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.textInputAction,
  });

  final String id;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = errorText;

    OutlineInputBorder errorBorder(double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoId(
          id: id,
          child: TextField(
            key: Key(id),
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            decoration: InputDecoration(
              labelText: label,
              prefixText: prefixText,
              suffixText: suffixText,
              enabledBorder: error != null ? errorBorder(1.5) : null,
              focusedBorder: error != null ? errorBorder(2) : null,
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: AutoId(
              id: '${id}_error',
              child: Text(
                error,
                key: Key('${id}_error'),
                style: TextStyle(color: scheme.error, fontSize: 12.5),
              ),
            ),
          ),
      ],
    );
  }
}
