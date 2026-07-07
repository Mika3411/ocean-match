import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import '../widgets/app_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 9;
  static const _zones = [
    'Mediterranee',
    'Atlantique Europe',
    'Canaries',
    'Cap-Vert',
    'Caraibes',
    'Europe du Nord',
    'Ocean Indien',
    'Pacifique',
  ];

  final _firstNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _languagesController = TextEditingController();
  final _bioController = TextEditingController();
  final _boatController = TextEditingController();

  int _step = 0;
  bool _submitting = false;
  String? _error;
  DateTime? _lastSavedAt;
  Gender _gender = Gender.woman;
  SearchGender _searchGender = SearchGender.everyone;
  BoardStatus _boardStatus = BoardStatus.liveaboard;
  SailingExperience _experience = SailingExperience.intermediate;
  String _currentZone = _zones.first;
  String _futureRoute = _zones[4];
  final Set<Intention> _intentions = {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _ageController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    _boatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _stepCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : OceanMatchScope.of(context).logout,
            icon: const Icon(Icons.logout),
            label: const Text('Quitter'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: progress)),
                const SizedBox(width: 12),
                Text(
                  '${_step + 1}/$_stepCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: OceanColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SaveStatus(
              lastSavedAt: _lastSavedAt,
              isSubmitting: _submitting,
              isFinalStep: _step == _stepCount - 1,
            ),
            const SizedBox(height: 16),
            _buildStep(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _OnboardingError(message: _error!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _next,
                    icon: Icon(
                      _step == _stepCount - 1
                          ? Icons.publish_outlined
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _submitting
                          ? 'Publication...'
                          : _step == _stepCount - 1
                              ? 'Publier mon profil'
                              : 'Continuer',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _identityStep();
      case 1:
        return _genderAndSearchStep();
      case 2:
        return _languagesStep();
      case 3:
        return _bioStep();
      case 4:
        return _lifeAboardStep();
      case 5:
        return _experienceStep();
      case 6:
        return _zonesStep();
      case 7:
        return _intentionsStep();
      case 8:
        return _recapStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _identityStep() {
    return SectionCard(
      title: '1. Identite',
      subtitle: 'Prenom visible et age minimum requis.',
      child: Column(
        children: [
          TextField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Prenom',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderAndSearchStep() {
    return SectionCard(
      title: '2. Genre et recherche',
      subtitle: 'Ces choix servent au matching du MVP.',
      child: Column(
        children: [
          DropdownButtonFormField<Gender>(
            initialValue: _gender,
            decoration: const InputDecoration(
              labelText: 'Genre',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: [
              for (final gender in Gender.values)
                DropdownMenuItem(value: gender, child: Text(gender.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _gender = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SearchGender>(
            initialValue: _searchGender,
            decoration: const InputDecoration(
              labelText: 'Recherche',
              prefixIcon: Icon(Icons.favorite_border),
            ),
            items: [
              for (final search in SearchGender.values)
                DropdownMenuItem(value: search, child: Text(search.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _searchGender = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _languagesStep() {
    return SectionCard(
      title: '3. Langues',
      subtitle: 'Separez les langues par des virgules.',
      child: TextField(
        controller: _languagesController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Langues',
          hintText: 'Francais, Anglais, Espagnol',
          prefixIcon: Icon(Icons.translate_outlined),
        ),
      ),
    );
  }

  Widget _bioStep() {
    return SectionCard(
      title: '4. Bio',
      subtitle: 'Une presentation courte, sans lieu exact.',
      child: TextField(
        controller: _bioController,
        maxLines: 4,
        maxLength: 240,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Bio',
          hintText: 'Votre rythme de vie a bord, vos envies, votre energie.',
          prefixIcon: Icon(Icons.notes_outlined),
        ),
      ),
    );
  }

  Widget _lifeAboardStep() {
    return SectionCard(
      title: '5. Vie a bord',
      subtitle: 'Statut actuel et bateau ou projet.',
      child: Column(
        children: [
          DropdownButtonFormField<BoardStatus>(
            initialValue: _boardStatus,
            decoration: const InputDecoration(
              labelText: 'Statut de vie a bord',
              prefixIcon: Icon(Icons.sailing_outlined),
            ),
            items: [
              for (final status in BoardStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _boardStatus = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _boatController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Type de bateau ou projet',
              hintText: 'Voilier 34 pieds, recherche embarquement...',
              prefixIcon: Icon(Icons.directions_boat_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceStep() {
    return SectionCard(
      title: '6. Experience',
      subtitle: 'Choisissez le niveau le plus juste.',
      child: DropdownButtonFormField<SailingExperience>(
        initialValue: _experience,
        decoration: const InputDecoration(
          labelText: 'Experience',
          prefixIcon: Icon(Icons.military_tech_outlined),
        ),
        items: [
          for (final experience in SailingExperience.values)
            DropdownMenuItem(
              value: experience,
              child: Text(experience.label),
            ),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _experience = value);
        },
      ),
    );
  }

  Widget _zonesStep() {
    return Column(
      children: [
        SectionCard(
          title: '7. Zones larges',
          subtitle: 'BlueWater Match ne collecte pas de position exacte.',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _currentZone,
                decoration: const InputDecoration(
                  labelText: 'Zone actuelle',
                  prefixIcon: Icon(Icons.public_outlined),
                ),
                items: [
                  for (final zone in _zones)
                    DropdownMenuItem(value: zone, child: Text(zone)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _currentZone = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _futureRoute,
                decoration: const InputDecoration(
                  labelText: 'Route future',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
                items: [
                  for (final zone in _zones)
                    DropdownMenuItem(value: zone, child: Text(zone)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _futureRoute = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const PrivacyNote(),
      ],
    );
  }

  Widget _intentionsStep() {
    return SectionCard(
      title: '8. Intentions',
      subtitle: 'Selectionnez au moins une intention.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final intention in Intention.values)
            FilterChip(
              label: Text(intention.label),
              selected: _intentions.contains(intention),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _intentions.add(intention);
                  } else {
                    _intentions.remove(intention);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _recapStep() {
    return SectionCard(
      title: '9. Recapitulatif',
      subtitle: 'Publiez seulement quand tout est juste.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Prenom', value: _firstNameController.text.trim()),
          InfoRow(label: 'Age', value: _ageController.text.trim()),
          InfoRow(label: 'Genre', value: _gender.label),
          InfoRow(label: 'Recherche', value: _searchGender.label),
          InfoRow(label: 'Langues', value: _languages.join(', ')),
          InfoRow(label: 'Bio', value: _bioController.text.trim()),
          InfoRow(label: 'Statut', value: _boardStatus.label),
          InfoRow(label: 'Bateau/projet', value: _boatController.text.trim()),
          InfoRow(label: 'Experience', value: _experience.label),
          InfoRow(label: 'Zone actuelle', value: _currentZone),
          InfoRow(label: 'Route future', value: _futureRoute),
          InfoRow(
            label: 'Intentions',
            value: intentionsLabel(_intentions.toList()),
          ),
          const SizedBox(height: 12),
          const PrivacyNote(),
        ],
      ),
    );
  }

  void _back() {
    setState(() {
      _error = null;
      _step -= 1;
    });
  }

  Future<void> _next() async {
    final validation = _validateStep();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _error = null;
      _lastSavedAt = DateTime.now();
    });
    if (_step < _stepCount - 1) {
      setState(() => _step += 1);
      return;
    }
    await _publishProfile();
  }

  String? _validateStep() {
    switch (_step) {
      case 0:
        final age = int.tryParse(_ageController.text.trim());
        if (_firstNameController.text.trim().isEmpty) {
          return 'Prenom obligatoire.';
        }
        if (age == null || age < 18 || age > 99) {
          return 'Age valide obligatoire, entre 18 et 99 ans.';
        }
        return null;
      case 2:
        if (_languages.isEmpty) return 'Ajoutez au moins une langue.';
        return null;
      case 3:
        final bio = _bioController.text.trim();
        if (bio.isEmpty) return 'Bio obligatoire.';
        return _exactPositionError(bio);
      case 4:
        final boatOrProject = _boatController.text.trim();
        if (boatOrProject.isEmpty) return 'Ajoutez un bateau ou un projet.';
        return _exactPositionError(boatOrProject);
      case 7:
        if (_intentions.isEmpty) return 'Selectionnez au moins une intention.';
        return null;
      default:
        return null;
    }
  }

  List<String> get _languages {
    return _languagesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _exactPositionError(String value) {
    if (!_containsExactPositionHint(value)) return null;
    return 'Gardez uniquement des zones larges, sans GPS, marina, quai ou ponton.';
  }

  bool _containsExactPositionHint(String value) {
    final normalized = value.toLowerCase();
    final coordinatePattern = RegExp(
      r'\b\d{1,2}([.,]\d+)?\s*[ns]\b|\b\d{1,3}([.,]\d+)?\s*[eoew]\b',
    );
    final exactWords = RegExp(
      r"\b(gps|latitude|longitude|lat\.?|lon\.?|coordonnees|coordinates|marina|quai|ponton|anneau|mouillage|port\s+(de|du|des|d'))\b",
    );
    return coordinatePattern.hasMatch(normalized) ||
        exactWords.hasMatch(normalized);
  }

  Future<void> _publishProfile() async {
    setState(() => _submitting = true);
    final controller = OceanMatchScope.of(context);
    final userId = controller.currentUser!.id;
    final age = int.parse(_ageController.text.trim());
    final now = DateTime.now();
    try {
      await controller.completeOnboarding(
        profile: Profile(
          userId: userId,
          firstName: _firstNameController.text.trim(),
          birthDate: DateTime(now.year - age, now.month, now.day),
          gender: _gender,
          searchGender: _searchGender,
          languages: _languages,
          bio: _bioController.text.trim(),
          isComplete: true,
          createdAt: now,
          updatedAt: now,
        ),
        photos: const [],
        lifeAboard: LifeAboard(
          userId: userId,
          status: _boardStatus,
          boatOrProject: _boatController.text.trim(),
          sailingType: _boardStatus.label,
          experience: _experience,
          lifestyleTags: const [],
          updatedAt: now,
        ),
        currentZone: CurrentZone(
          userId: userId,
          zone: _currentZone,
          updatedAt: now,
        ),
        futureRoute: FutureRoute(
          id: 'route-${now.microsecondsSinceEpoch}',
          userId: userId,
          destinationZone: _futureRoute,
          startPeriod: 'A preciser',
          endPeriod: 'A preciser',
          flexibility: RouteFlexibility.flexible,
          comment: '',
          isActive: true,
          updatedAt: now,
        ),
        preferences: Preferences(
          userId: userId,
          ageMin: 18,
          ageMax: 70,
          genderTargets: _searchGender,
          zones: [_currentZone, _futureRoute],
          intentions: _intentions.toList(),
        ),
      );
    } catch (error) {
      setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({
    required this.lastSavedAt,
    required this.isSubmitting,
    required this.isFinalStep,
  });

  final DateTime? lastSavedAt;
  final bool isSubmitting;
  final bool isFinalStep;

  @override
  Widget build(BuildContext context) {
    final label = isSubmitting
        ? 'Publication du profil...'
        : lastSavedAt == null
            ? 'Brouillon pret a enregistrer'
            : isFinalStep
                ? 'Brouillon enregistre, pret a publier'
                : 'Brouillon enregistre';
    return Row(
      children: [
        Icon(
          isSubmitting ? Icons.sync : Icons.check_circle_outline,
          size: 18,
          color: OceanColors.seaTeal,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: OceanColors.muted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingError extends StatelessWidget {
  const _OnboardingError({required this.message});

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
