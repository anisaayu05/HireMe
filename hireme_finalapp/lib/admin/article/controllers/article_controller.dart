import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ArticleController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  var title = ''.obs;
  var content = ''.obs;
  var mediaFiles = <File>[].obs; // Media yang dipilih oleh user
  var mediaUrls = <String>[].obs; // URL media lama dari artikel

  // Untuk artikel
  var articles = <Map<String, dynamic>>[].obs;
  var filteredArticles = <Map<String, dynamic>>[].obs;

  // Gunakan TextEditingController untuk Search
  final TextEditingController searchController = TextEditingController();

  // State untuk loading
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchArticles();

    // Listener untuk search input
    searchController.addListener(() {
      filterArticles(searchController.text);
    });
  }

  // Fungsi untuk mengambil data artikel dari Firestore
  Future<void> fetchArticles() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('article').get();
      articles.assignAll(
        snapshot.docs.map((doc) => {
              'id': doc.id,
              'title': doc['title'],
              'content': doc['content'],
              'media': doc['media'] ?? [],
              'createdAt': doc['createdAt'],
            }).toList(),
      );
      filteredArticles.assignAll(articles);
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data artikel: $e');
    }
  }

  // Fungsi untuk filter artikel berdasarkan judul
  void filterArticles(String query) {
    if (query.isEmpty) {
      filteredArticles.assignAll(articles);
    } else {
      filteredArticles.assignAll(
        articles.where((article) => article['title']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase())),
      );
    }
  }

  // Fungsi untuk menyimpan artikel
  Future<void> saveArticle() async {
    try {
      isLoading.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      List<String> mediaUrls = await _uploadMediaFiles();

      await _firestore.collection('article').add({
        'title': title.value,
        'content': content.value,
        'media': mediaUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      fetchArticles();
      Get.back(); // Tutup loading dialog
      Get.snackbar('Sukses', 'Artikel berhasil disimpan');
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Gagal menyimpan artikel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi untuk mengedit artikel
  Future<void> editArticle(String articleId) async {
    try {
      isLoading.value = true; // Set state ke loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Upload file baru ke Firebase Storage
      List<String> newMediaUrls = await _uploadMediaFiles();

      // Gabungkan media lama yang tidak dihapus dengan media baru
      List<String> updatedMediaUrls = [...mediaUrls, ...newMediaUrls];

      // Update artikel di Firestore
      await _firestore.collection('article').doc(articleId).update({
        'title': title.value,
        'content': content.value,
        'media': updatedMediaUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      fetchArticles(); // Refresh data artikel
      Get.back(); // Tutup loading dialog
      Get.snackbar('Sukses', 'Artikel berhasil diperbarui');
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Gagal memperbarui artikel: $e');
    } finally {
      isLoading.value = false; // Selesai loading
    }
  }

  // Fungsi untuk menghapus artikel
  Future<void> deleteArticle(String articleId) async {
    try {
      isLoading.value = true;

      DocumentSnapshot doc =
          await _firestore.collection('article').doc(articleId).get();
      List<String> mediaUrls = List<String>.from(doc['media'] ?? []);

      // Hapus file dari Firebase Storage
      for (var url in mediaUrls) {
        await _storage.refFromURL(url).delete();
      }

      await _firestore.collection('article').doc(articleId).delete();

      fetchArticles(); // Refresh data artikel
      Get.snackbar('Sukses', 'Artikel berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus artikel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi untuk memilih file media
  Future<void> pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      mediaFiles.addAll(pickedFiles.map((file) => File(file.path)));
    }
  }

  // Helper: Upload file media ke Firebase Storage
  Future<List<String>> _uploadMediaFiles() async {
    List<String> uploadedUrls = [];
    for (var file in mediaFiles) {
      String fileName =
          'article/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      UploadTask uploadTask = _storage.ref(fileName).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      uploadedUrls.add(downloadUrl);
    }
    return uploadedUrls;
  }
}
