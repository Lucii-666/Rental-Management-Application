import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _floorsController = TextEditingController();
  final _notesController = TextEditingController();

  final List<File> _pickedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _floorsController.dispose();
    _notesController.dispose();
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
    final xf = await picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1280);
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
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.dividerColor(context),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Add Photos', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16,
                  color: AppTheme.text(context))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _sourceButton(Icons.photo_library_rounded,
                      'Gallery', AppTheme.primaryGradient, () {
                    Navigator.pop(context);
                    _pickImages();
                  })),
                  const SizedBox(width: 16),
                  Expanded(child: _sourceButton(Icons.camera_alt_rounded,
                      'Camera', AppTheme.cyanGradient, () {
                    Navigator.pop(context);
                    _pickFromCamera();
                  })),
                ],
              ),
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
        decoration: BoxDecoration(
            gradient: grad, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    // 1. Create property first to get an ID
    final tempProperty = PropertyModel(
      id: '',
      ownerId: authService.currentUser!.uid,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      description: _descriptionController.text.trim(),
      floors: int.tryParse(_floorsController.text),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final error = await propertyService.addProperty(tempProperty);
    if (error != null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    // 2. Upload images if any — get the newly created property's ID
    if (_pickedImages.isNotEmpty) {
      try {
        // Fetch the newly created property to get its Firestore ID
        final props = await propertyService
            .getPropertiesStream(authService.currentUser!.uid)
            .first;
        final newProp = props.firstWhere((p) => p.name == _nameController.text.trim(),
            orElse: () => props.last);

        final urls = <String>[];
        for (final img in _pickedImages) {
          final url = await storageService.uploadPropertyImage(newProp.id, img);
          if (url != null) urls.add(url);
        }

        if (urls.isNotEmpty) {
          await propertyService.updatePropertyImages(newProp.id, urls);
        }
      } catch (e) {
        debugPrint('Image upload error: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property created successfully!'),
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
        title: Text('Add Property',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppTheme.text(context))),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo picker section ──────────────────────────────────────
              _buildSectionLabel('Property Photos', optional: true),
              const SizedBox(height: 12),
              _buildImageGrid(),
              const SizedBox(height: 28),

              // ── Fields ────────────────────────────────────────────────────
              _buildSectionLabel('Property Name'),
              const SizedBox(height: 8),
              _buildField(_nameController, 'e.g. Royal Residency',
                  Icons.business_rounded),
              const SizedBox(height: 20),

              _buildSectionLabel('Address'),
              const SizedBox(height: 8),
              _buildField(_addressController, 'House No, Street, Landmark',
                  Icons.location_on_rounded, maxLines: 2),
              const SizedBox(height: 20),

              _buildSectionLabel('City'),
              const SizedBox(height: 8),
              _buildField(_cityController, 'e.g. Mumbai',
                  Icons.location_city_rounded),
              const SizedBox(height: 20),

              _buildSectionLabel('Description'),
              const SizedBox(height: 8),
              _buildField(_descriptionController, 'Describe your property',
                  Icons.description_rounded, maxLines: 3),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Floors', optional: true),
                    const SizedBox(height: 8),
                    _buildField(_floorsController, 'Optional',
                        Icons.layers_rounded,
                        keyboardType: TextInputType.number,
                        isRequired: false),
                  ],
                )),
              ]),
              const SizedBox(height: 20),

              _buildSectionLabel('Additional Notes', optional: true),
              const SizedBox(height: 8),
              _buildField(_notesController, 'Any extra details',
                  Icons.note_add_rounded, maxLines: 2, isRequired: false),
              const SizedBox(height: 36),

              // ── Submit button ─────────────────────────────────────────────
              _isLoading
                  ? Center(child: Column(children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text('Creating property...',
                          style: GoogleFonts.inter(color: AppTheme.subtext(context))),
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
                        child: Text('Create Property',
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
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file,
              width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
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
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.primary(context).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primary(context).withValues(alpha: 0.3),
              width: 1.5,
              style: BorderStyle.solid),
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
}
