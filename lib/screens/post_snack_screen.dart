import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_background.dart';

class PostSnackScreen extends StatefulWidget {
  const PostSnackScreen({super.key});

  @override
  State<PostSnackScreen> createState() => _PostSnackScreenState();
}

class _PostSnackScreenState extends State<PostSnackScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  // Cloudinary credentials
  static const _cloudName = 'dzjgjcawu';
  static const _uploadPreset = 'unisnack_preset';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _imageBytes = file.bytes;
            _imageFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) _showError('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    try {
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: _imageFileName ?? 'image.jpg',
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        print('Cloudinary error: $responseBody');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _post() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = _priceController.text.trim();
    final amount = _amountController.text.trim();

    if (name.isEmpty ||
        description.isEmpty ||
        price.isEmpty ||
        amount.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (_imageBytes == null) {
      _showError('Please select an image.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please sign in again.');
        return;
      }

      // Upload to Cloudinary
      final imageUrl = await _uploadImageToCloudinary();
      if (imageUrl == null) {
        _showError('Failed to upload image. Please try again.');
        return;
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('snacks').add({
        'name': name,
        'description': description,
        'price': price,
        'amount': int.tryParse(amount) ?? 0,
        'sold': 0,
        'imageUrl': imageUrl,
        'likes': [],
        'userId': user.uid,
        'username': user.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snack posted successfully!'),
            backgroundColor: Color(0xFF02B4D8),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('Failed to post: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Post a Snack',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Share your snack with everyone!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 24),

          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF02B4D8).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: const Color(0xFF02B4D8).withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          _buildInputField(label: 'Snack Name', controller: _nameController),
          const SizedBox(height: 14),
          _buildInputField(
            label: 'Description',
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Price (\$)',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'Amount Available',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Center(
            child: SizedBox(
              width: 140,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _post,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02B4D8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isLoading ? 'Posting...' : 'Post',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isObscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF02B4D8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
