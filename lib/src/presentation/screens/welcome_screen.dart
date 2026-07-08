import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../widgets/app_widgets.dart';

enum _AuthMode { signUp, login }

bool _usesSimpleWelcome(double maxWidth) {
  return maxWidth < 920 ||
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
}

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
  bool _showAuth = false;
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final simpleWelcome = _usesSimpleWelcome(constraints.maxWidth);
          final form = _AuthPanel(
            formKey: _formKey,
            isBusy: _isBusy,
            isLogin: _isLogin,
            authLoading: _authLoading,
            resetLoading: _resetLoading,
            hidePassword: _hidePassword,
            emailController: _emailController,
            passwordController: _passwordController,
            emailFocus: _emailFocus,
            passwordFocus: _passwordFocus,
            error: _error,
            compact: simpleWelcome,
            onSetMode: _setMode,
            onSubmit: _submit,
            onResetPassword: _resetPassword,
            onTogglePassword: () => setState(
              () => _hidePassword = !_hidePassword,
            ),
          );

          return SelectionArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LandingHero(
                    form: form,
                    isBusy: _isBusy,
                    compactWelcome: simpleWelcome,
                    showAuth: _showAuth,
                    onShowAuth: _showAuthPanel,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setMode(_AuthMode mode) {
    if (_isBusy) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  void _showAuthPanel(_AuthMode mode) {
    if (_isBusy) return;
    setState(() {
      _mode = mode;
      _showAuth = true;
      _error = null;
    });
    _emailFocus.requestFocus();
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
            'Si un compte existe pour cet email, un lien de réinitialisation vient d être envoyé.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }
}

class _LandingHero extends StatelessWidget {
  const _LandingHero({
    required this.form,
    required this.isBusy,
    required this.compactWelcome,
    required this.showAuth,
    required this.onShowAuth,
  });

  final Widget form;
  final bool isBusy;
  final bool compactWelcome;
  final bool showAuth;
  final ValueChanged<_AuthMode> onShowAuth;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final compact = compactWelcome || viewport.width < 560;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OceanColors.deep,
            OceanColors.navy,
            OceanColors.obsidian,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 48,
            vertical: compact ? 30 : 44,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: showAuth
                    ? _AuthEntryContent(
                        key: const ValueKey('auth'),
                        form: form,
                        compact: compact,
                      )
                    : _WelcomeContent(
                        key: const ValueKey('welcome'),
                        isBusy: isBusy,
                        compact: compact,
                        onShowAuth: onShowAuth,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({
    required this.isBusy,
    required this.compact,
    required this.onShowAuth,
    super.key,
  });

  final bool isBusy;
  final bool compact;
  final ValueChanged<_AuthMode> onShowAuth;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - (compact ? 48 : 96);
    final contentWidth = math.max(
      180.0,
      math.min(compact ? 420.0 : 610.0, availableWidth),
    );
    final maxLogoWidth = compact ? 390.0 : 620.0;
    final logoWidth = math.max(
      180.0,
      math.min(maxLogoWidth, contentWidth),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          image: true,
          label: 'BlueWater Match. SAIL. MATCH. CONNECT.',
          child: SizedBox(
            width: logoWidth,
            child: Image.asset(
              bwmLogoFinalAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(height: compact ? 28 : 42),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: Text(
            'Rencontrez des personnes qui partagent la vie à bord.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OceanColors.cream,
              fontFamily: OceanTypography.uiFamily,
              fontFamilyFallback: OceanTypography.uiFallback,
              fontSize: compact ? 21 : 28,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: Text(
            'Une application de rencontre pour celles et ceux qui vivent, naviguent ou rêvent de vie en bateau.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: OceanColors.cream.withValues(alpha: 0.78),
                  fontSize: compact ? 15.5 : 18,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  letterSpacing: 0,
                ),
          ),
        ),
        SizedBox(height: compact ? 30 : 42),
        _WelcomeActions(
          compact: compact,
          maxWidth: contentWidth,
          isBusy: isBusy,
          onShowAuth: onShowAuth,
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    required this.compact,
    required this.maxWidth,
    required this.isBusy,
    required this.onShowAuth,
  });

  final bool compact;
  final double maxWidth;
  final bool isBusy;
  final ValueChanged<_AuthMode> onShowAuth;

  @override
  Widget build(BuildContext context) {
    final createButton = ElevatedButton(
      onPressed: isBusy ? null : () => onShowAuth(_AuthMode.signUp),
      style: ElevatedButton.styleFrom(
        minimumSize: compact ? const Size.fromHeight(54) : const Size(190, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: OceanColors.copper,
        foregroundColor: OceanColors.obsidian,
        textStyle: const TextStyle(
          fontFamily: OceanTypography.uiFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0,
        ),
      ),
      child: const Text('Créer un compte'),
    );

    final loginButton = OutlinedButton(
      onPressed: isBusy ? null : () => onShowAuth(_AuthMode.login),
      style: OutlinedButton.styleFrom(
        minimumSize: compact ? const Size.fromHeight(54) : const Size(170, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        foregroundColor: OceanColors.cream,
        side: BorderSide(color: OceanColors.cream.withValues(alpha: 0.42)),
        textStyle: const TextStyle(
          fontFamily: OceanTypography.uiFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0,
        ),
      ),
      child: const Text('Se connecter'),
    );

    if (compact) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            createButton,
            const SizedBox(height: 10),
            loginButton,
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          createButton,
          const SizedBox(width: 14),
          loginButton,
        ],
      ),
    );
  }
}

class _AuthEntryContent extends StatelessWidget {
  const _AuthEntryContent({
    required this.form,
    required this.compact,
    super.key,
  });

  final Widget form;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: PremiumLogoMark(size: compact ? 86 : 104)),
        SizedBox(height: compact ? 22 : 28),
        form,
      ],
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.formKey,
    required this.isBusy,
    required this.isLogin,
    required this.authLoading,
    required this.resetLoading,
    required this.hidePassword,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.error,
    required this.onSetMode,
    required this.onSubmit,
    required this.onResetPassword,
    required this.onTogglePassword,
    this.compact = false,
  });

  final GlobalKey<FormState> formKey;
  final bool isBusy;
  final bool isLogin;
  final bool authLoading;
  final bool resetLoading;
  final bool hidePassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final String? error;
  final bool compact;
  final ValueChanged<_AuthMode> onSetMode;
  final VoidCallback onSubmit;
  final VoidCallback onResetPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final isCompact = compact || MediaQuery.sizeOf(context).width < 480;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.navy.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.cream.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLogin ? 'Bon retour à bord' : 'Bienvenue à bord',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: OceanTypography.brandFamily,
                fontFamilyFallback: OceanTypography.brandFallback,
                color: OceanColors.cream,
                fontSize: isCompact ? 30 : 36,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            SegmentedButton<_AuthMode>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? OceanColors.copper.withValues(alpha: 0.22)
                      : OceanColors.obsidian.withValues(alpha: 0.32),
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? OceanColors.cream
                      : OceanColors.muted,
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(color: OceanColors.cream.withValues(alpha: 0.18)),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: _AuthMode.signUp,
                  label: Text('Créer'),
                ),
                ButtonSegment(
                  value: _AuthMode.login,
                  label: Text('Connexion'),
                ),
              ],
              selected: {isLogin ? _AuthMode.login : _AuthMode.signUp},
              onSelectionChanged:
                  isBusy ? null : (selection) => onSetMode(selection.first),
            ),
            SizedBox(height: isCompact ? 14 : 18),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    focusNode: emailFocus,
                    enabled: !isBusy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 12),
                  TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocus,
                    enabled: !isBusy,
                    obscureText: hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: [
                      if (isLogin)
                        AutofillHints.password
                      else
                        AutofillHints.newPassword,
                    ],
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: hidePassword
                            ? 'Afficher le mot de passe'
                            : 'Masquer le mot de passe',
                        onPressed: isBusy ? null : onTogglePassword,
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              _AuthError(message: error!),
            ],
            SizedBox(height: isCompact ? 14 : 18),
            ElevatedButton(
              onPressed: isBusy ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(isCompact ? 50 : 54),
                backgroundColor: OceanColors.copper,
                foregroundColor: OceanColors.obsidian,
                elevation: 0,
              ),
              child: Text(
                authLoading
                    ? 'Veuillez patienter...'
                    : isLogin
                        ? 'Se connecter'
                        : 'Créer un compte',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isBusy ? null : onResetPassword,
              child: Text(
                resetLoading ? 'Envoi en cours...' : 'Mot de passe oublié',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.copper.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.copper.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: OceanColors.copper),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: OceanColors.cream,
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
    return 'Le mot de passe doit contenir au moins 8 caractères.';
  }
  return null;
}
