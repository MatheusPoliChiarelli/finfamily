import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dashboard', style: AppTheme.display(28)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => AuthService().signOut(),
              child: Text('Sair', style: AppTheme.ui(13, color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}