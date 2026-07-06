import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../widgets/app_widgets.dart';

enum _AuthMode { signUp, login }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  _AuthMode _mode = _AuthMode.signUp;
  bool _hidePassword = true;
  bool _authLoading = false;
  bool _resetLoading = false;
  String? _error;

  bool get _isLogin => _mode == _AuthMode.login;
  bool get _isBusy => _authLoading || _resetLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Connexion' : 'Inscription';
    final subtitle = _isLogin
        ? 'Retrouvez votre compte et vos conversations.'
        : 'Creez un compte puis verifiez votre email avant de commencer.';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 28),
            const AppLogo(),
            const SizedBox(height: 28),
            Text(
              'Rencontrez des personnes qui comprennent la vie a bord.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: OceanColors.ink,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Un compte actif protege les profils, la decouverte et les messages.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: OceanColors.muted),
            ),
            const SizedBox(height: 20),
            const PrivacyNote(),
            const SizedBox(height: 16),
            SectionCard(
              title: title,
              subtitle: subtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_AuthMode>(
                    segments: const [
                      ButtonSegment(
                        value: _AuthMode.signUp,
                        label: Text('Inscription'),
                        icon: Icon(Icons.person_add_alt_1_outlined),
                      ),
                      ButtonSegment(
                        value: _AuthMode.login,
                        label: Text('Connexion'),
                        icon: Icon(Icons.login),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _isBusy
                        ? null
                        : (selection) {
                            setState(() {
                              _mode = selection.first;
                              _error = null;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          enabled: !_isBusy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          enabled: !_isBusy,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            if (_isLogin)
                              AutofillHints.password
                            else
                              AutofillHints.newPassword,
                          ],
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: _isBusy
                                  ? null
                                  : () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _AuthError(message: _error!),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _submit,
                    icon: Icon(_isLogin ? Icons.login : Icons.person_add_alt_1),
                    label: Text(
                      _authLoading
                          ? 'Veuillez patienter...'
                          : _isLogin
                              ? 'Se connecter'
                              : 'Creer mon compte',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isBusy ? null : _resetPassword,
                    icon: const Icon(Icons.help_outline),
                    label: Text(
                      _resetLoading
                          ? 'Envoi en cours...'
                          : 'Mot de passe oublie',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _authLoading = true;
      _error = null;
    });
    final controller = OceanMatchScope.of(context);
    try {
      if (_isLogin) {
        await controller.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await controller.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      _emailFocus.requestFocus();
      return;
    }
    setState(() {
      _resetLoading = true;
      _error = null;
    });
    try {
      await OceanMatchScope.of(context).requestPasswordReset(
        _emailController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si un compte existe pour cet email, un lien de reinitialisation vient d etre envoye.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (email.isEmpty) return 'Entrez votre email.';
    if (!emailPattern.hasMatch(email)) {
      return 'Entrez une adresse email valide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Entrez votre mot de passe.';
    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caracteres.';
    }
    return null;
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.coral.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.coral.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: OceanColors.coral),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: OceanColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
