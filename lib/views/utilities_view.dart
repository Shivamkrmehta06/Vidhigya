import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import 'location_map_view.dart';

class TrackIssueView extends StatefulWidget {
  const TrackIssueView({super.key});

  @override
  State<TrackIssueView> createState() => _TrackIssueViewState();
}

class _TrackIssueViewState extends State<TrackIssueView> {
  final TextEditingController _controller = TextEditingController();
  _TrackedIssue? _issue;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim().toUpperCase();
    if (query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter report ID')));
      return;
    }
    setState(() {
      _issue = _TrackedIssue(
        id: query,
        title: 'Deep pothole near flyover',
        location: 'Outer Ring Road',
        status: 'In Progress',
        latestUpdate: 'Crew assigned and patch work started.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Track by ID'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedEntrance(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Text(
              'Track your civic complaint status instantly using report ID.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Example: R-1042',
                      filled: true,
                      fillColor: AppTheme.surface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  child: const Text('Track'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_issue != null) _TrackedIssueCard(issue: _issue!),
          ],
        ),
      ),
    );
  }
}

class _TrackedIssueCard extends StatelessWidget {
  final _TrackedIssue issue;

  const _TrackedIssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  issue.status,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                issue.id,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.textMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            issue.title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.location,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Latest update',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.latestUpdate,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _TimelineDot(label: 'Reported'),
              _TimelineDot(label: 'Verified'),
              _TimelineDot(label: 'In Progress', active: true),
              _TimelineDot(label: 'Resolved'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final String label;
  final bool active;

  const _TimelineDot({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryNavy : AppTheme.border(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppTheme.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class HelplineDirectoryView extends StatelessWidget {
  const HelplineDirectoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final helplines = const [
      _Helpline(name: 'Emergency', number: '112', note: 'National helpline'),
      _Helpline(name: 'Police', number: '100', note: 'Immediate law support'),
      _Helpline(name: 'Ambulance', number: '108', note: 'Medical emergency'),
      _Helpline(name: 'Women Helpline', number: '1091', note: 'Safety support'),
      _Helpline(
        name: 'Ward Office',
        number: '080-22334455',
        note: 'Local civic office',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Helpline Directory'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedEntrance(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemBuilder: (context, index) {
            final line = helplines[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line.note,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dialing ${line.number} (mock)'),
                        ),
                      );
                    },
                    child: Text(
                      line.number,
                      style: const TextStyle(
                        color: AppTheme.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: helplines.length,
        ),
      ),
    );
  }
}

class ServiceNoticesView extends StatelessWidget {
  const ServiceNoticesView({super.key});

  @override
  Widget build(BuildContext context) {
    const notices = [
      _Notice(
        title: 'Water supply interruption',
        area: 'Indiranagar Block A',
        time: 'Tomorrow • 6:00 AM to 10:00 AM',
      ),
      _Notice(
        title: 'Power maintenance shutdown',
        area: 'BTM Layout 2nd Stage',
        time: 'Today • 11:30 PM to 2:00 AM',
      ),
      _Notice(
        title: 'Road resurfacing work',
        area: 'Outer Ring Road Service Lane',
        time: 'Saturday • 9:00 AM to 5:00 PM',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Service Notices'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedEntrance(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemBuilder: (context, index) {
            final notice = notices[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notice.area,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice.time,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: notices.length,
        ),
      ),
    );
  }
}

class OfflineDraftsView extends StatefulWidget {
  const OfflineDraftsView({super.key});

  @override
  State<OfflineDraftsView> createState() => _OfflineDraftsViewState();
}

class _OfflineDraftsViewState extends State<OfflineDraftsView> {
  final List<_DraftIssue> _drafts = [
    const _DraftIssue(
      title: 'Streetlight outage',
      location: '5th Lane, Indiranagar',
      savedAt: 'Saved 2h ago',
    ),
    const _DraftIssue(
      title: 'Garbage overflow near market',
      location: 'BTM Market Road',
      savedAt: 'Saved yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Offline Drafts'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedEntrance(
        child: _drafts.isEmpty
            ? Center(
                child: Text(
                  'No drafts available',
                  style: GoogleFonts.manrope(
                    color: AppTheme.textMuted(context),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.tealAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              Text(
                                draft.location,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                              Text(
                                draft.savedAt,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening draft (mock)'),
                              ),
                            );
                          },
                          child: const Text(
                            'Resume',
                            style: TextStyle(
                              color: AppTheme.primaryNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: _drafts.length,
              ),
      ),
    );
  }
}

class SafeSpotsView extends StatelessWidget {
  const SafeSpotsView({super.key});

  @override
  Widget build(BuildContext context) {
    const spots = [
      _SafeSpot(
        name: 'Indiranagar Police Station',
        type: 'Police',
        eta: '7 min',
        distance: '1.8 km',
      ),
      _SafeSpot(
        name: 'Manipal Hospital',
        type: 'Hospital',
        eta: '11 min',
        distance: '2.9 km',
      ),
      _SafeSpot(
        name: 'Women Support Center',
        type: 'Women Safety',
        eta: '14 min',
        distance: '3.4 km',
      ),
      _SafeSpot(
        name: '24x7 Pharmacy',
        type: 'Pharmacy',
        eta: '5 min',
        distance: '1.2 km',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nearby Safe Spots'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedEntrance(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemBuilder: (context, index) {
            final spot = spots[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.border(context)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${spot.type} • ${spot.distance} • ${spot.eta}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationMapView(
                            title: 'Route: ${spot.name}',
                            subtitle:
                                'Showing nearby map context for navigation to this safe spot.',
                            badgeLabel: 'Safe spot route',
                            badgeIcon: Icons.route_rounded,
                            accent: AppTheme.primaryNavy,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Route',
                      style: TextStyle(
                        color: AppTheme.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: spots.length,
        ),
      ),
    );
  }
}

class FirstAidGuideView extends StatelessWidget {
  const FirstAidGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    const guides = [
      _FirstAidGuide(
        title: 'Bleeding',
        steps: [
          'Apply direct pressure with clean cloth.',
          'Raise injured area above heart if possible.',
          'Do not remove deep embedded objects.',
          'Call emergency support immediately.',
        ],
      ),
      _FirstAidGuide(
        title: 'Burn',
        steps: [
          'Cool burn with running water for 10 minutes.',
          'Do not apply ice, toothpaste, or oil.',
          'Cover loosely with sterile non-stick dressing.',
          'Seek medical help for large or facial burns.',
        ],
      ),
      _FirstAidGuide(
        title: 'Fainting',
        steps: [
          'Lay person flat and elevate legs slightly.',
          'Loosen tight clothing around neck.',
          'Check breathing and responsiveness.',
          'Call for medical assistance if not recovering quickly.',
        ],
      ),
      _FirstAidGuide(
        title: 'Road Accident',
        steps: [
          'Ensure scene is safe before helping.',
          'Do not move victims with possible spine injury.',
          'Control visible bleeding with pressure.',
          'Call ambulance and share precise location.',
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('First Aid Guide'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedEntrance(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: guides.length,
          itemBuilder: (context, index) {
            final guide = guides[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: ExpansionTile(
                title: Text(
                  guide.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                children: guide.steps
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.circle,
                                size: 7,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrackedIssue {
  final String id;
  final String title;
  final String location;
  final String status;
  final String latestUpdate;

  const _TrackedIssue({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.latestUpdate,
  });
}

class _Helpline {
  final String name;
  final String number;
  final String note;

  const _Helpline({
    required this.name,
    required this.number,
    required this.note,
  });
}

class _Notice {
  final String title;
  final String area;
  final String time;

  const _Notice({required this.title, required this.area, required this.time});
}

class _DraftIssue {
  final String title;
  final String location;
  final String savedAt;

  const _DraftIssue({
    required this.title,
    required this.location,
    required this.savedAt,
  });
}

class _SafeSpot {
  final String name;
  final String type;
  final String eta;
  final String distance;

  const _SafeSpot({
    required this.name,
    required this.type,
    required this.eta,
    required this.distance,
  });
}

class _FirstAidGuide {
  final String title;
  final List<String> steps;

  const _FirstAidGuide({required this.title, required this.steps});
}
