import 'package:HireMe_Id/widgets/navbar_admin.dart';
import 'package:HireMe_Id/widgets/navbar_recruiter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:HireMe_Id/widgets/navbar_non_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/navbar_login.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Remember Me state
  var isRememberMe = true.obs;

  User? get currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    loadRememberedCredentials();
  }

  // Load email dan password yang disimpan
  Future<void> loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    isRememberMe.value = prefs.getBool('rememberMe') ?? false;
    if (isRememberMe.value) {
      String? email = prefs.getString('email');
      String? password = prefs.getString('password');
      if (email != null && password != null) {
        await login(email, password); // Auto-login jika Remember Me aktif
      }
    }
  }

  // Fungsi untuk toggle Remember Me
  void toggleRememberMe(bool value) {
    isRememberMe.value = value;
  }

  // Fungsi untuk login dengan email dan password// Login dengan email dan password
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Cek role dari Firestore
      final docSnapshot =
          await _firestore.collection('Accounts').doc(email).get();
      if (docSnapshot.exists) {
        final role = docSnapshot.data()?['role'] ?? '';

        // Navigasi sesuai role
        if (role == 'jobseeker') {
          Get.offAll(() => NavbarLoggedIn());
        } else if (role == 'recruiter') {
          Get.offAll(() => NavbarRecruiter());
        } else if (role == 'admin') {
          Get.offAll(() => NavbarAdmin());
        } else {
          throw Exception("Unknown role");
        }
      } else {
        throw Exception("Account not found in database");
      }

      // Simpan status login jika Remember Me aktif
      if (isRememberMe.value) {
        await _saveCredentials(email, password);
      }
    } catch (e) {
      _showErrorSnackbar("Failed to login", e.toString());
    }
  }

  // Fungsi registrasi untuk Job Seeker
  // ignore: non_constant_identifier_names
  Future<void> register_job(String email, String password) async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('Accounts').doc(email).set({
        'firstname': '',
        'lastname': '',
        'email_address': email,
        'phone_number': '',
        'address': '',
        'role': 'jobseeker',
        'created_at': FieldValue.serverTimestamp(),
      });

      await _saveLoginStatus();
      Get.offAll(() => NavbarLoggedIn());
    } catch (e) {
      _showErrorSnackbar("Failed to create job seeker account", e.toString());
    }
  }

  // Fungsi registrasi untuk Recruiter
  Future<void> register_recruiter(String email, String password) async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('Accounts').doc(email).set({
        'firstname': '',
        'lastname': '',
        'email_address': email,
        'phone_number': '',
        'address': '',
        'role': 'recruiter',
        'created_at': FieldValue.serverTimestamp(),
        'company_name': '', // Tambahan field untuk recruiter
        'company_position': '', // Tambahan field untuk recruiter
      });

      await _saveLoginStatus();
      Get.offAll(() => NavbarRecruiter());
    } catch (e) {
      _showErrorSnackbar("Failed to create recruiter account", e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        "Success",
        "Password reset email sent.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF6B34BE),
        colorText: Colors.white,
      );
    } catch (e) {
      _showErrorSnackbar("Failed to send reset email", e.toString());
    }
  }

  // Login dengan Google untuk Job Seeker
  Future<void> loginWithGoogle_job() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showErrorSnackbar("Login Cancelled", "No account selected.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Cek apakah user sudah ada di Firestore
        final docSnapshot =
            await _firestore.collection('Accounts').doc(user.email).get();

        if (!docSnapshot.exists) {
          // Jika belum ada, buat dokumen baru
          await _firestore.collection('Accounts').doc(user.email).set({
            'firstname': user.displayName?.split(' ').first ?? '',
            'lastname': user.displayName?.split(' ').last ?? '',
            'email_address': user.email,
            'phone_number': user.phoneNumber ?? '',
            'address': '',
            'role': 'jobseeker',
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        await _saveLoginStatus();
        Get.offAll(() => NavbarLoggedIn());
      } else {
        _showErrorSnackbar("Login Failed", "Google Sign-In failed.");
      }
    } catch (e) {
      _showErrorSnackbar("Failed to login with Google", e.toString());
    }
  }

  // Login dengan Google untuk Recruiter
  Future<void> loginWithGoogle_recruiter() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showErrorSnackbar("Login Cancelled", "No account selected.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Cek apakah user sudah ada di Firestore
        final docSnapshot =
            await _firestore.collection('Accounts').doc(user.email).get();

        if (!docSnapshot.exists) {
          // Jika belum ada, buat dokumen baru
          await _firestore.collection('Accounts').doc(user.email).set({
            'firstname': user.displayName?.split(' ').first ?? '',
            'lastname': user.displayName?.split(' ').last ?? '',
            'email_address': user.email,
            'phone_number': user.phoneNumber ?? '',
            'address': '',
            'role': 'recruiter',
            'created_at': FieldValue.serverTimestamp(),
            'company_name': '',
            'company_position': '',
          });
        }

        await _saveLoginStatus();
        Get.offAll(() => NavbarLoggedIn());
      } else {
        _showErrorSnackbar("Login Failed", "Google Sign-In failed.");
      }
    } catch (e) {
      _showErrorSnackbar("Failed to login with Google", e.toString());
    }
  }

  // Logout dan hapus data Remember Me
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _clearCredentials();
      Get.offAll(() => NavbarNonLogin());
    } catch (e) {
      _showErrorSnackbar("Failed to logout", e.toString());
    }
  }

  // Simpan email dan password ke SharedPreferences
  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', true);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  // Hapus email dan password dari SharedPreferences
  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await prefs.remove('email');
    await prefs.remove('password');
  }

  // Fungsi untuk menunjukkan error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
    );
  }
}

Future<void> _saveLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
}

Future<void> _clearLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isLoggedIn');
}

void _showErrorSnackbar(String title, String message) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
  );
}
