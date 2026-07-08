import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_match/src/application/ocean_match_controller.dart';
import 'package:ocean_match/src/data/ocean_match_repository.dart';
import 'package:ocean_match/src/domain/models.dart';

void main() {
  test('port activities expose aggregated current and destination counts',
      () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'test@oceanmatch.app',
      password: 'password-demo',
    );

    final lasPalmas = _activity(controller, 'las-palmas');
    final leMarin = _activity(controller, 'le-marin');

    expect(lasPalmas.currentCount, 2);
    expect(lasPalmas.destinationCount, 1);
    expect(lasPalmas.isCurrentUserHere, isTrue);
    expect(leMarin.currentCount, 0);
    expect(leMarin.destinationCount, 2);
    expect(leMarin.isCurrentUserGoing, isTrue);
  });

  test('choosing current and destination ports updates profile route data',
      () async {
    final controller = OceanMatchController(
      repository: MockOceanMatchRepository(),
    );

    await controller.login(
      email: 'test@oceanmatch.app',
      password: 'password-demo',
    );

    await controller.updateCurrentPort(_port(controller, 'marseille'));
    await controller.updateDestinationPort(_port(controller, 'mindelo'));

    expect(controller.currentZone?.zone, 'Mediterranee');
    expect(controller.currentZone?.country, 'France');
    expect(controller.currentZone?.portId, 'marseille');
    expect(controller.currentFutureRoute?.destinationZone, 'Cap-Vert');
    expect(controller.currentFutureRoute?.destinationCountry, 'Cap-Vert');
    expect(controller.currentFutureRoute?.destinationPortId, 'mindelo');

    final marseille = _activity(controller, 'marseille');
    final mindelo = _activity(controller, 'mindelo');
    final lasPalmas = _activity(controller, 'las-palmas');

    expect(marseille.currentCount, 1);
    expect(marseille.isCurrentUserHere, isTrue);
    expect(mindelo.destinationCount, 1);
    expect(mindelo.isCurrentUserGoing, isTrue);
    expect(lasPalmas.currentCount, 1);
  });
}

HarborPort _port(OceanMatchController controller, String id) {
  return controller.ports.firstWhere((port) => port.id == id);
}

PortActivity _activity(OceanMatchController controller, String id) {
  return controller.portActivities.firstWhere(
    (activity) => activity.port.id == id,
  );
}
