import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import '../widgets/app_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    final account = controller.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Compte',
              child: Column(
                children: [
                  InfoRow(label: 'Email', value: account?.email ?? ''),
                  InfoRow(
                    label: 'Verification',
                    value: account?.emailVerified == true ? 'Verifie' : 'Non verifie',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: controller.logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se deconnecter'),
                  ),
                ],
              ),
            ),
            const SectionCard(
              title: 'Confidentialite',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Position exacte jamais affichee.'),
                  SizedBox(height: 6),
                  Text('Photos affichees uniquement dans le profil et Decouvrir.'),
                  SizedBox(height: 6),
                  Text('Messages prives, uniquement entre deux personnes matchees.'),
                ],
              ),
            ),
            SectionCard(
              title: 'Securite',
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BlockedProfilesScreen()),
                    ),
                    icon: const Icon(Icons.block),
                    label: const Text('Profils bloques'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Le blocage coupe toute interaction : decouverte, likes, matchs et messages.',
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Compte et donnees',
              subtitle: 'La suppression retire votre profil de Decouvrir.',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: OceanColors.coral,
                  side: const BorderSide(color: OceanColors.coral),
                ),
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer mon compte'),
              ),
            ),
            const SectionCard(
              title: 'Premium plus tard',
              subtitle:
                  'Architecture prete pour les options futures, sans les activer dans le MVP.',
              child: Text(
                'Likes illimites, voir qui m a like, filtres avances, routes multiples, multi-zones et verification photo resteront hors MVP.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = OceanMatchScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le compte ?'),
          content: const Text(
            'Votre profil disparaitra de Decouvrir. Les nouveaux likes, matchs et messages seront impossibles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.deleteAccount();
    }
  }
}

class BlockedProfilesScreen extends StatelessWidget {
  const BlockedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profils bloques')),
      body: SafeArea(
        child: FutureBuilder<List<Block>>(
          future: controller.getBlocks(),
          builder: (context, snapshot) {
            final blocks = snapshot.data ?? const [];
            if (blocks.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SectionCard(
                    title: 'Aucun profil bloque',
                    subtitle:
                        'Les profils bloques ne peuvent plus interagir avec vous.',
                    child: PrivacyNote(),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final block = blocks[index];
                final profile = controller.profileFor(block.blockedId);
                final name = profile?.firstName ?? 'Utilisateur';
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: const Text('Interaction coupee dans les deux sens.'),
                    trailing: TextButton(
                      onPressed: () async {
                        await controller.unblockUser(block.blockedId);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BlockedProfilesScreen(),
                            ),
                          );
                        }
                      },
                      child: const Text('Debloquer'),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: blocks.length,
            );
          },
        ),
      ),
    );
  }
}
