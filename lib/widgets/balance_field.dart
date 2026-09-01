import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

class BalanceField extends StatefulWidget {
  const BalanceField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.onSave,
    this.valueColor,
    this.borderColor,
    this.emptyText = '--',
  });

  final String label;
  final IconData icon;
  final double? value;
  final ValueChanged<double>? onSave;
  final Color? valueColor;
  final Color? borderColor;
  final String emptyText;

  @override
  State<BalanceField> createState() => _BalanceFieldState();
}

class _BalanceFieldState extends State<BalanceField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;

  bool get _readOnly => widget.onSave == null;

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
    if (_readOnly) return;
    final current = widget.value ?? 0;
    _controller.text = current == 0 ? '' : currencyMask(current);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
  }

  void _commit() {
    final parsed = parseCurrency(_controller.text);
    setState(() => _editing = false);
    if (parsed != widget.value) widget.onSave?.call(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final border = _editing ? AppColors.accent : (widget.borderColor ?? AppColors.border);
    final hasBorderAccent = widget.borderColor != null || _editing;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: border, width: hasBorderAccent ? 1 : 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 9),
          Text(widget.label, style: AppTheme.ui(12, color: AppColors.accent)),
          const SizedBox(width: 12),
          SizedBox(
            width: 124,
            child: _editing
                ? TextField(
                    controller: _controller,
                    focusNode: _focus,
                    style: AppTheme.uiMoney(14, weight: FontWeight.w500),
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    onSubmitted: (_) => _commit(),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: '0,00',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('R\$', style: AppTheme.uiMoney(14, color: AppColors.textSecondary)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
                              widget.value == null ? widget.emptyText : money(widget.value!),
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.uiMoney(
                                14,
                                color: widget.value == null ? AppColors.textMuted : widget.valueColor,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (!_readOnly) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_outlined, size: 13, color: AppColors.textMuted),
                          ],
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