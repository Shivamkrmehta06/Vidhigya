import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'location_map_view.dart';
import 'reports_view.dart';
import 'report_issue_view.dart';
import 'community_alerts_view.dart';
import 'trata_mode_view.dart';
import 'local_news_view.dart';
import 'search_view.dart';
import 'profile_view.dart';
import 'for_you_view.dart';
import 'pratyukti_copilot_view.dart';
import 'utilities_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  int _selectedTab = 0;
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _bgOrbController;
  late final Animation<double> _sosPulse;

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _bgOrbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8200),
    )..repeat(reverse: true);
    _sosPulse = Tween<double>(begin: 1, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _bgOrbController.dispose();
    super.dispose();
  }

  void _openReportIssue() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportIssueView()),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedTab = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExploreMapView()),
      ).then((_) {
        if (!mounted) return;
        setState(() => _selectedTab = 0);
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsView()),
      ).then((_) {
        if (!mounted) return;
        setState(() => _selectedTab = 0);
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityAlertsView()),
      ).then((_) {
        if (!mounted) return;
        setState(() => _selectedTab = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textMuted(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [AppTheme.cloud, AppTheme.mist],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _HomeBackgroundOrbs(animation: _bgOrbController),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionReveal(
                    animation: _interval(0, 0.18),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'vidhigya-wordmark',
                          child: Image.asset(
                            'assets/images/vidhigya_wordmark.png',
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(),
                        _IconBubble(
                          icon: Icons.search_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchView(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _IconBubble(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommunityAlertsView(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileView(),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: AppTheme.surface(context),
                            child: const Icon(
                              Icons.person,
                              size: 18,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionReveal(
                    animation: _interval(0.12, 0.28),
                    child: Text(
                      l10n.t('home.greeting'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SectionReveal(
                    animation: _interval(0.18, 0.34),
                    child: Text(
                      l10n.t('home.subtitle'),
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(label: l10n.t('home.utilities')),
                  const SizedBox(height: 10),
                  _SectionReveal(
                    animation: _interval(0.24, 0.42),
                    child: SizedBox(
                      height: 86,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _QuickAction(
                            icon: Icons.pin_outlined,
                            label: l10n.t('home.trackId'),
                            accent: AppTheme.purpleAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrackIssueView(),
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.support_agent_rounded,
                            label: l10n.t('home.helplines'),
                            accent: AppTheme.tealAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelplineDirectoryView(),
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.event_note_outlined,
                            label: l10n.t('home.outages'),
                            accent: AppTheme.primaryNavy,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ServiceNoticesView(),
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.cloud_off_outlined,
                            label: l10n.t('home.drafts'),
                            accent: AppTheme.skyAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OfflineDraftsView(),
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.local_hospital_outlined,
                            label: l10n.t('home.safeSpots'),
                            accent: AppTheme.tealAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SafeSpotsView(),
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.medical_services_outlined,
                            label: l10n.t('home.firstAid'),
                            accent: AppTheme.purpleAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FirstAidGuideView(),
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.auto_awesome_rounded,
                            label: l10n.t('home.pratyukti'),
                            accent: AppTheme.mist,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PratyuktiCopilotView(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionReveal(
                    animation: _interval(0.32, 0.52),
                    child: ScaleTransition(
                      scale: _sosPulse,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrataModeView(),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFB91C1C),
                                        Color(0xFF7F1D1D),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      size: 140,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.38),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 94,
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFFF6A4D),
                                            Color(0xFFD7193A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const Text(
                                        'TRATA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        l10n.t('home.trataEmergencyTap'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
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
                  ),
                  const SizedBox(height: 20),
                  _SectionReveal(
                    animation: _interval(0.42, 0.6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('home.forYou'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForYouView(),
                            ),
                          ),
                          child: Text(
                            l10n.t('common.seeAll'),
                            style: TextStyle(
                              color: textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionReveal(
                    animation: _interval(0.48, 0.68),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _FeatureCard(
                          icon: Icons.report_problem_outlined,
                          title: l10n.t('home.reportIssue'),
                          imageUrl:
                              'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
                          onTap: _openReportIssue,
                        ),
                        _FeatureCard(
                          icon: Icons.map_outlined,
                          title: l10n.t('home.safetyMap'),
                          imageUrl:
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=900&q=80',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SafetyMapView(),
                            ),
                          ),
                        ),
                        _FeatureCard(
                          icon: Icons.assignment_outlined,
                          title: l10n.t('home.myReports'),
                          imageUrl:
                              'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=900&q=80',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportsView(),
                            ),
                          ),
                        ),
                        _FeatureCard(
                          icon: Icons.campaign_outlined,
                          title: l10n.t('home.communityAlerts'),
                          imageUrl:
                              'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=900&q=80',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommunityAlertsView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionReveal(
                    animation: _interval(0.62, 0.78),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('home.localNews'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocalNewsView(),
                            ),
                          ),
                          child: Text(
                            l10n.t('common.seeAll'),
                            style: TextStyle(
                              color: textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionReveal(
                    animation: _interval(0.68, 0.84),
                    child: Column(
                      children: const [
                        _NewsCard(
                          title: 'City announces new pothole response squad',
                          source: 'Bengaluru Civic Desk',
                          time: 'Today • 8:40 AM',
                          imageUrl:
                              'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=900&q=80',
                        ),
                        SizedBox(height: 10),
                        _NewsCard(
                          title:
                              'Water pipeline repairs planned for Indiranagar',
                          source: 'City Water Board',
                          time: 'Today • 7:15 AM',
                          imageUrl:
                              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
                        ),
                        SizedBox(height: 10),
                        _NewsCard(
                          title: 'Streetlight upgrades approved for 12 wards',
                          source: 'Urban Infra Update',
                          time: 'Yesterday • 6:05 PM',
                          imageUrl:
                              'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.home_filled,
              label: l10n.t('bottom.home'),
              selected: _selectedTab == 0,
              onTap: () => _onBottomNavTap(0),
            ),
            _BottomItem(
              icon: Icons.map_outlined,
              label: l10n.t('bottom.explore'),
              selected: _selectedTab == 1,
              onTap: () => _onBottomNavTap(1),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrataModeView()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFF6A4D), Color(0xFFD7193A)],
                  ),
                ),
                child: const Text(
                  'TRATA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _BottomItem(
              icon: Icons.description_outlined,
              label: l10n.t('bottom.reports'),
              selected: _selectedTab == 2,
              onTap: () => _onBottomNavTap(2),
            ),
            _BottomItem(
              icon: Icons.notifications_none,
              label: l10n.t('bottom.alerts'),
              selected: _selectedTab == 3,
              onTap: () => _onBottomNavTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryNavy),
      ),
    );
  }
}

class _SectionReveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _SectionReveal({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.16),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _HomeBackgroundOrbs extends StatelessWidget {
  final Animation<double> animation;

  const _HomeBackgroundOrbs({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _FloatingOrb(
            animation: animation,
            start: const Alignment(-1.2, -0.88),
            end: const Alignment(-0.84, -0.62),
            size: 220,
            colors: const [Color(0x334CB7D8), Color(0x2222D3EE)],
          ),
        ),
        Positioned.fill(
          child: _FloatingOrb(
            animation: animation,
            start: const Alignment(1.18, -0.16),
            end: const Alignment(0.94, 0.08),
            size: 280,
            colors: const [Color(0x33F2B95B), Color(0x224CB7D8)],
            phaseShift: 0.18,
          ),
        ),
        Positioned.fill(
          child: _FloatingOrb(
            animation: animation,
            start: const Alignment(-0.2, 1.3),
            end: const Alignment(0.18, 1.02),
            size: 250,
            colors: const [Color(0x2614B8A6), Color(0x334CB7D8)],
            phaseShift: 0.34,
          ),
        ),
      ],
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final Animation<double> animation;
  final Alignment start;
  final Alignment end;
  final double size;
  final List<Color> colors;
  final double phaseShift;

  const _FloatingOrb({
    required this.animation,
    required this.start,
    required this.end,
    required this.size,
    required this.colors,
    this.phaseShift = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final raw = (animation.value + phaseShift) % 1;
        final t = Curves.easeInOut.transform(raw);
        return Align(
          alignment: Alignment.lerp(start, end, t)!,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _PressableScale(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withOpacity(0.95), AppTheme.primaryNavy],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Stack(
          children: [
            Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover)),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.34)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String source;
  final String time;
  final String imageUrl;

  const _NewsCard({
    required this.title,
    required this.source,
    required this.time,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textMuted(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: SizedBox(
              width: 100,
              height: 88,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    source,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        color: AppTheme.textMuted(context),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryNavy : AppTheme.textMuted(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryNavy.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.06 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
