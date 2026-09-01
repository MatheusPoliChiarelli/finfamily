import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.month,
    required this.onShiftMonth,
    required this.onNewTransaction,
    required this.onSignOut,
  });

  final DateTime month;
  final ValueChanged<int> onShiftMonth;
  final VoidCallback onNewTransaction;
  final VoidCallback onSignOut;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Você';
    final email = user?.email ?? '';

    return Row(
      children: [
        Text('Visão geral', style: AppTheme.display(26)),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _arrow(Icons.chevron_left, () => onShiftMonth(-1)),
              SizedBox(
                width: 138,
                child: Text(
                  monthLabel(month),
                  textAlign: TextAlign.center,
                  style: AppTheme.ui(13, weight: FontWeight.w500),
                ),
              ),
              _arrow(Icons.chevron_right, () => onShiftMonth(1)),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: onNewTransaction,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo lançamento'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          color: AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          onSelected: (value) {
            if (value == 'signout') onSignOut();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.ui(13, weight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(email, style: AppTheme.ui(11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text('Sair', style: AppTheme.ui(13)),
                ],
              ),
            ),
          ],
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
              border: Border.all(color: AppColors.borderAccent, width: 0.5),
            ),
            child: Text(
              _initials(name),
              style: AppTheme.ui(13, color: AppColors.accent, weight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 17, color: AppColors.textSecondary),
      ),
    );
  }
}