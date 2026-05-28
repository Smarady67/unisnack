import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'snack_card.dart';

class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});

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
                child: Text(
                  'Liked Snacks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('snacks')
                    .where('likes', arrayContains: user?.uid)
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
                        'No liked snacks yet.\nTap the heart on any snack!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
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
                      return SnackCard(data: data, docId: docs[index].id);
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
