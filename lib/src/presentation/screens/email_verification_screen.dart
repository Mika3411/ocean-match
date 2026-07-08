import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../widgets/app_widgets.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  bool get _isBusy => _verifying || _resending;

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    final email = controller.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: _isBusy ? null : controller.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Quitter'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AppLogo(),
            const SizedBox(height: 28),
            GoldText(
              'Verifiez votre email',
              style: OceanTypography.title(context, fontSize: 34),
            ),
            const SizedBox(height: 8),
            Text(
              'Nous avons envoye un lien a $email. Votre profil et Decouvrir restent verrouilles tant que le compte n est pas actif.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: OceanColors.muted),
            ),
            const SizedBox(height: 20),
            const PrivacyNote(),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Email requis',
              subtitle:
                  'En developpement local, le bouton ci-dessous utilise le token de verification renvoye par l API.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    _VerificationError(message: _error!),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _verifyEmail,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text(
                      _verifying ? 'Verification...' : 'J ai verifie mon email',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _resendEmail,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _resending ? 'Renvoi en cours...' : 'Renvoyer l email',
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

  Future<void> _verifyEmail() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await OceanMatchScope.of(context).verifyEmail();
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await OceanMatchScope.of(context).requestEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de verification renvoye.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }
}

class _VerificationError extends StatelessWidget {
  const _VerificationError({required this.message});

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
