import 'package:flutter/material.dart';

import 'application/ocean_match_controller.dart';
import 'core/app_theme.dart';
import 'data/api_ocean_match_repository.dart';
import 'data/ocean_match_repository.dart';
import 'presentation/screens/auth_gate.dart';

class OceanMatchApp extends StatefulWidget {
  const OceanMatchApp({super.key, this.repository});

  final OceanMatchRepository? repository;

  @override
  State<OceanMatchApp> createState() => _OceanMatchAppState();
}

class _OceanMatchAppState extends State<OceanMatchApp> {
  late final OceanMatchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OceanMatchController(
      repository: widget.repository ?? createDefaultOceanMatchRepository(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OceanMatchScope(
      controller: _controller,
      child: MaterialApp(
        title: 'BlueWater Match',
        debugShowCheckedModeBanner: false,
        theme: OceanTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}

class OceanMatchScope extends InheritedNotifier<OceanMatchController> {
  const OceanMatchScope({
    required OceanMatchController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static OceanMatchController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OceanMatchScope>();
    assert(scope != null, 'OceanMatchScope not found');
    return scope!.notifier!;
  }
}
