import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class ExploreMapView extends StatelessWidget {
  const ExploreMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocationMapView(
      title: 'Explore',
      subtitle: 'See issues and resources around your current location.',
      badgeLabel: 'Live area map',
      badgeIcon: Icons.map_outlined,
      accent: AppTheme.tealAccent,
    );
  }
}

class SafetyMapView extends StatelessWidget {
  const SafetyMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocationMapView(
      title: 'Safety Map',
      subtitle: 'Track nearby safety zones and active alerts.',
      badgeLabel: 'Safety coverage',
      badgeIcon: Icons.shield_outlined,
      accent: AppTheme.primaryNavy,
    );
  }
}

class LocationMapView extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badgeLabel;
  final IconData badgeIcon;
  final Color accent;

  const LocationMapView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.accent,
  });

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(28.6139, 77.2090);
  bool _loading = true;
  String? _error;
  StreamSubscription<Position>? _positionSub;
  final TextEditingController _searchController = TextEditingController();
  final Distance _distance = const Distance();
  final List<_IssuePoint> _issues = [];
  final Set<String> _typeFilters = {};
  final Set<String> _statusFilters = {};
  final Set<String> _severityFilters = {};
  bool _showFilters = false;
  _IssuePoint? _selectedIssue;
  _IssuePoint? _routeIssue;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(() {
        _error = 'Location services are disabled.';
        _loading = false;
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permission denied.';
        _loading = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _updatePosition(position);
    _startTracking();
  }

  void _startTracking() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen(_updatePosition);
  }

  void _updatePosition(Position position) {
    final next = LatLng(position.latitude, position.longitude);
    if (!mounted) return;
    setState(() {
      _center = next;
      _loading = false;
      if (_issues.isEmpty) {
        _issues.addAll(_seedIssues(next));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_center, 15.5);
    });
  }

  Future<void> _retryPermission() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    await _initLocation();
  }

  List<_IssuePoint> _seedIssues(LatLng center) {
    return [
      _IssuePoint(
        id: 'p1',
        title: 'Deep pothole near flyover',
        type: 'Road',
        status: 'Open',
        severity: 'High',
        location: LatLng(center.latitude + 0.002, center.longitude + 0.001),
      ),
      _IssuePoint(
        id: 'p2',
        title: 'Streetlight not working',
        type: 'Lighting',
        status: 'Open',
        severity: 'Medium',
        location: LatLng(center.latitude - 0.001, center.longitude + 0.0015),
      ),
      _IssuePoint(
        id: 'p3',
        title: 'Overflowing garbage bin',
        type: 'Waste',
        status: 'Open',
        severity: 'Medium',
        location: LatLng(center.latitude + 0.0005, center.longitude - 0.0012),
      ),
      _IssuePoint(
        id: 'p4',
        title: 'Water leakage on road',
        type: 'Water',
        status: 'In Progress',
        severity: 'Low',
        location: LatLng(center.latitude - 0.0012, center.longitude - 0.001),
      ),
      _IssuePoint(
        id: 'p5',
        title: 'Unsafe crossing reported',
        type: 'Public Safety',
        status: 'Open',
        severity: 'High',
        location: LatLng(center.latitude + 0.0015, center.longitude - 0.0006),
      ),
      _IssuePoint(
        id: 'p6',
        title: 'Signal pole light blinking erratically',
        type: 'Lighting',
        status: 'In Progress',
        severity: 'Medium',
        location: LatLng(center.latitude + 0.0024, center.longitude - 0.0019),
      ),
      _IssuePoint(
        id: 'p7',
        title: 'Debris on service lane after roadwork',
        type: 'Waste',
        status: 'Open',
        severity: 'Low',
        location: LatLng(center.latitude - 0.0022, center.longitude + 0.0011),
      ),
      _IssuePoint(
        id: 'p8',
        title: 'Waterlogging near underpass',
        type: 'Water',
        status: 'Open',
        severity: 'High',
        location: LatLng(center.latitude - 0.0018, center.longitude - 0.0022),
      ),
      _IssuePoint(
        id: 'p9',
        title: 'Damaged road divider reflectors',
        type: 'Road',
        status: 'In Progress',
        severity: 'Medium',
        location: LatLng(center.latitude + 0.0009, center.longitude + 0.0021),
      ),
      _IssuePoint(
        id: 'p10',
        title: 'Dark stretch near park boundary wall',
        type: 'Public Safety',
        status: 'Open',
        severity: 'High',
        location: LatLng(center.latitude - 0.0004, center.longitude + 0.0026),
      ),
      _IssuePoint(
        id: 'p11',
        title: 'Overflowing roadside drain',
        type: 'Water',
        status: 'Open',
        severity: 'Medium',
        location: LatLng(center.latitude + 0.0027, center.longitude + 0.0003),
      ),
      _IssuePoint(
        id: 'p12',
        title: 'Garbage collection delay at market junction',
        type: 'Waste',
        status: 'In Progress',
        severity: 'Low',
        location: LatLng(center.latitude - 0.0026, center.longitude - 0.0008),
      ),
    ];
  }

  List<_IssuePoint> get _filteredIssues {
    final query = _searchController.text.trim().toLowerCase();
    return _issues.where((issue) {
      final matchesQuery = query.isEmpty ||
          issue.title.toLowerCase().contains(query) ||
          issue.type.toLowerCase().contains(query);
      final matchesType =
          _typeFilters.isEmpty || _typeFilters.contains(issue.type);
      final matchesStatus =
          _statusFilters.isEmpty || _statusFilters.contains(issue.status);
      final matchesSeverity =
          _severityFilters.isEmpty || _severityFilters.contains(issue.severity);
      return matchesQuery && matchesType && matchesStatus && matchesSeverity;
    }).toList();
  }

  void _toggleFilter(String value, Set<String> bucket) {
    setState(() {
      if (bucket.contains(value)) {
        bucket.remove(value);
      } else {
        bucket.add(value);
      }
    });
  }

  void _selectIssue(_IssuePoint issue) {
    setState(() {
      _selectedIssue = issue;
    });
  }

  void _setRoute(_IssuePoint issue) {
    setState(() {
      _routeIssue = issue;
    });
  }

  double _distanceKm(LatLng a, LatLng b) {
    return _distance.as(LengthUnit.Kilometer, a, b);
  }

  String _etaText(double km) {
    final minutes = (km / 25 * 60).round().clamp(2, 90);
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.primaryNavy,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Hero(
                    tag: 'vidhigya-wordmark',
                    child: Image.asset(
                      'assets/images/vidhigya_wordmark.png',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  widget.subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 15,
                          minZoom: 3,
                          maxZoom: 19,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'trata_app',
                          ),
                          if (_routeIssue != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [_center, _routeIssue!.location],
                                  strokeWidth: 4,
                                  color: widget.accent.withOpacity(0.8),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _center,
                                width: 48,
                                height: 48,
                                child: _LocationDot(accent: widget.accent),
                              ),
                              ..._filteredIssues.map(
                                (issue) => Marker(
                                  point: issue.location,
                                  width: 46,
                                  height: 46,
                                  child: _IssueMarker(
                                    issue: issue,
                                    selected: _selectedIssue?.id == issue.id,
                                    onTap: () => _selectIssue(issue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _Badge(
                          label: widget.badgeLabel,
                          icon: widget.badgeIcon,
                          accent: widget.accent,
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: _MapButton(
                          icon: _showFilters
                              ? Icons.close_rounded
                              : Icons.tune_rounded,
                          onTap: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 16,
                        right: 16,
                        child: _SearchBar(controller: _searchController),
                      ),
                      Positioned(
                        top: 112,
                        left: 16,
                        right: 16,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: _showFilters
                              ? _FilterPanel(
                                  typeFilters: _typeFilters,
                                  statusFilters: _statusFilters,
                                  severityFilters: _severityFilters,
                                  onToggle: _toggleFilter,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        bottom: 18,
                        right: 18,
                        child: _MapButton(
                          icon: Icons.my_location_rounded,
                          onTap: () {
                            _mapController.move(_center, 16);
                          },
                        ),
                      ),
                      if (_selectedIssue != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: _IssueCard(
                            issue: _selectedIssue!,
                            distanceKm: _distanceKm(
                              _center,
                              _selectedIssue!.location,
                            ),
                            eta: _etaText(
                              _distanceKm(_center, _selectedIssue!.location),
                            ),
                            accent: widget.accent,
                            onRoute: () => _setRoute(_selectedIssue!),
                          ),
                        ),
                      if (_loading || _error != null)
                        Positioned.fill(
                          child: Container(
                            color: AppTheme.surface(context).withOpacity(0.75),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface(context),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_loading)
                                      const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.location_off_rounded,
                                        size: 28,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _loading
                                          ? 'Finding your location...'
                                          : _error ?? 'Unable to access location.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: AppTheme.textMuted(context),
                                      ),
                                    ),
                                    if (!_loading)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: TextButton(
                                          onPressed: _retryPermission,
                                          child: const Text(
                                            'Try again',
                                            style: TextStyle(
                                              color: AppTheme.primaryNavy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDot extends StatelessWidget {
  final Color accent;

  const _LocationDot({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.surface(context),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _IssuePoint {
  final String id;
  final String title;
  final String type;
  final String status;
  final String severity;
  final LatLng location;

  const _IssuePoint({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.severity,
    required this.location,
  });
}

class _IssueMarker extends StatelessWidget {
  final _IssuePoint issue;
  final bool selected;
  final VoidCallback onTap;

  const _IssueMarker({
    required this.issue,
    required this.selected,
    required this.onTap,
  });

  Color get _accent {
    switch (issue.severity) {
      case 'High':
        return const Color(0xFFDC2626);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  IconData get _icon {
    switch (issue.type) {
      case 'Lighting':
        return Icons.lightbulb_outline;
      case 'Waste':
        return Icons.delete_outline;
      case 'Water':
        return Icons.water_drop_outlined;
      case 'Public Safety':
        return Icons.shield_outlined;
      default:
        return Icons.directions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            shape: BoxShape.circle,
            border: Border.all(color: _accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(_icon, color: _accent, size: 20),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _Badge({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppTheme.primaryNavy),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context).withOpacity(0.96),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 3,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search issues, category, or area',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final Set<String> typeFilters;
  final Set<String> statusFilters;
  final Set<String> severityFilters;
  final void Function(String, Set<String>) onToggle;

  const _FilterPanel({
    required this.typeFilters,
    required this.statusFilters,
    required this.severityFilters,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context).withOpacity(0.96),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChipRow(
              title: 'Type',
              values: const [
                'Road',
                'Lighting',
                'Waste',
                'Water',
                'Public Safety',
              ],
              selected: typeFilters,
              onToggle: (value) => onToggle(value, typeFilters),
            ),
            const SizedBox(height: 8),
            _ChipRow(
              title: 'Severity',
              values: const ['Low', 'Medium', 'High'],
              selected: severityFilters,
              onToggle: (value) => onToggle(value, severityFilters),
            ),
            const SizedBox(height: 8),
            _ChipRow(
              title: 'Status',
              values: const ['Open', 'In Progress'],
              selected: statusFilters,
              onToggle: (value) => onToggle(value, statusFilters),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String title;
  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ChipRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        Text(
          '$title:',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.textMuted(context),
          ),
        ),
        ...values.map(
          (value) => FilterChip(
            label: Text(value),
            selected: selected.contains(value),
            onSelected: (_) => onToggle(value),
            selectedColor: AppTheme.primaryNavy.withOpacity(0.12),
            checkmarkColor: AppTheme.primaryNavy,
          ),
        ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  final _IssuePoint issue;
  final double distanceKm;
  final String eta;
  final Color accent;
  final VoidCallback onRoute;

  const _IssueCard({
    required this.issue,
    required this.distanceKm,
    required this.eta,
    required this.accent,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.type,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${distanceKm.toStringAsFixed(2)} km',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  eta,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  issue.status,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onRoute,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Route'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
