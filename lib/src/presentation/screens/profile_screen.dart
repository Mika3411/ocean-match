import 'package:flutter/material.dart';

import '../../app.dart';
import '../../domain/models.dart';
import '../widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    if (!controller.hasActiveAccount) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Verifiez votre email pour activer votre compte avant de voir votre profil.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    final profile = controller.currentProfile;
    final life = controller.currentLifeAboard;
    final zone = controller.currentZone;
    final route = controller.currentFutureRoute;
    final preferences = controller.currentPreferences;
    final photos = controller.currentPhotos;
    final currentPort = _portName(controller.ports, zone?.portId);
    final destinationPort =
        _portName(controller.ports, route?.destinationPortId);

    if (profile == null || life == null || zone == null || route == null) {
      return const Scaffold(
        body: Center(child: Text('Profil incomplet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Profil pret',
              subtitle: 'Votre profil est visible dans Decouvrir.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 116,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                  child: PhotoTile(url: photos[index].url)),
                              if (photos[index].isPrimary)
                                const Positioned(
                                  left: 8,
                                  top: 8,
                                  child: OceanBadge(
                                    label: 'Principale',
                                    icon: Icons.star,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: photos.length,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InfoRow(label: 'Prenom', value: profile.firstName),
                  InfoRow(label: 'Age', value: '${profile.age}'),
                  InfoRow(label: 'Genre', value: profile.gender.label),
                  InfoRow(
                      label: 'Recherche', value: profile.searchGender.label),
                  InfoRow(
                      label: 'Langues', value: profile.languages.join(', ')),
                  InfoRow(label: 'Bio', value: profile.bio),
                ],
              ),
            ),
            SectionCard(
              title: 'Vie a bord',
              child: Column(
                children: [
                  InfoRow(label: 'Statut', value: life.status.label),
                  InfoRow(label: 'Bateau', value: life.boatOrProject),
                  InfoRow(label: 'Navigation', value: life.sailingType),
                  InfoRow(label: 'Experience', value: life.experience.label),
                  InfoRow(label: 'Style', value: life.lifestyleTags.join(', ')),
                ],
              ),
            ),
            SectionCard(
              title: 'Zone actuelle',
              trailing: IconButton(
                tooltip: 'Modifier la zone',
                onPressed: () => _showZoneDialog(context, zone.zone),
                icon: const Icon(Icons.edit_location_alt_outlined),
              ),
              child: Column(
                children: [
                  InfoRow(label: 'Zone', value: zone.zone),
                  if (currentPort != null)
                    InfoRow(label: 'Port', value: currentPort),
                  const SizedBox(height: 8),
                  const Text(
                    'Votre position exacte n est jamais affichee.',
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Route future',
              trailing: IconButton(
                tooltip: 'Modifier la route',
                onPressed: () => _showRouteDialog(context, route),
                icon: const Icon(Icons.edit_road_outlined),
              ),
              child: Column(
                children: [
                  InfoRow(label: 'Destination', value: route.destinationZone),
                  if (destinationPort != null)
                    InfoRow(label: 'Port vise', value: destinationPort),
                  InfoRow(
                    label: 'Periode',
                    value: '${route.startPeriod} - ${route.endPeriod}',
                  ),
                  InfoRow(label: 'Flexibilite', value: route.flexibility.label),
                  if (route.comment.isNotEmpty)
                    InfoRow(label: 'Note', value: route.comment),
                ],
              ),
            ),
            SectionCard(
              title: 'Intentions',
              child: Text(intentionsLabel(preferences?.intentions ?? const [])),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showZoneDialog(BuildContext context, String currentZone) async {
    final textController = TextEditingController(text: currentZone);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier la zone'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Zone actuelle',
              helperText: 'Zone large uniquement, jamais de position exacte.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                await OceanMatchScope.of(context).updateCurrentZone(
                  textController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    textController.dispose();
  }

  Future<void> _showRouteDialog(BuildContext context, FutureRoute route) async {
    final destinationController =
        TextEditingController(text: route.destinationZone);
    final startController = TextEditingController(text: route.startPeriod);
    final endController = TextEditingController(text: route.endPeriod);
    final commentController = TextEditingController(text: route.comment);
    var flexibility = route.flexibility;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier la route'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: destinationController,
                      decoration:
                          const InputDecoration(labelText: 'Destination'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: startController,
                      decoration: const InputDecoration(labelText: 'Debut'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: endController,
                      decoration: const InputDecoration(labelText: 'Fin'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<RouteFlexibility>(
                      initialValue: flexibility,
                      decoration:
                          const InputDecoration(labelText: 'Flexibilite'),
                      items: [
                        for (final item in RouteFlexibility.values)
                          DropdownMenuItem(
                              value: item, child: Text(item.label)),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => flexibility = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire',
                        helperText: 'Evitez les ports precis.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    await OceanMatchScope.of(context).updateFutureRoute(
                      destinationZone: destinationController.text.trim(),
                      startPeriod: startController.text.trim(),
                      endPeriod: endController.text.trim(),
                      flexibility: flexibility,
                      comment: commentController.text.trim(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
    destinationController.dispose();
    startController.dispose();
    endController.dispose();
    commentController.dispose();
  }
}

String? _portName(List<HarborPort> ports, String? id) {
  if (id == null) return null;
  for (final port in ports) {
    if (port.id == id) return port.displayName;
  }
  return null;
}
