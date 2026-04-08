import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/room_model.dart';
import '../../services/property_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import 'room_details_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final propertyService = Provider.of<PropertyService>(context, listen: false);

    return StreamBuilder<PropertyModel>(
      stream: propertyService.getPropertyStream(widget.property.id),
      initialData: widget.property,
      builder: (context, snapshot) {
        final property = snapshot.data!;

        return Scaffold(
          backgroundColor: AppTheme.bg(context),
          appBar: AppBar(
            backgroundColor: AppTheme.bg(context),
            elevation: 0,
            title: Text(property.name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: AppTheme.text(context))),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyImages(property),
                const SizedBox(height: 20),
                _buildPropertyInfo(property),
                const SizedBox(height: 24),
                _buildJoinCodeSection(property, propertyService),
                const SizedBox(height: 24),
                _buildHeader(context, property.id),
                const SizedBox(height: 16),
                _buildRoomsList(property.id, propertyService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyImages(PropertyModel property) {
    if (property.imageUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: property.imageUrls.length,
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(property.imageUrls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.card(context),
                child: Icon(Icons.broken_image_rounded,
                    color: AppTheme.subtext(context), size: 40),
              )),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppTheme.primary(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${property.address}, ${property.city}',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: AppTheme.text(context)),
                ),
              ),
            ],
          ),
          if (property.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(property.description,
                style: GoogleFonts.inter(
                    color: AppTheme.subtext(context), fontSize: 13)),
          ],
          if (property.floors != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.layers_rounded,
                  color: AppTheme.primary(context), size: 16),
              const SizedBox(width: 6),
              Text('${property.floors} floors',
                  style: GoogleFonts.inter(
                      color: AppTheme.subtext(context), fontSize: 13)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinCodeSection(PropertyModel property, PropertyService service) {
    final dark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.darkPrimaryGradient : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.glowShadow(context)],
      ),
      child: Column(
        children: [
          Text('Secure Join Code',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                property.joinCode ?? '------',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w800, letterSpacing: 6),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => service.updateJoinCode(property.id, 24),
              ),
            ],
          ),
          if (property.joinCodeExpiry != null)
            Text(
              'Expires: ${property.joinCodeExpiry.toString().split('.')[0]}',
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String propertyId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Rooms',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppTheme.text(context))),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRoomScreen(propertyId: propertyId),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text('Add Room',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsList(String propertyId, PropertyService service) {
    return StreamBuilder<List<RoomModel>>(
      stream: service.getRoomsStream(propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No rooms added yet.',
                  style: GoogleFonts.inter(color: AppTheme.subtext(context))),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final room = snapshot.data![index];
            return _buildRoomCard(room, propertyId);
          },
        );
      },
    );
  }

  Widget _buildRoomCard(RoomModel room, String propertyId) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomDetailsScreen(propertyId: propertyId, room: room),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor(context)),
          boxShadow: [AppTheme.softShadow(context)],
        ),
        child: Row(
          children: [
            if (room.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16)),
                child: Image.network(room.imageUrls.first,
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 80, height: 80,
                        color: AppTheme.primary(context).withValues(alpha: 0.1),
                        child: Icon(Icons.meeting_room_rounded,
                            color: AppTheme.primary(context)))),
              )
            else
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary(context).withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16)),
                ),
                child: Icon(Icons.meeting_room_rounded,
                    color: AppTheme.primary(context), size: 32),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${room.roomNumber}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15,
                          color: AppTheme.text(context))),
                  Text('₹${room.rentAmount.toStringAsFixed(0)}/month',
                      style: GoogleFonts.inter(
                          color: AppTheme.subtext(context), fontSize: 13)),
                  Text('${room.currentOccupancy}/${room.maxOccupancy} tenants',
                      style: GoogleFonts.inter(
                          color: AppTheme.subtext(context), fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(room.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(room.status,
                    style: GoogleFonts.inter(
                        color: _getStatusColor(room.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Full': return Colors.red;
      default: return Colors.orange;
    }
  }
}

// ─── Add Room Screen ──────────────────────────────────────────────────────────

class AddRoomScreen extends StatefulWidget {
  final String propertyId;
  const AddRoomScreen({super.key, required this.propertyId});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _rentController = TextEditingController();
  final _occupancyController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<File> _pickedImages = [];
  final List<Map<String, dynamic>> _extraFees = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _roomNumberController.dispose();
    _rentController.dispose();
    _occupancyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 75, maxWidth: 1280);
    if (picked.isEmpty) return;
    setState(() {
      for (final xf in picked) {
        if (_pickedImages.length < 6) _pickedImages.add(File(xf.path));
      }
    });
  }

  Future<void> _pickFromCamera() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final xf = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 75, maxWidth: 1280);
    if (xf == null) return;
    if (_pickedImages.length < 6) {
      setState(() => _pickedImages.add(File(xf.path)));
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() => _pickedImages.removeAt(index));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.dividerColor(context),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Add Photos',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 16,
                      color: AppTheme.text(context))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _sourceButton(
                    Icons.photo_library_rounded, 'Gallery',
                    AppTheme.primaryGradient, () {
                  Navigator.pop(context);
                  _pickImages();
                })),
                const SizedBox(width: 16),
                Expanded(child: _sourceButton(
                    Icons.camera_alt_rounded, 'Camera',
                    AppTheme.cyanGradient, () {
                  Navigator.pop(context);
                  _pickFromCamera();
                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, LinearGradient grad, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showAddFeeDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        title: Text('Add Extra Fee',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700,
                color: AppTheme.text(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              style: GoogleFonts.inter(color: AppTheme.text(context)),
              decoration: InputDecoration(
                labelText: 'Fee Name (e.g. Water)',
                labelStyle: GoogleFonts.inter(color: AppTheme.subtext(context)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppTheme.text(context)),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: GoogleFonts.inter(color: AppTheme.subtext(context)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppTheme.subtext(context)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary(context)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty &&
                  amountCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _extraFees.add({
                    'name': nameCtrl.text.trim(),
                    'amount': double.tryParse(amountCtrl.text.trim()) ?? 0.0,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: Text('Add', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    final newRoom = RoomModel(
      id: '',
      propertyId: widget.propertyId,
      roomNumber: _roomNumberController.text.trim(),
      rentAmount: double.tryParse(_rentController.text.trim()) ?? 0.0,
      maxOccupancy: int.tryParse(_occupancyController.text.trim()) ?? 1,
      createdAt: DateTime.now(),
      extraFees: _extraFees,
    );

    final roomId = await propertyService.addRoom(newRoom);

    if (roomId != null && _pickedImages.isNotEmpty) {
      try {
        final urls = <String>[];
        for (final img in _pickedImages) {
          final url = await storageService.uploadRoomImage(
              widget.propertyId, roomId, img);
          if (url != null) urls.add(url);
        }
        if (urls.isNotEmpty) {
          await propertyService.updateRoomImages(widget.propertyId, roomId, urls);
        }
      } catch (e) {
        debugPrint('Room image upload error: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Room added successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        title: Text('Add Room',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppTheme.text(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photos
              _buildSectionLabel('Room Photos', optional: true),
              const SizedBox(height: 12),
              _buildImageGrid(),
              const SizedBox(height: 28),

              // Room Number
              _buildSectionLabel('Room Name / Number'),
              const SizedBox(height: 8),
              _buildField(_roomNumberController, 'e.g. 101 or Ground Floor',
                  Icons.meeting_room_rounded),
              const SizedBox(height: 20),

              // Rent
              _buildSectionLabel('Monthly Rent'),
              const SizedBox(height: 8),
              _buildField(_rentController, 'e.g. 8000',
                  Icons.payments_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              // Max Occupancy
              _buildSectionLabel('Max Occupancy'),
              const SizedBox(height: 8),
              _buildField(_occupancyController, 'e.g. 2',
                  Icons.people_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              // Description
              _buildSectionLabel('Description', optional: true),
              const SizedBox(height: 8),
              _buildField(_descriptionController, 'Describe this room',
                  Icons.description_rounded, maxLines: 2, isRequired: false),
              const SizedBox(height: 24),

              // Extra Fees
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('Extra Fees', optional: true),
                  GestureDetector(
                    onTap: _showAddFeeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        Icon(Icons.add_rounded,
                            color: AppTheme.primary(context), size: 16),
                        const SizedBox(width: 4),
                        Text('Add Fee',
                            style: GoogleFonts.inter(
                                color: AppTheme.primary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
              if (_extraFees.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._extraFees.asMap().entries.map((e) => _buildFeeChip(e.value, e.key)),
              ],
              const SizedBox(height: 36),

              // Submit
              _isLoading
                  ? Center(child: Column(children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text('Creating room...',
                          style: GoogleFonts.inter(
                              color: AppTheme.subtext(context))),
                    ]))
                  : GestureDetector(
                      onTap: _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: dark
                              ? AppTheme.darkPrimaryGradient
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.glowShadow(context)],
                        ),
                        alignment: Alignment.center,
                        child: Text('Create Room',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, {bool optional = false}) {
    return Row(children: [
      Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14,
              color: AppTheme.text(context))),
      if (optional) ...[
        const SizedBox(width: 6),
        Text('(optional)',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.subtext(context))),
      ],
    ]);
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: AppTheme.text(context), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary(context)),
      ),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._pickedImages.asMap().entries.map((e) => _buildImageThumb(e.value, e.key)),
        if (_pickedImages.length < 6) _buildAddImageButton(),
      ],
    );
  }

  Widget _buildImageThumb(File file, int index) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
      ),
      Positioned(
        top: 4, right: 4,
        child: GestureDetector(
          onTap: () => _removeImage(index),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ),
    ]);
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AppTheme.primary(context).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primary(context).withValues(alpha: 0.3),
              width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: AppTheme.primary(context), size: 28),
            const SizedBox(height: 4),
            Text('Add Photo',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.primary(context),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeChip(Map<String, dynamic> fee, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Row(children: [
        Icon(Icons.receipt_long_rounded,
            color: AppTheme.primary(context), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(fee['name'] ?? '',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500, color: AppTheme.text(context))),
        ),
        Text('₹${(fee['amount'] as double).toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppTheme.primary(context))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _extraFees.removeAt(index)),
          child: Icon(Icons.close_rounded,
              size: 18, color: AppTheme.subtext(context)),
        ),
      ]),
    );
  }
}
