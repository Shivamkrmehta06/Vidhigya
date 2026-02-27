import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import 'community_alerts_view.dart';
import 'local_news_view.dart';
import 'location_map_view.dart';
import 'report_issue_view.dart';
import 'reports_view.dart';
import 'trata_mode_view.dart';
import 'pratyukti_copilot_view.dart';

class ForYouView extends StatelessWidget {
  const ForYouView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedEntrance(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                    'For You',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Personalized actions based on nearby civic activity and your recent reports.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.textMuted(context),
                ),
              ),
              const SizedBox(height: 14),
              _RecommendationCard(
                title: 'Ask Pratyukti AI Copilot',
                subtitle: 'Chat + image recognition to prepare a smart complaint draft.',
                imageUrl:
                    'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=900&q=80',
                cta: 'Open Pratyukti',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PratyuktiCopilotView(),
                  ),
                ),
              ),
              _RecommendationCard(
                title: 'Report a new civic issue',
                subtitle: 'Fast capture with AI-assisted categorization.',
                imageUrl:
                    'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
                cta: 'Open Report',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportIssueView()),
                ),
              ),
              _RecommendationCard(
                title: 'Review nearby safety hotspots',
                subtitle: 'Map view with active alerts and risk zones.',
                imageUrl:
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=900&q=80',
                cta: 'Open Safety Map',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SafetyMapView()),
                ),
              ),
              _RecommendationCard(
                title: 'Community is discussing 8 new updates',
                subtitle: 'Check verified neighborhood alerts and requests.',
                imageUrl:
                    'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=900&q=80',
                cta: 'Open Alerts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CommunityAlertsView(),
                  ),
                ),
              ),
              _RecommendationCard(
                title: 'Track your report progress',
                subtitle: 'Follow status updates and latest authority actions.',
                imageUrl:
                    'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=900&q=80',
                cta: 'Open Reports',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsView()),
                ),
              ),
              _RecommendationCard(
                title: 'Run TRATA readiness check',
                subtitle: 'Verify emergency triggers and trusted circle setup.',
                imageUrl:
                    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
                cta: 'Open TRATA',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrataModeView()),
                ),
              ),
              _RecommendationCard(
                title: 'Read local civic updates',
                subtitle: 'See current city works and public notices.',
                imageUrl:
                    'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=900&q=80',
                cta: 'Open News',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocalNewsView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String cta;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 138,
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(cta),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
