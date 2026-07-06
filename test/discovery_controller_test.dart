import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_match/src/application/ocean_match_controller.dart';
import 'package:ocean_match/src/core/app_error.dart';
import 'package:ocean_match/src/data/ocean_match_repository.dart';
import 'package:ocean_match/src/domain/models.dart';

void main() {
  test('discovery shows compatible complete active profiles', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'lea.demo@oceanmatch.app',
      password: 'password-demo',
    );

    final ids = _discoveryIds(controller);
    expect(ids, containsAll(['seed-sofia', 'seed-nina']));
    expect(ids, isNot(contains('seed-marc')));
    for (final discoveryProfile in controller.discoveryProfiles) {
      expect(discoveryProfile.profile.isComplete, isTrue);
      expect(discoveryProfile.primaryPhoto, isNotNull);
      expect(discoveryProfile.currentZone.zone, isNotEmpty);
      expect(discoveryProfile.futureRoute.destinationZone, isNotEmpty);
      expect(discoveryProfile.intentions, isNotEmpty);
      expect(discoveryProfile.lifeAboard.boatOrProject, isNotEmpty);
    }
  });

  test('pass and like remove the profile from discovery', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'lea.demo@oceanmatch.app',
      password: 'password-demo',
    );

    final passedId = controller.discoveryProfiles.first.profile.userId;
    await controller.passProfile(passedId);
    expect(_discoveryIds(controller), isNot(contains(passedId)));

    final likedId = controller.discoveryProfiles.first.profile.userId;
    await controller.likeProfile(likedId);
    expect(_discoveryIds(controller), isNot(contains(likedId)));

    await controller.refreshDiscovery();
    expect(_discoveryIds(controller), isNot(contains(passedId)));
    expect(_discoveryIds(controller), isNot(contains(likedId)));
  });

  test('blocked profiles disappear in both discovery directions', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'lea.demo@oceanmatch.app',
      password: 'password-demo',
    );

    final blockedId = controller.discoveryProfiles.first.profile.userId;
    await controller.blockUser(blockedId);
    expect(_discoveryIds(controller), isNot(contains(blockedId)));

    await controller.logout();
    await controller.login(
      email: _seedEmail(blockedId),
      password: 'password-demo',
    );
    expect(_discoveryIds(controller), isNot(contains('seed-lea')));
  });

  test('deleted, suspended and incomplete accounts are excluded', () async {
    final repository = MockOceanMatchRepository();
    final deleted = await _createCompatibleSofiaTarget(
      repository,
      email: 'deleted.compatible@example.com',
    );
    final suspended = await _createCompatibleSofiaTarget(
      repository,
      email: 'suspended.compatible@example.com',
    );
    final incomplete = await repository.signUp(
      email: 'incomplete.compatible@example.com',
      password: 'password123',
    );
    await repository.verifyEmail(incomplete.id);

    final controller = OceanMatchController(repository: repository);
    await controller.login(
      email: 'sofia.demo@oceanmatch.app',
      password: 'password-demo',
    );

    expect(_discoveryIds(controller), contains(deleted.id));
    expect(_discoveryIds(controller), contains(suspended.id));
    expect(_discoveryIds(controller), isNot(contains(incomplete.id)));

    await repository.deleteAccount(deleted.id);
    repository.setAccountStatusForTesting(
      suspended.id,
      AccountStatus.suspended,
    );
    await controller.refreshDiscovery();

    final ids = _discoveryIds(controller);
    expect(ids, isNot(contains(deleted.id)));
    expect(ids, isNot(contains(suspended.id)));
    expect(ids, isNot(contains(incomplete.id)));
  });

  test('exact boat positions are rejected from public discovery data', () async {
    final repository = MockOceanMatchRepository();
    final account = await repository.signUp(
      email: 'precise.position@example.com',
      password: 'password123',
    );
    await repository.verifyEmail(account.id);

    await expectLater(
      _completeCompatibleProfile(
        repository,
        userId: account.id,
        zone: '43.12, -8.45',
      ),
      throwsA(isA<OceanMatchException>()),
    );
  });
}

List<String> _discoveryIds(OceanMatchController controller) {
  return [
    for (final discoveryProfile in controller.discoveryProfiles)
      discoveryProfile.profile.userId,
  ];
}

String _seedEmail(String userId) {
  switch (userId) {
    case 'seed-lea':
      return 'lea.demo@oceanmatch.app';
    case 'seed-marc':
      return 'marc.demo@oceanmatch.app';
    case 'seed-sofia':
      return 'sofia.demo@oceanmatch.app';
    case 'seed-nina':
      return 'nina.demo@oceanmatch.app';
  }
  throw StateError('Unknown seed user: $userId');
}

Future<UserAccount> _createCompatibleSofiaTarget(
  MockOceanMatchRepository repository, {
  required String email,
}) async {
  final account = await repository.signUp(
    email: email,
    password: 'password123',
  );
  await repository.verifyEmail(account.id);
  await _completeCompatibleProfile(repository, userId: account.id);
  return account;
}

Future<void> _completeCompatibleProfile(
  MockOceanMatchRepository repository, {
  required String userId,
  String zone = 'Cap-Vert',
  String route = 'Caraibes',
}) {
  final now = DateTime.now();
  return repository.completeOnboarding(
    profile: Profile(
      userId: userId,
      firstName: 'Alex',
      birthDate: DateTime(now.year - 31, now.month, now.day),
      gender: Gender.man,
      searchGender: SearchGender.women,
      languages: const ['Francais', 'Anglais'],
      bio: 'Disponible pour une navigation simple et des escales calmes.',
      isComplete: false,
      createdAt: now,
      updatedAt: now,
    ),
    photos: [
      for (var i = 0; i < 2; i += 1)
        ProfilePhoto(
          id: '$userId-photo-$i',
          userId: userId,
          url: 'https://example.com/photo-$i.jpg',
          isPrimary: i == 0,
          order: i,
          status: PhotoModerationStatus.approved,
          createdAt: now,
        ),
    ],
    lifeAboard: LifeAboard(
      userId: userId,
      status: BoardStatus.crew,
      boatOrProject: 'Recherche embarquement',
      sailingType: 'Equipage partage',
      experience: SailingExperience.intermediate,
      lifestyleTags: const ['equipage partage', 'aventure'],
      updatedAt: now,
    ),
    currentZone: CurrentZone(
      userId: userId,
      zone: zone,
      updatedAt: now,
    ),
    futureRoute: FutureRoute(
      id: '$userId-route',
      userId: userId,
      destinationZone: route,
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
      genderTargets: SearchGender.women,
      zones: [zone, route],
      intentions: const [Intention.crew, Intention.sailingProject],
    ),
  );
}
