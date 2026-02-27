import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LocalNewsView extends StatefulWidget {
  const LocalNewsView({super.key});

  @override
  State<LocalNewsView> createState() => _LocalNewsViewState();
}

class _LocalNewsViewState extends State<LocalNewsView> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  static const List<_NewsStory> _stories = [
    _NewsStory(
      title: 'City announces new pothole response squad',
      source: 'Bengaluru Civic Desk',
      time: 'Today • 8:40 AM',
      imageUrl:
          'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=1200&q=80',
      body: [
        'The city corporation has launched a rapid response squad dedicated to pothole repairs across high-traffic corridors. The squad is expected to begin work within 24 hours of a verified report, focusing first on arterial routes and school zones.',
        'Officials say the initiative will use a priority scoring system based on safety impact, traffic volume, and citizen complaints submitted through civic apps. Residents are encouraged to include clear photos and precise locations to speed up verification.',
        'The first deployment will cover 12 wards this week, with additional teams expected to roll out across the city by next month.',
      ],
    ),
    _NewsStory(
      title: 'Water pipeline repairs planned for Indiranagar',
      source: 'City Water Board',
      time: 'Today • 7:15 AM',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
      body: [
        'The Water Board has scheduled pipeline maintenance in Indiranagar to address recurring leaks. Repairs are expected to begin at 10 PM and may temporarily impact pressure in surrounding lanes.',
        'Residents are advised to store water in advance. Emergency response teams will be stationed near 12th Main to assist with urgent supply needs.',
        'The board said a detailed maintenance plan will be published later today with lane-specific timings.',
      ],
    ),
    _NewsStory(
      title: 'Streetlight upgrades approved for 12 wards',
      source: 'Urban Infra Update',
      time: 'Yesterday • 6:05 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80',
      body: [
        'A proposal to replace aging streetlights with LED smart fixtures has been approved for 12 wards. The new system will include remote monitoring and faster fault detection.',
        'Installation work is scheduled to begin in phases, starting with areas that have reported frequent outages. Officials say the rollout will reduce power usage and improve nighttime safety.',
        'Residents can continue to report outages in the app; verified issues will be prioritized for immediate replacement.',
      ],
    ),
    _NewsStory(
      title: 'New waste segregation drive launched in 8 zones',
      source: 'City Sanitation Board',
      time: 'Yesterday • 4:20 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=1200&q=80',
      body: [
        'The sanitation department has started a ward-level segregation campaign covering eight high-density zones. Collection teams will now use color-coded bins and daily tracking logs.',
        'Residents will receive door-to-door guidance on dry and wet waste categories this week. Apartment associations are being asked to appoint floor coordinators for compliance.',
        'Officials said consistent participation in the first 30 days will decide whether penalties are deferred or enforced.',
      ],
    ),
    _NewsStory(
      title: 'Traffic police announce school-hour diversion plan',
      source: 'City Traffic Cell',
      time: 'Yesterday • 1:05 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80',
      body: [
        'A new diversion plan has been rolled out near major school clusters to reduce congestion and improve crossing safety between 7:30 AM and 9:30 AM.',
        'Temporary barricades and volunteer marshals will be deployed at critical intersections. Parents are advised to use designated drop points instead of stopping on arterial lanes.',
        'The traffic cell will review commute data over two weeks before finalizing permanent changes.',
      ],
    ),
    _NewsStory(
      title: 'Rain preparedness teams activated ahead of forecast',
      source: 'Disaster Management Desk',
      time: '2 days ago • 9:15 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
      body: [
        'The city has activated pre-monsoon response teams to clear storm drains, inspect pumping stations, and identify flood-prone intersections.',
        'Residents in low-lying areas are requested to report blocked drains through civic apps with photos and exact landmarks for faster dispatch.',
        'Control rooms will operate round the clock during heavy rainfall windows for quicker coordination.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textMuted(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.primaryNavy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Local News',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text(
                    'Story ${_currentIndex + 1} of ${_stories.length}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  _StoryDots(
                    count: _stories.length,
                    index: _currentIndex,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                physics: const PageScrollPhysics(),
                itemCount: _stories.length,
                controller: _controller,
                onPageChanged: (value) {
                  setState(() => _currentIndex = value);
                },
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  return _NewsStoryPage(story: story);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsStoryPage extends StatelessWidget {
  final _NewsStory story;

  const _NewsStoryPage({required this.story});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textMuted(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Image.network(
              story.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            story.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                story.source,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                story.time,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: story.body.length,
              itemBuilder: (context, index) {
                final paragraph = story.body[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    paragraph,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.5,
                      color: textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Text(
              'Swipe up or down for stories',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsStory {
  final String title;
  final String source;
  final String time;
  final String imageUrl;
  final List<String> body;

  const _NewsStory({
    required this.title,
    required this.source,
    required this.time,
    required this.imageUrl,
    required this.body,
  });
}

class _StoryDots extends StatelessWidget {
  final int count;
  final int index;

  const _StoryDots({
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                active ? AppTheme.primaryNavy : AppTheme.border(context),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
