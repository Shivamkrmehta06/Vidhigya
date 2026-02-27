import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import '../widgets/animated_entrance.dart';
import 'home_view.dart';
import 'login_view.dart';

class OnboardingRegister extends StatefulWidget {
  const OnboardingRegister({super.key});

  @override
  State<OnboardingRegister> createState() => _OnboardingRegisterState();
}

class _OnboardingRegisterState extends State<OnboardingRegister> {
  final PageController controller = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  int currentPage = 0;
  final int totalSteps = 5;
  final List<String> _indianCities = const [
    'Agartala',
    'Agra',
    'Ahmedabad',
    'Aizawl',
    'Ajmer',
    'Akola',
    'Aligarh',
    'Allahabad',
    'Alwar',
    'Amaravati',
    'Ambala',
    'Amravati',
    'Amritsar',
    'Anand',
    'Anantapur',
    'Aurangabad',
    'Bareilly',
    'Belagavi',
    'Bengaluru',
    'Bhagalpur',
    'Bharatpur',
    'Bhatinda',
    'Bhavnagar',
    'Bhilai',
    'Bhilwara',
    'Bhopal',
    'Bhubaneswar',
    'Bikaner',
    'Bilaspur',
    'Bokaro',
    'Chandigarh',
    'Chennai',
    'Coimbatore',
    'Cuttack',
    'Dehradun',
    'Delhi',
    'Dhanbad',
    'Dharwad',
    'Durg',
    'Erode',
    'Faridabad',
    'Firozabad',
    'Gandhinagar',
    'Ghaziabad',
    'Gorakhpur',
    'Gulbarga',
    'Guntur',
    'Gurugram',
    'Guwahati',
    'Gwalior',
    'Hisar',
    'Howrah',
    'Hubballi',
    'Hyderabad',
    'Imphal',
    'Indore',
    'Jabalpur',
    'Jaipur',
    'Jalandhar',
    'Jammu',
    'Jamnagar',
    'Jamshedpur',
    'Jhansi',
    'Jodhpur',
    'Junagadh',
    'Kakinada',
    'Kannur',
    'Kanpur',
    'Karnal',
    'Kochi',
    'Kolhapur',
    'Kolkata',
    'Kota',
    'Kozhikode',
    'Kurnool',
    'Latur',
    'Lucknow',
    'Ludhiana',
    'Madurai',
    'Mangalore',
    'Meerut',
    'Moradabad',
    'Mumbai',
    'Muzaffarpur',
    'Mysuru',
    'Nagpur',
    'Nashik',
    'Navi Mumbai',
    'Noida',
    'Patna',
    'Pimpri-Chinchwad',
    'Pondicherry',
    'Pune',
    'Raipur',
    'Rajkot',
    'Ranchi',
    'Rourkela',
    'Salem',
    'Sangli',
    'Shimla',
    'Siliguri',
    'Solapur',
    'Srinagar',
    'Surat',
    'Thane',
    'Thiruvananthapuram',
    'Thrissur',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tiruppur',
    'Udaipur',
    'Ujjain',
    'Vadodara',
    'Varanasi',
    'Vellore',
    'Vijayawada',
    'Visakhapatnam',
    'Warangal',
  ];
  String? selectedCity;

  String name = "";
  String city = "";
  bool nirbhayaMode = false;
  bool isOtpSent = false;
  bool isMobileVerified = false;

  @override
  void dispose() {
    controller.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentPage == 0 && !isMobileVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('snack.verifyMobileContinue'))),
      );
      return;
    }
    if (currentPage == 2 && (selectedCity == null || selectedCity!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('snack.selectCityContinue'))),
      );
      return;
    }

    if (currentPage < 4) {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _sendOrVerifyOtp() {
    final String phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('snack.phoneInvalid'))));
      return;
    }

    if (!isOtpSent) {
      setState(() {
        isOtpSent = true;
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

    setState(() {
      isMobileVerified = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('snack.mobileVerified'))));
    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
          child: AnimatedEntrance(
            delay: const Duration(milliseconds: 60),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        context.tr('register.createAccount'),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${currentPage + 1}/$totalSteps',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProgressDots(total: totalSteps, current: currentPage),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView(
                    controller: controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                      if (index == totalSteps - 1) {
                        Future.delayed(const Duration(milliseconds: 900), () {
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeView()),
                          );
                        });
                      }
                    },
                    children: [
                      _buildMobileVerificationStep(),
                      _buildInputStep(
                        title: context.tr('register.namePrompt'),
                        hint: context.tr('register.nameHint'),
                        onChanged: (val) => name = val,
                      ),
                      _buildCityStep(),
                      _buildNirbhayaStep(),
                      _buildSuccessStep(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      context.tr('register.alreadyHaveAccount'),
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
      ),
    );
  }

  Widget _buildMobileVerificationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('register.mobileVerifyTitle'),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('register.mobileVerifySubtitle'),
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 18),
            _RoundedField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              hintText: context.tr('login.mobileHint'),
              icon: Icons.phone_rounded,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return SizeTransition(
                  sizeFactor: curved,
                  child: FadeTransition(opacity: curved, child: child),
                );
              },
              child: isOtpSent
                  ? Padding(
                      key: const ValueKey('otp'),
                      padding: const EdgeInsets.only(top: 12),
                      child: _RoundedField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        hintText: context.tr('login.otpHint'),
                        icon: Icons.lock_rounded,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            const SizedBox(height: 16),
            _GradientButton(
              label: isOtpSent
                  ? context.tr('login.verifyOtp')
                  : context.tr('login.sendOtp'),
              onTap: _sendOrVerifyOtp,
            ),
            if (isMobileVerified) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('register.mobileVerifiedNext'),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputStep({
    required String title,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            _RoundedField(
              hintText: hint,
              icon: Icons.edit_rounded,
              onChanged: onChanged,
            ),
            const SizedBox(height: 20),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCityStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('register.cityPrompt'),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCity,
              items: _indianCities
                  .map(
                    (cityName) => DropdownMenuItem(
                      value: cityName,
                      child: Text(cityName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                  city = value ?? '';
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_city_rounded),
                hintText: context.tr('register.cityHint'),
                filled: true,
                fillColor: AppTheme.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNirbhayaStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('register.enableTrata'),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('register.enableTrataDesc'),
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppTheme.primaryNavy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('register.activateTrata'),
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: nirbhayaMode,
                    activeColor: AppTheme.primaryNavy,
                    onChanged: (val) {
                      setState(() {
                        nirbhayaMode = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              context.tr('register.allSet'),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('register.successSubtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 16),
            _GradientButton(
              label: context.tr('register.goHome'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return _GradientButton(
      label: context.tr('register.continue'),
      onTap: nextPage,
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final inactive = AppTheme.border(
      context,
    ).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.6 : 1);
    return Row(
      children: List.generate(total, (index) {
        final isActive = index <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 6,
          width: isActive ? 30 : 16,
          margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryNavy : inactive,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int? maxLength;
  final String hintText;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const _RoundedField({
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    required this.hintText,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
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
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
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
              color: AppTheme.primaryNavy.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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
