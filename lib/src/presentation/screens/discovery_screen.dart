import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/safety_sheets.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({required this.onOpenMessages, super.key});

  final VoidCallback onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    if (!controller.hasActiveAccount) {
      return const _LockedDiscovery(
        title: 'Compte non actif',
        message:
            'Verifiez votre email pour activer votre compte avant d acceder a Decouvrir.',
      );
    }
    if (!controller.isProfileComplete) {
      return const _LockedDiscovery(
        title: 'Profil incomplet',
        message: 'Completez votre profil avant d acceder a Decouvrir.',
      );
    }
    final profiles = controller.discoveryProfiles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decouvrir'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.refreshDiscovery,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: profiles.isEmpty
            ? _EmptyDiscovery(onRefresh: controller.refreshDiscovery)
            : _DiscoveryCard(
                discoveryProfile: profiles.first,
                remainingCount: profiles.length,
                onOpenMessages: onOpenMessages,
              ),
      ),
    );
  }
}

class _LockedDiscovery extends StatelessWidget {
  const _LockedDiscovery({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decouvrir')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PrivacyNote(),
            const SizedBox(height: 16),
            SectionCard(
              title: title,
              subtitle: message,
              child: const Text(
                'Revenez ici apres validation du compte.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PrivacyNote(),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Aucun profil pour le moment',
          subtitle:
              'Essayez une zone ou une route plus large. Les profils passes, likes ou bloques ne reapparaissent pas.',
          child: ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryCard extends StatefulWidget {
  const _DiscoveryCard({
    required this.discoveryProfile,
    required this.remainingCount,
    required this.onOpenMessages,
  });

  final DiscoveryProfile discoveryProfile;
  final int remainingCount;
  final VoidCallback onOpenMessages;

  @override
  State<_DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<_DiscoveryCard> {
  String? _pendingAction;

  bool get _isBusy => _pendingAction != null;
  DiscoveryProfile get discoveryProfile => widget.discoveryProfile;

  @override
  Widget build(BuildContext context) {
    final profile = discoveryProfile.profile;
    final photo = discoveryProfile.primaryPhoto;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${widget.remainingCount} profil(s) compatible(s)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: OceanColors.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 0.78,
          child: Stack(
            children: [
              Positioned.fill(
                child: photo == null
                    ? const ColoredBox(color: OceanColors.mist)
                    : PhotoTile(url: photo.url, borderRadius: 8),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.firstName}, ${profile.age}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OceanBadge(
                          label: discoveryProfile.currentZone.zone,
                          icon: Icons.place_outlined,
                          color: Colors.white,
                        ),
                        OceanBadge(
                          label:
                              'Route ${discoveryProfile.futureRoute.destinationZone}',
                          icon: Icons.route_outlined,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Route et intentions',
          subtitle: 'Zones larges uniquement, jamais de position exacte.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: 'Zone actuelle',
                value: _zoneLabel(discoveryProfile.currentZone),
              ),
              InfoRow(
                label: 'Route future',
                value: _routeLabel(discoveryProfile.futureRoute),
              ),
              InfoRow(
                label: 'Intentions',
                value: intentionsLabel(discoveryProfile.intentions),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Compatibilite nautique',
          subtitle: 'Score simple MVP : ${discoveryProfile.score}/100',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: 'Vie a bord',
                value: discoveryProfile.lifeAboard.status.label,
              ),
              InfoRow(
                label: 'Experience',
                value: discoveryProfile.lifeAboard.experience.label,
              ),
              InfoRow(
                label: 'Bateau',
                value: discoveryProfile.lifeAboard.boatOrProject,
              ),
              InfoRow(
                label: 'Navigation',
                value: discoveryProfile.lifeAboard.sailingType,
              ),
              const SizedBox(height: 8),
              const Text(
                'Position exacte masquee. Seule la zone large est visible.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : () => _pass(context),
                icon: const Icon(Icons.close),
                label: Text(_pendingAction == 'pass' ? '...' : 'Passer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isBusy ? null : () => _like(context),
                icon: const Icon(Icons.favorite),
                label: Text(_pendingAction == 'like' ? '...' : 'Liker'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : () => _report(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Signaler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : () => _block(context),
                icon: const Icon(Icons.block),
                label: const Text('Bloquer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isBusy ? null : () => _showProfileDetails(context),
          icon: const Icon(Icons.person_search_outlined),
          label: const Text('Voir le profil detaille'),
        ),
      ],
    );
  }

  Future<void> _pass(BuildContext context) async {
    final target = discoveryProfile.profile;
    await _runProfileAction(
      action: 'pass',
      task: () async {
        await OceanMatchScope.of(context).passProfile(
          target.userId,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil passe.')),
        );
      },
    );
  }

  Future<void> _like(BuildContext context) async {
    final target = discoveryProfile.profile;
    await _runProfileAction(
      action: 'like',
      task: () async {
        final result = await OceanMatchScope.of(context).likeProfile(
          target.userId,
        );
        if (!context.mounted) return;
        if (result.createdMatch) {
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('C est un match'),
                content: Text(
                  'Vous pouvez maintenant discuter gratuitement avec ${target.firstName}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continuer'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onOpenMessages();
                    },
                    child: const Text('Envoyer un message'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Like envoye.')),
          );
        }
      },
    );
  }

  Future<void> _report(BuildContext context) {
    return showReportSheet(
      context: context,
      targetUserId: discoveryProfile.profile.userId,
      targetName: discoveryProfile.profile.firstName,
    );
  }

  Future<void> _block(BuildContext context) async {
    await showBlockDialog(
      context: context,
      targetUserId: discoveryProfile.profile.userId,
      targetName: discoveryProfile.profile.firstName,
    );
  }

  void _showProfileDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _ProfileDetailsSheet(
          discoveryProfile: discoveryProfile,
          onOpenMessages: widget.onOpenMessages,
        );
      },
    );
  }

  Future<void> _runProfileAction({
    required String action,
    required Future<void> Function() task,
  }) async {
    if (_isBusy) return;
    setState(() => _pendingAction = action);
    try {
      await task();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingAction = null);
    }
  }
}

class _ProfileDetailsSheet extends StatelessWidget {
  const _ProfileDetailsSheet({
    required this.discoveryProfile,
    required this.onOpenMessages,
  });

  final DiscoveryProfile discoveryProfile;
  final VoidCallback onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final profile = discoveryProfile.profile;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              '${profile.firstName}, ${profile.age}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 132,
                    child: PhotoTile(url: discoveryProfile.photos[index].url),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: discoveryProfile.photos.length,
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Profil',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.bio),
                  const SizedBox(height: 10),
                  InfoRow(
                      label: 'Langues', value: profile.languages.join(', ')),
                  InfoRow(
                      label: 'Recherche', value: profile.searchGender.label),
                ],
              ),
            ),
            SectionCard(
              title: 'Navigation',
              child: Column(
                children: [
                  InfoRow(
                    label: 'Statut',
                    value: discoveryProfile.lifeAboard.status.label,
                  ),
                  InfoRow(
                    label: 'Bateau',
                    value: discoveryProfile.lifeAboard.boatOrProject,
                  ),
                  InfoRow(
                    label: 'Type',
                    value: discoveryProfile.lifeAboard.sailingType,
                  ),
                  InfoRow(
                    label: 'Experience',
                    value: discoveryProfile.lifeAboard.experience.label,
                  ),
                  InfoRow(
                    label: 'Zone',
                    value: _zoneLabel(discoveryProfile.currentZone),
                  ),
                  InfoRow(
                    label: 'Route',
                    value: _routeLabel(discoveryProfile.futureRoute),
                  ),
                  InfoRow(
                    label: 'Intentions',
                    value: intentionsLabel(discoveryProfile.intentions),
                  ),
                ],
              ),
            ),
            const PrivacyNote(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await OceanMatchScope.of(context)
                            .passProfile(profile.userId);
                        if (context.mounted) Navigator.pop(context);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(userFacingError(error))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Passer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final controller = OceanMatchScope.of(context);
                        final result =
                            await controller.likeProfile(profile.userId);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (result.createdMatch) onOpenMessages();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(userFacingError(error))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.favorite),
                    label: const Text('Liker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showReportSheet(
                      context: context,
                      targetUserId: profile.userId,
                      targetName: profile.firstName,
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Signaler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final blocked = await showBlockDialog(
                        context: context,
                        targetUserId: profile.userId,
                        targetName: profile.firstName,
                      );
                      if (blocked && context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Bloquer'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

String _zoneLabel(CurrentZone zone) {
  final country = zone.country;
  if (country == null || country.trim().isEmpty) return zone.zone;
  return '${zone.zone}, $country';
}

String _routeLabel(FutureRoute route) {
  return '${route.destinationZone} (${route.startPeriod} - ${route.endPeriod}, ${route.flexibility.label})';
}
