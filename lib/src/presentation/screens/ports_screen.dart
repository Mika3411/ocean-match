import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../application/ocean_match_controller.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import '../widgets/app_widgets.dart';

enum _PortMapFilter { all, active }

class PortsScreen extends StatefulWidget {
  const PortsScreen({super.key});

  @override
  State<PortsScreen> createState() => _PortsScreenState();
}

class _PortsScreenState extends State<PortsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedPortId;
  _PortMapFilter _filter = _PortMapFilter.all;
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    OceanMatchScope.of(context).refreshPorts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    final activities = _activitiesFor(controller);
    final visibleActivities = _visibleActivities(activities);
    final selected = _selectedActivity(activities, visibleActivities);

    return Scaffold(
      body: OceanBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PortsHeader(),
                      const SizedBox(height: 18),
                      _SearchAndFilterBar(
                        controller: _searchController,
                        query: _query,
                        filter: _filter,
                        onQueryChanged: (value) {
                          setState(() {
                            _query = value;
                            final firstMatch = _visibleActivities(activities)
                                .map((activity) => activity.port.id)
                                .firstOrNull;
                            _selectedPortId = firstMatch ?? _selectedPortId;
                          });
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        onFilterChanged: (value) {
                          setState(() => _filter = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      _PortsMap(
                        activities: visibleActivities.isEmpty
                            ? activities
                            : visibleActivities,
                        selectedPortId: selected?.port.id,
                        onSelected: (portId) {
                          setState(() => _selectedPortId = portId);
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_query.trim().isNotEmpty)
                        _SearchResults(
                          activities: visibleActivities,
                          selectedPortId: selected?.port.id,
                          onSelected: (activity) {
                            setState(() => _selectedPortId = activity.port.id);
                          },
                        ),
                      if (_query.trim().isNotEmpty) const SizedBox(height: 14),
                      if (selected == null)
                        const SectionCard(
                          title: 'Aucun port',
                          subtitle: 'Essayez une autre recherche.',
                          child: Text(''),
                        )
                      else
                        _PortDetailsCard(
                          activity: selected,
                          saving: _saving,
                          onSetCurrent: () => _runPortAction(
                            task: () => controller.updateCurrentPort(
                              selected.port,
                            ),
                            message: '${selected.port.name} est votre port.',
                          ),
                          onSetDestination: () => _runPortAction(
                            task: () => controller.updateDestinationPort(
                              selected.port,
                            ),
                            message:
                                '${selected.port.name} est votre destination.',
                          ),
                        ),
                      const SizedBox(height: 14),
                      const _PortsPrivacyNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PortActivity> _activitiesFor(OceanMatchController controller) {
    if (controller.portActivities.isNotEmpty) {
      return controller.portActivities;
    }
    return [
      for (final port in controller.ports)
        PortActivity(
          port: port,
          currentCount: 0,
          destinationCount: 0,
          isCurrentUserHere: false,
          isCurrentUserGoing: false,
        ),
    ];
  }

  List<PortActivity> _visibleActivities(List<PortActivity> activities) {
    return activities.where((activity) {
      if (!activity.port.matches(_query)) return false;
      if (_filter == _PortMapFilter.active && activity.totalCount == 0) {
        return false;
      }
      return true;
    }).toList();
  }

  PortActivity? _selectedActivity(
    List<PortActivity> activities,
    List<PortActivity> visibleActivities,
  ) {
    final selectedId = _selectedPortId;
    if (selectedId != null) {
      for (final activity in activities) {
        if (activity.port.id == selectedId) return activity;
      }
    }
    if (visibleActivities.isNotEmpty) return visibleActivities.first;
    if (activities.isNotEmpty) return activities.first;
    return null;
  }

  Future<void> _runPortAction({
    required Future<void> Function() task,
    required String message,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await task();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PortsHeader extends StatelessWidget {
  const _PortsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AppLogo(compact: true),
          ),
        ),
        const SizedBox(height: 18),
        Divider(
          height: 1,
          color: OceanColors.champagne.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Ports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: OceanColors.cream,
                  fontFamily: OceanTypography.uiFamily,
                  fontFamilyFallback: OceanTypography.uiFallback,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: 0,
                  shadows: const [],
                ),
              ),
            ),
            const Icon(
              Icons.location_on_outlined,
              color: OceanColors.champagne,
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onClear,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String query;
  final _PortMapFilter filter;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_PortMapFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            labelText: 'Rechercher un port',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_PortMapFilter>(
            segments: const [
              ButtonSegment(
                value: _PortMapFilter.all,
                icon: Icon(Icons.public_outlined),
                label: Text('Tous'),
              ),
              ButtonSegment(
                value: _PortMapFilter.active,
                icon: Icon(Icons.groups_outlined),
                label: Text('Actifs'),
              ),
            ],
            selected: {filter},
            onSelectionChanged: (selection) {
              onFilterChanged(selection.first);
            },
          ),
        ),
      ],
    );
  }
}

class _PortsMap extends StatelessWidget {
  const _PortsMap({
    required this.activities,
    required this.selectedPortId,
    required this.onSelected,
  });

  static const _mapWidth = 980.0;
  static const _mapHeight = 560.0;

  final List<PortActivity> activities;
  final String? selectedPortId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carte interactive des ports',
      child: SizedBox(
        height: 420,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: OceanColors.obsidian,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OceanColors.glassLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractiveViewer(
              minScale: 0.85,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(120),
              child: SizedBox(
                width: _mapWidth,
                height: _mapHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OceanMapPainter(
                          activities: activities,
                          selectedPortId: selectedPortId,
                        ),
                      ),
                    ),
                    for (final activity in activities)
                      _PositionedPortMarker(
                        activity: activity,
                        position: _project(activity.port),
                        selected: activity.port.id == selectedPortId,
                        onTap: () => onSelected(activity.port.id),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Offset _project(HarborPort port) {
    const minLongitude = -160.0;
    const maxLongitude = 65.0;
    const minLatitude = -32.0;
    const maxLatitude = 66.0;
    final x = ((port.longitude - minLongitude) /
            (maxLongitude - minLongitude) *
            _mapWidth)
        .clamp(28.0, _mapWidth - 28.0);
    final y = ((maxLatitude - port.latitude) /
            (maxLatitude - minLatitude) *
            _mapHeight)
        .clamp(28.0, _mapHeight - 28.0);
    return Offset(x, y);
  }
}

class _OceanMapPainter extends CustomPainter {
  const _OceanMapPainter({
    required this.activities,
    required this.selectedPortId,
  });

  final List<PortActivity> activities;
  final String? selectedPortId;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          OceanColors.deepBlue,
          OceanColors.obsidian,
          Color(0xFF0B2732),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    _drawGrid(canvas, size);
    _drawLandMasses(canvas, size);
    _drawRoutes(canvas, size);
    _drawRegionLabels(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OceanColors.champagne.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = 80.0; x < size.width; x += 120) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 70.0; y < size.height; y += 90) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLandMasses(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OceanColors.mist.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = OceanColors.champagne.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final europe = Path()
      ..moveTo(size.width * 0.61, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.02,
        size.width * 0.92,
        size.height * 0.16,
      )
      ..lineTo(size.width * 0.90, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.46,
        size.width * 0.68,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.24,
        size.width * 0.61,
        size.height * 0.08,
      )
      ..close();
    final americas = Path()
      ..moveTo(size.width * 0.04, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.12,
        size.width * 0.23,
        size.height * 0.30,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.47,
        size.width * 0.30,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.26, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.74,
        size.width * 0.05,
        size.height * 0.52,
      )
      ..close();
    final africa = Path()
      ..moveTo(size.width * 0.70, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.40,
        size.width * 0.81,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.78,
        size.width * 0.64,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.59,
        size.height * 0.62,
        size.width * 0.64,
        size.height * 0.44,
      )
      ..close();
    canvas
      ..drawPath(europe, paint)
      ..drawPath(europe, border)
      ..drawPath(americas, paint)
      ..drawPath(americas, border)
      ..drawPath(africa, paint)
      ..drawPath(africa, border);
  }

  void _drawRoutes(Canvas canvas, Size size) {
    final selected = activities.where(
      (activity) =>
          activity.port.id == selectedPortId ||
          activity.isCurrentUserHere ||
          activity.isCurrentUserGoing,
    );
    final paint = Paint()
      ..color = OceanColors.coral.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final points = selected
        .map((activity) => _PortsMap._project(activity.port))
        .toList(growable: false);
    if (points.length < 2) return;
    for (var i = 0; i < points.length - 1; i += 1) {
      final start = points[i];
      final end = points[i + 1];
      final control = Offset(
        (start.dx + end.dx) / 2,
        math.min(start.dy, end.dy) - 70,
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _drawRegionLabels(Canvas canvas) {
    const labels = [
      _MapLabel('Atlantique', Offset(440, 230)),
      _MapLabel('Caraibes', Offset(360, 310)),
      _MapLabel('Mediterranee', Offset(735, 195)),
      _MapLabel('Ocean Indien', Offset(900, 410)),
      _MapLabel('Pacifique', Offset(135, 470)),
    ];
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: OceanColors.champagne.withValues(alpha: 0.18),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, label.offset);
    }
  }

  @override
  bool shouldRepaint(covariant _OceanMapPainter oldDelegate) {
    return oldDelegate.activities != activities ||
        oldDelegate.selectedPortId != selectedPortId;
  }
}

class _MapLabel {
  const _MapLabel(this.text, this.offset);

  final String text;
  final Offset offset;
}

class _PositionedPortMarker extends StatelessWidget {
  const _PositionedPortMarker({
    required this.activity,
    required this.position,
    required this.selected,
    required this.onTap,
  });

  final PortActivity activity;
  final Offset position;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 58.0 : 46.0;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      width: size,
      height: size,
      child: Tooltip(
        message: activity.port.displayName,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _markerColor(activity),
                border: Border.all(
                  color: selected ? OceanColors.champagne : OceanColors.coral,
                  width: selected ? 2.4 : 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _markerColor(activity).withValues(alpha: 0.34),
                    blurRadius: selected ? 22 : 14,
                    spreadRadius: selected ? 3 : 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    activity.isCurrentUserHere
                        ? Icons.my_location
                        : activity.isCurrentUserGoing
                            ? Icons.near_me
                            : Icons.anchor_rounded,
                    color: OceanColors.obsidian,
                    size: selected ? 22 : 18,
                  ),
                  Positioned(
                    right: 3,
                    top: 2,
                    child: _CountDot(count: activity.totalCount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _markerColor(PortActivity activity) {
    if (activity.isCurrentUserHere) return OceanColors.seaTeal;
    if (activity.isCurrentUserGoing) return OceanColors.coral;
    if (activity.totalCount > 0) return OceanColors.champagne;
    return OceanColors.muted;
  }
}

class _CountDot extends StatelessWidget {
  const _CountDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OceanColors.obsidian,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OceanColors.champagne.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: OceanColors.champagne,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.activities,
    required this.selectedPortId,
    required this.onSelected,
  });

  final List<PortActivity> activities;
  final String? selectedPortId;
  final ValueChanged<PortActivity> onSelected;

  @override
  Widget build(BuildContext context) {
    final results = activities.take(5).toList();
    return SectionCard(
      title: 'Recherche',
      child: results.isEmpty
          ? const Text('Aucun port trouve.')
          : Column(
              children: [
                for (final activity in results)
                  _PortResultRow(
                    activity: activity,
                    selected: activity.port.id == selectedPortId,
                    onTap: () => onSelected(activity),
                  ),
              ],
            ),
    );
  }
}

class _PortResultRow extends StatelessWidget {
  const _PortResultRow({
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  final PortActivity activity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.location_on : Icons.location_on_outlined,
        color: selected ? OceanColors.coral : OceanColors.champagne,
      ),
      title: Text(
        activity.port.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${activity.port.region} - ${activity.port.country}'),
      trailing: Text(
        '${activity.currentCount}/${activity.destinationCount}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: OceanColors.champagne,
              fontWeight: FontWeight.w900,
            ),
      ),
      onTap: onTap,
    );
  }
}

class _PortDetailsCard extends StatelessWidget {
  const _PortDetailsCard({
    required this.activity,
    required this.saving,
    required this.onSetCurrent,
    required this.onSetDestination,
  });

  final PortActivity activity;
  final bool saving;
  final VoidCallback onSetCurrent;
  final VoidCallback onSetDestination;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: activity.port.name,
      subtitle: '${activity.port.region} - ${activity.port.country}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PortStat(
                  icon: Icons.people_alt_outlined,
                  label: 'Sur place',
                  value: activity.currentCount,
                  color: OceanColors.seaTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PortStat(
                  icon: Icons.near_me_outlined,
                  label: 'Y vont',
                  value: activity.destinationCount,
                  color: OceanColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving || activity.isCurrentUserHere
                      ? null
                      : onSetCurrent,
                  icon: Icon(
                    activity.isCurrentUserHere
                        ? Icons.check_circle
                        : Icons.my_location,
                  ),
                  label: Text(
                    activity.isCurrentUserHere
                        ? 'Vous etes ici'
                        : 'Je suis ici',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: saving || activity.isCurrentUserGoing
                      ? null
                      : onSetDestination,
                  icon: Icon(
                    activity.isCurrentUserGoing
                        ? Icons.check_circle
                        : Icons.near_me,
                  ),
                  label: Text(
                    activity.isCurrentUserGoing ? 'Destination' : 'J y vais',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortStat extends StatelessWidget {
  const _PortStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            OceanColors.obsidian.withValues(alpha: 0.42),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: OceanColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: OceanColors.champagne,
                fontFamily: OceanTypography.uiFamily,
                fontFamilyFallback: OceanTypography.uiFallback,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: const [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortsPrivacyNote extends StatelessWidget {
  const _PortsPrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: OceanColors.seaTeal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les ports sont affiches avec des compteurs agreges. Aucune position exacte de bateau, quai ou ponton n est visible.',
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
