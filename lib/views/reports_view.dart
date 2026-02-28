import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final Set<String> _escalatingReportDocIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ReportItem> _filteredReports(List<_ReportItem> reports) {
    final String query = _searchController.text.trim().toLowerCase();
    return reports.where((report) {
      final bool matchesQuery =
          query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.location.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query);
      final bool matchesFilter =
          _selectedFilter == 'All' || report.status.label == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const _InfoScaffold(
        title: 'My Reports',
        message: 'Connect Firebase configuration to load your reports.',
      );
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _InfoScaffold(
        title: 'My Reports',
        message: 'Login required to view your submitted reports.',
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedEntrance(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('createdBy', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final List<_ReportItem> reports = snapshot.hasData
                  ? snapshot.data!.docs.map(_reportFromDoc).toList()
                  : const <_ReportItem>[];
              final List<_ReportItem> filteredReports = _filteredReports(
                reports,
              );
              final _ReportSummary summary = _ReportSummary.fromReports(
                reports,
              );

              return Column(
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
                        Text(
                          'My Reports',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const Spacer(),
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
                      'Track status, follow updates, and keep your community moving.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _SearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _SummaryRow(summary: summary),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _FilterPopupBar(
                      selected: _selectedFilter,
                      onSelect: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildListState(
                      snapshot: snapshot,
                      filteredReports: filteredReports,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListState({
    required AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    required List<_ReportItem> filteredReports,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Could not load reports right now. Please retry.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(color: AppTheme.textMuted(context)),
          ),
        ),
      );
    }

    if (filteredReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No reports found for the selected filter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(color: AppTheme.textMuted(context)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemBuilder: (context, index) {
        final _ReportItem report = filteredReports[index];
        return _ReportCard(
          report: report,
          canEscalate: _canEscalate(report),
          isEscalated: report.escalated,
          isEscalating: _escalatingReportDocIds.contains(report.docId),
          onEscalate: () => _escalateIssue(report),
          onTap: () => _showDetails(report),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemCount: filteredReports.length,
    );
  }

  _ReportItem _reportFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final DateTime createdAt = _readTimestamp(
      data['createdAt'],
      fallback: DateTime.now(),
    );
    final DateTime updatedAt = _readTimestamp(
      data['updatedAt'],
      fallback: createdAt,
    );
    final DateTime? deadlineAt = data['deadlineAt'] is Timestamp
        ? (data['deadlineAt'] as Timestamp).toDate()
        : null;
    final ReportStatus status = _statusFromValue(data['status'] as String?);

    return _ReportItem(
      docId: doc.id,
      id: (data['reportCode'] as String?)?.trim().isNotEmpty == true
          ? data['reportCode'] as String
          : 'R-${doc.id.substring(0, 4).toUpperCase()}',
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'Civic issue reported',
      category: (data['category'] as String?)?.trim().isNotEmpty == true
          ? data['category'] as String
          : 'General',
      status: status,
      location: (data['location'] as String?)?.trim().isNotEmpty == true
          ? data['location'] as String
          : 'Location pending',
      lastUpdate: _lastUpdateText(
        customUpdate: data['lastUpdate'] as String?,
        status: status,
        updatedAt: updatedAt,
      ),
      createdAt: 'Submitted ${_relativeTime(createdAt)}',
      submittedAt: createdAt,
      deadlineAt: deadlineAt,
      progress: _readProgress(data['progress'], status),
      priority: _readPriority(data, status),
      escalated:
          data['escalated'] == true ||
          (data['escalationState'] as String?) == 'requested',
    );
  }

  DateTime _readTimestamp(Object? value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    return fallback;
  }

  double _readProgress(Object? rawValue, ReportStatus status) {
    if (rawValue is num) {
      return rawValue.toDouble().clamp(0.0, 1.0);
    }
    switch (status) {
      case ReportStatus.open:
        return 0.15;
      case ReportStatus.inReview:
        return 0.4;
      case ReportStatus.inProgress:
        return 0.65;
      case ReportStatus.resolved:
        return 1.0;
    }
  }

  String _readPriority(Map<String, dynamic> data, ReportStatus status) {
    final String? stored = data['priority'] as String?;
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }
    final double severity = (data['severity'] as num?)?.toDouble() ?? 0.5;
    if (severity >= 0.67) return 'High';
    if (severity >= 0.34) return 'Medium';
    if (status == ReportStatus.resolved) return 'Low';
    return 'Medium';
  }

  String _lastUpdateText({
    required String? customUpdate,
    required ReportStatus status,
    required DateTime updatedAt,
  }) {
    final String timeline = _relativeTime(updatedAt);
    if (customUpdate != null && customUpdate.trim().isNotEmpty) {
      return '${customUpdate.trim()} • $timeline';
    }
    switch (status) {
      case ReportStatus.open:
        return 'Awaiting inspection • $timeline';
      case ReportStatus.inReview:
        return 'Verification in progress • $timeline';
      case ReportStatus.inProgress:
        return 'Work crew assigned • $timeline';
      case ReportStatus.resolved:
        return 'Resolved by authority • $timeline';
    }
  }

  String _relativeTime(DateTime moment) {
    final Duration diff = DateTime.now().difference(moment);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final int weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '${weeks}w ago';
    final int months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }

  ReportStatus _statusFromValue(String? value) {
    final String normalized = (value ?? '').toLowerCase().replaceAll(' ', '');
    switch (normalized) {
      case 'open':
        return ReportStatus.open;
      case 'inreview':
        return ReportStatus.inReview;
      case 'inprogress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      default:
        return ReportStatus.open;
    }
  }

  void _showDetails(_ReportItem report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ReportDetailSheet(report: report);
      },
    );
  }

  bool _canEscalate(_ReportItem report) {
    if (report.status == ReportStatus.resolved || report.escalated) {
      return false;
    }
    final DateTime deadline =
        report.deadlineAt ?? report.submittedAt.add(const Duration(hours: 72));
    return DateTime.now().isAfter(deadline);
  }

  Future<void> _escalateIssue(_ReportItem report) async {
    if (_escalatingReportDocIds.contains(report.docId) || report.escalated) {
      return;
    }
    if (!_canEscalate(report)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalation becomes available after 72 hours.'),
        ),
      );
      return;
    }
    setState(() {
      _escalatingReportDocIds.add(report.docId);
    });
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(report.docId)
          .update({
            'escalated': true,
            'escalationState': 'requested',
            'escalationRequestedAt': FieldValue.serverTimestamp(),
            'lastUpdate': 'Escalated to higher authority',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${report.id} escalated to higher authority.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Escalation failed.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _escalatingReportDocIds.remove(report.docId);
        });
      }
    }
  }
}

class _InfoScaffold extends StatelessWidget {
  final String title;
  final String message;

  const _InfoScaffold({required this.title, required this.message});

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
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: AppTheme.textMuted(context),
                    ),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 2,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search reports, category, or area',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterPopupBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterPopupBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const List<String> filters = <String>[
      'All',
      'Open',
      'In Review',
      'In Progress',
      'Resolved',
    ];
    return Row(
      children: [
        Text(
          'Status',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted(context),
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          initialValue: selected,
          onSelected: onSelect,
          itemBuilder: (context) => filters
              .map(
                (status) =>
                    PopupMenuItem<String>(value: status, child: Text(status)),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: AppTheme.primaryNavy,
                ),
                const SizedBox(width: 6),
                Text(
                  selected,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.textMuted(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final _ReportSummary summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Open',
            value: summary.open,
            accent: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'In Review',
            value: summary.inReview,
            accent: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Resolved',
            value: summary.resolved,
            accent: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _ReportItem report;
  final bool canEscalate;
  final bool isEscalated;
  final bool isEscalating;
  final VoidCallback onEscalate;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.canEscalate,
    required this.isEscalated,
    required this.isEscalating,
    required this.onEscalate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusPill(status: report.status),
                  const Spacer(),
                  Text(
                    report.id,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: AppTheme.textMuted(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                  _PriorityPill(priority: report.priority),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: report.progress,
                minHeight: 5,
                backgroundColor: AppTheme.border(context),
                color: report.status.color,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 8),
              Text(
                report.lastUpdate,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.textMuted(context),
                ),
              ),
              if (canEscalate || isEscalated) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isEscalated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Escalated',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    if (canEscalate && !isEscalated) ...[
                      const Spacer(),
                      OutlinedButton(
                        onPressed: isEscalating ? null : onEscalate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryNavy,
                          side: BorderSide(
                            color: AppTheme.primaryNavy.withOpacity(0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: isEscalating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Escalate'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ReportStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String priority;

  const _PriorityPill({required this.priority});

  Color get _color {
    switch (priority) {
      case 'High':
        return const Color(0xFFDC2626);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  final _ReportItem report;

  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border(context),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusPill(status: report.status),
              const SizedBox(width: 8),
              _PriorityPill(priority: report.priority),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Category', value: report.category),
          _DetailRow(label: 'Location', value: report.location),
          _DetailRow(label: 'Created', value: report.createdAt),
          _DetailRow(label: 'Latest update', value: report.lastUpdate),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.textMuted(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItem {
  final String docId;
  final String id;
  final String title;
  final String category;
  final ReportStatus status;
  final String location;
  final String lastUpdate;
  final String createdAt;
  final DateTime submittedAt;
  final DateTime? deadlineAt;
  final double progress;
  final String priority;
  final bool escalated;

  const _ReportItem({
    required this.docId,
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.location,
    required this.lastUpdate,
    required this.createdAt,
    required this.submittedAt,
    required this.deadlineAt,
    required this.progress,
    required this.priority,
    required this.escalated,
  });
}

enum ReportStatus {
  open('Open', Color(0xFFDC2626)),
  inReview('In Review', Color(0xFFF59E0B)),
  inProgress('In Progress', Color(0xFF2563EB)),
  resolved('Resolved', Color(0xFF16A34A));

  final String label;
  final Color color;

  const ReportStatus(this.label, this.color);
}

class _ReportSummary {
  final int open;
  final int inReview;
  final int resolved;

  const _ReportSummary({
    required this.open,
    required this.inReview,
    required this.resolved,
  });

  factory _ReportSummary.fromReports(List<_ReportItem> reports) {
    int open = 0;
    int inReview = 0;
    int resolved = 0;
    for (final report in reports) {
      switch (report.status) {
        case ReportStatus.open:
          open += 1;
          break;
        case ReportStatus.inReview:
          inReview += 1;
          break;
        case ReportStatus.resolved:
          resolved += 1;
          break;
        case ReportStatus.inProgress:
          break;
      }
    }
    return _ReportSummary(open: open, inReview: inReview, resolved: resolved);
  }
}
