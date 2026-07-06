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
      return _LockedDiscovery(
        title: 'Compte non actif',
        message:
            'Verifiez votre email pour activer votre compte avant d acceder a Decouvrir.',
        onRefresh: controller.refreshDiscovery,
        onOpenMessages: onOpenMessages,
      );
    }
    if (!controller.isProfileComplete) {
      return _LockedDiscovery(
        title: 'Profil incomplet',
        message: 'Completez votre profil avant d acceder a Decouvrir.',
        onRefresh: controller.refreshDiscovery,
        onOpenMessages: onOpenMessages,
      );
    }
    final profiles = controller.discoveryProfiles;
    return Scaffold(
      body: SafeArea(
        child: profiles.isEmpty
            ? _EmptyDiscovery(
                onRefresh: controller.refreshDiscovery,
                onOpenMessages: onOpenMessages,
              )
            : _DiscoveryCard(
                discoveryProfile: profiles.first,
                remainingCount: profiles.length,
                onOpenMessages: onOpenMessages,
                onRefresh: controller.refreshDiscovery,
              ),
      ),
    );
  }
}

class _LockedDiscovery extends StatelessWidget {
  const _LockedDiscovery({
    required this.title,
    required this.message,
    required this.onRefresh,
    required this.onOpenMessages,
  });

  final String title;
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onOpenMessages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            _DiscoveryHeader(
              onRefresh: onRefresh,
              onOpenMessages: onOpenMessages,
            ),
            const SizedBox(height: 18),
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
  const _EmptyDiscovery({
    required this.onRefresh,
    required this.onOpenMessages,
  });

  final VoidCallback onRefresh;
  final VoidCallback onOpenMessages;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _DiscoveryHeader(
          onRefresh: onRefresh,
          onOpenMessages: onOpenMessages,
        ),
        const SizedBox(height: 18),
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
        const SizedBox(height: 12),
        const PrivacyNote(),
      ],
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.onRefresh,
    this.onOpenMessages,
    this.remainingCount,
  });

  final VoidCallback onRefresh;
  final VoidCallback? onOpenMessages;
  final int? remainingCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppLogo(compact: true),
                const Spacer(),
                _HeaderIconButton(
                  tooltip: 'Actualiser',
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  tooltip: 'Messages',
                  icon: Icons.chat_bubble_outline,
                  onPressed: onOpenMessages ?? onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: OceanColors.line),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Decouvrir',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontFamily: 'Georgia',
                                  color: OceanColors.sand,
                                  fontWeight: FontWeight.w500,
                                  height: 0.95,
                                ),
                      ),
                      Text(
                        'des profils',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontFamily: 'Georgia',
                                  color: OceanColors.gold,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  height: 0.95,
                                ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Filtres'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(104, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: OceanColors.card,
                  ),
                ),
              ],
            ),
            if (remainingCount != null) ...[
              const SizedBox(height: 10),
              Text(
                '$remainingCount profils compatibles',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: OceanColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.line),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: OceanColors.muted),
      ),
    );
  }
}

class _DiscoveryCard extends StatefulWidget {
  const _DiscoveryCard({
    required this.discoveryProfile,
    required this.remainingCount,
    required this.onOpenMessages,
    required this.onRefresh,
  });

  final DiscoveryProfile discoveryProfile;
  final int remainingCount;
  final VoidCallback onOpenMessages;
  final VoidCallback onRefresh;

  @override
  State<_DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<_DiscoveryCard> {
  String? _pendingAction;

  bool get _isBusy => _pendingAction != null;
  DiscoveryProfile get discoveryProfile => widget.discoveryProfile;

  @override
  Widget build(BuildContext context) {
    final photo = discoveryProfile.primaryPhoto;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _DiscoveryHeader(
          onRefresh: widget.onRefresh,
          onOpenMessages: widget.onOpenMessages,
          remainingCount: widget.remainingCount,
        ),
        const SizedBox(height: 26),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AspectRatio(
              aspectRatio: 0.60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: OceanColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: OceanColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (photo == null)
                              const _ProfilePhotoFallback()
                            else
                              PhotoTile(
                                url: photo.url,
                                borderRadius: 0,
                              ),
                            const Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _PhotoShade(),
                            ),
                            const Positioned(
                              top: 16,
                              left: 0,
                              right: 0,
                              child: _CardPager(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _ProfileCardBody(
                          discoveryProfile: discoveryProfile,
                          onOpenDetails: () => _showProfileDetails(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isBusy ? null : () => _pass(context),
                        icon: const Icon(Icons.close),
                        label: Text(
                          _pendingAction == 'pass' ? '...' : 'Passer',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : () => _like(context),
                        icon: const Icon(Icons.favorite),
                        label: Text(
                          _pendingAction == 'like' ? '...' : 'Liker',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isBusy ? null : () => _report(context),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Signaler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OceanColors.coral,
                          side: BorderSide(
                            color: OceanColors.coral.withValues(alpha: 0.34),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isBusy ? null : () => _block(context),
                        icon: const Icon(Icons.block),
                        label: const Text('Bloquer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OceanColors.muted,
                          side: const BorderSide(color: OceanColors.line),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const PrivacyNote(),
              ],
            ),
          ),
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
      backgroundColor: Colors.transparent,
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

class _ProfileCardBody extends StatelessWidget {
  const _ProfileCardBody({
    required this.discoveryProfile,
    required this.onOpenDetails,
  });

  final DiscoveryProfile discoveryProfile;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final profile = discoveryProfile.profile;
    return ColoredBox(
      color: OceanColors.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxHeight < 290;
          return Padding(
            padding: EdgeInsets.fromLTRB(22, isTight ? 16 : 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        profile.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontFamily: 'Georgia',
                                  color: OceanColors.sand,
                                  fontSize: isTight ? 31.0 : 36.0,
                                  height: 0.95,
                                  fontWeight: FontWeight.w400,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        '${profile.age}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: 'Georgia',
                              color: OceanColors.muted,
                              fontSize: isTight ? 19.0 : null,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTight ? 9 : 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OceanBadge(
                      label:
                          _boardStatusLabel(discoveryProfile.lifeAboard.status),
                      icon: Icons.directions_boat_filled,
                      color: OceanColors.gold,
                    ),
                    OceanBadge(
                      label: _zoneRouteLabel(discoveryProfile),
                      icon: Icons.place_outlined,
                      color: OceanColors.seaTeal,
                    ),
                    OceanBadge(
                      label: _primaryIntention(discoveryProfile.intentions),
                      icon: Icons.favorite_border,
                      color: OceanColors.muted,
                    ),
                  ],
                ),
                const Spacer(),
                if (!isTight)
                  _CompatibilityNotice(score: discoveryProfile.score),
                if (!isTight) const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onOpenDetails,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: OceanColors.cardAlt,
                    minimumSize: Size.fromHeight(isTight ? 46 : 52),
                  ),
                  child: const Text('Voir le profil complet ->'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhotoShade extends StatelessWidget {
  const _PhotoShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 140,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                OceanColors.card.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoFallback extends StatelessWidget {
  const _ProfilePhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B3E55),
            OceanColors.deepBlue,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_boat_filled,
          color: OceanColors.gold,
          size: 96,
        ),
      ),
    );
  }
}

class _CardPager extends StatelessWidget {
  const _CardPager();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PagerSegment(active: true),
        SizedBox(width: 6),
        _PagerSegment(active: false),
        SizedBox(width: 6),
        _PagerSegment(active: false),
      ],
    );
  }
}

class _PagerSegment extends StatelessWidget {
  const _PagerSegment({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 34 : 28,
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? OceanColors.sand
            : OceanColors.sand.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _CompatibilityNotice extends StatelessWidget {
  const _CompatibilityNotice({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.mist.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.gold.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 18,
              color: OceanColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profil $score%. Zones larges uniquement, jamais de position exacte.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: OceanColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final primaryPhoto = discoveryProfile.primaryPhoto;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: OceanColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.fromBorderSide(BorderSide(color: OceanColors.line)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(26, 12, 26, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: OceanColors.muted.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AspectRatio(
                aspectRatio: 1.25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: primaryPhoto == null
                      ? const _ProfilePhotoFallback()
                      : PhotoTile(url: primaryPhoto.url, borderRadius: 0),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      profile.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontFamily: 'Georgia',
                            color: OceanColors.sand,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${profile.age} ans',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Georgia',
                            color: OceanColors.muted,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OceanBadge(
                    label:
                        _boardStatusLabel(discoveryProfile.lifeAboard.status),
                    icon: Icons.directions_boat_filled,
                    color: OceanColors.gold,
                  ),
                  OceanBadge(
                    label: _zoneLabel(discoveryProfile.currentZone),
                    icon: Icons.place_outlined,
                    color: OceanColors.seaTeal,
                  ),
                  OceanBadge(
                    label: _primaryIntention(discoveryProfile.intentions),
                    icon: Icons.favorite_border,
                    color: OceanColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ScoreBar(score: discoveryProfile.score),
              const SizedBox(height: 18),
              _CompatibilityNotice(score: discoveryProfile.score),
              const SizedBox(height: 24),
              _DetailSection(
                title: 'A propos',
                child: Text(
                  profile.bio,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        color: OceanColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _DetailSection(
                title: 'Route',
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Zone actuelle',
                      value: _zoneLabel(discoveryProfile.currentZone),
                    ),
                    InfoRow(
                      label: 'Prochaine zone',
                      value: discoveryProfile.futureRoute.destinationZone,
                    ),
                    InfoRow(
                      label: 'Periode',
                      value:
                          '${discoveryProfile.futureRoute.startPeriod} - ${discoveryProfile.futureRoute.endPeriod}',
                    ),
                    InfoRow(
                      label: 'Flexibilite',
                      value: discoveryProfile.futureRoute.flexibility.label,
                    ),
                  ],
                ),
              ),
              _DetailSection(
                title: 'Intentions',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final intention in discoveryProfile.intentions)
                      OceanBadge(
                        label: intention.label,
                        icon: Icons.favorite_border,
                        color: OceanColors.gold,
                      ),
                  ],
                ),
              ),
              _DetailSection(
                title: 'Infos nautiques',
                child: Column(
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
                  ],
                ),
              ),
              if (discoveryProfile.lifeAboard.lifestyleTags.isNotEmpty)
                _DetailSection(
                  title: 'Style de vie a bord',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag
                          in discoveryProfile.lifeAboard.lifestyleTags)
                        OceanBadge(
                          label: tag,
                          color: OceanColors.gold,
                        ),
                    ],
                  ),
                ),
              if (discoveryProfile.photos.length > 1) ...[
                _DetailSection(
                  title: 'Photos',
                  child: SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 116,
                          child: PhotoTile(
                            url: discoveryProfile.photos[index].url,
                            borderRadius: 8,
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: discoveryProfile.photos.length,
                    ),
                  ),
                ),
              ],
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
              const SizedBox(height: 10),
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OceanColors.coral,
                        side: BorderSide(
                          color: OceanColors.coral.withValues(alpha: 0.34),
                        ),
                      ),
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OceanColors.muted,
                        side: const BorderSide(color: OceanColors.line),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: OceanColors.cardAlt,
                  foregroundColor: OceanColors.muted,
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final value = score.clamp(0, 100) / 100.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: OceanColors.mist,
              valueColor: const AlwaysStoppedAnimation(OceanColors.gold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Profil $score%',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: OceanColors.gold,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: OceanColors.gold,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: OceanColors.line),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

String _zoneLabel(CurrentZone zone) {
  final country = zone.country;
  if (country == null || country.trim().isEmpty) return zone.zone;
  return '${zone.zone} - $country';
}

String _boardStatusLabel(BoardStatus status) {
  if (status == BoardStatus.liveaboard) return 'Vit a bord a l annee';
  return status.label;
}

String _zoneRouteLabel(DiscoveryProfile discoveryProfile) {
  return '${discoveryProfile.currentZone.zone} -> ${discoveryProfile.futureRoute.destinationZone}';
}

String _primaryIntention(List<Intention> intentions) {
  if (intentions.isEmpty) return 'Intentions a definir';
  return intentions.first.label;
}
