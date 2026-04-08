import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/room_model.dart';
import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class PropertyExplorerScreen extends StatefulWidget {
  final String propertyId;
  const PropertyExplorerScreen({super.key, required this.propertyId});

  @override
  State<PropertyExplorerScreen> createState() => _PropertyExplorerScreenState();
}

class _PropertyExplorerScreenState extends State<PropertyExplorerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyService = Provider.of<PropertyService>(context);
    final dark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: StreamBuilder<PropertyModel>(
        stream: propertyService.getPropertyStream(widget.propertyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: AppTheme.bg(context),
              appBar: AppBar(backgroundColor: AppTheme.bg(context), elevation: 0),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final property = snapshot.data!;

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(property, dark),
                SliverToBoxAdapter(child: _buildPropertyInfo(property)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Available Rooms',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(context),
                      ),
                    ),
                  ),
                ),
                StreamBuilder<List<RoomModel>>(
                  stream: propertyService.getRoomsStream(widget.propertyId),
                  builder: (context, roomSnapshot) {
                    if (!roomSnapshot.hasData) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }
                    final rooms = roomSnapshot.data!;
                    if (rooms.isEmpty) {
                      return SliverToBoxAdapter(child: _buildEmptyRooms());
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRoomCard(rooms[index]),
                          childCount: rooms.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(PropertyModel property, bool dark) {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: AppTheme.bg(context),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: dark
                ? AppTheme.darkPrimaryGradient
                : AppTheme.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_city_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            property.city,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.address,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(PropertyModel property) {
    if (property.description.isEmpty) return const SizedBox.shrink();
    final dark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow(context),
          border: dark
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: dark
                    ? AppTheme.darkPrimaryGradient
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                property.description,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.subtext(context),
                    height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRooms() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: Icon(Icons.meeting_room_outlined,
                size: 48, color: AppTheme.subtext(context)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Rooms Available',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context)),
          ),
          const SizedBox(height: 8),
          Text(
            "The owner hasn't added any rooms yet.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.subtext(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final isFull = room.currentOccupancy >= room.maxOccupancy;
    final occupancyRatio = room.maxOccupancy > 0
        ? room.currentOccupancy / room.maxOccupancy
        : 0.0;
    final dark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow(context),
        border: dark
            ? null
            : Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.imageUrls.isNotEmpty) _buildImageCarousel(room.imageUrls),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Room ${room.roomNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: dark
                            ? AppTheme.darkPrimaryGradient
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${room.rentAmount.toStringAsFixed(0)}/mo',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOccupancyRow(
                    room.currentOccupancy, room.maxOccupancy, occupancyRatio, isFull),
                if (room.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    room.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.subtext(context),
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (room.extraFees.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildExtraFeesChips(room.extraFees),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isFull
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.subtext(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.block_rounded,
                                    color: AppTheme.subtext(context), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Room Full',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.subtext(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showRoomRequestSheet(room);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: dark
                                  ? AppTheme.darkPrimaryGradient
                                  : AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary(context)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Request Room',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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

  Widget _buildImageCarousel(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.card(context),
                    child: Icon(Icons.broken_image_rounded,
                        color: AppTheme.subtext(context), size: 40),
                  ),
                );
              },
            ),
            if (imageUrls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imageUrls.length,
                    (i) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyRow(
      int current, int max, double ratio, bool isFull) {
    Color barColor;
    Color badgeColor;
    if (isFull) {
      barColor = const Color(0xFFEF4444);
      badgeColor = const Color(0xFFEF4444);
    } else if (ratio > 0.6) {
      barColor = const Color(0xFFF59E0B);
      badgeColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFF10B981);
      badgeColor = const Color(0xFF10B981);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_rounded,
                size: 15, color: AppTheme.subtext(context)),
            const SizedBox(width: 6),
            Text(
              '$current/$max occupied',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.subtext(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFull ? 'Full' : 'Available',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor:
                AppTheme.subtext(context).withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraFeesChips(List<Map<String, dynamic>> fees) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: fees.map((fee) {
        final name = fee['name']?.toString() ?? '';
        final amount = fee['amount'];
        final label = amount != null ? '$name ₹$amount' : name;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.primary(context).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 12, color: AppTheme.primary(context)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary(context),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showRoomRequestSheet(RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoomRequestSheet(
        room: room,
        propertyId: widget.propertyId,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Request Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RoomRequestSheet extends StatefulWidget {
  final RoomModel room;
  final String propertyId;

  const _RoomRequestSheet({
    required this.room,
    required this.propertyId,
  });

  @override
  State<_RoomRequestSheet> createState() => _RoomRequestSheetState();
}

class _RoomRequestSheetState extends State<_RoomRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _maritalStatus;
  bool _loading = false;

  static const _maritalOptions = ['Single', 'Married', 'Divorced', 'Widowed'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).userModel;
    if (user?.email != null) _emailCtrl.text = user!.email!;
    if (user?.phoneNumber != null) _phoneCtrl.text = user!.phoneNumber!;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.subtext(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => (dark
                        ? AppTheme.darkPrimaryGradient
                        : AppTheme.primaryGradient)
                    .createShader(b),
                child: Text(
                  'Request Room ${widget.room.roomNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fill in your details so the owner can review your request.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.subtext(context)),
              ),
              const SizedBox(height: 24),
              _buildField(
                controller: _phoneCtrl,
                label: 'Mobile Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (v.trim().length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email address is required';
                  }
                  final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailReg.hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _ageCtrl,
                label: 'Age',
                icon: Icons.cake_rounded,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(v.trim());
                  if (age == null || age < 16 || age > 100) {
                    return 'Enter a valid age (16–100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildMaritalDropdown(dark),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: dark
                              ? AppTheme.darkPrimaryGradient
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: dark
                                ? AppTheme.darkPrimaryGradient
                                : AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary(context)
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Request',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final dark = AppTheme.isDark(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AppTheme.text(context), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            color: AppTheme.subtext(context), fontSize: 14),
        prefixIcon:
            Icon(icon, color: AppTheme.primary(context), size: 20),
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppTheme.dividerColor(context), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.primary(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildMaritalDropdown(bool dark) {
    return DropdownButtonFormField<String>(
      value: _maritalStatus,
      decoration: InputDecoration(
        labelText: 'Marital Status',
        labelStyle: GoogleFonts.inter(
            color: AppTheme.subtext(context), fontSize: 14),
        prefixIcon: Icon(Icons.favorite_border_rounded,
            color: AppTheme.primary(context), size: 20),
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppTheme.dividerColor(context), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.primary(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style:
          GoogleFonts.inter(color: AppTheme.text(context), fontSize: 14),
      dropdownColor: AppTheme.card(context),
      items: _maritalOptions
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s,
                    style: GoogleFonts.inter(
                        color: AppTheme.text(context), fontSize: 14)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _maritalStatus = v),
      validator: (v) =>
          v == null ? 'Please select your marital status' : null,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final authService =
        Provider.of<AuthService>(context, listen: false);
    final propertyService =
        Provider.of<PropertyService>(context, listen: false);
    final user = authService.userModel!;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final property =
        await propertyService.getPropertyStream(widget.propertyId).first;

    final error = await propertyService.sendRoomRequest(
      tenantId: user.uid,
      tenantName: user.name,
      propertyId: widget.propertyId,
      roomId: widget.room.id,
      roomNumber: widget.room.roomNumber,
      ownerId: property.ownerId,
      tenantPhone: _phoneCtrl.text.trim(),
      tenantEmail: _emailCtrl.text.trim(),
      tenantAge: int.tryParse(_ageCtrl.text.trim()) ?? 0,
      maritalStatus: _maritalStatus ?? '',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    navigator.pop();

    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Request sent successfully!',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $error',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
