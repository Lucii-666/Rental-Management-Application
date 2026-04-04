import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).userModel;
    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    final error = await authService.updateProfile(
      name: _nameController.text,
      bio: _bioController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = AppTheme.isDark(context);
    final gradient = isDark ? AppTheme.darkPrimaryGradient : AppTheme.primaryGradient;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroHeader(user, gradient, isDark)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditCard(context, isDark),
                      const SizedBox(height: 16),
                      if (Provider.of<AuthService>(context).userModel?.isVerified ?? false)
                        _buildVerifiedBadge(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildCircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
            ),
          ),
          // Save button fixed at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSaveBar(gradient),
          ),
        ],
      ),
    );
  }

  // ── Hero gradient header ──────────────────────────────────────────────────

  Widget _buildHeroHeader(UserModel user, LinearGradient gradient, bool isDark) {
    final isOwner = user.role == UserRole.owner;
    final roleLabel = isOwner ? 'Property Owner' : 'Tenant';

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          child: Column(
            children: [
              // Avatar with gradient ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Gradient ring
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // White spacer (gives ring appearance)
                  Container(
                    width: 118,
                    height: 118,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  // Actual avatar
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                  // Camera edit button
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(user),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.cyanGradient,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Role badge pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOwner ? Icons.home_work_rounded : Icons.person_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Email / phone
              Text(
                user.phoneNumber ?? user.email ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image picker (exact original logic) ────────────────────────────────────

  Future<void> _pickAndUploadImage(UserModel user) async {
    final picker = ImagePicker();

    // Capture context BEFORE any async gap
    final storageService =
        Provider.of<StorageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final scout = ScaffoldMessenger.of(context);

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null) return;

    try {
      final downloadUrl =
          await storageService.uploadProfileImage(user.uid, File(image.path));

      if (!mounted) return;

      if (downloadUrl != null) {
        final error = await authService.updateProfile(photoUrl: downloadUrl);

        if (!mounted) return;
        setState(() => _isSaving = false);

        if (error == null) {
          scout.showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        } else {
          scout.showSnackBar(
            SnackBar(content: Text('Error updating profile: $error')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      scout.showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  // ── Edit fields card ────────────────────────────────────────────────────────

  Widget _buildEditCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.text(context),
            ),
          ),
          const SizedBox(height: 20),
          // Full Name
          _buildFieldLabel('Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.inter(
                fontSize: 15, color: AppTheme.text(context)),
            decoration: _premiumInputDecoration(
              hint: 'Enter your full name',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 20),
          // Bio
          _buildFieldLabel('Bio / About', Icons.notes_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 3,
            style: GoogleFonts.inter(
                fontSize: 15, color: AppTheme.text(context)),
            decoration: _premiumInputDecoration(
              hint: 'Tell owners a bit about yourself…',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary(context)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.subtext(context),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  InputDecoration _premiumInputDecoration({
    required String hint,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.subtext(context).withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppTheme.primaryColor.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTheme.primary(context),
          width: 1.5,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  // ── Verified badge ───────────────────────────────────────────────────────────

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.12),
            const Color(0xFF10B981).withValues(alpha: 0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.emeraldGradient,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity Verified',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
              Text(
                'Your account is fully verified',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Save bar ─────────────────────────────────────────────────────────────────

  Widget _buildSaveBar(LinearGradient gradient) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveProfile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            gradient: _isSaving ? null : gradient,
            color: _isSaving ? AppTheme.subtext(context).withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary(context).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Saving…',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Save Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Utility: small circle icon button ────────────────────────────────────────

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.25),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
