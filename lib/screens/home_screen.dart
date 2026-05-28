import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_snack_screen.dart';
import 'liked_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'snack_card.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const OrdersScreen(),
    const LikedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF02B4D8),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 32), activeIcon: Icon(Icons.add_circle, size: 32), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Liked'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black87),
                    onPressed: () {
                      showSearch(context: context, delegate: SnackSearchDelegate());
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'UniSnack',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF02B4D8)),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('userId', isEqualTo: user?.uid)
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data?.docs.length ?? 0;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('What do you want to eat?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PostSnackScreen()));
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02B4D8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('snacks').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF02B4D8)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No snacks posted yet.\nBe the first to post!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      return SnackCard(data: data, docId: docId);
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

class SnackSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Search for snacks...', style: TextStyle(color: Colors.grey)));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('snacks').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF02B4D8)));
        }
        final results = snapshot.data!.docs.where((doc) {
          final name = (doc.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
        if (results.isEmpty) {
          return const Center(child: Text('No snacks found.', style: TextStyle(color: Colors.grey)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return SnackCard(data: data, docId: doc.id);
          }).toList(),
        );
      },
    );
  }
}
