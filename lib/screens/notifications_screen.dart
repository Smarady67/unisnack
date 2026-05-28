import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('Delete all notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final snap = await FirebaseFirestore.instance.collection('notifications').where('userId', isEqualTo: user?.uid).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) { batch.delete(doc.reference); }
    await batch.commit();
  }

  @override
  void initState() {
    super.initState();
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('notifications').where('userId', isEqualTo: user!.uid).where('read', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) { batch.update(doc.reference, {'read': true}); }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 14, color: Colors.black54),
                          SizedBox(width: 4),
                          Text('Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('notifications').where('userId', isEqualTo: user?.uid).orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF02B4D8)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No notifications yet.', style: TextStyle(color: Colors.grey, fontSize: 14)));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final isRead = data['read'] ?? false;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFF02B4D8).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isRead ? Colors.grey.shade200 : const Color(0xFF02B4D8).withOpacity(0.3), width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF02B4D8).withOpacity(0.15),
                              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF02B4D8), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(data['body'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteNotification(docId),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                child: const Icon(Icons.close, size: 14, color: Colors.red),
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(color: Color(0xFF02B4D8), shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
