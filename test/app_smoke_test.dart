import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_match/src/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const OceanMatchApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    final finder = find.text(label, skipOffstage: false).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('BlueWater Match app starts on the welcome screen',
      (tester) async {
    await pumpApp(tester);

    expect(
      find.text('Rencontrez des personnes qui partagent la vie à bord.'),
      findsOneWidget,
    );
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('new users sign up and must verify email before onboarding',
      (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Créer un compte');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'camille.mvp@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tapText(tester, 'Créer un compte');

    expect(find.text('Verifiez votre email'), findsOneWidget);
    expect(find.textContaining('camille.mvp@example.com'), findsOneWidget);
    expect(find.text('Decouvrir'), findsNothing);

    await tapText(tester, 'J ai verifie mon email');

    expect(find.text('1. Identite'), findsOneWidget);
    expect(find.text('Decouvrir'), findsNothing);
  });

  testWidgets('new users complete onboarding and publish their profile',
      (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Créer un compte');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'onboarding.mvp@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tapText(tester, 'Créer un compte');
    await tapText(tester, 'J ai verifie mon email');

    expect(find.text('1. Identite'), findsOneWidget);
    expect(find.text('Decouvrir'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'Camille');
    await tester.enterText(find.byType(TextField).at(1), '36');
    await tapText(tester, 'Continuer');

    expect(find.text('2. Genre et recherche'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('3. Langues'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(0),
      'Francais, Anglais',
    );
    await tapText(tester, 'Continuer');

    expect(find.text('4. Bio'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(0),
      'Vie a bord lente, escales longues et projet de route partage.',
    );
    await tapText(tester, 'Continuer');

    expect(find.text('5. Vie a bord'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Voilier 34 pieds');
    await tapText(tester, 'Continuer');

    expect(find.text('6. Experience'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('7. Zones larges'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('8. Intentions'), findsOneWidget);
    await tapText(tester, 'Relation serieuse');
    await tapText(tester, 'Continuer');

    expect(find.text('9. Recapitulatif'), findsOneWidget);
    expect(find.text('Brouillon enregistre, pret a publier'), findsOneWidget);
    await tapText(tester, 'Publier mon profil');

    expect(find.text('Decouvrir'), findsWidgets);
    expect(find.text('Profil pret'), findsNothing);
  });

  testWidgets('forgotten password request confirms without exposing accounts',
      (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Créer un compte');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'reset@example.com',
    );
    await tapText(tester, 'Mot de passe oublié');

    expect(find.textContaining('lien de réinitialisation'), findsOneWidget);
  });

  testWidgets('verified users can log in and log out', (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Se connecter');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'lea.demo@oceanmatch.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password-demo');
    await tapText(tester, 'Se connecter');

    expect(find.text('Decouvrir'), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final logoutButton = find.widgetWithText(
      OutlinedButton,
      'Se deconnecter',
    );
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
