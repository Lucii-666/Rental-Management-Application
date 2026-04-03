import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/identity_model.dart';
import '../../models/notification_model.dart';
import '../../utils/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'dart:io';

class IdentityUploadScreen extends StatefulWidget {
  const IdentityUploadScreen({super.key});

  @override
  State<IdentityUploadScreen> createState() => _IdentityUploadScreenState();
}

class _IdentityUploadScreenState extends State<IdentityUploadScreen> {
  IdentityType _selectedType = IdentityType.aadhaar;
  bool _isUploading = false;
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Select Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.text(context))),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
                  child: Icon(Icons.camera_alt_outlined, color: AppTheme.primary(context)),
                ),
                title: const Text('Camera'),
                subtitle: Text('Take a photo now', style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
                  child: Icon(Icons.photo_library_outlined, color: AppTheme.primary(context)),
                ),
                title: const Text('Gallery'),
                subtitle: Text('Choose from your photos', style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUpload() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture an image of your ID')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final scout = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final user = authService.userModel;
    final uid = authService.currentUser!.uid;

    try {
      // 1. Upload image to Supabase Storage
      final downloadUrl = await storageService.uploadIdentityDoc(
        uid,
        _selectedType.name,
        _selectedImage!,
      );

      if (!mounted) return;

      if (downloadUrl != null) {
        // 2. Save identity document record to Firestore with status: pending
        final identityDoc = IdentityModel(
          userId: uid,
          userName: user?.name ?? '',
          docType: _selectedType,
          fileUrl: downloadUrl,
          status: IdentityStatus.pending,
          uploadedAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('identity_documents')
            .add(identityDoc.toMap());

        // 3. Notify the property owner (if tenant is linked to a property)
        if (user?.propertyId != null && user!.propertyId!.isNotEmpty) {
          final propDoc = await FirebaseFirestore.instance
              .collection('properties')
              .doc(user.propertyId)
              .get();

          if (propDoc.exists) {
            final ownerId = propDoc.data()?['ownerId'] as String?;
            if (ownerId != null) {
              await notificationService.sendNotification(
                NotificationModel(
                  id: '',
                  userId: ownerId,
                  title: 'Document Verification Request',
                  message: '${user.name} has uploaded a ${_selectedType.name.toUpperCase()} document for verification.',
                  type: 'identity_verification',
                  createdAt: DateTime.now(),
                ),
              );
            }
          }
        }

        if (mounted) {
          scout.showSnackBar(
            const SnackBar(
              content: Text('Document submitted for verification! Your owner will review it.'),
              backgroundColor: Colors.green,
            ),
          );
          nav.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        scout.showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final uid = authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: Column(
        children: [
          // Show current verification status
          if (uid != null) _buildStatusBanner(uid),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Government ID Verification',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a clear photo of your government-issued ID. Your property owner will review and verify it.',
                    style: TextStyle(color: AppTheme.subtext(context)),
                  ),
                  const SizedBox(height: 32),
                  Text('Select Document Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text(context))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<IdentityType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: IdentityType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _showSourcePicker,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor(context)),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_outlined, size: 48, color: AppTheme.subtext(context)),
                                const SizedBox(height: 12),
                                Text('Tap to upload or capture', style: TextStyle(color: AppTheme.subtext(context), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Camera or Gallery', style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _handleUpload,
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit for Verification'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('identity_documents')
          .where('userId', isEqualTo: uid)
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final doc = IdentityModel.fromMap(
          snapshot.data!.docs.first.data() as Map<String, dynamic>,
          snapshot.data!.docs.first.id,
        );

        Color statusColor;
        IconData statusIcon;
        String statusText;

        switch (doc.status) {
          case IdentityStatus.pending:
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_top_rounded;
            statusText = 'Your ${doc.docType.name.toUpperCase()} is under review';
          case IdentityStatus.verified:
            statusColor = Colors.green;
            statusIcon = Icons.verified_rounded;
            statusText = 'Your ${doc.docType.name.toUpperCase()} has been verified';
          case IdentityStatus.rejected:
            statusColor = Colors.red;
            statusIcon = Icons.cancel_rounded;
            statusText = 'Your ${doc.docType.name.toUpperCase()} was rejected';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: statusColor.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (doc.status == IdentityStatus.rejected && doc.rejectionReason != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    'Reason: ${doc.rejectionReason}',
                    style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
