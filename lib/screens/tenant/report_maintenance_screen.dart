import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReportMaintenanceScreen extends StatefulWidget {
  const ReportMaintenanceScreen({super.key});

  @override
  State<ReportMaintenanceScreen> createState() => _ReportMaintenanceScreenState();
}

class _ReportMaintenanceScreenState extends State<ReportMaintenanceScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final user = authService.userModel!;

    if (user.propertyId == null || user.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be assigned to a property and room to report issues.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Capture context before async gap
    final scoutMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Since we need ownerId, let's fetch property details first
    final property = await propertyService.getPropertyStream(user.propertyId!).first;


    final request = MaintenanceRequestModel(
      id: '', // Will be set by Firestore
      propertyId: user.propertyId!,
      roomId: user.roomId!,
      tenantId: user.uid,
      tenantName: user.name,
      title: _titleController.text,
      description: _descController.text,
      createdAt: DateTime.now(),
      ownerId: property.ownerId,
      imageUrl: '', // Will be updated
    );

    final error = await propertyService.submitMaintenanceRequest(request, imageFile: _selectedImage);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      scoutMessenger.showSnackBar(
        const SnackBar(content: Text('Maintenance request submitted successfully!')),
      );
      navigator.pop();
    } else {
      scoutMessenger.showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.build_circle_outlined, size: 60, color: AppTheme.primary(context)),
            const SizedBox(height: 24),
            const Text(
              'What needs fixing?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _titleController,
              decoration: AppTheme.inputDecoration('Title (e.g., Leaking Tap)', Icons.title),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration('Describe the issue in detail...', Icons.description),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor(context)),
                  image: _selectedImage != null 
                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    : null,
                ),
                child: _selectedImage == null ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Capture Photo of Issue', style: TextStyle(color: Colors.grey)),
                  ],
                ) : null,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
