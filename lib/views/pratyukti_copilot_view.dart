import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _sendPrompt([String? preset]) {
    final input = (preset ?? _controller.text).trim();
    if (input.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: input));
      _messages.add(
        const _ChatMessage(
          role: _ChatRole.ai,
          text:
              'Based on your context, this looks like a civic complaint. Add a photo for precise detection and severity scoring.',
        ),
      );
      if (preset == null) {
        _controller.clear();
      }
    });
    _scrollToBottom();
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
                color: AppTheme.primaryNavy.withOpacity(0.12),
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
                          onPressed: _sendPrompt,
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
                            onTap: () =>
                                _sendPrompt('Who handles this issue?'),
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
                itemCount: _messages.length + (_analysis == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (_analysis != null && index == _messages.length) {
                    return _AnalysisCard(
                      analysis: _analysis!,
                      onUseInReport: _applyToReport,
                    );
                  }
                  final message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                border: Border(top: BorderSide(color: AppTheme.border(context))),
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

  const _AnalysisCard({
    required this.analysis,
    required this.onUseInReport,
  });

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
              const Icon(Icons.image_search_rounded, color: AppTheme.primaryNavy),
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
                      color: AppTheme.primaryNavy.withOpacity(0.1),
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
              ? AppTheme.primaryNavy.withOpacity(0.12)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isUser
                ? AppTheme.primaryNavy.withOpacity(0.25)
                : AppTheme.border(context),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: isUser ? AppTheme.primaryNavy : AppTheme.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({
    required this.label,
    required this.onTap,
  });

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
        backgroundColor: AppTheme.primaryNavy.withOpacity(0.08),
        side: BorderSide(color: AppTheme.border(context)),
      ),
    );
  }
}

enum _ChatRole { user, ai }

class _ChatMessage {
  final _ChatRole role;
  final String text;

  const _ChatMessage({
    required this.role,
    required this.text,
  });
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
