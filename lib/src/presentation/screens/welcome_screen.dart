import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../widgets/app_widgets.dart';

enum _AuthMode { signUp, login }

const _heroImagePath = 'assets/images/landing-hero.png';

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
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _safetyKey = GlobalKey();
  final _howKey = GlobalKey();
  final _audienceKey = GlobalKey();

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelectionArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _LandingHero(
                isBusy: _isBusy,
                isLogin: _isLogin,
                onSetMode: _setMode,
                onScrollToFeatures: () => _scrollTo(_featuresKey),
                onScrollToSafety: () => _scrollTo(_safetyKey),
                onScrollToHow: () => _scrollTo(_howKey),
                onScrollToAudience: () => _scrollTo(_audienceKey),
                form: _AuthPanel(
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
                  onSetMode: _setMode,
                  onSubmit: _submit,
                  onResetPassword: _resetPassword,
                  onTogglePassword: () => setState(
                    () => _hidePassword = !_hidePassword,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              key: _featuresKey,
              child: const _WideZoneBand(),
            ),
            SliverToBoxAdapter(
              key: _safetyKey,
              child: _LandingSection(
                child: _TrustSection(onScrollToHow: () => _scrollTo(_howKey)),
              ),
            ),
            SliverToBoxAdapter(
              key: _howKey,
              child: const _LandingSection(child: _HowItWorksSection()),
            ),
            SliverToBoxAdapter(
              key: _audienceKey,
              child: _LandingSection(
                child: _AudienceSection(onCreateAccount: _focusSignup),
              ),
            ),
          ],
        ),
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

  void _focusSignup() {
    _setMode(_AuthMode.signUp);
    _emailFocus.requestFocus();
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
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
}

class _LandingHero extends StatelessWidget {
  const _LandingHero({
    required this.form,
    required this.isBusy,
    required this.isLogin,
    required this.onSetMode,
    required this.onScrollToFeatures,
    required this.onScrollToSafety,
    required this.onScrollToHow,
    required this.onScrollToAudience,
  });

  final Widget form;
  final bool isBusy;
  final bool isLogin;
  final ValueChanged<_AuthMode> onSetMode;
  final VoidCallback onScrollToFeatures;
  final VoidCallback onScrollToSafety;
  final VoidCallback onScrollToHow;
  final VoidCallback onScrollToAudience;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;
        final viewport = MediaQuery.sizeOf(context);
        final heroHeight =
            (viewport.height * 0.92).clamp(680.0, 790.0).toDouble();

        if (!isWide) {
          return const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_heroImagePath),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            child: _HeroShade(
              child: SizedBox.shrink(),
            ),
          ).withHeroContent(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LandingNav(
                      isBusy: isBusy,
                      isLogin: isLogin,
                      isWide: isWide,
                      onSetMode: onSetMode,
                      onScrollToFeatures: onScrollToFeatures,
                      onScrollToSafety: onScrollToSafety,
                      onScrollToHow: onScrollToHow,
                      onScrollToAudience: onScrollToAudience,
                    ),
                    const SizedBox(height: 32),
                    const _HeroCopy(),
                    const SizedBox(height: 20),
                    form,
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  _heroImagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => const _HeroFallback(),
                ),
              ),
              const Positioned.fill(child: _HeroShade()),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 48 : 20,
                    22,
                    isWide ? 48 : 20,
                    isWide ? 26 : 42,
                  ),
                  child: Column(
                    children: [
                      _LandingNav(
                        isBusy: isBusy,
                        isLogin: isLogin,
                        isWide: isWide,
                        onSetMode: onSetMode,
                        onScrollToFeatures: onScrollToFeatures,
                        onScrollToSafety: onScrollToSafety,
                        onScrollToHow: onScrollToHow,
                        onScrollToAudience: onScrollToAudience,
                      ),
                      SizedBox(height: isWide ? 72 : 46),
                      Expanded(
                        child: Align(
                          alignment:
                              isWide ? Alignment.center : Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Expanded(
                                        flex: 6,
                                        child: _HeroCopy(),
                                      ),
                                      const SizedBox(width: 44),
                                      Expanded(
                                        flex: 4,
                                        child: form,
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _HeroCopy(),
                                      const SizedBox(height: 26),
                                      form,
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LandingNav extends StatelessWidget {
  const _LandingNav({
    required this.isBusy,
    required this.isLogin,
    required this.isWide,
    required this.onSetMode,
    required this.onScrollToFeatures,
    required this.onScrollToSafety,
    required this.onScrollToHow,
    required this.onScrollToAudience,
  });

  final bool isBusy;
  final bool isLogin;
  final bool isWide;
  final ValueChanged<_AuthMode> onSetMode;
  final VoidCallback onScrollToFeatures;
  final VoidCallback onScrollToSafety;
  final VoidCallback onScrollToHow;
  final VoidCallback onScrollToAudience;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.obsidian.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.sand.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(isWide ? 16 : 10, 10, 10, 10),
        child: Row(
          children: [
            const AppLogo(compact: true),
            if (isWide) ...[
              const Spacer(),
              _NavTextButton(
                label: 'Fonctionnalites',
                onPressed: onScrollToFeatures,
              ),
              _NavTextButton(label: 'Securite', onPressed: onScrollToSafety),
              _NavTextButton(
                label: 'Comment ca marche',
                onPressed: onScrollToHow,
              ),
              _NavTextButton(label: 'Pour qui', onPressed: onScrollToAudience),
              const SizedBox(width: 18),
            ] else
              const Spacer(),
            OutlinedButton.icon(
              onPressed: isBusy
                  ? null
                  : () =>
                      onSetMode(isLogin ? _AuthMode.signUp : _AuthMode.login),
              icon: Icon(
                isLogin ? Icons.person_add_alt_1 : Icons.login,
                size: 18,
              ),
              label: Text(isLogin ? 'Creer un compte' : 'Se connecter'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: OceanColors.obsidian.withValues(alpha: 0.48),
                side: BorderSide(
                  color: OceanColors.champagne.withValues(alpha: 0.42),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  const _NavTextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: OceanColors.ink.withValues(alpha: 0.84),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Text(label),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 640;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rencontrez au rythme des escales.',
            style: OceanTypography.display(
              context,
              fontSize: isCompact ? 50 : 90,
              color: OceanColors.sand,
            )?.copyWith(height: 0.94),
          ),
          SizedBox(height: isCompact ? 20 : 28),
          Text(
            'Ocean Match rapproche celles et ceux qui vivent, naviguent ou preparent une vie a bord.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: OceanColors.champagne,
                  fontSize: isCompact ? 22 : null,
                  fontWeight: FontWeight.w500,
                  height: 1.20,
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: isCompact ? 16 : 22),
          Text(
            'Profils nautiques, zones larges uniquement, match reciproque et messages texte gratuits entre personnes compatibles.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: OceanColors.ink.withValues(alpha: 0.86),
                  fontSize: isCompact ? 16 : null,
                  height: isCompact ? 1.42 : 1.55,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: isCompact ? 20 : 28),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroProof(icon: Icons.shield_outlined, label: 'Zones larges'),
              _HeroProof(
                  icon: Icons.favorite_rounded, label: 'Match reciproque'),
              _HeroProof(
                  icon: Icons.chat_bubble_outline, label: 'Messages gratuits'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroProof extends StatelessWidget {
  const _HeroProof({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            OceanColors.obsidian.withValues(alpha: 0.58),
            OceanColors.deepBlue.withValues(alpha: 0.40),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: OceanColors.champagne.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: OceanColors.champagne),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: OceanColors.sand,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
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
  final ValueChanged<_AuthMode> onSetMode;
  final VoidCallback onSubmit;
  final VoidCallback onResetPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 480;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.glassStrong,
            OceanColors.obsidian.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: OceanColors.champagne.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: OceanColors.coral.withValues(alpha: 0.10),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OceanColors.obsidian,
                  border: Border.all(
                    color: OceanColors.champagne.withValues(alpha: 0.48),
                  ),
                ),
                child: const Icon(
                  Icons.anchor_rounded,
                  color: OceanColors.champagne,
                  size: 26,
                ),
              ),
            ),
            SizedBox(height: isCompact ? 10 : 14),
            Text(
              isLogin ? 'Bon retour a bord' : 'Bienvenue a bord',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: OceanColors.sand,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: isCompact ? 14 : 18),
            SegmentedButton<_AuthMode>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? OceanColors.coral.withValues(alpha: 0.20)
                      : OceanColors.obsidian.withValues(alpha: 0.38),
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? OceanColors.champagne
                      : OceanColors.muted,
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(
                    color: OceanColors.champagne.withValues(alpha: 0.28),
                  ),
                ),
              ),
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
              selected: {isLogin ? _AuthMode.login : _AuthMode.signUp},
              onSelectionChanged:
                  isBusy ? null : (selection) => onSetMode(selection.first),
            ),
            SizedBox(height: isCompact ? 12 : 16),
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
            SizedBox(height: isCompact ? 12 : 16),
            ElevatedButton.icon(
              onPressed: isBusy ? null : onSubmit,
              icon: Icon(isLogin ? Icons.login : Icons.anchor_rounded),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(isCompact ? 50 : 54),
                backgroundColor: OceanColors.coral,
                foregroundColor: OceanColors.obsidian,
                shadowColor: OceanColors.coral.withValues(alpha: 0.36),
                elevation: 0,
              ),
              label: Text(
                authLoading
                    ? 'Veuillez patienter...'
                    : isLogin
                        ? 'Se connecter'
                        : 'Creer mon compte',
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: isBusy ? null : onResetPassword,
              icon: const Icon(Icons.help_outline),
              label: Text(
                resetLoading ? 'Envoi en cours...' : 'Mot de passe oublie',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideZoneBand extends StatelessWidget {
  const _WideZoneBand();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF103B45),
            OceanColors.obsidian.withValues(alpha: 0.98),
          ],
        ),
        border: const Border.symmetric(
          horizontal: BorderSide(color: OceanColors.glassLine),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final text = Column(
                  crossAxisAlignment: isWide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Zones larges uniquement',
                      textAlign: isWide ? TextAlign.start : TextAlign.center,
                      style: OceanTypography.display(
                        context,
                        fontSize: 32,
                        color: OceanColors.sand,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ocean Match connecte les navigateurs par bassin, route et intention, jamais par position exacte.',
                      textAlign: isWide ? TextAlign.start : TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: OceanColors.ink.withValues(alpha: 0.78),
                            height: 1.45,
                          ),
                    ),
                  ],
                );
                return isWide
                    ? Row(
                        children: [
                          const Icon(
                            Icons.waves_rounded,
                            color: OceanColors.champagne,
                            size: 54,
                          ),
                          const SizedBox(width: 28),
                          Expanded(child: text),
                          const SizedBox(width: 34),
                          const Icon(
                            Icons.sailing_outlined,
                            color: OceanColors.champagne,
                            size: 54,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.waves_rounded,
                            color: OceanColors.champagne,
                            size: 54,
                          ),
                          const SizedBox(height: 12),
                          text,
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingSection extends StatelessWidget {
  const _LandingSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OceanColors.abyss,
            OceanColors.midnight,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 54),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection({required this.onScrollToHow});

  final VoidCallback onScrollToHow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final intro = _SectionIntro(
          title: 'Securite et confidentialite',
          body:
              'L app est pensee pour les rencontres en mer : pas de position exacte publique, blocage instantane, signalement conserve et profils visibles seulement apres verification email.',
          action: OutlinedButton.icon(
            onPressed: onScrollToHow,
            icon: const Icon(Icons.route_outlined),
            label: const Text('Voir le fonctionnement'),
          ),
        );
        const tiles = Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _FeatureTile(
              icon: Icons.shield_outlined,
              title: 'Position protegee',
              body:
                  'Les zones restent larges : Canaries, Caraibes, Mediterranee.',
            ),
            _FeatureTile(
              icon: Icons.block,
              title: 'Controle simple',
              body:
                  'Un blocage coupe decouverte, match et message dans les deux sens.',
            ),
            _FeatureTile(
              icon: Icons.flag_outlined,
              title: 'Signalements utiles',
              body:
                  'Les signalements gardent le contexte pour la moderation future.',
            ),
          ],
        );
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: intro),
                  const SizedBox(width: 44),
                  const Expanded(flex: 6, child: tiles),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  intro,
                  const SizedBox(height: 24),
                  tiles,
                ],
              );
      },
    );
  }
}

extension on Widget {
  Widget withHeroContent({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(child: this),
        child,
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionIntro(
          title: 'Comment ca marche',
          body:
              'Ocean Match rapproche les personnes par mode de vie, route future, zone actuelle et intentions. Si le like est reciproque, la conversation texte s ouvre gratuitement.',
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 780;
            const steps = [
              _StepTile(
                number: '1',
                title: 'Profil nautique',
                body:
                    'Vie a bord, experience, bateau ou projet, langues et intentions.',
              ),
              _StepTile(
                number: '2',
                title: 'Compatibilite',
                body:
                    'La decouverte classe les profils par zone, route et style de vie.',
              ),
              _StepTile(
                number: '3',
                title: 'Match et message',
                body:
                    'Si chacun like, vous pouvez discuter sans option Premium.',
              ),
            ];
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < steps.length; i += 1) ...[
                        Expanded(child: steps[i]),
                        if (i != steps.length - 1) const SizedBox(width: 16),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      for (final step in steps) ...[
                        step,
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _AudienceSection extends StatelessWidget {
  const _AudienceSection({required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.glassStrong,
            OceanColors.deepBlue.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.glassLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            const intro = _SectionIntro(
              title: 'Pour qui ?',
              body:
                  'Pour celles et ceux qui vivent deja a bord, preparent une transat, cherchent un equipier, ou imaginent une vie plus proche des mouillages et des escales.',
            );
            final tags = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OceanBadge(label: 'Vit a bord', icon: Icons.home_outlined),
                    OceanBadge(
                      label: 'Projet navigation',
                      icon: Icons.sailing_outlined,
                    ),
                    OceanBadge(label: 'Equipier', icon: Icons.groups_outlined),
                    OceanBadge(
                      label: 'Relation serieuse',
                      icon: Icons.favorite_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onCreateAccount,
                  icon: const Icon(Icons.anchor_rounded),
                  label: const Text('Creer mon compte'),
                ),
              ],
            );
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 5, child: intro),
                      const SizedBox(width: 36),
                      Expanded(flex: 5, child: tags),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      intro,
                      const SizedBox(height: 22),
                      tags,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: OceanTypography.display(
            context,
            fontSize: 42,
            color: OceanColors.sand,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: OceanColors.ink.withValues(alpha: 0.78),
                height: 1.56,
              ),
        ),
        if (action != null) ...[
          const SizedBox(height: 22),
          action!,
        ],
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OceanColors.glassStrong,
              OceanColors.obsidian.withValues(alpha: 0.80),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OceanColors.glassLine),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: OceanColors.seaTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: OceanColors.seaTeal.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: OceanColors.seaTeal, size: 24),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: OceanColors.sand,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: OceanColors.muted,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.glassStrong,
            OceanColors.obsidian.withValues(alpha: 0.86),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.glassLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: OceanColors.champagne.withValues(alpha: 0.16),
              foregroundColor: OceanColors.champagne,
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: OceanColors.sand,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: OceanColors.muted,
                    height: 1.48,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroShade extends StatelessWidget {
  const _HeroShade({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            OceanColors.abyss.withValues(alpha: 0.98),
            OceanColors.midnight.withValues(alpha: 0.72),
            OceanColors.midnight.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              OceanColors.abyss.withValues(alpha: 0.46),
              Colors.transparent,
              OceanColors.abyss.withValues(alpha: 0.78),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.abyss,
            OceanColors.deepBlue,
            Color(0xFF0E4050),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.sailing_outlined,
          size: 220,
          color: OceanColors.line,
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
