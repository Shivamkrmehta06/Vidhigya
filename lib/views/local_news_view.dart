import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import '../theme/app_theme.dart';

class LocalNewsView extends StatefulWidget {
  const LocalNewsView({super.key});

  @override
  State<LocalNewsView> createState() => _LocalNewsViewState();
}

class _LocalNewsViewState extends State<LocalNewsView> {
  final PageController _controller = PageController();
  List<_NewsStory> _stories = const <_NewsStory>[];
  bool _isLoading = false;
  bool _usingFallback = false;
  String? _statusMessage;
  int _currentIndex = 0;

  static final Uri _feedUri = Uri.parse(
    'https://news.google.com/rss/search?q=${Uri.encodeQueryComponent('(Bengaluru OR Karnataka) civic issues municipal updates')}&hl=en-IN&gl=IN&ceid=IN:en',
  );

  static const Map<String, List<String>>
  _topicImagePools = <String, List<String>>{
    'road': <String>[
      'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1520975922284-8b456906c813?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=1200&q=80',
    ],
    'water': <String>[
      'https://images.unsplash.com/photo-1521207418485-99c705420785?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
    ],
    'waste': <String>[
      'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1621451537084-482c73073a0f?auto=format&fit=crop&w=1200&q=80',
    ],
    'electric': <String>[
      'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1479973905280-9f9a9a3a1f0a?auto=format&fit=crop&w=1200&q=80',
    ],
    'traffic': <String>[
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1465447142348-e9952c393450?auto=format&fit=crop&w=1200&q=80',
    ],
    'weather': <String>[
      'https://images.unsplash.com/photo-1432836431433-925d3cc0a5cd?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1499346030926-9a72daac6c63?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80',
    ],
    'general': <String>[
      'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80',
    ],
  };

  static const List<_NewsStory> _fallbackStories = [
    _NewsStory(
      title: 'City announces new pothole response squad',
      source: 'Bengaluru Civic Desk',
      time: 'Today • 8:40 AM',
      imageUrl:
          'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=1200&q=80',
      fallbackImageUrl:
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
      fallbackImageUrl:
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
      fallbackImageUrl:
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
      fallbackImageUrl:
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
      fallbackImageUrl:
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
      fallbackImageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
      body: [
        'The city has activated pre-monsoon response teams to clear storm drains, inspect pumping stations, and identify flood-prone intersections.',
        'Residents in low-lying areas are requested to report blocked drains through civic apps with photos and exact landmarks for faster dispatch.',
        'Control rooms will operate round the clock during heavy rainfall windows for quicker coordination.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveStories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLiveStories() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final http.Response response = await http
          .get(_feedUri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('Feed request failed with ${response.statusCode}');
      }
      final XmlDocument document = XmlDocument.parse(
        utf8.decode(response.bodyBytes),
      );
      final List<XmlElement> items = document
          .findAllElements('item')
          .take(10)
          .toList();
      final List<_NewsStory> parsed = <_NewsStory>[];
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
        final List<String> paragraphs = _buildParagraphs(description);

        parsed.add(
          _NewsStory(
            title: _deriveTitle(rawTitle),
            source: source,
            time: _formatRelativeTime(_readElement(item, 'pubDate')),
            imageUrl: primaryImageUrl,
            fallbackImageUrl: fallbackImageUrl,
            linkUrl: storyLink,
            body: paragraphs,
            isPublisherImage:
                publisherImageUrl != null &&
                primaryImageUrl == publisherImageUrl,
          ),
        );
      }

      if (!mounted) return;
      if (parsed.isEmpty) {
        setState(() {
          _stories = _fallbackStories;
          _usingFallback = true;
          _isLoading = false;
          _statusMessage = 'Live feed unavailable. Showing fallback stories.';
          _currentIndex = 0;
        });
        return;
      }

      setState(() {
        _stories = parsed;
        _usingFallback = false;
        _isLoading = false;
        _statusMessage = 'Live feed loaded';
        _currentIndex = 0;
      });
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stories = _fallbackStories;
        _usingFallback = true;
        _isLoading = false;
        _statusMessage = 'Live feed unavailable. Showing fallback stories.';
        _currentIndex = 0;
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
    if (html.isEmpty) {
      return '';
    }
    String text = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length > 360) {
      text = '${text.substring(0, 357)}...';
    }
    return text;
  }

  List<String> _buildParagraphs(String html) {
    final String text = _sanitizeHtml(html);
    if (text.isEmpty) {
      return const <String>['Open the source article for full details.'];
    }
    final List<String> sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((String part) => part.trim())
        .where((String part) => part.length > 30)
        .toList();
    if (sentences.isEmpty) {
      return <String>[_limitLength(text, 220)];
    }

    final List<String> paragraphs = <String>[];
    final StringBuffer current = StringBuffer();
    for (final String sentence in sentences) {
      final String candidate = current.isEmpty
          ? sentence
          : '${current.toString()} $sentence';
      if (candidate.length > 220 && current.isNotEmpty) {
        paragraphs.add(current.toString());
        current
          ..clear()
          ..write(sentence);
      } else {
        current
          ..write(current.isEmpty ? '' : ' ')
          ..write(sentence);
      }
      if (paragraphs.length == 2) {
        break;
      }
    }
    if (current.isNotEmpty && paragraphs.length < 3) {
      paragraphs.add(_limitLength(current.toString(), 220));
    }
    if (paragraphs.isEmpty) {
      paragraphs.add(_limitLength(text, 220));
    }
    return paragraphs.take(3).toList();
  }

  String _limitLength(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
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
      final String? url = match?.group(1);
      final String? normalized = _normalizeUrl(url);
      if (normalized != null && _looksLikeImage(normalized)) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalizeUrl(String? url) {
    if (url == null) {
      return null;
    }
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
    // Many publisher CDN URLs don't end with an extension.
    if (lower.contains('image') ||
        lower.contains('img') ||
        lower.contains('photo') ||
        lower.contains('thumb') ||
        lower.contains('cdn') ||
        lower.contains('media')) {
      return true;
    }
    // Reject obvious non-image links.
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
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textMuted(context);
    final bool hasStories = _stories.isNotEmpty;
    final int displayIndex = hasStories ? _currentIndex + 1 : 0;
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
                  IconButton(
                    onPressed: _isLoading ? null : _loadLiveStories,
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppTheme.primaryNavy,
                    tooltip: 'Refresh',
                  ),
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
                    hasStories
                        ? 'Story $displayIndex of ${_stories.length}'
                        : 'No stories available',
                    style: GoogleFonts.manrope(fontSize: 12, color: textMuted),
                  ),
                  const Spacer(),
                  _StoryDots(count: _stories.length, index: _currentIndex),
                ],
              ),
            ),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      _usingFallback
                          ? Icons.info_outline
                          : Icons.public_rounded,
                      size: 14,
                      color: textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: hasStories
                  ? PageView.builder(
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
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading) const CircularProgressIndicator(),
                          if (_isLoading) const SizedBox(height: 12),
                          Text(
                            _isLoading
                                ? 'Loading live local stories...'
                                : 'Could not load news. Pull to refresh.',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
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
    final bool showPublisherLogo = story.isPublisherImage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: story.imageUrl == null && story.fallbackImageUrl == null
                ? Container(
                    height: 220,
                    width: double.infinity,
                    color: AppTheme.surface(context),
                    alignment: Alignment.center,
                    child: const Icon(Icons.newspaper_rounded, size: 36),
                  )
                : Image.network(
                    story.imageUrl ?? story.fallbackImageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: showPublisherLogo ? BoxFit.contain : BoxFit.cover,
                    alignment: Alignment.center,
                    headers: const <String, String>{
                      'User-Agent':
                          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                          '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
                    },
                    errorBuilder: (context, error, stackTrace) {
                      if (story.imageUrl != null &&
                          story.fallbackImageUrl != null) {
                        return Image.network(
                          story.fallbackImageUrl!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, fallbackError, fallbackStackTrace) {
                                return Container(
                                  height: 220,
                                  width: double.infinity,
                                  color: AppTheme.surface(context),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.newspaper_rounded,
                                    size: 36,
                                  ),
                                );
                              },
                        );
                      }
                      return Container(
                        height: 220,
                        width: double.infinity,
                        color: AppTheme.surface(context),
                        alignment: Alignment.center,
                        child: const Icon(Icons.newspaper_rounded, size: 36),
                      );
                    },
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
                style: GoogleFonts.manrope(fontSize: 12, color: textMuted),
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
          if (story.linkUrl != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final String raw = story.linkUrl!.trim();
                  final Uri? url = Uri.tryParse(raw);
                  if (url == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid article link')),
                    );
                    return;
                  }
                  try {
                    final bool opened = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open article')),
                      );
                    }
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open article')),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Read full article'),
              ),
            ),
          ],
          Center(
            child: Text(
              'Swipe up or down for stories',
              style: GoogleFonts.manrope(fontSize: 12, color: textMuted),
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
  final String? imageUrl;
  final String? fallbackImageUrl;
  final String? linkUrl;
  final List<String> body;
  final bool isPublisherImage;

  const _NewsStory({
    required this.title,
    required this.source,
    required this.time,
    required this.imageUrl,
    this.fallbackImageUrl,
    this.linkUrl,
    required this.body,
    this.isPublisherImage = false,
  });
}

class _StoryDots extends StatelessWidget {
  final int count;
  final int index;

  const _StoryDots({required this.count, required this.index});

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
            color: active ? AppTheme.primaryNavy : AppTheme.border(context),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
