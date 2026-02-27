import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import '../widgets/animated_entrance.dart';
import 'email_login_view.dart';
import 'home_view.dart';
import 'register_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isActionPressed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleOtpFlow() {
    final String phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('snack.phoneInvalid'))));
      return;
    }

    if (!_otpSent) {
      setState(() {
        _otpSent = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('snack.otpSent'))));
      return;
    }

    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('snack.otpInvalid'))));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('snack.loginSuccess'))));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  void _handleEmailLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmailLoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textMuted(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'vidhigya-wordmark',
                            child: Image.asset(
                              'assets/images/vidhigya_wordmark.png',
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Text(
                            '   ${context.tr('login.tagline')}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 140),
                  child: Text(
                    context.tr('login.welcomeBack'),
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    context.tr('login.subtitle'),
                    style: GoogleFonts.manrope(fontSize: 14, color: textMuted),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 260),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('login.phoneLogin'),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PhoneField(controller: _phoneController),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            );
                            return SizeTransition(
                              sizeFactor: curved,
                              child: FadeTransition(
                                opacity: curved,
                                child: child,
                              ),
                            );
                          },
                          child: _otpSent
                              ? Padding(
                                  key: const ValueKey('otp'),
                                  padding: const EdgeInsets.only(top: 14),
                                  child: _OtpField(controller: _otpController),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),
                        const SizedBox(height: 18),
                        _GradientButton(
                          label: _otpSent
                              ? context.tr('login.verifyOtp')
                              : context.tr('login.sendOtp'),
                          isPressed: _isActionPressed,
                          onTap: _handleOtpFlow,
                          onHighlightChanged: (isPressed) {
                            setState(() {
                              _isActionPressed = isPressed;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleEmailLogin,
                            child: Text(
                              context.tr('login.emailLogin'),
                              style: TextStyle(
                                color: AppTheme.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 320),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingRegister(),
                          ),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: context.tr('login.newHere'),
                          style: TextStyle(color: textMuted),
                          children: [
                            TextSpan(
                              text: context.tr('login.createAccount'),
                              style: TextStyle(
                                color: AppTheme.primaryNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 380),
                  child: Text(
                    context.tr('login.terms'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 11, color: textMuted),
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

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.phone_rounded),
        hintText: context.tr('login.mobileHint'),
        counterText: '',
        filled: true,
        fillColor: AppTheme.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;

  const _OtpField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_rounded),
        hintText: context.tr('login.otpHint'),
        counterText: '',
        filled: true,
        fillColor: AppTheme.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isPressed;
  final VoidCallback onTap;
  final ValueChanged<bool> onHighlightChanged;

  const _GradientButton({
    required this.label,
    required this.isPressed,
    required this.onTap,
    required this.onHighlightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isPressed
                ? [
                    AppTheme.primaryNavy.withOpacity(0.9),
                    AppTheme.purpleAccent.withOpacity(0.9),
                    AppTheme.tealAccent.withOpacity(0.9),
                  ]
                : [
                    AppTheme.primaryNavy,
                    AppTheme.purpleAccent,
                    AppTheme.tealAccent,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          onHighlightChanged: onHighlightChanged,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
