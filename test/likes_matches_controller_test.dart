import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_match/src/application/ocean_match_controller.dart';
import 'package:ocean_match/src/core/app_error.dart';
import 'package:ocean_match/src/data/ocean_match_repository.dart';
import 'package:ocean_match/src/domain/models.dart';

void main() {
  test('A likes B without return does not create a match', () async {
    final repository = MockOceanMatchRepository();
    final a = await _createOnboardedUser(
      repository,
      email: 'a.no-return@example.com',
      firstName: 'Alice',
      gender: Gender.woman,
    );
    final b = await _createOnboardedUser(
      repository,
      email: 'b.no-return@example.com',
      firstName: 'Benoit',
      gender: Gender.man,
    );

    final result = await a.likeProfile(b.currentUser!.id);

    expect(result.createdMatch, isFalse);
    expect(result.match, isNull);
    expect(result.conversation, isNull);
    expect(a.conversationSummaries, isEmpty);
  });

  test('reciprocal likes create one match and one conversation', () async {
    final repository = MockOceanMatchRepository();
    final a = await _createOnboardedUser(
      repository,
      email: 'a.reciprocal@example.com',
      firstName: 'Alice',
      gender: Gender.woman,
    );
    final b = await _createOnboardedUser(
      repository,
      email: 'b.reciprocal@example.com',
      firstName: 'Benoit',
      gender: Gender.man,
    );

    await a.likeProfile(b.currentUser!.id);
    final result = await b.likeProfile(a.currentUser!.id);

    expect(result.createdMatch, isTrue);
    expect(result.match, isNotNull);
    expect(result.conversation, isNotNull);
    expect(result.conversation!.matchId, result.match!.id);

    await a.refreshConversations();
    expect(a.conversationSummaries, hasLength(1));
    expect(b.conversationSummaries, hasLength(1));
    expect(a.conversationSummaries.single.match.id, result.match!.id);
    expect(
      b.conversationSummaries.single.conversation.id,
      result.conversation!.id,
    );
  });

  test('repeated likes do not duplicate matches or conversations', () async {
    final repository = MockOceanMatchRepository();
    final a = await _createOnboardedUser(
      repository,
      email: 'a.duplicate@example.com',
      firstName: 'Alice',
      gender: Gender.woman,
    );
    final b = await _createOnboardedUser(
      repository,
      email: 'b.duplicate@example.com',
      firstName: 'Benoit',
      gender: Gender.man,
    );

    final firstLike = await a.likeProfile(b.currentUser!.id);
    final repeatedFirstLike = await a.likeProfile(b.currentUser!.id);
    final match = await b.likeProfile(a.currentUser!.id);
    final repeatedReciprocalLike = await b.likeProfile(a.currentUser!.id);

    expect(firstLike.createdMatch, isFalse);
    expect(repeatedFirstLike.createdMatch, isFalse);
    expect(match.createdMatch, isTrue);
    expect(repeatedReciprocalLike.createdMatch, isFalse);
    expect(repeatedReciprocalLike.match?.id, match.match!.id);

    await a.refreshConversations();
    await b.refreshConversations();
    expect(a.conversationSummaries, hasLength(1));
    expect(b.conversationSummaries, hasLength(1));
    expect(
      a.conversationSummaries.single.conversation.id,
      match.conversation!.id,
    );
    expect(
      b.conversationSummaries.single.conversation.id,
      match.conversation!.id,
    );
  });

  test('passed profile does not immediately return to discovery', () async {
    final repository = MockOceanMatchRepository();
    final a = await _createOnboardedUser(
      repository,
      email: 'a.pass@example.com',
      firstName: 'Alice',
      gender: Gender.woman,
    );
    final b = await _createOnboardedUser(
      repository,
      email: 'b.pass@example.com',
      firstName: 'Benoit',
      gender: Gender.man,
    );
    final targetId = b.currentUser!.id;

    await a.refreshDiscovery();
    expect(_discoveryIds(a), contains(targetId));

    await a.passProfile(targetId);
    expect(_discoveryIds(a), isNot(contains(targetId)));

    await a.refreshDiscovery();
    expect(_discoveryIds(a), isNot(contains(targetId)));
  });

  test('blocked users cannot create a match', () async {
    final repository = MockOceanMatchRepository();
    final a = await _createOnboardedUser(
      repository,
      email: 'a.block@example.com',
      firstName: 'Alice',
      gender: Gender.woman,
    );
    final b = await _createOnboardedUser(
      repository,
      email: 'b.block@example.com',
      firstName: 'Benoit',
      gender: Gender.man,
    );

    await a.likeProfile(b.currentUser!.id);
    await a.blockUser(b.currentUser!.id);

    expect(
      b.likeProfile(a.currentUser!.id),
      throwsA(isA<OceanMatchException>()),
    );

    await a.refreshConversations();
    await b.refreshConversations();
    expect(a.conversationSummaries, isEmpty);
    expect(b.conversationSummaries, isEmpty);
  });
}

List<String> _discoveryIds(OceanMatchController controller) {
  return [
    for (final discoveryProfile in controller.discoveryProfiles)
      discoveryProfile.profile.userId,
  ];
}

Future<OceanMatchController> _createOnboardedUser(
  MockOceanMatchRepository repository, {
  required String email,
  required String firstName,
  required Gender gender,
}) async {
  final controller = OceanMatchController(repository: repository);
  await controller.signUp(email: email, password: 'password123');
  await controller.verifyEmail();

  final userId = controller.currentUser!.id;
  final now = DateTime.now();
  await controller.completeOnboarding(
    profile: Profile(
      userId: userId,
      firstName: firstName,
      birthDate: DateTime(now.year - 34, now.month, now.day),
      gender: gender,
      searchGender: SearchGender.everyone,
      languages: const ['Francais', 'Anglais'],
      bio: 'Navigation tranquille entre Canaries et Caraibes.',
      isComplete: false,
      createdAt: now,
      updatedAt: now,
    ),
    photos: [
      for (var i = 0; i < 2; i += 1)
        ProfilePhoto(
          id: '$userId-photo-$i',
          userId: userId,
          url: 'https://example.com/$userId-photo-$i.jpg',
          isPrimary: i == 0,
          order: i,
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
