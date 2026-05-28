import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'snack_detail_screen.dart';

class SnackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool showLike;

  const SnackCard({
    super.key,
    required this.data,
    required this.docId,
    this.showLike = true,
  });

  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('snacks').doc(docId);
    final likes = List<String>.from(data['likes'] ?? []);
    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
    }
    await ref.update({'likes': likes});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = likes.contains(user?.uid);
    final imageUrl = data['imageUrl'] as String?;
    final isSoldOut = data['sold'] == data['amount'] &&
        data['sold'] != null &&
        data['amount'] != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SnackDetailScreen(docId: docId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLiked
                ? const Color(0xFF02B4D8).withOpacity(0.4)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  // SOLD OUT overlay
                  if (isSoldOut)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: const Center(
                          child: Text(
                            'SOLD OUT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (showLike)
                          GestureDetector(
                            onTap: () => _toggleLike(context),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                          )
                        else
                          Text(
                            '${likes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${data["price"] ?? "0"} per Item',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${data["sold"] ?? 0}/${data["amount"] ?? 0}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF02B4D8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.fastfood, color: Color(0xFF02B4D8), size: 32),
    );
  }
}
