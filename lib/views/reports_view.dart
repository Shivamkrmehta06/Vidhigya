import 'package:flutter/material.dart';
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

  final List<_ReportItem> _reports = const [
    _ReportItem(
      id: 'R-1042',
      title: 'Deep pothole near flyover',
      category: 'Road',
      status: ReportStatus.inProgress,
      location: 'Outer Ring Road',
      lastUpdate: 'Work crew assigned • 2h ago',
      createdAt: 'Submitted 2 days ago',
      progress: 0.6,
      priority: 'High',
    ),
    _ReportItem(
      id: 'R-1048',
      title: 'Streetlight not working',
      category: 'Lighting',
      status: ReportStatus.open,
      location: 'MG Road',
      lastUpdate: 'Awaiting inspection • 4h ago',
      createdAt: 'Submitted today',
      progress: 0.25,
      priority: 'Medium',
    ),
    _ReportItem(
      id: 'R-1029',
      title: 'Overflowing garbage bin',
      category: 'Waste',
      status: ReportStatus.resolved,
      location: 'Indiranagar 12th Main',
      lastUpdate: 'Cleaned and resolved • Yesterday',
      createdAt: 'Submitted 4 days ago',
      progress: 1.0,
      priority: 'Low',
    ),
    _ReportItem(
      id: 'R-1036',
      title: 'Water leakage on service road',
      category: 'Water',
      status: ReportStatus.inReview,
      location: 'KR Puram',
      lastUpdate: 'Verification in progress • 1d ago',
      createdAt: 'Submitted 3 days ago',
      progress: 0.4,
      priority: 'Medium',
    ),
    _ReportItem(
      id: 'R-1051',
      title: 'Unsafe crossing near school',
      category: 'Public Safety',
      status: ReportStatus.open,
      location: 'BTM Layout',
      lastUpdate: 'Queued for review • 6h ago',
      createdAt: 'Submitted today',
      progress: 0.2,
      priority: 'High',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ReportItem> get _filteredReports {
    final query = _searchController.text.trim().toLowerCase();
    return _reports.where((report) {
      final matchesQuery = query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.location.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query);
      final matchesFilter = _selectedFilter == 'All' ||
          report.status.label == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _ReportSummary.fromReports(_reports);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedEntrance(
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
                child: _SearchBar(controller: _searchController),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SummaryRow(summary: summary),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _FilterRow(
                  selected: _selectedFilter,
                  onSelect: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemBuilder: (context, index) {
                    final report = _filteredReports[index];
                    return _ReportCard(
                      report: report,
                      onTap: () => _showDetails(report),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _filteredReports.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 2,
      child: TextField(
        controller: controller,
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

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Open', 'In Review', 'In Progress', 'Resolved'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = filters[index];
          final selectedChip = label == selected;
          return ChoiceChip(
            label: Text(label),
            selected: selectedChip,
            onSelected: (_) => onSelect(label),
            selectedColor: AppTheme.primaryNavy.withOpacity(0.12),
            labelStyle: TextStyle(
              color:
                  selectedChip ? AppTheme.primaryNavy : AppTheme.textMuted(context),
              fontWeight: selectedChip ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _ReportItem report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

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
                  Icon(Icons.place_outlined,
                      size: 14, color: AppTheme.textMuted(context)),
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
  final String id;
  final String title;
  final String category;
  final ReportStatus status;
  final String location;
  final String lastUpdate;
  final String createdAt;
  final double progress;
  final String priority;

  const _ReportItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.location,
    required this.lastUpdate,
    required this.createdAt,
    required this.progress,
    required this.priority,
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
