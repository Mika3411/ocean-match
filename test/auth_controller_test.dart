import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_match/src/application/ocean_match_controller.dart';
import 'package:ocean_match/src/core/app_error.dart';
import 'package:ocean_match/src/data/ocean_match_repository.dart';
import 'package:ocean_match/src/domain/models.dart';

void main() {
  test('new users cannot access discovery before active complete account',
      () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.signUp(
      email: 'new.sailor@example.com',
      password: 'password123',
    );

    expect(controller.isAuthenticated, isTrue);
    expect(controller.hasActiveAccount, isFalse);
    expect(controller.canAccessDiscovery, isFalse);

    await controller.refreshDiscovery();

    expect(controller.discoveryProfiles, isEmpty);
    expect(
      controller.likeProfile('seed-lea'),
      throwsA(isA<OceanMatchException>()),
    );

    await controller.verifyEmail();

    expect(controller.hasActiveAccount, isTrue);
    expect(controller.canAccessDiscovery, isFalse);

    await controller.refreshDiscovery();

    expect(controller.discoveryProfiles, isEmpty);
  });

  test('complete onboarding publishes profile and unlocks discovery', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.signUp(
      email: 'complete.sailor@example.com',
      password: 'password123',
    );
    await controller.verifyEmail();

    expect(controller.canAccessDiscovery, isFalse);

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
        bio: 'Vie a bord lente, escales longues et projet de route partage.',
        isComplete: false,
        createdAt: now,
        updatedAt: now,
      ),
      photos: const [],
      lifeAboard: LifeAboard(
        userId: userId,
        status: BoardStatus.liveaboard,
        boatOrProject: 'Voilier 34 pieds',
        sailingType: BoardStatus.liveaboard.label,
        experience: SailingExperience.confirmed,
        lifestyleTags: const [],
        updatedAt: now,
      ),
      currentZone: CurrentZone(
        userId: userId,
        zone: 'Canaries',
        updatedAt: now,
      ),
      futureRoute: FutureRoute(
        id: 'route-test',
        userId: userId,
        destinationZone: 'Caraibes',
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
        genderTargets: SearchGender.everyone,
        zones: const ['Canaries', 'Caraibes'],
        intentions: const [
          Intention.seriousRelationship,
          Intention.sailingProject,
        ],
      ),
    );

    expect(controller.isProfileComplete, isTrue);
    expect(controller.canAccessDiscovery, isTrue);
    expect(controller.currentProfile?.firstName, 'Camille');
    expect(controller.currentPhotos, isEmpty);
    expect(controller.discoveryProfiles, isNotEmpty);
  });

  test('onboarding rejects exact position hints', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.signUp(
      email: 'privacy.sailor@example.com',
      password: 'password123',
    );
    await controller.verifyEmail();

    final userId = controller.currentUser!.id;
    final now = DateTime.now();
    expect(
      controller.completeOnboarding(
        profile: Profile(
          userId: userId,
          firstName: 'Sam',
          birthDate: DateTime(now.year - 31, now.month, now.day),
          gender: Gender.nonBinary,
          searchGender: SearchGender.everyone,
          languages: const ['Francais'],
          bio: 'Disponible pour une route tranquille.',
          isComplete: false,
          createdAt: now,
          updatedAt: now,
        ),
        photos: const [],
        lifeAboard: LifeAboard(
          userId: userId,
          status: BoardStatus.crew,
          boatOrProject: 'Ponton B12',
          sailingType: BoardStatus.crew.label,
          experience: SailingExperience.intermediate,
          lifestyleTags: const [],
          updatedAt: now,
        ),
        currentZone: CurrentZone(
          userId: userId,
          zone: 'Canaries',
          updatedAt: now,
        ),
        futureRoute: FutureRoute(
          id: 'route-privacy',
          userId: userId,
          destinationZone: 'Caraibes',
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
          genderTargets: SearchGender.everyone,
          zones: const ['Canaries', 'Caraibes'],
          intentions: const [Intention.friendship],
        ),
      ),
      throwsA(isA<OceanMatchException>()),
    );
  });

  test('test account can log in and access discovery directly', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'test@oceanmatch.app',
      password: 'password-demo',
    );

    expect(controller.hasActiveAccount, isTrue);
    expect(controller.isProfileComplete, isTrue);
    expect(controller.canAccessDiscovery, isTrue);
    expect(controller.discoveryProfiles, isNotEmpty);
  });

  test('test account also accepts the simple test password', () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'test@oceanmatch.app',
      password: 'password123',
    );

    expect(controller.hasActiveAccount, isTrue);
    expect(controller.canAccessDiscovery, isTrue);
  });
}
