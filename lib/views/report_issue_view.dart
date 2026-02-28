import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  bool _postToX = false;
  bool _isSubmitting = false;
  bool _isAiAnalyzing = false;
  Uint8List? _photoBytes;
  _IssueAiDraft? _aiDraft;

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

  Future<void> _pickPhoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _hasPhoto = true;
      _aiReady = false;
      _aiDraft = null;
    });
  }

  Future<bool> _runAi({bool silent = false}) async {
    if (!_hasPhoto || _photoBytes == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a photo to run AI analysis.')),
        );
      }
      return false;
    }
    if (_isAiAnalyzing || _isSubmitting) return false;
    setState(() => _isAiAnalyzing = true);
    try {
      final _IssueAiDraft draft = await _generateIssueDraft();
      if (!mounted) return false;
      setState(() {
        _aiDraft = draft;
        _titleController.text = draft.title;
        _descController.text = draft.description;
        _category = draft.category;
        _severity = draft.severity;
        _aiReady = true;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI analysis ready (${draft.engine}).')),
        );
      }
      return true;
    } finally {
      if (mounted) setState(() => _isAiAnalyzing = false);
    }
  }

  Future<void> _runAnalysisOnly() async {
    await _runAi();
  }

  Future<void> _runAiAndAutoSubmit() async {
    final bool ok = await _runAi(silent: true);
    if (!ok || !mounted) return;
    await _submitIssue(aiAutoSubmitted: true);
  }

  Future<_IssueAiDraft> _generateIssueDraft() async {
    final _IssueAiDraft localDraft = _buildHeuristicDraft();
    if (_photoBytes == null) return localDraft;
    const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) return localDraft;
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
                    'You are a civic-issue classifier for India. Analyze this image and return strict JSON only with keys: title, description, category, severity, confidence, tags. '
                    'Category must be one of: Road, Lighting, Waste, Water, Public Safety. '
                    'severity and confidence are numbers from 0.0 to 1.0. tags is array of short strings. '
                    'Use concise professional text suitable for direct complaint submission.',
              },
              <String, dynamic>{
                'inline_data': <String, dynamic>{
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(_photoBytes!),
                },
              },
            ],
          },
        ],
      };
      final http.Response response = await http
          .post(
            uri,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 16));
      if (response.statusCode != 200) return localDraft;
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> candidates = (decoded['candidates'] as List?) ?? [];
      if (candidates.isEmpty) return localDraft;
      final List<dynamic> parts =
          (candidates.first['content']?['parts'] as List?) ?? [];
      if (parts.isEmpty) return localDraft;
      final String modelText = (parts.first['text'] ?? '').toString();
      final String jsonText = _extractJson(modelText);
      if (jsonText.isEmpty) return localDraft;
      final Map<String, dynamic> data = (jsonDecode(jsonText) as Map)
          .cast<String, dynamic>();
      return _IssueAiDraft(
        title: (data['title'] ?? localDraft.title).toString().trim(),
        description: (data['description'] ?? localDraft.description)
            .toString()
            .trim(),
        category: _normalizeCategory(
          (data['category'] ?? localDraft.category).toString(),
        ),
        severity: _normalizeFraction(
          data['severity'],
          fallback: localDraft.severity,
        ),
        confidence: _normalizeFraction(
          data['confidence'],
          fallback: localDraft.confidence,
        ),
        tags: _normalizeTags(data['tags'], fallback: localDraft.tags),
        engine: 'Pratyukti Gemini Vision',
      );
    } catch (_) {
      return localDraft;
    }
  }

  _IssueAiDraft _buildHeuristicDraft() {
    final String text = '${_titleController.text} ${_descController.text}'
        .toLowerCase();
    String category = _category;
    if (text.contains('pothole') ||
        text.contains('road') ||
        text.contains('flyover') ||
        text.contains('street')) {
      category = 'Road';
    } else if (text.contains('light') || text.contains('dark')) {
      category = 'Lighting';
    } else if (text.contains('garbage') ||
        text.contains('waste') ||
        text.contains('trash')) {
      category = 'Waste';
    } else if (text.contains('water') ||
        text.contains('leak') ||
        text.contains('drain')) {
      category = 'Water';
    } else if (text.contains('unsafe') ||
        text.contains('accident') ||
        text.contains('harassment')) {
      category = 'Public Safety';
    }
    final double severity = _severity >= 0.7
        ? _severity
        : text.contains('urgent') || text.contains('danger')
        ? 0.82
        : 0.64;
    final String title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _defaultTitleForCategory(category);
    final String description = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : _defaultDescriptionForCategory(category);
    return _IssueAiDraft(
      title: title,
      description: description,
      category: category,
      severity: severity,
      confidence: 0.76,
      tags: _defaultTagsForCategory(category),
      engine: 'Pratyukti Heuristic',
    );
  }

  String _defaultTitleForCategory(String category) {
    switch (category) {
      case 'Lighting':
        return 'Streetlight not working in public area';
      case 'Waste':
        return 'Garbage accumulation needs urgent clearing';
      case 'Water':
        return 'Water leakage and overflow on public road';
      case 'Public Safety':
        return 'Public safety hazard reported by resident';
      case 'Road':
      default:
        return 'Road hazard creating commuter risk';
    }
  }

  String _defaultDescriptionForCategory(String category) {
    switch (category) {
      case 'Lighting':
        return 'Area is poorly lit after dark and creates safety risk for commuters and pedestrians.';
      case 'Waste':
        return 'Waste accumulation is causing foul smell and potential health concerns for nearby residents.';
      case 'Water':
        return 'Water leakage is causing puddling and slippery road conditions, affecting movement and safety.';
      case 'Public Safety':
        return 'Observed on-ground safety risk requiring authority action and community protection measures.';
      case 'Road':
      default:
        return 'Road surface condition appears unsafe and needs inspection and repair to prevent accidents.';
    }
  }

  List<String> _defaultTagsForCategory(String category) {
    switch (category) {
      case 'Lighting':
        return const <String>['Lighting', 'Safety', 'Urgent'];
      case 'Waste':
        return const <String>['Sanitation', 'Public Health', 'Civic'];
      case 'Water':
        return const <String>['Water', 'Leakage', 'Public Safety'];
      case 'Public Safety':
        return const <String>['Safety', 'High Priority', 'Community Risk'];
      case 'Road':
      default:
        return const <String>['Road Safety', 'High Priority', 'Public Hazard'];
    }
  }

  String _extractJson(String raw) {
    final String cleaned = raw.trim();
    final int start = cleaned.indexOf('{');
    final int end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return '';
    return cleaned.substring(start, end + 1);
  }

  double _normalizeFraction(dynamic value, {required double fallback}) {
    final num? parsed = value is num
        ? value
        : num.tryParse((value ?? '').toString());
    if (parsed == null) return fallback;
    if (parsed < 0) return 0;
    if (parsed > 1) return 1;
    return parsed.toDouble();
  }

  String _normalizeCategory(String raw) {
    const List<String> allowed = <String>[
      'Road',
      'Lighting',
      'Waste',
      'Water',
      'Public Safety',
    ];
    for (final String item in allowed) {
      if (raw.toLowerCase() == item.toLowerCase()) return item;
    }
    return _category;
  }

  List<String> _normalizeTags(dynamic raw, {required List<String> fallback}) {
    if (raw is! List) return fallback;
    final List<String> tags = raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(5)
        .toList();
    return tags.isEmpty ? fallback : tags;
  }

  Future<void> _openPratyukti() async {
    final result = await Navigator.push<PratyuktiResult>(
      context,
      MaterialPageRoute(builder: (_) => const PratyuktiCopilotView()),
    );
    if (!mounted || result == null) return;
    final String normalizedCategory = _normalizeCategory(result.category);
    setState(() {
      _titleController.text = result.title;
      _descController.text = result.description;
      _category = normalizedCategory;
      _severity = result.severity;
      _hasPhoto = true;
      _aiReady = true;
      _aiDraft = _IssueAiDraft(
        title: result.title,
        description: result.description,
        category: normalizedCategory,
        severity: result.severity,
        confidence: 0.88,
        tags: _defaultTagsForCategory(normalizedCategory),
        engine: 'Pratyukti Copilot',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pratyukti analysis added to report.')),
    );
  }

  Future<void> _submitIssue({bool aiAutoSubmitted = false}) async {
    if (_isSubmitting) return;
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase is not configured yet. Add app config from Firebase console.',
          ),
        ),
      );
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login before reporting an issue.'),
        ),
      );
      return;
    }

    final _IssueAiDraft? draft = _aiDraft;
    final String title = _titleController.text.trim().isEmpty
        ? (draft?.title ?? 'Civic issue reported')
        : _titleController.text.trim();
    final String details = _descController.text.trim().isEmpty
        ? (draft?.description ?? '')
        : _descController.text.trim();
    final String reportCode =
        'R-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final String priority = _severity >= 0.67
        ? 'High'
        : _severity >= 0.34
        ? 'Medium'
        : 'Low';
    setState(() => _isSubmitting = true);

    try {
      final CollectionReference<Map<String, dynamic>> reports =
          FirebaseFirestore.instance.collection('reports');
      final DocumentReference<Map<String, dynamic>> doc = reports.doc();
      String? mediaUrl;
      String? mediaPath;
      if (_photoBytes != null) {
        final Reference ref = FirebaseStorage.instance.ref().child(
          'reports/${user.uid}/${doc.id}.jpg',
        );
        await ref.putData(
          _photoBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        mediaUrl = await ref.getDownloadURL();
        mediaPath = ref.fullPath;
      }

      await doc.set({
        'reportCode': reportCode,
        'title': title,
        'description': details,
        'category': _category,
        'severity': _severity,
        'priority': priority,
        'status': 'Open',
        'progress': 0.12,
        'location': 'MG Road, Bengaluru',
        'lastUpdate': 'Submitted and waiting for admin review',
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deadlineAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 72)),
        ),
        'escalated': false,
        'escalationState': 'none',
        'postToX': _postToX,
        'mediaUrl': mediaUrl,
        'mediaPath': mediaPath,
        'aiAssisted': _aiReady || draft != null,
        'aiAutoSubmitted': aiAutoSubmitted,
        'aiConfidence': draft?.confidence,
        'aiTags': draft?.tags ?? const <String>[],
        'aiEngine': draft?.engine,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aiAutoSubmitted
                ? 'AI analyzed image and submitted issue automatically.'
                : 'Issue submitted.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Issue submission failed.')),
      );
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    Navigator.pop(context);
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
                      label: const Text('Ask Pratyukti'),
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
                            child: _photoBytes != null
                                ? ClipRRect(
                                    key: const ValueKey('photo'),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radius,
                                    ),
                                    child: Image.memory(
                                      _photoBytes!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _hasPhoto
                                ? Container(
                                    key: const ValueKey('ai_only'),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 32,
                                          color: AppTheme.primaryNavy,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Issue draft prepared by AI',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: AppTheme.textMuted(context),
                                          ),
                                        ),
                                      ],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  onTap: () => _pickPhoto(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.upload_rounded,
                                  label: 'Upload',
                                  onTap: () => _pickPhoto(ImageSource.gallery),
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
                          Text(
                            '2. Pratyukti AI',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: _isAiAnalyzing
                                      ? null
                                      : _runAnalysisOnly,
                                  child: Text(
                                    _isAiAnalyzing
                                        ? 'Analyzing...'
                                        : 'Run analysis',
                                    style: TextStyle(
                                      color: AppTheme.primaryNavy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isAiAnalyzing || _isSubmitting
                                      ? null
                                      : _runAiAndAutoSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryNavy,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.auto_awesome_rounded),
                                  label: const Text('Auto Submit'),
                                ),
                              ],
                            ),
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
                                  'Detected: ${_aiDraft?.title ?? 'Issue from captured image'}',
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
                                  children:
                                      (_aiDraft?.tags ??
                                              const <String>[
                                                'Road Safety',
                                                'High Priority',
                                                'Public Hazard',
                                              ])
                                          .map((tag) => _AiChip(label: tag))
                                          .toList(),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Suggested severity (${((_aiDraft?.confidence ?? 0.76) * 100).round()}% confidence)',
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
                            key: ValueKey<String>(_category),
                            initialValue: _category,
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
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius,
                                ),
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
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius,
                              ),
                              border: Border.all(
                                color: AppTheme.border(context),
                              ),
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
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius,
                              ),
                              border: Border.all(
                                color: AppTheme.border(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.campaign_outlined,
                                  color: AppTheme.primaryNavy,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Post it to X(Twitter)',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Share this issue publicly to reach more people.',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: AppTheme.textMuted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _postToX,
                                  activeThumbColor: AppTheme.primaryNavy,
                                  onChanged: (value) {
                                    setState(() {
                                      _postToX = value;
                                    });
                                  },
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
                      isLoading: _isSubmitting,
                      onTap: () => _submitIssue(),
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

class _IssueAiDraft {
  final String title;
  final String description;
  final String category;
  final double severity;
  final double confidence;
  final List<String> tags;
  final String engine;

  const _IssueAiDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.confidence,
    required this.tags,
    required this.engine,
  });
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
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        color: AppTheme.primaryNavy.withValues(alpha: 0.08),
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
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

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
              color: AppTheme.primaryNavy.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
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
