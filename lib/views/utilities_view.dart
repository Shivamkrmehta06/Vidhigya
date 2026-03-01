import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final String query = _controller.text.trim().toUpperCase();
    if (query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter report ID')));
      return;
    }

    if (Firebase.apps.isEmpty) {
      setState(() {
        _issue = null;
        _searchError = 'Firebase is not configured for this build.';
      });
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _issue = null;
        _searchError = 'Please login to track your reports.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final Set<String> candidates = <String>{
      query,
      if (!query.startsWith('R-')) 'R-$query',
    };

    try {
      QueryDocumentSnapshot<Map<String, dynamic>>? matchedDoc;
      String matchedCode = query;

      for (final String code in candidates) {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('reports')
                .where('createdBy', isEqualTo: user.uid)
                .where('reportCode', isEqualTo: code)
                .limit(1)
                .get();
        if (snapshot.docs.isNotEmpty) {
          matchedDoc = snapshot.docs.first;
          matchedCode = code;
          break;
        }
      }

      if (!mounted) return;
      if (matchedDoc == null) {
        setState(() {
          _issue = null;
          _searchError = 'No report found for ID ${query.toUpperCase()}.';
        });
        return;
      }

      final Map<String, dynamic> data = matchedDoc.data();
      final String status = _normalizeStatus(
        (data['status'] ?? 'Open').toString(),
      );
      final String title = (data['title'] ?? 'Civic issue reported')
          .toString()
          .trim();
      final String location = (data['location'] ?? 'Location pending')
          .toString()
          .trim();
      final String latestUpdate = (data['lastUpdate'] ?? 'No updates yet')
          .toString()
          .trim();
      final double progress = _readProgress(data['progress'], status);
      final String priority = (data['priority'] ?? 'Medium').toString().trim();

      setState(() {
        _issue = _TrackedIssue(
          id: matchedCode,
          title: title,
          location: location,
          status: status,
          latestUpdate: latestUpdate,
          progress: progress,
          priority: priority,
        );
        _searchError = null;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _issue = null;
        _searchError = error.code == 'permission-denied'
            ? 'You can track only your own submitted reports.'
            : (error.message ?? 'Could not fetch report right now.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _issue = null;
        _searchError = 'Could not fetch report right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  String _normalizeStatus(String raw) {
    final String value = raw.trim().toLowerCase().replaceAll(' ', '');
    switch (value) {
      case 'inreview':
        return 'In Review';
      case 'inprogress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Open';
    }
  }

  double _readProgress(Object? raw, String status) {
    if (raw is num) {
      final double parsed = raw.toDouble();
      if (parsed < 0) return 0;
      if (parsed > 1) return 1;
      return parsed;
    }
    switch (status) {
      case 'Resolved':
        return 1;
      case 'In Progress':
        return 0.66;
      case 'In Review':
        return 0.33;
      default:
        return 0.12;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'Track by ID',
      subtitle: 'Track your civic complaint status instantly using report ID.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _search(),
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
                onPressed: _isSearching ? null : _search,
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
                child: Text(_isSearching ? 'Tracking...' : 'Track'),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 10),
            Text(
              _searchError!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ),
          if (_issue != null) _TrackedIssueCard(issue: _issue!),
        ],
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
          LinearProgressIndicator(
            value: issue.progress,
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
            backgroundColor: AppTheme.border(context),
            color: AppTheme.primaryNavy,
          ),
          const SizedBox(height: 8),
          Text(
            'Priority: ${issue.priority}',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TimelineDot(
                label: 'Reported',
                active: issue.stepIndex == 0,
                completed: issue.stepIndex > 0,
              ),
              _TimelineDot(
                label: 'Verified',
                active: issue.stepIndex == 1,
                completed: issue.stepIndex > 1,
              ),
              _TimelineDot(
                label: 'In Progress',
                active: issue.stepIndex == 2,
                completed: issue.stepIndex > 2,
              ),
              _TimelineDot(label: 'Resolved', active: issue.stepIndex == 3),
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
  final bool completed;

  const _TimelineDot({
    required this.label,
    this.active = false,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = active || completed
        ? AppTheme.primaryNavy
        : AppTheme.border(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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

    return _UtilityScaffold(
      title: 'Helpline Directory',
      subtitle: 'Emergency and civic support numbers in one place.',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
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
                      SnackBar(content: Text('Dialing ${line.number} (mock)')),
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

    return _UtilityScaffold(
      title: 'Service Notices',
      subtitle: 'Planned maintenance and civic work announcements.',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
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
    return _UtilityScaffold(
      title: 'Offline Drafts',
      subtitle: 'Saved reports you can resume anytime.',
      child: _drafts.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Text(
                  'No drafts available',
                  style: GoogleFonts.manrope(
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
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

    return _UtilityScaffold(
      title: 'Nearby Safe Spots',
      subtitle: 'Find nearby police, hospitals, and support centers.',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
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

    return _UtilityScaffold(
      title: 'First Aid Guide',
      subtitle: 'Quick actionable steps for common emergencies.',
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
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
    );
  }
}

class _UtilityScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _UtilityScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const _UtilityBackdrop(),
          SafeArea(
            child: AnimatedEntrance(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        _UtilityTopIconBubble(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Hero(
                          tag: 'vidhigya-wordmark',
                          child: Image.asset(
                            'assets/images/vidhigya_wordmark.png',
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityBackdrop extends StatelessWidget {
  const _UtilityBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.cloud, AppTheme.mist],
              ),
            ),
          ),
        ),
        Positioned(
          left: -86,
          top: 108,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: AppTheme.tealAccent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -74,
          bottom: 150,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: AppTheme.purpleAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _UtilityTopIconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _UtilityTopIconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: AppTheme.softShadow,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 21, color: AppTheme.primaryNavy),
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
  final double progress;
  final String priority;

  const _TrackedIssue({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.latestUpdate,
    required this.progress,
    required this.priority,
  });

  int get stepIndex {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'inreview':
        return 1;
      case 'inprogress':
        return 2;
      case 'resolved':
        return 3;
      default:
        return 0;
    }
  }
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
