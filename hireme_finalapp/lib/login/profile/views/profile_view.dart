import 'package:HireMe_Id/login/profile/views/detail_profile_view.dart';
import 'package:HireMe_Id/login/profile/views/faq_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD6C5FF), Color(0xFF6B34BE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content Area
          SafeArea(
            child: FutureBuilder<bool?>(
              future: user != null
                  ? profileController
                      .fetchProfile(user.email!)
                      .then((_) => null)
                  : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Ambil hasil dari Get.back jika ada
                final result = Get.arguments as bool?;
                if (result == true && user != null) {
                  // Fetch ulang data jika result true
                  profileController.fetchProfile(user.email!);
                }

                // Konversi RxMap ke Map sebelum dilewatkan
                final profile =
                    Map<String, dynamic>.from(profileController.profileData);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildProfileCard(
                          profile), // Profile dilewatkan sebagai Map
                      _buildMenu(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16), // Padding konsisten
      child: Center(
        // Pusatkan teks di tengah
        child: Text(
          'Profile',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Picture Section
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFD6C5FF),
              backgroundImage: (profile['profile_image'] != null &&
                      profile['profile_image'].isNotEmpty)
                  ? NetworkImage(profile['profile_image'])
                  : null,
              child: (profile['profile_image'] == null ||
                      profile['profile_image'].isEmpty)
                  ? const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF6B34BE),
                    )
                  : null,
            ),
            const SizedBox(width: 20),

            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    (profile['firstname']?.isEmpty ?? true) &&
                            (profile['lastname']?.isEmpty ?? true)
                        ? 'Belum diatur'
                        : '${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B34BE),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    profile['email_address'] ?? 'No Email',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  // Edit Profile Button
                  TextButton(
                    onPressed: () async {
                      final result = await Get.to(() => DetailProfileView());
                      if (result == true) {
                        // Trigger FutureBuilder untuk refresh data
                        Get.forceAppUpdate();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Color(0xFF6B34BE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              // Tambahkan navigasi ke halaman notifikasi
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'FAQ',
            onTap: () {
              Get.to(() => const FaqPage());
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock,
            title: 'Two-Factor Authentication',
            onTap: () {
              // Tambahkan navigasi ke halaman 2FA
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () async {
  final bool? confirm = await showDialog<bool>(
    context: Get.context!,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B34BE), // Warna utama aplikasi
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(false); // Tidak logout
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B34BE), // Warna utama
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop(true); // Konfirmasi logout
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Warna teks putih
              ),
            ),
          ),
        ],
      );
    },
  );

  // Jika user mengkonfirmasi logout, jalankan logika logout
  if (confirm == true) {
    await authController.logout();
  }
},

          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF6B34BE),
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 20,
    );
  }
}
