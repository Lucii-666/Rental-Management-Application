import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
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
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final propertyService = Provider.of<PropertyService>(context, listen: false);

      final newProperty = PropertyModel(
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

      final error = await propertyService.addProperty(newProperty);
      
      setState(() => _isLoading = false);

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Add New Property', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Property Name',
                hint: 'e.g. Royal Residency',
                icon: Icons.business_rounded,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'House No, Street, Landmark',
                icon: Icons.location_on_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'e.g. Mumbai',
                icon: Icons.location_city_rounded,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your property',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _floorsController,
                      label: 'Floors',
                      hint: 'Optional',
                      icon: Icons.layers_rounded,
                      keyboardType: TextInputType.number,
                      isRequired: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Placeholder for alignment
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hint: 'Any other details',
                icon: Icons.note_add_rounded,
                maxLines: 2,
                isRequired: false,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Create Property'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.secondary(context))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary(context)),
          ),
          validator: isRequired 
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null,
        ),
      ],
    );
  }
}
