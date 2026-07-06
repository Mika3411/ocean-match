import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_match/src/application/ocean_match_controller.dart';
import 'package:ocean_match/src/core/app_error.dart';
import 'package:ocean_match/src/data/ocean_match_repository.dart';
import 'package:ocean_match/src/domain/models.dart';

void main() {
  test('messages require an existing active match conversation', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'lea.demo@oceanmatch.app',
      password: 'password-demo',
    );

    expect(
      controller.sendMessage(
        conversationId: 'missing-conversation',
        content: 'Bonjour',
      ),
      throwsA(isA<OceanMatchException>()),
    );
  });

  test('non participants cannot read or send messages in a conversation',
      () async {
    final repository = MockOceanMatchRepository();
    final camille = await _createOnboardedUser(repository);
    final match = await camille.likeProfile('seed-lea');
    final conversationId = match.conversation!.id;

    final sofia = OceanMatchController(repository: repository);
    await sofia.login(
      email: 'sofia.demo@oceanmatch.app',
      password: 'password-demo',
    );

    expect(
      sofia.loadMessages(conversationId),
      throwsA(isA<OceanMatchException>()),
    );
    expect(
      sofia.sendMessage(
        conversationId: conversationId,
        content: 'Je ne fais pas partie de ce match.',
      ),
      throwsA(isA<OceanMatchException>()),
    );
  });

  test('messages are rejected when the match is no longer active', () async {
    final repository = MockOceanMatchRepository();
    final camille = await _createOnboardedUser(repository);
    final match = await camille.likeProfile('seed-lea');
    final conversationId = match.conversation!.id;

    await repository.deleteAccount('seed-lea');

    expect(
      camille.sendMessage(
        conversationId: conversationId,
        content: 'Ce match n est plus actif.',
      ),
      throwsA(isA<OceanMatchException>()),
    );
  });

  test('matched users can exchange free text messages and see history',
      () async {
    final repository = MockOceanMatchRepository();
    final camille = await _createOnboardedUser(repository);
    final match = await camille.likeProfile('seed-lea');
    final conversationId = match.conversation!.id;

    await camille.sendMessage(
      conversationId: conversationId,
      content: 'Salut Lea, cap sur les Caraibes ?',
    );

    expect(camille.messagesFor(conversationId), hasLength(1));
    expect(
      camille.conversationSummaries.single.lastMessage?.content,
      'Salut Lea, cap sur les Caraibes ?',
    );

    final lea = OceanMatchController(repository: repository);
    await lea.login(
      email: 'lea.demo@oceanmatch.app',
      password: 'password-demo',
    );
    await lea.loadMessages(conversationId);

    expect(
      lea.messagesFor(conversationId).single.content,
      'Salut Lea, cap sur les Caraibes ?',
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));
    await lea.sendMessage(
      conversationId: conversationId,
      content: 'Oui, et la messagerie texte reste gratuite entre matchs.',
    );

    await camille.loadMessages(conversationId);
    await camille.refreshConversations();

    expect(
      camille.messagesFor(conversationId).map((message) => message.content),
      const [
        'Salut Lea, cap sur les Caraibes ?',
        'Oui, et la messagerie texte reste gratuite entre matchs.',
      ],
    );
    expect(
      camille.conversationSummaries.single.lastMessage?.content,
      'Oui, et la messagerie texte reste gratuite entre matchs.',
    );
  });

  test('blocked matched users cannot send new messages', () async {
    final repository = MockOceanMatchRepository();
    final camille = await _createOnboardedUser(repository);
    final match = await camille.likeProfile('seed-lea');
    final conversationId = match.conversation!.id;

    await camille.sendMessage(
      conversationId: conversationId,
      content: 'Message avant blocage',
    );
    await camille.blockUser('seed-lea');

    expect(camille.conversationSummaries.single.isBlocked, isTrue);
    expect(
      camille.sendMessage(
        conversationId: conversationId,
        content: 'Message apres blocage',
      ),
      throwsA(isA<OceanMatchException>()),
    );

    final lea = OceanMatchController(repository: repository);
    await lea.login(
      email: 'lea.demo@oceanmatch.app',
      password: 'password-demo',
    );

    expect(lea.conversationSummaries.single.isBlocked, isTrue);
    expect(
      lea.sendMessage(
        conversationId: conversationId,
        content: 'Reponse apres blocage',
      ),
      throwsA(isA<OceanMatchException>()),
    );

    await lea.loadMessages(conversationId);
    expect(
      lea.messagesFor(conversationId).single.content,
      'Message avant blocage',
    );
  });

  test('users can report the matched participant from a conversation',
      () async {
    final repository = MockOceanMatchRepository();
    final camille = await _createOnboardedUser(repository);
    final match = await camille.likeProfile('seed-lea');
    final conversationId = match.conversation!.id;

    await camille.reportUser(
      reportedId: 'seed-lea',
      reason: ReportReason.suspiciousBehavior,
      conversationId: conversationId,
      comment: 'Signalement depuis la conversation.',
    );

    expect(
      camille.reportUser(
        reportedId: 'seed-marc',
        reason: ReportReason.suspiciousBehavior,
        conversationId: conversationId,
      ),
      throwsA(isA<OceanMatchException>()),
    );
  });
}

Future<OceanMatchController> _createOnboardedUser(
  MockOceanMatchRepository repository,
) async {
  final controller = OceanMatchController(repository: repository);
  await controller.signUp(
    email: 'camille.messaging@example.com',
    password: 'password123',
  );
  await controller.verifyEmail();

  final userId = controller.currentUser!.id;
  final now = DateTime.now();
  await controller.completeOnboarding(
    profile: Profile(
      userId: userId,
      firstName: 'Camille',
      birthDate: DateTime(now.year - 36, now.month, now.day),
      gender: Gender.woman,
      searchGender: SearchGender.everyone,
      languages: const ['Francais', 'Anglais'],
      bio: 'Navigation tranquille entre Canaries et Caraibes.',
      isComplete: true,
      createdAt: now,
      updatedAt: now,
    ),
    photos: [
      ProfilePhoto(
        id: '$userId-photo-0',
        userId: userId,
        url: 'https://example.com/photo-0.jpg',
        isPrimary: true,
        order: 0,
        status: PhotoModerationStatus.approved,
        createdAt: now,
      ),
      ProfilePhoto(
        id: '$userId-photo-1',
        userId: userId,
        url: 'https://example.com/photo-1.jpg',
        isPrimary: false,
        order: 1,
        status: PhotoModerationStatus.approved,
        createdAt: now,
      ),
    ],
    lifeAboard: LifeAboard(
      userId: userId,
      status: BoardStatus.liveaboard,
      boatOrProject: 'Voilier 34 pieds',
      sailingType: 'Hauturier tranquille',
      experience: SailingExperience.intermediate,
      lifestyleTags: const ['navigation lente', 'escales calmes'],
      updatedAt: now,
    ),
    currentZone: CurrentZone(
      userId: userId,
      zone: 'Canaries',
      updatedAt: now,
    ),
    futureRoute: FutureRoute(
      id: '$userId-route',
      userId: userId,
      destinationZone: 'Caraibes',
      startPeriod: 'Hiver',
      endPeriod: 'Printemps',
      flexibility: RouteFlexibility.flexible,
      comment: '',
      isActive: true,
      updatedAt: now,
    ),
    preferences: Preferences(
      userId: userId,
      ageMin: 18,
      ageMax: 70,
      genderTargets: SearchGender.everyone,
      zones: const ['Canaries', 'Caraibes'],
      intentions: const [
        Intention.seriousRelationship,
        Intention.sailingProject,
      ],
    ),
  );
  return controller;
}
