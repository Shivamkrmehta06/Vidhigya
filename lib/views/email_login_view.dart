import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import '../widgets/animated_entrance.dart';
import 'home_view.dart';

class EmailLoginView extends StatefulWidget {
  const EmailLoginView({super.key});

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isActionPressed = false;
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAction() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final bool isEmailValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);

    if (!isEmailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('snack.emailInvalid'))));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('snack.passwordShort'))),
      );
      return;
    }

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

    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (_isRegisterMode) {
        final UserCredential credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final User? user = credential.user;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _isRegisterMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent. Please verify your email and then login.',
            ),
          ),
        );
        return;
      }

      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await credential.user?.reload();
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
        return;
      }

      if (!currentUser.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please verify your email before login.'),
            action: SnackBarAction(
              label: 'Resend',
              onPressed: () {
                currentUser.sendEmailVerification();
              },
            ),
          ),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      await _ensureUserProfile(currentUser);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_emailAuthErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _emailAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again after some time.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  Future<void> _ensureUserProfile(User user) async {
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
    if (snapshot.exists) return;
    final String fallbackName = user.email?.split('@').first ?? 'Citizen';
    await ref.set({
      'uid': user.uid,
      'name': fallbackName,
      'email': user.email,
      'city': '',
      'nirbhayaMode': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _handleForgotPassword() async {
    final String email = _emailController.text.trim();
    final bool isEmailValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
    if (!isEmailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('snack.emailInvalid'))));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_emailAuthErrorMessage(error))));
    }
  }

  void _toggleRegisterMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
    });
  }

  String get _title => _isRegisterMode
      ? 'Create account with email'
      : context.tr('emailLogin.title');
  String get _subtitle => _isRegisterMode
      ? 'Create your account and verify your email before login.'
      : context.tr('emailLogin.subtitle');
  String get _buttonLabel => _isRegisterMode
      ? context.tr('emailLogin.register')
      : context.tr('emailLogin.login');
  String get _toggleLabel => _isRegisterMode
      ? 'Already have an account? Login'
      : context.tr('emailLogin.register');

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
                  delay: const Duration(milliseconds: 40),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppTheme.primaryNavy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    _title,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    _subtitle,
                    style: GoogleFonts.manrope(fontSize: 14, color: textMuted),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 240),
                  child: GlassCard(
                    child: Column(
                      children: [
                        _EmailField(controller: _emailController),
                        const SizedBox(height: 12),
                        _PasswordField(controller: _passwordController),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              context.tr('emailLogin.forgotPassword'),
                              style: TextStyle(
                                color: AppTheme.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        _GradientButton(
                          label: _isLoading ? 'Please wait...' : _buttonLabel,
                          isPressed: _isActionPressed,
                          onTap: _isLoading ? () {} : _handleEmailAction,
                          onHighlightChanged: (isPressed) {
                            setState(() {
                              _isActionPressed = isPressed;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 320),
                  child: Center(
                    child: TextButton(
                      onPressed: _toggleRegisterMode,
                      child: Text(
                        _toggleLabel,
                        style: TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
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

class _EmailField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.alternate_email_rounded),
        hintText: context.tr('emailLogin.emailHint'),
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;

  const _PasswordField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        hintText: context.tr('emailLogin.passwordHint'),
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
