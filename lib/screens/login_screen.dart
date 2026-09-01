import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Preencha e-mail e senha');
      return;
    }
    if (_isSignUp && _name.text.trim().isEmpty) {
      setState(() => _error = 'Informe seu nome');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await _auth.signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          inviteCode: _invite.text,
        );
      } else {
        await _auth.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _auth.messageFor(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FinFamily', style: AppTheme.display(30)),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Crie sua conta para começar'
                        : 'Entre para ver as contas do mês',
                    style: AppTheme.ui(14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (_isSignUp) ...[
                    TextField(
                      controller: _name,
                      style: AppTheme.ui(14),
                      decoration: const InputDecoration(hintText: 'Seu nome'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    style: AppTheme.ui(14),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    style: AppTheme.ui(14),
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(hintText: 'Senha'),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _invite,
                      style: AppTheme.ui(14),
                      decoration: const InputDecoration(
                        hintText: 'Código da casa (opcional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deixe em branco para criar uma casa nova',
                      style: AppTheme.ui(12, color: AppColors.textMuted),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onAccent,
                            ),
                          )
                        : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                    child: Text(
                      _isSignUp ? 'Já tenho conta' : 'Criar uma conta',
                      style: AppTheme.ui(13, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}