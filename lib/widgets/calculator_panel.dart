import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

class CalculatorPanel extends StatefulWidget {
  const CalculatorPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<CalculatorPanel> createState() => _CalculatorPanelState();
}

class _CalculatorPanelState extends State<CalculatorPanel> {
  final _focus = FocusNode();

  String _display = '0';
  String _history = '';
  double? _accumulator;
  String? _operation;
  bool _resetOnNextDigit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _current => double.tryParse(_display.replaceAll(',', '.')) ?? 0;

  void _typeDigit(String d) {
    setState(() {
      if (_resetOnNextDigit || _display == '0') {
        _display = d;
        _resetOnNextDigit = false;
      } else {
        _display += d;
      }
    });
  }

  void _typeDecimal() {
    setState(() {
      if (_resetOnNextDigit) {
        _display = '0,';
        _resetOnNextDigit = false;
        return;
      }
      if (!_display.contains(',')) _display += ',';
    });
  }

  void _setOperation(String op) {
    setState(() {
      if (_accumulator != null && _operation != null && !_resetOnNextDigit) {
        _accumulator = _apply(_accumulator!, _current, _operation!);
        _display = _format(_accumulator!);
      } else {
        _accumulator = _current;
      }
      _history = '${_format(_accumulator!)} ${_symbol(op)}';
      _operation = op;
      _resetOnNextDigit = true;
    });
  }

  void _equals() {
    if (_accumulator == null || _operation == null) return;
    setState(() {
      final result = _apply(_accumulator!, _current, _operation!);
      _history = '$_history $_display =';
      _display = _format(result);
      _accumulator = null;
      _operation = null;
      _resetOnNextDigit = true;
    });
  }

  String _symbol(String op) {
    switch (op) {
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return op;
    }
  }

  double _apply(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b == 0 ? 0 : a / b;
      default:
        return b;
    }
  }

  String _format(double v) {
    final text = v.toStringAsFixed(2).replaceAll('.', ',');
    return text.endsWith(',00') ? text.substring(0, text.length - 3) : text;
  }

  void _clear() {
    setState(() {
      _display = '0';
      _history = '';
      _accumulator = null;
      _operation = null;
      _resetOnNextDigit = false;
    });
  }

  void _backspace() {
    setState(() {
      if (_display.length <= 1) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  Future<void> _copyAndClose() async {
    await Clipboard.setData(ClipboardData(text: plain(_current)));
    widget.onClose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _equals();
      return;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return;
    }

    final digits = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    final digit = digits[key];
    if (digit != null) {
      _typeDigit(digit);
      return;
    }

    final operations = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.add: '+',
      LogicalKeyboardKey.numpadAdd: '+',
      LogicalKeyboardKey.minus: '-',
      LogicalKeyboardKey.numpadSubtract: '-',
      LogicalKeyboardKey.asterisk: '*',
      LogicalKeyboardKey.numpadMultiply: '*',
      LogicalKeyboardKey.slash: '/',
      LogicalKeyboardKey.numpadDivide: '/',
    };

    final op = operations[key];
    if (op != null) {
      _setOperation(op);
      return;
    }

    if (key == LogicalKeyboardKey.comma || key == LogicalKeyboardKey.period) {
      _typeDecimal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Calculadora', style: AppTheme.ui(13, color: AppColors.accent)),
                  const Spacer(),
                  InkWell(
                    onTap: widget.onClose,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _history,
                          style: AppTheme.uiMoney(12, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 34,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(_display, style: AppTheme.displayMoney(28)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _row(['C', '⌫', '/', '*']),
              const SizedBox(height: 8),
              _row(['7', '8', '9', '-']),
              const SizedBox(height: 8),
              _row(['4', '5', '6', '+']),
              const SizedBox(height: 8),
              _row(['1', '2', '3', '=']),
              const SizedBox(height: 8),
              _row(['0', ',']),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _copyAndClose,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar resultado'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> labels) {
    return Row(
      children: List.generate(labels.length, (i) {
        final label = labels[i];
        final wide = labels.length == 2 && i == 0;
        return Expanded(
          flex: wide ? 3 : 1,
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
            child: _key(label),
          ),
        );
      }),
    );
  }

  Widget _key(String label) {
    final isOperation = ['+', '-', '*', '/', '='].contains(label);
    final isAction = label == 'C' || label == '⌫';

    final color = isOperation
        ? AppColors.accent
        : isAction
            ? AppColors.expense
            : AppColors.textPrimary;

    return InkWell(
      onTap: () {
        switch (label) {
          case 'C':
            _clear();
            break;
          case '⌫':
            _backspace();
            break;
          case '=':
            _equals();
            break;
          case ',':
            _typeDecimal();
            break;
          case '+':
          case '-':
          case '*':
          case '/':
            _setOperation(label);
            break;
          default:
            _typeDigit(label);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOperation ? AppColors.accentSoft : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOperation ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(label, style: AppTheme.ui(16, color: color, weight: FontWeight.w500)),
      ),
    );
  }
}