import 'package:HireMe_Id/recruiter/applied/views/applied_view.dart';
import 'package:HireMe_Id/recruiter/explore/views/explore_view.dart';
import 'package:HireMe_Id/recruiter/home/views/home_view_recruiter.dart';
import 'package:HireMe_Id/recruiter/profile/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavbarRecruiter extends StatelessWidget {
  final RxInt _currentIndex = 0.obs; // State management dengan GetX

  // Daftar halaman yang akan ditampilkan berdasarkan tab
  final List<Widget> _pages = [
    HomeViewRecruiter(),
    ExploreView(),

    AppliedView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex.value != 0) {
          _currentIndex.value = 0; // Jika bukan di tab pertama, pindah ke tab pertama
          return false; // Jangan keluar dari aplikasi
        }
        return true; // Keluar dari aplikasi jika di tab pertama
      },
      child: Scaffold(
        body: Obx(() => _pages[_currentIndex.value]), // Menampilkan halaman berdasarkan index
        bottomNavigationBar: Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.white, // Latar belakang putih untuk navigasi
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex.value,
              onTap: (index) {
                _currentIndex.value = index; // Mengubah index saat tab ditekan
              },
              backgroundColor: Colors.transparent,
              elevation: 0, // Menghilangkan bayangan default
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF6B34BE), // Warna ungu untuk ikon terpilih
              unselectedItemColor: Colors.grey[500], // Warna abu untuk ikon tidak terpilih
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 11,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  activeIcon: Icon(Icons.work),
                  label: 'Applied',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
