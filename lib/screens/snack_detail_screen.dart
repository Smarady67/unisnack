import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller_profile_screen.dart';

class SnackDetailScreen extends StatefulWidget {
  final String docId;

  const SnackDetailScreen({super.key, required this.docId});

  @override
  State<SnackDetailScreen> createState() => _SnackDetailScreenState();
}

class _SnackDetailScreenState extends State<SnackDetailScreen> {
  int _quantity = 1;
  bool _isOrdering = false;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final available = (data['amount'] ?? 0) - (data['sold'] ?? 0);
    if (available <= 0) { _showMessage('This snack is sold out!', isError: true); return; }
    if (_quantity > available) { _showMessage('Only $available available!', isError: true); return; }
    if (data['userId'] == user.uid) { _showMessage('You cannot order your own snack!', isError: true); return; }

    setState(() => _isOrdering = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'snackId': widget.docId,
        'snackName': data['name'],
        'snackImage': data['imageUrl'],
        'price': data['price'],
        'quantity': _quantity,
        'totalPrice': (double.tryParse(data['price'].toString()) ?? 0) * _quantity,
        'buyerId': user.uid,
        'buyerName': user.displayName ?? 'User',
        'sellerId': data['userId'],
        'sellerName': data['username'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newSold = (data['sold'] ?? 0) + _quantity;
      final amount = data['amount'] ?? 0;

      await FirebaseFirestore.instance.collection('snacks').doc(widget.docId).update({'sold': FieldValue.increment(_quantity)});

      // Notify seller of new order
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': data['userId'],
        'title': 'New Order Received!',
        'body': '${user.displayName ?? 'Someone'} ordered $_quantity x ${data['name']}',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify seller if sold out
      if (newSold >= amount) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': data['userId'],
          'title': 'Snack Sold Out!',
          'body': '${data['name']} is now sold out. Consider restocking!',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        _showMessage('Order placed successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showMessage('Failed to place order. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  Future<void> _saveEdit() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('snacks').doc(widget.docId).update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'amount': int.tryParse(_amountController.text.trim()) ?? 0,
      });
      if (mounted) { setState(() => _isEditing = false); _showMessage('Snack updated successfully!'); }
    } catch (e) {
      if (mounted) _showMessage('Failed to save. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSnack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Snack?'),
        content: const Text('Are you sure you want to delete this snack?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('snacks').doc(widget.docId).delete();
    if (mounted) Navigator.pop(context);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : const Color(0xFF02B4D8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('snacks').doc(widget.docId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF02B4D8)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Snack not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final user = FirebaseAuth.instance.currentUser;
          final isOwnSnack = data['userId'] == user?.uid;
          final available = (data['amount'] ?? 0) - (data['sold'] ?? 0);
          final price = double.tryParse(data['price'].toString()) ?? 0;
          final total = price * _quantity;
          final imageUrl = data['imageUrl'] as String?;
          final likes = List<String>.from(data['likes'] ?? []);
          final likeCount = likes.length;

          if (!_isEditing) {
            _nameController.text = data['name'] ?? '';
            _descriptionController.text = data['description'] ?? '';
            _priceController.text = data['price']?.toString() ?? '';
            _amountController.text = data['amount']?.toString() ?? '';
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, width: double.infinity, height: 280, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder())
                          : _imagePlaceholder(),
                      if (available <= 0)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                              child: const Text('SOLD OUT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 12, left: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.arrow_back, size: 14, color: Colors.black54),
                              SizedBox(width: 4),
                              Text('Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ]),
                          ),
                        ),
                      ),
                      if (isOwnSnack)
                        Positioned(
                          top: 12, right: 12,
                          child: Row(children: [
                            GestureDetector(
                              onTap: () => setState(() => _isEditing = !_isEditing),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                                child: Icon(_isEditing ? Icons.close : Icons.edit, size: 18, color: const Color(0xFF02B4D8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _deleteSnack,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              ),
                            ),
                          ]),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing) ...[
                          _buildEditField('Snack Name', _nameController),
                          const SizedBox(height: 12),
                          _buildEditField('Description', _descriptionController, maxLines: 3),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _buildEditField('Price', _priceController, keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildEditField('Amount', _amountController, keyboardType: TextInputType.number)),
                          ]),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity, height: 44,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveEdit,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF02B4D8), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text(_isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(data['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                              Row(children: [
                                const Icon(Icons.favorite, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text('$likeCount', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(data['description'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                          const SizedBox(height: 16),
                          Row(children: [
                            const Icon(Icons.attach_money, size: 16, color: Colors.black54),
                            Text('Price: \$${data["price"]} per Item', style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(available > 0 ? Icons.check_circle_outline : Icons.cancel_outlined, size: 16, color: available > 0 ? Colors.green : Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              available > 0 ? 'Available: $available' : 'Sold Out',
                              style: TextStyle(fontSize: 14, color: available > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(sellerId: data['userId'], sellerName: data['username'] ?? 'Seller'),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF02B4D8).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF02B4D8).withOpacity(0.2)),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF02B4D8).withOpacity(0.2),
                                child: Text((data['username'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF02B4D8), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(data['username'] ?? 'Seller', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const Text('Tap to view seller profile', style: TextStyle(fontSize: 11, color: Color(0xFF02B4D8))),
                              ])),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!isOwnSnack && available > 0) ...[
                          const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, color: const Color(0xFF02B4D8)),
                                Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add, size: 18), onPressed: _quantity < available ? () => setState(() => _quantity++) : null, color: const Color(0xFF02B4D8)),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ]),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              onPressed: _isOrdering ? null : () => _placeOrder(data),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF02B4D8), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: Text(_isOrdering ? 'Ordering...' : 'Order', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else if (isOwnSnack) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('This is your snack - tap edit to modify', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ]),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sold Out', style: TextStyle(color: Colors.red, fontSize: 13)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity, height: 280,
      color: const Color(0xFF02B4D8).withOpacity(0.1),
      child: const Icon(Icons.fastfood, color: Color(0xFF02B4D8), size: 64),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
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
            controller: controller, maxLines: maxLines, keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: InputBorder.none),
          ),
        ),
      ],
    );
  }
}
