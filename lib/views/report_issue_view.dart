import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import '../widgets/animated_entrance.dart';
import 'pratyukti_copilot_view.dart';

class ReportIssueView extends StatefulWidget {
  const ReportIssueView({super.key});

  @override
  State<ReportIssueView> createState() => _ReportIssueViewState();
}

class _ReportIssueViewState extends State<ReportIssueView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _category = 'Road';
  double _severity = 0.5;
  bool _hasPhoto = false;
  bool _aiReady = false;

  late final AnimationController _entryController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _mockAddPhoto() {
    setState(() {
      _hasPhoto = true;
      _aiReady = false;
    });
  }

  void _runAi() {
    if (!_hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo to run AI analysis.')),
      );
      return;
    }
    setState(() {
      _aiReady = true;
    });
  }

  Future<void> _openPratyukti() async {
    final result = await Navigator.push<PratyuktiResult>(
      context,
      MaterialPageRoute(builder: (_) => const PratyuktiCopilotView()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _titleController.text = result.title;
      _descController.text = result.description;
      _category = result.category;
      _severity = result.severity;
      _hasPhoto = true;
      _aiReady = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pratyukti analysis added to report.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AuthBackground(
        child: SafeArea(
          child: AnimatedEntrance(
            child: FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppTheme.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Report Issue',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const Spacer(),
                        Image.asset(
                          'assets/images/vidhigya_wordmark.png',
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Capture the issue, use Pratyukti AI, and submit in seconds.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openPratyukti,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Ask Pratyukti Copilot'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        side: BorderSide(color: AppTheme.border(context)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. Add a photo',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _hasPhoto
                                ? ClipRRect(
                                    key: const ValueKey('photo'),
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radius),
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey('placeholder'),
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface(context),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radius,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.border(context),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 32,
                                          color: AppTheme.primaryNavy,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to add a clear photo',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: AppTheme.textMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.camera_alt_rounded,
                                  label: 'Capture',
                                  onTap: _mockAddPhoto,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.upload_rounded,
                                  label: 'Upload',
                                  onTap: _mockAddPhoto,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '2. Pratyukti AI',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _openPratyukti,
                                child: const Text(
                                  'Open Copilot',
                                  style: TextStyle(
                                    color: AppTheme.primaryNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _runAi,
                                child: const Text(
                                  'Run analysis',
                                  style: TextStyle(
                                    color: AppTheme.primaryNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 260),
                            crossFadeState: _aiReady
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: Text(
                              'AI will auto-detect the issue, severity, and tags.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detected: Pothole on main road',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: const [
                                    _AiChip(label: 'Road Safety'),
                                    _AiChip(label: 'High Priority'),
                                    _AiChip(label: 'Public Hazard'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Suggested severity',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.textMuted(context),
                                  ),
                                ),
                                Slider(
                                  value: _severity,
                                  onChanged: (value) {
                                    setState(() {
                                      _severity = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3. Details',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RoundedField(
                            controller: _titleController,
                            hintText: 'Issue title',
                            icon: Icons.report_outlined,
                          ),
                          const SizedBox(height: 12),
                          _RoundedField(
                            controller: _descController,
                            hintText: 'Add more details (optional)',
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _category,
                            items: const [
                              DropdownMenuItem(
                                value: 'Road',
                                child: Text('Road'),
                              ),
                              DropdownMenuItem(
                                value: 'Lighting',
                                child: Text('Lighting'),
                              ),
                              DropdownMenuItem(
                                value: 'Waste',
                                child: Text('Waste'),
                              ),
                              DropdownMenuItem(
                                value: 'Water',
                                child: Text('Water'),
                              ),
                              DropdownMenuItem(
                                value: 'Public Safety',
                                child: Text('Public Safety'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _category = value ?? 'Road';
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.category_outlined),
                              hintText: 'Category',
                              filled: true,
                              fillColor: AppTheme.surface(context),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radius),
                              border: Border.all(color: AppTheme.border(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Current location • MG Road, Bengaluru',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppTheme.textMuted(context),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: AppTheme.primaryNavy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SubmitButton(
                      label: 'Submit Issue',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Issue submitted (mock).'),
                          ),
                        );
                        Navigator.pop(context);
                      },
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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        side: BorderSide(color: AppTheme.border(context)),
        foregroundColor: AppTheme.primaryNavy,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  final String label;

  const _AiChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int maxLines;

  const _RoundedField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SubmitButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppTheme.primaryNavy,
              AppTheme.purpleAccent,
              AppTheme.tealAccent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
