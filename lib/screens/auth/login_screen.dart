import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'role_selection_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    final error = await authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isGoogleLoading = true);

    String? error = await authService.signInWithGoogle();

    if (!mounted) return;

    if (error == 'role_required') {
      final UserRole? role = await showDialog<UserRole>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.card(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Welcome! You are a...',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.text(context)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose your role to complete sign-up.',
                  style: TextStyle(color: AppTheme.subtext(context))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _roleDialogButton(
                      context,
                      'Owner',
                      Icons.business_center_outlined,
                      AppTheme.primary(context),
                      UserRole.owner,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _roleDialogButton(
                      context,
                      'Tenant',
                      Icons.person_outline,
                      AppTheme.accent(context),
                      UserRole.tenant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (role == null) {
        await authService.signOut();
        setState(() => _isGoogleLoading = false);
        return;
      }

      error = await authService.signInWithGoogle(role: role);
    }

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (error != null && error != 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget _roleDialogButton(BuildContext context, String label, IconData icon,
      Color color, UserRole role) {
    return InkWell(
      onTap: () => Navigator.pop(context, role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primary(context);

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen gradient background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0A0E1A),
                        const Color(0xFF111827),
                        AppTheme.darkBackgroundColor,
                      ]
                    : [
                        const Color(0xFF6366F1).withValues(alpha: 0.07),
                        const Color(0xFFEEF2FF),
                        Colors.white,
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Decorative top blob
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDark
                    ? AppTheme.darkPrimaryGradient
                    : AppTheme.primaryGradient,
              ),
              child: Opacity(
                opacity: isDark ? 0.12 : 0.08,
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 52),

                      // Logo with gradient glow ring
                      Center(
                        child: _GlowLogoWidget(primary: primary),
                      ),

                      const SizedBox(height: 40),

                      // "Welcome Back" gradient ShaderMask heading
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            (isDark
                                    ? AppTheme.darkPrimaryGradient
                                    : AppTheme.primaryGradient)
                                .createShader(bounds),
                        child: Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Log in to manage your properties.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.subtext(context),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(
                            color: AppTheme.text(context), fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Please enter your email';
                          if (!val.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(
                            color: AppTheme.text(context), fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.subtext(context),
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) => val!.isEmpty
                            ? 'Please enter your password'
                            : null,
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Gradient Login button
                      _GradientButton(
                        onPressed: _isLoading ? null : _handleEmailLogin,
                        isLoading: _isLoading,
                        label: 'Log In',
                        gradient: isDark
                            ? AppTheme.darkPrimaryGradient
                            : AppTheme.primaryGradient,
                      ),

                      const SizedBox(height: 28),

                      // OR divider
                      _OrDivider(),

                      const SizedBox(height: 28),

                      // Google button
                      _GoogleButton(
                        onPressed:
                            _isGoogleLoading ? null : _handleGoogleSignIn,
                        isLoading: _isGoogleLoading,
                        label: 'Continue with Google',
                      ),

                      const SizedBox(height: 36),

                      // Bottom register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: GoogleFonts.inter(
                              color: AppTheme.subtext(context),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const RoleSelectionScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                            ),
                            child: Text(
                              'Register Now',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _GlowLogoWidget extends StatelessWidget {
  final Color primary;
  const _GlowLogoWidget({required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppTheme.darkPrimaryColor.withValues(alpha: 0.6),
                      const Color(0xFFA78BFA).withValues(alpha: 0.3),
                    ]
                  : [
                      AppTheme.primaryColor.withValues(alpha: 0.5),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.45 : 0.30),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        // Inner white ring
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.card(context),
            border: Border.all(
              color: primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
        ),
        // Logo image
        ClipOval(
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final LinearGradient gradient;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null
            ? AppTheme.subtext(context).withValues(alpha: 0.2)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.dividerColor(context),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.dividerColor(context), width: 1),
            ),
            child: Text(
              'OR',
              style: GoogleFonts.inter(
                color: AppTheme.subtext(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.dividerColor(context),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GoogleButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primary(context),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        height: 22,
                        width: 22,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: AppTheme.text(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
