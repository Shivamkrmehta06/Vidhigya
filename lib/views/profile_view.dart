import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';

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

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final settings = AppSettings.of(context);
    final activeLanguage = AppLocalizations.languageFromLocale(settings.locale);
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
                      context.tr('profile.title'),
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
                const SizedBox(height: 12),
                _ProfileHeader(),
                const SizedBox(height: 18),
                _SectionTitle(title: context.tr('profile.account')),
                const SizedBox(height: 8),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  title: '+91 98XXXXXX10',
                  subtitle: context.tr('profile.primaryNumber'),
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  title: 'priya@vidhigya.app',
                  subtitle: context.tr('profile.emailAddress'),
                ),
                _InfoTile(
                  icon: Icons.place_outlined,
                  title: 'Bengaluru, Karnataka',
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
                _SectionTitle(title: context.tr('profile.notifications')),
                const SizedBox(height: 8),
                _SwitchTile(
                  title: context.tr('profile.appNotifications'),
                  subtitle: context.tr('profile.issueUpdates'),
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
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
                  onChanged: (value) => setState(() => _silentNight = value),
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: context.tr('profile.language')),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
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
                            content: Text(context.tr('snack.languageUpdated')),
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
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppTheme.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(context.tr('profile.signOut')),
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

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryNavy,
            child: Text(
              'P',
              style: TextStyle(
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
                  'Priya Sharma',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('profile.verifiedResidentReports'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
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
          if (trailing != null) trailing!,
        ],
      ),
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
