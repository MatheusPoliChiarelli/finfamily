import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'password_dialog.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentSoft,
                    border: Border.all(color: AppColors.accent, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '\$',
                    style: AppTheme.ui(15, color: AppColors.accent, weight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 11),
                Text('FinFamily', style: AppTheme.display(22)),
              ],
            ),
          ),
          _item('overview', Icons.grid_view_outlined, 'Visão geral'),
          _item('summary', Icons.insights_outlined, 'Resumo do mês'),
          _item('year', Icons.calendar_month_outlined, 'Resumo do ano'),
          _item('cars', Icons.directions_car_outlined, 'RobMotors'),
          _item('fashion', Icons.checkroom_outlined, 'Vise Versa'),

          const Spacer(),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: _userTile(context),
          ),
        ],
      ),
    );
  }


    Widget _userTile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Você';
    final email = user?.email ?? '';

    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts.first.substring(0, 1).toUpperCase()
            : (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(color: AppColors.borderAccent, width: 0.5),
          ),
          child: Text(
            initials,
            style: AppTheme.ui(12, color: AppColors.accent, weight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(13),
          ),
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, -100),
          padding: EdgeInsets.zero,
          splashRadius: 18,
          color: AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          onSelected: (value) {
            if (value == 'password') showPasswordDialog(context);
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(email, style: AppTheme.ui(11, color: AppColors.textMuted)),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'password',
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text('Alterar senha', style: AppTheme.ui(13)),
                ],
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.expand_less, size: 18, color: AppColors.textMuted),
          ),
        ),
        InkWell(
          onTap: onSignOut,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.logout, size: 17, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _item(String id, IconData icon, String label) {
    final active = selected == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: InkWell(
        onTap: () => onSelect(id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: active ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTheme.ui(
                  13,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  weight: active ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap, bool enabled) {
    return Tooltip(
      message: enabled ? '' : 'Escolha um banco para lançar',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.55), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 9),
                Text(label, style: AppTheme.ui(13, color: color, weight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }