import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isTriggeringSos = false;
  bool _isContactsLoading = false;
  bool _isEvidenceBusy = false;
  bool _isCheckInBusy = false;
  String _evidenceStatus = 'Evidence vault ready';
  String _checkInStatus = 'No safety check-in sent yet';
  List<_EmergencyContact> _trustedContacts = const [];
  final Telephony _telephony = Telephony.instance;

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
    _loadTrustedContacts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startActivationFlow() async {
    if (_isTriggeringSos) return;
    final activated = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ActivationCountdownSheet(),
    );
    if (!mounted || activated != true) return;
    final _SosDispatchResult? result = await _dispatchSos();
    if (!mounted || result == null) return;
    _showActivatedSheet(result);
  }

  User? _activeUser() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> _loadTrustedContacts() async {
    final User? user = _activeUser();
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _trustedContacts = const <_EmergencyContact>[];
      });
      return;
    }
    setState(() => _isContactsLoading = true);
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final List<_EmergencyContact> parsed = _parseContacts(
        snapshot.data()?['emergencyContacts'],
      );
      final String evidenceStatus = _deriveEvidenceStatus(
        snapshot.data()?['lastTrataEvidence'],
      );
      final String checkInStatus = _deriveCheckInStatus(
        snapshot.data()?['lastTrataCheckIn'],
      );
      if (!mounted) return;
      setState(() {
        _trustedContacts = parsed;
        _evidenceStatus = evidenceStatus;
        _checkInStatus = checkInStatus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trustedContacts = const <_EmergencyContact>[];
      });
    } finally {
      if (mounted) setState(() => _isContactsLoading = false);
    }
  }

  List<_EmergencyContact> _parseContacts(dynamic raw) {
    if (raw is! List) {
      return const <_EmergencyContact>[];
    }
    final List<_EmergencyContact> contacts = raw
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> value) {
          final String name = (value['name'] ?? '').toString().trim();
          final String relation = (value['relation'] ?? '').toString().trim();
          final String phone = (value['phone'] ?? '').toString().trim();
          if (name.isEmpty || phone.isEmpty) {
            return null;
          }
          return _EmergencyContact(
            name: name,
            relation: relation.isEmpty ? 'Trusted contact' : relation,
            phone: phone,
          );
        })
        .whereType<_EmergencyContact>()
        .toList();
    if (contacts.isEmpty) {
      return const <_EmergencyContact>[];
    }
    return contacts;
  }

  Future<void> _saveTrustedContacts() async {
    final User? user = _activeUser();
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'emergencyContacts': _trustedContacts.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _addOrEditContact({int? index}) async {
    final _EmergencyContact? existing = index == null
        ? null
        : _trustedContacts[index];
    final _EmergencyContact? updated = await showDialog<_EmergencyContact>(
      context: context,
      builder: (_) => _ContactEditorDialog(existing: existing),
    );
    if (updated == null) return;
    final List<_EmergencyContact> next = List<_EmergencyContact>.from(
      _trustedContacts,
    );
    if (index == null) {
      next.add(updated);
    } else {
      next[index] = updated;
    }
    setState(() => _trustedContacts = next);
    try {
      await _saveTrustedContacts();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save trusted contact.')),
      );
    }
  }

  Future<void> _removeContact(int index) async {
    final List<_EmergencyContact> next = List<_EmergencyContact>.from(
      _trustedContacts,
    );
    next.removeAt(index);
    setState(() => _trustedContacts = next);
    try {
      await _saveTrustedContacts();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update trusted contacts.')),
      );
    }
  }

  String _normalizePhone(String value) {
    final String trimmed = value.trim();
    if (trimmed.startsWith('+')) {
      return '+${trimmed.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    return trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _relativeTime(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  String _deriveEvidenceStatus(dynamic raw) {
    if (raw is! Map) return 'Evidence vault ready';
    final String type = (raw['type'] ?? '').toString();
    final dynamic atRaw = raw['capturedAt'];
    if (type.isEmpty || atRaw is! Timestamp) return 'Evidence vault ready';
    final String label = type == 'video' ? 'Video evidence' : 'Photo evidence';
    return '$label captured ${_relativeTime(atRaw.toDate())}';
  }

  String _deriveCheckInStatus(dynamic raw) {
    if (raw is! Map) return 'No safety check-in sent yet';
    final dynamic atRaw = raw['sentAt'];
    if (atRaw is! Timestamp) return 'No safety check-in sent yet';
    return 'Last check-in ${_relativeTime(atRaw.toDate())}';
  }

  Future<Position?> _resolveCurrentLocation() async {
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  String _buildMapsUrl(Position position) {
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }

  String _buildSosMessage({
    required String incident,
    required String phone,
    required Position? position,
  }) {
    final String base =
        'TRATA SOS ALERT\nIncident: $incident\nFrom: $phone\nImmediate help needed.';
    if (position == null) {
      return base;
    }
    return '$base\nLive location: ${_buildMapsUrl(position)}';
  }

  Future<bool> _launchSms({
    required List<String> recipients,
    required String body,
  }) async {
    if (recipients.isEmpty) return false;
    final String encodedBody = Uri.encodeComponent(body);
    final String recipientPath = recipients.join(',');
    final Uri uri = Uri.parse('sms:$recipientPath?body=$encodedBody');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<_SmsDispatchResult> _sendSmsWithBestEffort({
    required List<String> recipients,
    required String body,
  }) async {
    final List<String> normalized = recipients
        .map(_normalizePhone)
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) {
      return const _SmsDispatchResult();
    }

    if (Platform.isAndroid) {
      try {
        final bool granted =
            await _telephony.requestPhoneAndSmsPermissions ?? false;
        if (granted) {
          int autoSentCount = 0;
          for (final String to in normalized) {
            try {
              await _telephony.sendSms(to: to, message: body);
              autoSentCount += 1;
            } catch (_) {
              // Keep trying remaining numbers.
            }
          }
          if (autoSentCount > 0) {
            return _SmsDispatchResult(autoSentCount: autoSentCount);
          }
        }
      } catch (_) {
        // Fallback to composer below.
      }
    }

    final bool opened = await _launchSms(recipients: normalized, body: body);
    return _SmsDispatchResult(composerOpened: opened);
  }

  Future<bool> _launchCall(String phone) async {
    final String normalized = _normalizePhone(phone);
    if (normalized.isEmpty) return false;
    if (Platform.isAndroid) {
      try {
        final bool? called = await FlutterPhoneDirectCaller.callNumber(
          normalized,
        );
        if (called == true) return true;
      } catch (_) {
        // Fallback to dialer intent.
      }
    }
    final Uri uri = Uri.parse('tel:$normalized');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistSosSnapshot({
    required String incident,
    required Position? position,
    required List<_EmergencyContact> contacts,
    required bool smsOpened,
    required int smsAutoSentCount,
    required bool callOpened,
  }) async {
    final User? user = _activeUser();
    if (user == null) return;
    final Map<String, dynamic> payload = <String, dynamic>{
      'incident': incident,
      'smsOpened': smsOpened,
      'smsAutoSentCount': smsAutoSentCount,
      'callOpened': callOpened,
      'contactsCount': contacts.length,
      'triggeredAt': FieldValue.serverTimestamp(),
      'contactPhones': contacts.map((e) => _normalizePhone(e.phone)).toList(),
    };
    if (position != null) {
      payload['location'] = <String, double>{
        'lat': position.latitude,
        'lng': position.longitude,
      };
      payload['mapsUrl'] = _buildMapsUrl(position);
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'lastTrataAlert': payload,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _persistCheckInSnapshot({
    required Position? position,
    required bool smsOpened,
    required int smsAutoSentCount,
  }) async {
    final User? user = _activeUser();
    if (user == null) return;
    final Map<String, dynamic> payload = <String, dynamic>{
      'smsOpened': smsOpened,
      'smsAutoSentCount': smsAutoSentCount,
      'sentAt': FieldValue.serverTimestamp(),
    };
    if (position != null) {
      payload['location'] = <String, double>{
        'lat': position.latitude,
        'lng': position.longitude,
      };
      payload['mapsUrl'] = _buildMapsUrl(position);
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'lastTrataCheckIn': payload,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _captureEvidence({required bool video}) async {
    if (_isEvidenceBusy) return;
    final User? user = _activeUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to capture evidence.')),
      );
      return;
    }

    setState(() => _isEvidenceBusy = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? captured = video
          ? await picker.pickVideo(
              source: ImageSource.camera,
              maxDuration: const Duration(minutes: 2),
            )
          : await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 82,
              maxWidth: 1800,
            );
      if (captured == null) return;

      String? downloadUrl;
      String? storagePath;
      try {
        final String extension = video ? 'mp4' : 'jpg';
        final String contentType = video ? 'video/mp4' : 'image/jpeg';
        final Reference ref = FirebaseStorage.instance.ref().child(
          'trata_evidence/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$extension',
        );
        if (video) {
          await ref.putFile(
            File(captured.path),
            SettableMetadata(contentType: contentType),
          );
        } else {
          final bytes = await captured.readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: contentType));
        }
        downloadUrl = await ref.getDownloadURL();
        storagePath = ref.fullPath;
      } catch (_) {
        // Keep evidence flow usable even when Storage isn't available.
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastTrataEvidence': <String, dynamic>{
          'type': video ? 'video' : 'photo',
          'uploadStatus': downloadUrl == null ? 'local_only' : 'uploaded',
          'storageUrl': downloadUrl,
          'storagePath': storagePath,
          'capturedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _evidenceStatus =
            '${video ? 'Video' : 'Photo'} evidence captured just now';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloadUrl == null
                ? 'Evidence captured locally. Storage upload unavailable.'
                : '${video ? 'Video' : 'Photo'} evidence uploaded.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture evidence.')),
      );
    } finally {
      if (mounted) setState(() => _isEvidenceBusy = false);
    }
  }

  Future<_SosDispatchResult?> _dispatchSos() async {
    final User? user = _activeUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login required to activate TRATA.')),
        );
      }
      return null;
    }
    setState(() => _isTriggeringSos = true);
    try {
      final List<_EmergencyContact> contacts = _trustedContacts;
      if (contacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Add at least one trusted contact before activating TRATA.',
              ),
            ),
          );
        }
        return null;
      }
      final Position? position = _shareLiveLocation
          ? await _resolveCurrentLocation()
          : null;
      final _EmergencyContact primary = contacts.first;
      final String senderPhone = user.phoneNumber?.trim().isNotEmpty == true
          ? user.phoneNumber!.trim()
          : 'Registered user';
      final String message = _buildSosMessage(
        incident: _incidentType,
        phone: senderPhone,
        position: position,
      );

      bool callOpened = false;
      if (_autoCallPrimary) {
        // Judges asked for immediate call escalation on activation.
        callOpened = await _launchCall(primary.phone);
      }

      int smsAutoSentCount = 0;
      bool smsOpened = false;
      if (_sendSms) {
        final _SmsDispatchResult smsResult = await _sendSmsWithBestEffort(
          recipients: contacts.map((c) => c.phone).toList(),
          body: message,
        );
        smsAutoSentCount = smsResult.autoSentCount;
        smsOpened = smsResult.composerOpened;
      }

      await _persistSosSnapshot(
        incident: _incidentType,
        position: position,
        contacts: contacts,
        smsOpened: smsOpened,
        smsAutoSentCount: smsAutoSentCount,
        callOpened: callOpened,
      );

      final List<String> tags = <String>[
        if (_shareLiveLocation)
          position == null ? 'Location unavailable' : 'Live location captured',
        if (_sendSms)
          smsAutoSentCount > 0
              ? 'SMS sent automatically ($smsAutoSentCount)'
              : smsOpened
              ? 'SMS composer opened'
              : 'SMS send blocked',
        if (_autoCallPrimary)
          callOpened ? 'Primary call triggered' : 'Call launch blocked',
        if (_autoRecord) 'Evidence mode enabled',
      ];

      return _SosDispatchResult(
        incident: _incidentType,
        mapUrl: position == null ? null : _buildMapsUrl(position),
        actionTags: tags,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TRATA activation failed. Try again.')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isTriggeringSos = false);
    }
  }

  Future<void> _sendCheckIn() async {
    if (_isCheckInBusy) return;
    final List<_EmergencyContact> contacts = _trustedContacts;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add trusted contacts first.')),
      );
      return;
    }
    setState(() => _isCheckInBusy = true);
    Position? position;
    try {
      if (_shareLiveLocation) {
        position = await _resolveCurrentLocation();
      }
      final String message = position == null
          ? 'TRATA check-in: I am safe now.'
          : 'TRATA check-in: I am safe now. Current location: ${_buildMapsUrl(position)}';
      final _SmsDispatchResult smsResult = await _sendSmsWithBestEffort(
        recipients: contacts.map((e) => e.phone).toList(),
        body: message,
      );
      await _persistCheckInSnapshot(
        position: position,
        smsOpened: smsResult.composerOpened,
        smsAutoSentCount: smsResult.autoSentCount,
      );
      if (!mounted) return;
      setState(() => _checkInStatus = 'Check-in sent just now');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            smsResult.autoSentCount > 0
                ? 'Check-in SMS sent automatically to ${smsResult.autoSentCount} contact(s).'
                : smsResult.composerOpened
                ? 'Check-in message ready to send.'
                : 'Could not open SMS app for check-in.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckInBusy = false);
    }
  }

  void _showActivatedSheet(_SosDispatchResult result) {
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
                'Incident: ${result.incident}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.textMuted(context),
                ),
              ),
              if (result.mapUrl != null) ...[
                const SizedBox(height: 6),
                SelectableText(
                  result.mapUrl!,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.actionTags
                    .map((label) => _ActionTag(label: label))
                    .toList(),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                  children:
                      ['Personal Safety', 'Medical', 'Accident', 'Harassment']
                          .map(
                            (item) => ChoiceChip(
                              label: Text(item),
                              selected: _incidentType == item,
                              onSelected: (_) =>
                                  setState(() => _incidentType = item),
                              selectedColor: AppTheme.primaryNavy.withValues(
                                alpha: 0.12,
                              ),
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
                    onTap: _isTriggeringSos ? null : _startActivationFlow,
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
                            color: const Color(
                              0xFFD7193A,
                            ).withValues(alpha: 0.35),
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
                              color: Colors.white.withValues(alpha: 0.18),
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
                                  _isTriggeringSos
                                      ? 'ACTIVATING...'
                                      : 'TRATA ALERT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isTriggeringSos
                                      ? 'Dispatching SMS/call/location actions.'
                                      : 'Tap once: 5-second countdown with cancel.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.92),
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
                Row(
                  children: [
                    const _SectionTitle(title: 'Trusted Circle'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isContactsLoading
                          ? null
                          : () => _addOrEditContact(),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isContactsLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  if (_trustedContacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: AppTheme.border(context)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Text(
                        'No trusted contacts added yet. TRATA will send alerts only to contacts you add.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ),
                  for (
                    int index = 0;
                    index < _trustedContacts.length;
                    index++
                  ) ...[
                    _ContactCard(
                      name: _trustedContacts[index].name,
                      relation: _trustedContacts[index].relation,
                      phone: _trustedContacts[index].phone,
                      accent: index == 0
                          ? AppTheme.primaryNavy
                          : index == 1
                          ? AppTheme.tealAccent
                          : const Color(0xFFDC2626),
                      status: index == 0 ? 'Primary' : 'Ready',
                      onCall: () => _launchCall(_trustedContacts[index].phone),
                      onEdit: () => _addOrEditContact(index: index),
                      onDelete: _trustedContacts.length <= 1
                          ? null
                          : () => _removeContact(index),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
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
                  subtitle: 'Quick evidence capture tools stay ready',
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
                          _mockAction(
                            _siren ? 'Siren stopped' : 'Siren started',
                          );
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
                            _flashlight
                                ? 'Flashlight off'
                                : 'Flashlight strobe on',
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
                              _evidenceStatus,
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
                              onPressed: _isCheckInBusy ? null : _sendCheckIn,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(
                                _isCheckInBusy ? 'Sending...' : 'Check-In',
                              ),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isEvidenceBusy
                                  ? null
                                  : () => _captureEvidence(video: false),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                _isEvidenceBusy
                                    ? 'Please wait'
                                    : 'Capture Photo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isEvidenceBusy
                                  ? null
                                  : () => _captureEvidence(video: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.tealAccent,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.videocam_outlined),
                              label: const Text('Record Video'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Video evidence records audio as well.',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _checkInStatus,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryNavy,
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
    );
  }
}

class _ActivationCountdownSheet extends StatefulWidget {
  const _ActivationCountdownSheet();

  @override
  State<_ActivationCountdownSheet> createState() =>
      _ActivationCountdownSheetState();
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
        color: AppTheme.primaryNavy.withValues(alpha: 0.1),
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
  final VoidCallback? onCall;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ContactCard({
    required this.name,
    required this.relation,
    required this.phone,
    required this.accent,
    required this.status,
    this.onCall,
    this.onEdit,
    this.onDelete,
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
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
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
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              if (value == 'call') {
                onCall?.call();
                return;
              }
              if (value == 'edit') {
                onEdit?.call();
                return;
              }
              if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'call', child: Text('Call')),
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              if (onDelete != null)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const _EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  Map<String, String> toMap() {
    return <String, String>{'name': name, 'relation': relation, 'phone': phone};
  }
}

class _SosDispatchResult {
  final String incident;
  final String? mapUrl;
  final List<String> actionTags;

  const _SosDispatchResult({
    required this.incident,
    required this.mapUrl,
    required this.actionTags,
  });
}

class _SmsDispatchResult {
  final bool composerOpened;
  final int autoSentCount;

  const _SmsDispatchResult({
    this.composerOpened = false,
    this.autoSentCount = 0,
  });
}

class _ContactEditorDialog extends StatefulWidget {
  final _EmergencyContact? existing;

  const _ContactEditorDialog({this.existing});

  @override
  State<_ContactEditorDialog> createState() => _ContactEditorDialogState();
}

class _ContactEditorDialogState extends State<_ContactEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _relationController = TextEditingController(
      text: widget.existing?.relation ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existing?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    final String relation = _relationController.text.trim();
    final String phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      return;
    }
    Navigator.pop(
      context,
      _EmergencyContact(
        name: name,
        relation: relation.isEmpty ? 'Trusted contact' : relation,
        phone: phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add trusted contact' : 'Edit contact',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _relationController,
            decoration: const InputDecoration(labelText: 'Relation'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
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
      activeThumbColor: AppTheme.primaryNavy,
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
              Icon(icon, color: active ? Colors.white : AppTheme.primaryNavy),
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
