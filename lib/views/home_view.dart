import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
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
  List<_HomeNewsItem> _localNewsItems = _fallbackLocalNewsItems;
  bool _isNewsLoading = false;

  static final Uri _newsFeedUri = Uri.parse(
    'https://news.google.com/rss/search?q=${Uri.encodeQueryComponent('(Bengaluru OR Karnataka) civic issues municipal updates')}&hl=en-IN&gl=IN&ceid=IN:en',
  );

  static const Map<String, List<String>>
  _topicImagePools = <String, List<String>>{
    'road': <String>[
      'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1520975922284-8b456906c813?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=900&q=80',
    ],
    'water': <String>[
      'https://images.unsplash.com/photo-1521207418485-99c705420785?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
    ],
    'waste': <String>[
      'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1621451537084-482c73073a0f?auto=format&fit=crop&w=900&q=80',
    ],
    'electric': <String>[
      'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1479973905280-9f9a9a3a1f0a?auto=format&fit=crop&w=900&q=80',
    ],
    'traffic': <String>[
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1465447142348-e9952c393450?auto=format&fit=crop&w=900&q=80',
    ],
    'weather': <String>[
      'https://images.unsplash.com/photo-1432836431433-925d3cc0a5cd?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1499346030926-9a72daac6c63?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=900&q=80',
    ],
    'general': <String>[
      'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
    ],
  };

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
    _loadLocalNewsPreview();
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

  String _fallbackName() {
    if (Firebase.apps.isNotEmpty) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String fromEmail = (user.email ?? '').split('@').first;
        if (fromEmail.isNotEmpty) {
          return fromEmail;
        }
        final String phone = user.phoneNumber ?? '';
        if (phone.isNotEmpty) {
          final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length >= 4) {
            return 'User ${digits.substring(digits.length - 4)}';
          }
        }
      }
    }
    return 'Citizen';
  }

  Future<void> _loadLocalNewsPreview() async {
    setState(() => _isNewsLoading = true);
    try {
      final http.Response response = await http
          .get(_newsFeedUri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('Feed request failed with ${response.statusCode}');
      }
      final XmlDocument document = XmlDocument.parse(
        utf8.decode(response.bodyBytes),
      );
      final List<XmlElement> items = document
          .findAllElements('item')
          .take(3)
          .toList();
      final List<_HomeNewsItem> parsed = <_HomeNewsItem>[];
      final Set<String> usedFallbackImages = <String>{};
      for (final XmlElement item in items) {
        final String rawTitle = _readElement(item, 'title');
        if (rawTitle.isEmpty) {
          continue;
        }
        final String sourceText = _readElement(item, 'source');
        final String sourceUrl = _readElementAttribute(item, 'source', 'url');
        final String description = _readElementHtml(item, 'description');
        final String? storyLink = _normalizeUrl(_readElement(item, 'link'));
        final String source = _deriveSource(rawTitle, sourceText);
        final String? publisherImageUrl = _extractPublisherLogoUrl(
          sourceUrl: sourceUrl,
          articleUrl: storyLink,
          htmlDescription: description,
        );
        final String? articleImageUrl = _extractPublisherImage(
          item,
          description,
        );
        final String? primaryImageUrl = publisherImageUrl ?? articleImageUrl;
        final String? fallbackImageUrl = publisherImageUrl != null
            ? articleImageUrl
            : _pickRelevantFallbackImage(
                rawTitle,
                description,
                usedFallbackImages,
              );
        parsed.add(
          _HomeNewsItem(
            title: _deriveTitle(rawTitle),
            source: source,
            time: _formatRelativeTime(_readElement(item, 'pubDate')),
            imageUrl: primaryImageUrl,
            fallbackImageUrl: fallbackImageUrl,
            summary: _buildPreviewSummary(description),
            isPublisherImage:
                publisherImageUrl != null &&
                primaryImageUrl == publisherImageUrl,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _localNewsItems = parsed.isEmpty ? _fallbackLocalNewsItems : parsed;
        _isNewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localNewsItems = _fallbackLocalNewsItems;
        _isNewsLoading = false;
      });
    }
  }

  String _readElement(XmlElement parent, String name) {
    final Iterable<XmlElement> elements = parent.findElements(name);
    if (elements.isEmpty) {
      return '';
    }
    return elements.first.innerText.trim();
  }

  String _readElementHtml(XmlElement parent, String name) {
    final Iterable<XmlElement> elements = parent.findElements(name);
    if (elements.isEmpty) {
      return '';
    }
    return elements.first.innerXml.trim();
  }

  String _readElementAttribute(
    XmlElement parent,
    String elementName,
    String attributeName,
  ) {
    final Iterable<XmlElement> elements = parent.findElements(elementName);
    if (elements.isEmpty) {
      return '';
    }
    return (elements.first.getAttribute(attributeName) ?? '').trim();
  }

  String _deriveTitle(String rawTitle) {
    final int splitIndex = rawTitle.lastIndexOf(' - ');
    if (splitIndex <= 0) {
      return rawTitle.trim();
    }
    return rawTitle.substring(0, splitIndex).trim();
  }

  String _deriveSource(String rawTitle, String sourceFromFeed) {
    if (sourceFromFeed.isNotEmpty) {
      return sourceFromFeed;
    }
    final int splitIndex = rawTitle.lastIndexOf(' - ');
    if (splitIndex <= 0 || splitIndex + 3 >= rawTitle.length) {
      return 'Local News Feed';
    }
    return rawTitle.substring(splitIndex + 3).trim();
  }

  String _sanitizeHtml(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildPreviewSummary(String html) {
    final String cleaned = _sanitizeHtml(html);
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= 120) return cleaned;
    return '${cleaned.substring(0, 117)}...';
  }

  String _pickRelevantFallbackImage(
    String title,
    String description,
    Set<String> used,
  ) {
    final String topic = _deriveTopic('$title $description');
    final List<String> topicPool = _topicImagePools[topic] ?? const <String>[];
    final List<String> generalPool =
        _topicImagePools['general'] ?? const <String>[];
    final List<String> ordered = <String>[...topicPool, ...generalPool];
    for (final String candidate in ordered) {
      if (!used.contains(candidate)) {
        used.add(candidate);
        return candidate;
      }
    }
    final int index = used.length % generalPool.length;
    final String fallback = generalPool[index];
    used.add(fallback);
    return fallback;
  }

  String _deriveTopic(String text) {
    final String lower = text.toLowerCase();
    if (lower.contains('pothole') ||
        lower.contains('road') ||
        lower.contains('bridge') ||
        lower.contains('flyover')) {
      return 'road';
    }
    if (lower.contains('water') ||
        lower.contains('pipeline') ||
        lower.contains('drain') ||
        lower.contains('sewage') ||
        lower.contains('flood')) {
      return 'water';
    }
    if (lower.contains('garbage') ||
        lower.contains('waste') ||
        lower.contains('sanitation') ||
        lower.contains('clean')) {
      return 'waste';
    }
    if (lower.contains('streetlight') ||
        lower.contains('power') ||
        lower.contains('electric') ||
        lower.contains('outage')) {
      return 'electric';
    }
    if (lower.contains('traffic') ||
        lower.contains('diversion') ||
        lower.contains('commute') ||
        lower.contains('vehicle')) {
      return 'traffic';
    }
    if (lower.contains('rain') ||
        lower.contains('storm') ||
        lower.contains('weather') ||
        lower.contains('monsoon')) {
      return 'weather';
    }
    return 'general';
  }

  String? _extractPublisherImage(XmlElement item, String htmlDescription) {
    for (final XmlElement element in item.descendants.whereType<XmlElement>()) {
      final String localName = element.name.local.toLowerCase();
      final String? url =
          element.getAttribute('url') ??
          element.getAttribute('href') ??
          element.getAttribute('src');
      final String? normalized = _normalizeUrl(url);
      if (normalized == null || !_looksLikeImage(normalized)) {
        continue;
      }
      if (localName == 'content' ||
          localName == 'thumbnail' ||
          localName == 'enclosure') {
        return normalized;
      }
    }
    return _extractImageUrl(htmlDescription);
  }

  String? _extractPublisherLogoUrl({
    required String sourceUrl,
    required String? articleUrl,
    required String htmlDescription,
  }) {
    final String? fromSource = _faviconFromUrl(sourceUrl);
    if (fromSource != null) {
      return fromSource;
    }
    final String? fromDescription = _faviconFromDescriptionLink(
      htmlDescription,
    );
    if (fromDescription != null) {
      return fromDescription;
    }
    return _faviconFromUrl(articleUrl);
  }

  String? _faviconFromDescriptionLink(String html) {
    if (html.isEmpty) {
      return null;
    }
    final RegExp hrefPattern = RegExp(
      r'''href\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    );
    for (final RegExpMatch match in hrefPattern.allMatches(html)) {
      final String? candidate = match.group(1);
      final String? favicon = _faviconFromUrl(candidate);
      if (favicon != null) {
        return favicon;
      }
    }
    return null;
  }

  String? _faviconFromUrl(String? rawUrl) {
    final String? normalized = _normalizeUrl(rawUrl);
    if (normalized == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty || _looksLikeNewsAggregator(uri.host)) {
      return null;
    }
    return Uri.https('www.google.com', '/s2/favicons', <String, String>{
      'sz': '256',
      'domain_url': '${uri.scheme}://${uri.host}',
    }).toString();
  }

  bool _looksLikeNewsAggregator(String host) {
    final String lower = host.toLowerCase();
    return lower == 'news.google.com' ||
        lower.endsWith('.news.google.com') ||
        lower.contains('google.com');
  }

  String? _extractImageUrl(String html) {
    final List<RegExp> patterns = <RegExp>[
      RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false),
      RegExp(r"<img[^>]+src='([^']+)'", caseSensitive: false),
      RegExp(r'<img[^>]+data-src="([^"]+)"', caseSensitive: false),
      RegExp(r"<img[^>]+data-src='([^']+)'", caseSensitive: false),
      RegExp(r'<img[^>]+data-original="([^"]+)"', caseSensitive: false),
      RegExp(r"<img[^>]+data-original='([^']+)'", caseSensitive: false),
    ];
    for (final RegExp pattern in patterns) {
      final RegExpMatch? match = pattern.firstMatch(html);
      final String? normalized = _normalizeUrl(match?.group(1));
      if (normalized != null && _looksLikeImage(normalized)) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalizeUrl(String? url) {
    if (url == null) return null;
    String normalized = url
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .trim();
    if (normalized.startsWith('//')) {
      normalized = 'https:$normalized';
    }
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      return null;
    }
    return normalized;
  }

  bool _looksLikeImage(String url) {
    final String lower = url.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    if (lower.contains('.svg')) {
      return false;
    }
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.avif') ||
        lower.contains('.gif')) {
      return true;
    }
    if (lower.contains('image') ||
        lower.contains('img') ||
        lower.contains('photo') ||
        lower.contains('thumb') ||
        lower.contains('cdn') ||
        lower.contains('media')) {
      return true;
    }
    if (lower.contains('/article/') ||
        lower.contains('/story/') ||
        lower.contains('/news/')) {
      return false;
    }
    return true;
  }

  DateTime? _parseRfc822(String value) {
    final RegExpMatch? match = RegExp(
      r'^\w{3},\s(\d{1,2})\s(\w{3})\s(\d{4})\s(\d{2}):(\d{2}):(\d{2})\sGMT$',
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    const Map<String, int> months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final int? month = months[match.group(2)];
    if (month == null) {
      return null;
    }
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }

  String _formatRelativeTime(String pubDate) {
    final DateTime? parsed = _parseRfc822(pubDate);
    if (parsed == null) {
      return 'Live';
    }
    final Duration diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  Widget _buildGreeting(BuildContext context, Color textPrimary) {
    if (Firebase.apps.isEmpty) {
      return Text(
        'Hello, ${_fallbackName()}',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      );
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Text(
        'Welcome back',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ?? <String, dynamic>{};
        final String name = (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : _fallbackName();
        return Text(
          'Hello, $name',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        );
      },
    );
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
                    child: _buildGreeting(context, textPrimary),
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
                      children: [
                        if (_isNewsLoading && _localNewsItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        for (int i = 0; i < _localNewsItems.length; i++) ...[
                          _NewsCard(
                            title: _localNewsItems[i].title,
                            source: _localNewsItems[i].source,
                            time: _localNewsItems[i].time,
                            imageUrl: _localNewsItems[i].imageUrl,
                            fallbackImageUrl:
                                _localNewsItems[i].fallbackImageUrl,
                            summary: _localNewsItems[i].summary,
                            isPublisherImage:
                                _localNewsItems[i].isPublisherImage,
                          ),
                          if (i != _localNewsItems.length - 1)
                            const SizedBox(height: 10),
                        ],
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

const List<_HomeNewsItem> _fallbackLocalNewsItems = <_HomeNewsItem>[
  _HomeNewsItem(
    title: 'City announces new pothole response squad',
    source: 'Bengaluru Civic Desk',
    time: 'Today • 8:40 AM',
    imageUrl:
        'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=900&q=80',
    fallbackImageUrl:
        'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=900&q=80',
    summary:
        'Rapid pothole response teams have been announced for high-traffic corridors and school zones.',
  ),
  _HomeNewsItem(
    title: 'Water pipeline repairs planned for Indiranagar',
    source: 'City Water Board',
    time: 'Today • 7:15 AM',
    imageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
    fallbackImageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
    summary:
        'Night maintenance near 12th Main may affect pressure in nearby lanes; residents advised to store water.',
  ),
  _HomeNewsItem(
    title: 'Streetlight upgrades approved for 12 wards',
    source: 'Urban Infra Update',
    time: 'Yesterday • 6:05 PM',
    imageUrl:
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
    fallbackImageUrl:
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
    summary:
        'Smart LED replacement with remote fault monitoring has been approved for phased rollout.',
  ),
];

class _HomeNewsItem {
  final String title;
  final String source;
  final String time;
  final String? imageUrl;
  final String? fallbackImageUrl;
  final String summary;
  final bool isPublisherImage;

  const _HomeNewsItem({
    required this.title,
    required this.source,
    required this.time,
    required this.imageUrl,
    this.fallbackImageUrl,
    required this.summary,
    this.isPublisherImage = false,
  });
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String source;
  final String time;
  final String? imageUrl;
  final String? fallbackImageUrl;
  final String? summary;
  final bool isPublisherImage;

  const _NewsCard({
    required this.title,
    required this.source,
    required this.time,
    this.imageUrl,
    this.fallbackImageUrl,
    this.summary,
    this.isPublisherImage = false,
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
              child: imageUrl == null && fallbackImageUrl == null
                  ? Container(
                      color: AppTheme.cloud,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.newspaper_rounded,
                        color: textMuted,
                        size: 22,
                      ),
                    )
                  : Image.network(
                      imageUrl ?? fallbackImageUrl!,
                      fit: isPublisherImage ? BoxFit.contain : BoxFit.cover,
                      alignment: Alignment.center,
                      headers: const <String, String>{
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                            '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
                      },
                      errorBuilder: (context, error, stackTrace) {
                        if (imageUrl != null && fallbackImageUrl != null) {
                          return Image.network(
                            fallbackImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, fallbackError, fallbackStackTrace) {
                                  return Container(
                                    color: AppTheme.cloud,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.newspaper_rounded,
                                      color: textMuted,
                                      size: 22,
                                    ),
                                  );
                                },
                          );
                        }
                        return Container(
                          color: AppTheme.cloud,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.newspaper_rounded,
                            color: textMuted,
                            size: 22,
                          ),
                        );
                      },
                    ),
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
                  if (summary != null && summary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
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
