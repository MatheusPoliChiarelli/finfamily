import 'package:flutter/material.dart';

import '../data/banks.dart';
import '../theme/app_theme.dart';

class BankSelector extends StatelessWidget {
  const BankSelector({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: Banks.all.map((bank) {
        final selected = bank.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onSelect(bank.id),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 44,
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
              decoration: BoxDecoration(
                color: selected ? bank.color.withValues(alpha: 0.14) : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? bank.color : AppColors.border,
                  width: selected ? 1 : 0.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: bank.color.withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bank.logo != null
                          ? Colors.white
                          : (selected ? bank.color : bank.color.withValues(alpha: 0.22)),
                    ),
                    child: bank.logo != null
                        ? Padding(
                            padding: const EdgeInsets.all(3),
                            child: Image.asset(bank.logo!, fit: BoxFit.contain),
                          )
                        : Text(
                            bank.short,
                            style: AppTheme.ui(
                              13,
                              color: selected ? bank.onColor : bank.color,
                              weight: FontWeight.w500,
                            ),
                          ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    bank.name,
                    style: AppTheme.ui(
                      13,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      weight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}