import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF02B4D8),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF02B4D8),
              tabs: const [
                Tab(text: 'My Orders'),
                Tab(text: 'Incoming Orders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('buyerId', isEqualTo: user?.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    emptyMessage: 'You have not ordered anything yet.',
                    isSeller: false,
                  ),
                  _OrdersList(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('sellerId', isEqualTo: user?.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    emptyMessage: 'No incoming orders yet.',
                    isSeller: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMessage;
  final bool isSeller;

  const _OrdersList({required this.stream, required this.emptyMessage, required this.isSeller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF02B4D8)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return OrderCard(data: data, docId: docId, isSeller: isSeller);
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isSeller;

  const OrderCard({super.key, required this.data, required this.docId, required this.isSeller});

  Future<void> _cancelOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('snacks').doc(data['snackId']).update({'sold': FieldValue.increment(-(data['quantity'] ?? 1))});
      await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled.'), backgroundColor: Color(0xFF02B4D8)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel. Try again.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _deleteOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Order?'),
        content: const Text('Remove this order from your history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted.'), backgroundColor: Color(0xFF02B4D8)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete. Try again.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _markAsCompleted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': 'completed'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as completed!'), backgroundColor: Color(0xFF02B4D8)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update. Try again.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['snackImage'] as String?;
    final status = data['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['snackName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(
                    isSeller ? 'Ordered by: ${data['buyerName'] ?? ''}' : 'Seller: ${data['sellerName'] ?? ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${data['quantity']} x \$${data['price']} = \$${(data['totalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status == 'pending' ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'pending' ? Colors.orange : Colors.green),
                        ),
                      ),
                      Row(
                        children: [
                          // Buyer: cancel if pending, delete if completed
                          if (!isSeller && status == 'pending')
                            GestureDetector(
                              onTap: () => _cancelOrder(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (!isSeller && status == 'completed')
                            GestureDetector(
                              onTap: () => _deleteOrder(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          // Seller: mark complete if pending, delete if completed
                          if (isSeller && status == 'pending')
                            GestureDetector(
                              onTap: () => _markAsCompleted(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Mark Complete', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (isSeller && status == 'completed') ...[
                            GestureDetector(
                              onTap: () => _deleteOrder(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(color: const Color(0xFF02B4D8).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.fastfood, color: Color(0xFF02B4D8), size: 28),
    );
  }
}
