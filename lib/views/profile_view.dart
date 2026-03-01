import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _notifications = true;
  bool _communityAlerts = true;
  bool _silentNight = false;
  bool _trataAutoRecord = true;
  bool _isSigningOut = false;
  bool _isProfileSaving = false;
  bool _isEmailBusy = false;

  String _fallbackNameFromUser(User user) {
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
    return 'Citizen';
  }

  String _titleCaseName(String raw) {
    final String normalized = raw.trim();
    if (normalized.isEmpty) return normalized;
    return normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _displayPhone(Map<String, dynamic> data, User user) {
    final String phone = (user.phoneNumber ?? data['phoneNumber'] ?? '')
        .toString()
        .trim();
    return phone.isEmpty ? 'Not set' : phone;
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Sign out failed.')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'provider-already-linked':
        return 'Email/password is already linked to this account.';
      case 'credential-already-in-use':
        return 'This credential is already linked with another account.';
      case 'requires-recent-login':
        return 'Please login again and retry this action.';
      default:
        return error.message ?? 'Action failed. Please try again.';
    }
  }

  Future<void> _openEditProfileDialog({
    required User user,
    required String currentName,
    required String currentCity,
  }) async {
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: currentName,
        initialCity: currentCity,
      ),
    );
    if (result == null) return;

    final String name = result['name'] ?? '';
    final String city = result['city'] ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }

    setState(() => _isProfileSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'city': city,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not update profile.')),
      );
    } finally {
      if (mounted) setState(() => _isProfileSaving = false);
    }
  }

  Future<void> _openAddEmailDialog(User user) async {
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddEmailDialog(),
    );
    if (result == null) return;

    final String email = result['email'] ?? '';
    final String password = result['password'] ?? '';
    final bool isEmailValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
    if (!isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password should be at least 6 characters.'),
        ),
      );
      return;
    }

    setState(() => _isEmailBusy = true);
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);
      await user.sendEmailVerification();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email linked. Verification link sent to your inbox.'),
        ),
      );
      setState(() {});
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isEmailBusy = false);
    }
  }

  Future<void> _sendEmailVerification(User user) async {
    setState(() => _isEmailBusy = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent.')));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isEmailBusy = false);
    }
  }

  Future<void> _refreshUser(User user) async {
    await user.reload();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final settings = AppSettings.of(context);
    final activeLanguage = AppLocalizations.languageFromLocale(settings.locale);
    final bool firebaseReady = Firebase.apps.isNotEmpty;
    final User? currentUser = firebaseReady
        ? FirebaseAuth.instance.currentUser
        : null;

    if (!firebaseReady || currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const _ScreenBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        _TopIconBubble(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Hero(
                          tag: 'vidhigya-wordmark',
                          child: Image.asset(
                            'assets/images/vidhigya_wordmark.png',
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr('profile.title'),
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          border: Border.all(color: AppTheme.border(context)),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Text(
                          'Login required to view profile.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const _ScreenBackdrop(),
          SafeArea(
            child: AnimatedEntrance(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, profileSnapshot) {
                  final Map<String, dynamic> data =
                      profileSnapshot.data?.data() ?? <String, dynamic>{};
                  final String name = _titleCaseName(
                    (data['name'] as String?)?.trim().isNotEmpty == true
                        ? data['name'] as String
                        : _fallbackNameFromUser(currentUser),
                  );
                  final String email =
                      (currentUser.email ?? data['email'] ?? '')
                          .toString()
                          .trim();
                  final String city = (data['city'] ?? '').toString().trim();
                  final bool emailVerified = currentUser.emailVerified;
                  final bool hasEmail = email.isNotEmpty;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _TopIconBubble(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Hero(
                              tag: 'vidhigya-wordmark',
                              child: Image.asset(
                                'assets/images/vidhigya_wordmark.png',
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('profile.title'),
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your identity, safety settings, and account access.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ProfileHeader(
                          name: name,
                          userId: currentUser.uid,
                          onEdit: _isProfileSaving
                              ? null
                              : () => _openEditProfileDialog(
                                  user: currentUser,
                                  currentName: name,
                                  currentCity: city,
                                ),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle(title: context.tr('profile.account')),
                        const SizedBox(height: 8),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          title: _displayPhone(data, currentUser),
                          subtitle: context.tr('profile.primaryNumber'),
                        ),
                        _InfoTile(
                          icon: Icons.email_outlined,
                          title: email.isEmpty ? 'Not set' : email,
                          subtitle: hasEmail
                              ? '${context.tr('profile.emailAddress')} • ${emailVerified ? 'Verified' : 'Unverified'}'
                              : context.tr('profile.emailAddress'),
                          trailing: _EmailActionButton(
                            hasEmail: hasEmail,
                            emailVerified: emailVerified,
                            isBusy: _isEmailBusy,
                            onAddEmail: () => _openAddEmailDialog(currentUser),
                            onSendVerification: () =>
                                _sendEmailVerification(currentUser),
                            onRefreshStatus: () => _refreshUser(currentUser),
                          ),
                        ),
                        _InfoTile(
                          icon: Icons.place_outlined,
                          title: city.isEmpty ? 'Not set' : city,
                          subtitle: context.tr('profile.homeLocation'),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle(title: context.tr('profile.safety')),
                        const SizedBox(height: 8),
                        _SwitchTile(
                          title: context.tr('profile.autoRecord'),
                          subtitle: context.tr('profile.storeEvidence'),
                          value: _trataAutoRecord,
                          onChanged: (value) =>
                              setState(() => _trataAutoRecord = value),
                        ),
                        _InfoTile(
                          icon: Icons.shield_outlined,
                          title: context.tr('profile.emergencyContacts'),
                          subtitle: context.tr('profile.contactsConfigured'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle(
                          title: context.tr('profile.notifications'),
                        ),
                        const SizedBox(height: 8),
                        _SwitchTile(
                          title: context.tr('profile.appNotifications'),
                          subtitle: context.tr('profile.issueUpdates'),
                          value: _notifications,
                          onChanged: (value) =>
                              setState(() => _notifications = value),
                        ),
                        _SwitchTile(
                          title: context.tr('profile.communityAlerts'),
                          subtitle: context.tr('profile.nearbyAlerts'),
                          value: _communityAlerts,
                          onChanged: (value) =>
                              setState(() => _communityAlerts = value),
                        ),
                        _SwitchTile(
                          title: context.tr('profile.silentNight'),
                          subtitle: context.tr('profile.muteNight'),
                          value: _silentNight,
                          onChanged: (value) =>
                              setState(() => _silentNight = value),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle(title: context.tr('profile.language')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius,
                            ),
                            border: Border.all(color: AppTheme.border(context)),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Locale>(
                              value: activeLanguage.locale,
                              isExpanded: true,
                              hint: Text(context.tr('profile.selectLanguage')),
                              items: AppLocalizations.languages
                                  .map(
                                    (language) => DropdownMenuItem<Locale>(
                                      value: language.locale,
                                      child: Text(language.dropdownLabel),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (locale) {
                                if (locale == null) return;
                                settings.setLocale(locale);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr('snack.languageUpdated'),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle(title: context.tr('profile.support')),
                        const SizedBox(height: 8),
                        _InfoTile(
                          icon: Icons.help_outline,
                          title: context.tr('profile.helpCenter'),
                          subtitle: context.tr('profile.faqSupport'),
                        ),
                        _InfoTile(
                          icon: Icons.description_outlined,
                          title: context.tr('profile.termsPrivacy'),
                          subtitle: context.tr('profile.policiesData'),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSigningOut ? null : _handleSignOut,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppTheme.primaryNavy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _isSigningOut
                                  ? 'Signing out...'
                                  : _isProfileSaving
                                  ? 'Saving profile...'
                                  : context.tr('profile.signOut'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenBackdrop extends StatelessWidget {
  const _ScreenBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.cloud, AppTheme.mist],
              ),
            ),
          ),
        ),
        Positioned(
          left: -86,
          top: 108,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: AppTheme.tealAccent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -74,
          bottom: 150,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: AppTheme.purpleAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopIconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: AppTheme.softShadow,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 21, color: AppTheme.primaryNavy),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String userId;
  final VoidCallback? onEdit;

  const _ProfileHeader({
    required this.name,
    required this.userId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryNavy,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('createdBy', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final int count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      'Verified resident • $count reports',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.textMuted(context),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              context.tr('profile.edit'),
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialCity;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialCity,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'city': _cityController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddEmailDialog extends StatefulWidget {
  const _AddEmailDialog();

  @override
  State<_AddEmailDialog> createState() => _AddEmailDialogState();
}

class _AddEmailDialogState extends State<_AddEmailDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add email login'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password (min 6 chars)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'email': _emailController.text.trim(),
              'password': _passwordController.text.trim(),
            });
          },
          child: const Text('Link'),
        ),
      ],
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryNavy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          if (trailing case final Widget t) t,
        ],
      ),
    );
  }
}

class _EmailActionButton extends StatelessWidget {
  final bool hasEmail;
  final bool emailVerified;
  final bool isBusy;
  final VoidCallback onAddEmail;
  final VoidCallback onSendVerification;
  final VoidCallback onRefreshStatus;

  const _EmailActionButton({
    required this.hasEmail,
    required this.emailVerified,
    required this.isBusy,
    required this.onAddEmail,
    required this.onSendVerification,
    required this.onRefreshStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!hasEmail) {
      return TextButton(onPressed: onAddEmail, child: const Text('Add'));
    }

    if (emailVerified) {
      return const Icon(Icons.verified_rounded, color: Color(0xFF16A34A));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onSendVerification, child: const Text('Verify')),
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: onRefreshStatus,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh status',
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
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
