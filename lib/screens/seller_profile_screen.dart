import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'snack_card.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == sellerId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back,
                              size: 14, color: Colors.black54),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOwnProfile ? 'My Store' : '$sellerName\'s Store',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Seller Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF02B4D8).withOpacity(0.15),
              child: Text(
                sellerName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF02B4D8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sellerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // Seller class/major from Firestore
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(sellerId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final cls = data['class'] ?? '';
                  final major = data['major'] ?? '';
                  if (cls.isNotEmpty || major.isNotEmpty) {
                    return Text(
                      [cls, major].where((s) => s.isNotEmpty).join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),

            // Snacks list
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Snacks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('snacks')
                    .where('userId', isEqualTo: sellerId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF02B4D8)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No snacks posted yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final isSoldOut =
                          (data['amount'] ?? 0) - (data['sold'] ?? 0) <= 0;

                      return Stack(
                        children: [
                          SnackCard(data: data, docId: docId, showLike: false),
                          // Delete button for own snacks that are sold out
                          if (isOwnProfile && isSoldOut)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Remove Snack?'),
                                      content: const Text(
                                          'This snack is sold out. Remove it?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await FirebaseFirestore.instance
                                        .collection('snacks')
                                        .doc(docId)
                                        .delete();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
