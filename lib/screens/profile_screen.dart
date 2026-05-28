import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_screen.dart';
import 'snack_card.dart';
import 'forgot_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _classController = TextEditingController();
  final _majorController = TextEditingController();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _classController.dispose();
    _majorController.dispose();
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    setState(() => _isSaving = true);
    try {
      if (newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'class': _classController.text.trim(),
        'major': _majorController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF02B4D8)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _currentPasswordController.clear();
      _newPasswordController.clear();

      if (mounted) {
        setState(() => _isChangingPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Color(0xFF02B4D8)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Failed to change password.';
        if (e.code == 'wrong-password') msg = 'Current password is incorrect.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePost(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this snack?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('snacks').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted.'), backgroundColor: Color(0xFF02B4D8)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete. Try again.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: _logout),
                ],
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFF02B4D8).withOpacity(0.15),
                child: Text(
                  (user?.displayName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF02B4D8)),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile fields
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    if (!_isEditing) {
                      _classController.text = data['class'] ?? '';
                      _majorController.text = data['major'] ?? '';
                      _nameController.text = user.displayName ?? '';
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        _buildField(label: 'Display Name', controller: _nameController, enabled: true, hint: 'Your name'),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(child: _buildField(label: 'Class', controller: _classController, enabled: _isEditing, hint: 'e.g. Year 2')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(label: 'Major', controller: _majorController, enabled: _isEditing, hint: 'e.g. CS')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isEditing = false),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF02B4D8), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(_isSaving ? 'Saving...' : 'Save'),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF02B4D8),
                              side: const BorderSide(color: Color(0xFF02B4D8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Change Password section
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const SizedBox(height: 12),

              if (_isChangingPassword) ...[
                _buildPasswordField(
                  label: 'Current Password',
                  controller: _currentPasswordController,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  hint: 'Enter current password',
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  hint: 'Enter new password',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    },
                    child: const Text('Forgot password?', style: TextStyle(fontSize: 12, color: Color(0xFF02B4D8), fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          setState(() => _isChangingPassword = false);
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _changePassword,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF02B4D8), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(_isSaving ? 'Saving...' : 'Change'),
                      ),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isChangingPassword = true),
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text('Change Password'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF02B4D8),
                      side: const BorderSide(color: Color(0xFF02B4D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),

              // My Posts
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('My Posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('snacks')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF02B4D8)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('You have not posted any snacks yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      return Stack(
                        children: [
                          SnackCard(data: data, docId: docId),
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () => _deletePost(context, docId),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, bool enabled = false, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF02B4D8), fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(color: enabled ? const Color(0xFFEFEFEF) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller, enabled: enabled,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none, hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool obscure, required VoidCallback onToggle, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF02B4D8), fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFEFEFEF), borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller, obscureText: obscure,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none, hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
