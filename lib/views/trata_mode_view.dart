import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import 'location_map_view.dart';

class TrataModeView extends StatefulWidget {
  const TrataModeView({super.key});

  @override
  State<TrataModeView> createState() => _TrataModeViewState();
}

class _TrataModeViewState extends State<TrataModeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  String _incidentType = 'Personal Safety';
  bool _shareLiveLocation = true;
  bool _autoCallPrimary = true;
  bool _sendSms = true;
  bool _autoRecord = true;
  bool _voiceTrigger = true;
  bool _powerButtonTrigger = false;
  bool _geoFenceAlert = true;
  bool _stealthMode = false;
  bool _siren = false;
  bool _flashlight = false;
  bool _fakeCall = false;

  int get _readinessScore {
    final toggles = [
      _shareLiveLocation,
      _autoCallPrimary,
      _sendSms,
      _autoRecord,
      _voiceTrigger,
      _geoFenceAlert,
    ];
    final enabled = toggles.where((item) => item).length;
    return (enabled / toggles.length * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startActivationFlow() async {
    final activated = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ActivationCountdownSheet(),
    );
    if (!mounted || activated != true) return;
    _showActivatedSheet();
  }

  void _showActivatedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.border(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'TRATA Activated',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Incident: $_incidentType',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.textMuted(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_shareLiveLocation) const _ActionTag(label: 'Live location shared'),
                  if (_sendSms) const _ActionTag(label: 'SMS alerts sent'),
                  if (_autoCallPrimary) const _ActionTag(label: 'Primary contact called'),
                  if (_autoRecord) const _ActionTag(label: 'Evidence recording on'),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mockAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedEntrance(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                      'TRATA Mode',
                      style: GoogleFonts.outfit(
                        fontSize: 21,
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
                const SizedBox(height: 8),
                Text(
                  'TRATA is your emergency layer: one trigger to alert trusted contacts, share location, and capture evidence.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 14),
                _ReadinessCard(score: _readinessScore),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Incident Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Personal Safety',
                    'Medical',
                    'Accident',
                    'Harassment',
                  ]
                      .map(
                        (item) => ChoiceChip(
                          label: Text(item),
                          selected: _incidentType == item,
                          onSelected: (_) => setState(() => _incidentType = item),
                          selectedColor: AppTheme.primaryNavy.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: _incidentType == item
                                ? AppTheme.primaryNavy
                                : AppTheme.textMuted(context),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: _pulse,
                  child: GestureDetector(
                    onTap: _startActivationFlow,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB91C1C), Color(0xFFD7193A)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD7193A).withOpacity(0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TRATA ALERT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap once: 5-second countdown with cancel.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.92),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Trusted Circle'),
                const SizedBox(height: 8),
                _ContactCard(
                  name: 'Mom',
                  relation: 'Primary contact',
                  phone: '+91 98XXXXXX10',
                  accent: AppTheme.primaryNavy,
                  status: 'Online',
                ),
                const SizedBox(height: 10),
                _ContactCard(
                  name: 'Rohit',
                  relation: 'Friend',
                  phone: '+91 98XXXXXX22',
                  accent: AppTheme.tealAccent,
                  status: 'Online',
                ),
                const SizedBox(height: 10),
                _ContactCard(
                  name: 'Ward Helpline',
                  relation: 'City emergency',
                  phone: '112',
                  accent: const Color(0xFFDC2626),
                  status: 'Priority',
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Smart Triggers'),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Voice keyword trigger',
                  subtitle: 'Activate TRATA using your emergency phrase',
                  value: _voiceTrigger,
                  onChanged: (value) => setState(() => _voiceTrigger = value),
                ),
                _ToggleTile(
                  title: 'Power button trigger',
                  subtitle: 'Press power button 3 times rapidly',
                  value: _powerButtonTrigger,
                  onChanged: (value) =>
                      setState(() => _powerButtonTrigger = value),
                ),
                _ToggleTile(
                  title: 'Geofence safety alert',
                  subtitle: 'Alert if you leave your safe route at night',
                  value: _geoFenceAlert,
                  onChanged: (value) => setState(() => _geoFenceAlert = value),
                ),
                _ToggleTile(
                  title: 'Stealth mode',
                  subtitle: 'Discreet activation with silent UI',
                  value: _stealthMode,
                  onChanged: (value) => setState(() => _stealthMode = value),
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Auto Actions'),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Share live location',
                  subtitle: 'Real-time tracking for trusted contacts',
                  value: _shareLiveLocation,
                  onChanged: (value) =>
                      setState(() => _shareLiveLocation = value),
                ),
                _ToggleTile(
                  title: 'Auto call primary contact',
                  subtitle: 'Immediately dial your primary contact',
                  value: _autoCallPrimary,
                  onChanged: (value) =>
                      setState(() => _autoCallPrimary = value),
                ),
                _ToggleTile(
                  title: 'Send SMS alert',
                  subtitle: 'Broadcast emergency message with location',
                  value: _sendSms,
                  onChanged: (value) => setState(() => _sendSms = value),
                ),
                _ToggleTile(
                  title: 'Auto record audio/video',
                  subtitle: 'Secure evidence buffer starts immediately',
                  value: _autoRecord,
                  onChanged: (value) => setState(() => _autoRecord = value),
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Quick Tools'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.volume_up_rounded,
                        label: 'Siren',
                        active: _siren,
                        onTap: () {
                          setState(() => _siren = !_siren);
                          _mockAction(_siren ? 'Siren stopped' : 'Siren started');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.flashlight_on_rounded,
                        label: 'Flash',
                        active: _flashlight,
                        onTap: () {
                          setState(() => _flashlight = !_flashlight);
                          _mockAction(
                            _flashlight ? 'Flashlight off' : 'Flashlight strobe on',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.phone_in_talk_rounded,
                        label: 'Fake Call',
                        active: _fakeCall,
                        onTap: () {
                          setState(() => _fakeCall = !_fakeCall);
                          _mockAction('Incoming call simulation (mock)');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Evidence & Check-In'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppTheme.border(context)),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.security_rounded,
                            color: AppTheme.primaryNavy,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Evidence vault ready • Last sync 2 mins ago',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _mockAction('Check-in sent to trusted circle'),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Check-In'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SafetyMapView(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Safe Route'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryNavy,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivationCountdownSheet extends StatefulWidget {
  const _ActivationCountdownSheet();

  @override
  State<_ActivationCountdownSheet> createState() => _ActivationCountdownSheetState();
}

class _ActivationCountdownSheetState extends State<_ActivationCountdownSheet> {
  int _seconds = 5;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _seconds > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _seconds -= 1);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (5 - _seconds) / 5;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border(context),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Activating TRATA',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cancel within countdown to prevent emergency dispatch.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            color: const Color(0xFFD7193A),
            backgroundColor: AppTheme.border(context),
          ),
          const SizedBox(height: 12),
          Text(
            '$_seconds s',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD7193A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7193A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Activate Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final int score;

  const _ReadinessCard({required this.score});

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
              Text(
                'Safety readiness',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              Text(
                '$score%',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            color: AppTheme.primaryNavy,
            backgroundColor: AppTheme.border(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Improve readiness by enabling all smart triggers and auto actions.',
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

class _ActionTag extends StatelessWidget {
  final String label;

  const _ActionTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary(context),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String relation;
  final String phone;
  final Color accent;
  final String status;

  const _ContactCard({
    required this.name,
    required this.relation,
    required this.phone,
    required this.accent,
    required this.status,
  });

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withOpacity(0.15),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Text(
                  '$relation • $status',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            phone,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryNavy,
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: AppTheme.textMuted(context),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTheme.primaryNavy : AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppTheme.primaryNavy,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
