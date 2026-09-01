import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

class OpeningBalanceField extends StatefulWidget {
  const OpeningBalanceField({
    super.key,
    required this.value,
    required this.onSave,
  });

  final double value;
  final ValueChanged<double> onSave;

  @override
  State<OpeningBalanceField> createState() => _OpeningBalanceFieldState();
}

class _OpeningBalanceFieldState extends State<OpeningBalanceField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    _controller.text = widget.value == 0 ? '' : currencyMask(widget.value);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
  }

  void _commit() {
    final parsed = parseCurrency(_controller.text);
    setState(() => _editing = false);
    if (parsed != widget.value) widget.onSave(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _editing ? AppColors.accent : AppColors.border,
          width: _editing ? 1 : 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.savings_outlined, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 9),
          Text('Saldo inicial', style: AppTheme.ui(12, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          SizedBox(
            width: 132,
            child: _editing
                ? TextField(
                    controller: _controller,
                    focusNode: _focus,
                    style: AppTheme.uiMoney(14, weight: FontWeight.w500),
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    onSubmitted: (_) => _commit(),
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: '0,00',
                      prefixText: 'R\$ ',
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  )
                : InkWell(
                    onTap: _start,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              money(widget.value),
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.uiMoney(14, weight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 13, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}