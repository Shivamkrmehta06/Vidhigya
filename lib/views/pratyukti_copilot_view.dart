import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';

class PratyuktiResult {
  final String title;
  final String description;
  final String category;
  final double severity;

  const PratyuktiResult({
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
  });
}

class PratyuktiCopilotView extends StatefulWidget {
  const PratyuktiCopilotView({super.key});

  @override
  State<PratyuktiCopilotView> createState() => _PratyuktiCopilotViewState();
}

class _PratyuktiCopilotViewState extends State<PratyuktiCopilotView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.ai,
      text:
          'Hi, I am Pratyukti. I can help identify civic issues and suggest what to file.',
    ),
  ];

  _AiImageAnalysis? _analysis;
  bool _scanning = false;
  bool _thinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendPrompt([String? preset]) async {
    final input = (preset ?? _controller.text).trim();
    if (input.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: input));
      _thinking = true;
      if (preset == null) {
        _controller.clear();
      }
    });
    _scrollToBottom();
    final String reply = await _replyForInput(input);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.add(_ChatMessage(role: _ChatRole.ai, text: reply));
    });
    _scrollToBottom();
  }

  Future<String> _replyForInput(String input) async {
    final String lower = input.toLowerCase();

    final String? trackingReply = await _maybeTrackingReply(input);
    if (trackingReply != null) {
      return trackingReply;
    }

    final _AiImageAnalysis? analysis = _analysis;
    if (analysis != null &&
        (lower.contains('urgent') ||
            lower.contains('severity') ||
            lower.contains('priority'))) {
      final int severity = (analysis.severity * 100).round();
      final String urgency = severity >= 70 ? 'high' : 'moderate';
      return 'Based on scanned evidence, urgency is $urgency ($severity%). I recommend submitting immediately and enabling escalation if unresolved within 72 hours.';
    }

    if (analysis != null &&
        (lower.contains('who handles') ||
            lower.contains('department') ||
            lower.contains('authority'))) {
      return 'For the current scanned issue, recommended department is ${analysis.department}. Category is ${analysis.category}.';
    }

    if (lower.contains('what can i report') ||
        lower.contains('what to report')) {
      return 'You can report road damage, drainage/water leaks, garbage overflow, streetlight failures, and public safety hazards. Add a photo, run analysis, then auto-submit.';
    }

    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return 'Hi. I can help classify issues, suggest department/severity, and track report status by ID (for example: "Track R-1042").';
    }

    final String? modelReply = await _askGemini(input);
    if (modelReply != null && modelReply.isNotEmpty) {
      return modelReply;
    }

    if (analysis == null) {
      return 'I can answer better after image scan. Use "Scan Photo" and ask things like "Is this urgent?" or "Who handles this issue?".';
    }
    return 'From current analysis: ${analysis.issueTitle}. Category ${analysis.category}, severity ${(analysis.severity * 100).round()}%, recommended department ${analysis.department}.';
  }

  Future<String?> _maybeTrackingReply(String input) async {
    final String lower = input.toLowerCase();
    final bool asksTrack =
        lower.contains('track') ||
        lower.contains('status') ||
        lower.contains('progress') ||
        lower.contains('report');
    final RegExp codePattern = RegExp(r'\bR-\d+\b', caseSensitive: false);
    final Match? codeMatch = codePattern.firstMatch(input);
    if (!asksTrack && codeMatch == null) {
      return null;
    }

    if (Firebase.apps.isEmpty) {
      return 'Tracking requires Firebase configuration in this build.';
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'Login first to track your reports.';
    }

    try {
      final CollectionReference<Map<String, dynamic>> reports =
          FirebaseFirestore.instance.collection('reports');
      const int localScanLimit = 40;
      final QuerySnapshot<Map<String, dynamic>> snapshot = await reports
          .where('createdBy', isEqualTo: user.uid)
          .limit(localScanLimit)
          .get();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
          snapshot.docs;

      QueryDocumentSnapshot<Map<String, dynamic>>? target;
      if (codeMatch != null) {
        final String code = codeMatch.group(0)!.toUpperCase();
        for (final doc in docs) {
          if ((doc.data()['reportCode'] ?? '').toString().toUpperCase() ==
              code) {
            target = doc;
            break;
          }
        }
      } else if (docs.isNotEmpty) {
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> sorted =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs)
              ..sort((a, b) {
                final Timestamp? atA = a.data()['createdAt'] as Timestamp?;
                final Timestamp? atB = b.data()['createdAt'] as Timestamp?;
                final int millisA = atA?.millisecondsSinceEpoch ?? 0;
                final int millisB = atB?.millisecondsSinceEpoch ?? 0;
                return millisB.compareTo(millisA);
              });
        target = sorted.first;
      }

      if (target == null) {
        if (codeMatch != null) {
          return 'I could not find ${codeMatch.group(0)!.toUpperCase()} in your reports. Please verify the report ID.';
        }
        return 'No reports found for your account yet.';
      }

      final Map<String, dynamic> data = target.data();
      final String code = (data['reportCode'] ?? 'Unknown').toString();
      final String title = (data['title'] ?? 'Issue').toString();
      final String status = (data['status'] ?? 'Open').toString();
      final String priority = (data['priority'] ?? 'Medium').toString();
      final String lastUpdate = (data['lastUpdate'] ?? 'No update yet')
          .toString();
      final num progressRaw = (data['progress'] as num?) ?? 0;
      final int progress = (progressRaw * 100).round().clamp(0, 100);
      final Timestamp? deadlineTs = data['deadlineAt'] as Timestamp?;
      final String deadline = deadlineTs == null
          ? 'Not set'
          : '${deadlineTs.toDate().day}/${deadlineTs.toDate().month}/${deadlineTs.toDate().year}';

      return 'Tracking $code\nTitle: $title\nStatus: $status ($progress%)\nPriority: $priority\nLast update: $lastUpdate\nDeadline: $deadline';
    } catch (_) {
      return 'Could not fetch tracking right now. Please try again in a moment.';
    }
  }

  String _analysisContext() {
    final _AiImageAnalysis? analysis = _analysis;
    if (analysis == null) return 'No scanned issue context available.';
    return 'Detected issue: ${analysis.issueTitle}. Category: ${analysis.category}. Department: ${analysis.department}. Severity: ${(analysis.severity * 100).round()}%.';
  }

  Future<String?> _askGemini(String input) async {
    const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) return null;
    try {
      final Uri uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );
      final Map<String, dynamic> payload = <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{
                'text':
                    'You are Pratyukti, a civic-issue assistant for Indian users. Keep replies concise and practical. '
                    'If user asks tracking, ask for report ID in format R-1234 if not provided. '
                    'Current app context: ${_analysisContext()}\n\nUser: $input',
              },
            ],
          },
        ],
      };
      final http.Response response = await http
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> candidates = (decoded['candidates'] as List?) ?? [];
      if (candidates.isEmpty) return null;
      final List<dynamic> parts =
          (candidates.first['content']?['parts'] as List?) ?? [];
      if (parts.isEmpty) return null;
      return (parts.first['text'] ?? '').toString().trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _scanImage() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final result = const _AiImageAnalysis(
      issueTitle: 'Deep pothole near flyover service lane',
      summary:
          'Likely a road-surface hazard causing two-wheeler instability and water accumulation risk.',
      category: 'Road',
      department: 'Road Maintenance Cell',
      confidence: 0.93,
      severity: 0.84,
      tags: ['Road Safety', 'High Priority', 'Public Hazard'],
    );
    setState(() {
      _analysis = result;
      _scanning = false;
      _messages.add(
        const _ChatMessage(
          role: _ChatRole.ai,
          text: 'Image processed. I prepared a structured analysis below.',
        ),
      );
    });
    _scrollToBottom();
  }

  void _applyToReport() {
    final analysis = _analysis;
    if (analysis == null) return;
    final report = PratyuktiResult(
      title: analysis.issueTitle,
      description:
          '${analysis.summary} Suggested department: ${analysis.department}.',
      category: analysis.category,
      severity: analysis.severity,
    );
    Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.primaryNavy,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Pratyukti',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: AnimatedEntrance(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Ask Pratyukti about this issue...',
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.surface(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendPrompt(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _sendPrompt(),
                          icon: const Icon(Icons.send_rounded),
                          color: AppTheme.primaryNavy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _PromptChip(
                            label: 'What can I report here?',
                            onTap: () => _sendPrompt('What can I report here?'),
                          ),
                          _PromptChip(
                            label: 'Is this urgent?',
                            onTap: () => _sendPrompt('Is this urgent?'),
                          ),
                          _PromptChip(
                            label: 'Who handles this issue?',
                            onTap: () => _sendPrompt('Who handles this issue?'),
                          ),
                          _PromptChip(
                            label: 'Track my latest report',
                            onTap: () =>
                                _sendPrompt('Track my latest report status'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                itemCount:
                    _messages.length +
                    (_thinking ? 1 : 0) +
                    (_analysis == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    final message = _messages[index];
                    return _MessageBubble(message: message);
                  }
                  int cursor = _messages.length;
                  if (_thinking) {
                    if (index == cursor) {
                      return const _TypingBubble();
                    }
                    cursor += 1;
                  }
                  if (_analysis != null && index == cursor) {
                    return _AnalysisCard(
                      analysis: _analysis!,
                      onUseInReport: _applyToReport,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                border: Border(
                  top: BorderSide(color: AppTheme.border(context)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanning ? null : _scanImage,
                      icon: Icon(
                        _scanning ? Icons.hourglass_bottom : Icons.camera_alt,
                      ),
                      label: Text(_scanning ? 'Scanning...' : 'Scan Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        side: BorderSide(color: AppTheme.border(context)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _analysis == null ? null : _applyToReport,
                      icon: const Icon(Icons.assignment_turned_in_outlined),
                      label: const Text('Use in Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

class _AnalysisCard extends StatelessWidget {
  final _AiImageAnalysis analysis;
  final VoidCallback onUseInReport;

  const _AnalysisCard({required this.analysis, required this.onUseInReport});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
              const Icon(
                Icons.image_search_rounded,
                color: AppTheme.primaryNavy,
              ),
              const SizedBox(width: 6),
              Text(
                'Image Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _KeyValue(label: 'Detected issue', value: analysis.issueTitle),
          _KeyValue(label: 'Category', value: analysis.category),
          _KeyValue(label: 'Department', value: analysis.department),
          _KeyValue(
            label: 'Confidence',
            value: '${(analysis.confidence * 100).round()}%',
          ),
          _KeyValue(
            label: 'Severity',
            value: '${(analysis.severity * 100).round()}%',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppTheme.primaryNavy,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            analysis.summary,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.textMuted(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onUseInReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use in Report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 94,
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
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryNavy.withValues(alpha: 0.12)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isUser
                ? AppTheme.primaryNavy.withValues(alpha: 0.25)
                : AppTheme.border(context),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: isUser
                ? AppTheme.primaryNavy
                : AppTheme.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pratyukti is thinking...',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: onTap,
        label: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
        side: BorderSide(color: AppTheme.border(context)),
      ),
    );
  }
}

enum _ChatRole { user, ai }

class _ChatMessage {
  final _ChatRole role;
  final String text;

  const _ChatMessage({required this.role, required this.text});
}

class _AiImageAnalysis {
  final String issueTitle;
  final String summary;
  final String category;
  final String department;
  final double confidence;
  final double severity;
  final List<String> tags;

  const _AiImageAnalysis({
    required this.issueTitle,
    required this.summary,
    required this.category,
    required this.department,
    required this.confidence,
    required this.severity,
    required this.tags,
  });
}
