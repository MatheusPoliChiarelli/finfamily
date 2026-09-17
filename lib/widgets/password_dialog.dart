import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

Future<void> showPasswordDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _PasswordDialog());

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _auth = AuthService();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_current.text.isEmpty) {
      setState(() => _error = 'Informe a senha atual');
      return;
    }
    if (_newPassword.text.length < 6) {
      setState(() => _error = 'A nova senha precisa ter ao menos 6 caracteres');
      return;
    }
    if (_newPassword.text != _confirm.text) {
      setState(() => _error = 'As senhas não coincidem');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.changePassword(_current.text, _newPassword.text);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = _auth.messageFor(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): _save,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): _save,
          },
          child: Focus(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: _done ? _successView() : _formView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.income.withValues(alpha: 0.14),
            border: Border.all(color: AppColors.income.withValues(alpha: 0.5), width: 0.5),
          ),
          child: const Icon(Icons.check, size: 24, color: AppColors.income),
        ),
        const SizedBox(height: 18),
        Text('Senha alterada', style: AppTheme.display(24), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Use a nova senha no próximo acesso',
          style: AppTheme.ui(13, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Alterar senha', style: AppTheme.display(24)),
        const SizedBox(height: 4),
        Text(
          'Confirme a senha atual por segurança',
          style: AppTheme.ui(12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        Text('Senha atual', style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _current,
          autofocus: true,
          obscureText: true,
          style: AppTheme.ui(14),
          decoration: const InputDecoration(hintText: 'Sua senha de hoje'),
        ),
        const SizedBox(height: 18),
        Text('Nova senha', style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _newPassword,
          obscureText: true,
          style: AppTheme.ui(14),
          decoration: const InputDecoration(hintText: 'Ao menos 6 caracteres'),
        ),
        const SizedBox(height: 18),
        Text('Confirmar nova senha', style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirm,
          obscureText: true,
          style: AppTheme.ui(14),
          onSubmitted: (_) => _save(),
          decoration: const InputDecoration(hintText: 'Repita a nova senha'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
        ],
        const SizedBox(height: 26),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                )
              : const Text('Alterar senha'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTheme.ui(13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}