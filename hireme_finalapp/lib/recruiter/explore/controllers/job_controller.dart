import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class JobController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  var jobs = <Map<String, dynamic>>[].obs; // Observable untuk daftar pekerjaan
  var recruiterData = {}.obs; // Observable untuk data recruiter
  var isLoading = false.obs; // Observable untuk status loading
  final RxList<String> galleryImageUrls = <String>[].obs; // Daftar URL galeri
  late final Directory tempDir;

  @override
  void onInit() {
    super.onInit();
    initTemporaryDirectory();
  }

  Future<void> initTemporaryDirectory() async {
    try {
      tempDir = await getTemporaryDirectory();
      print("✅ Temporary directory initialized: ${tempDir.path}");
    } catch (e) {
      print("❗ Error initializing temporary directory: $e");
    }
  }

  // Fungsi menambahkan pekerjaan baru ke Firestore
  Future<void> addJob({
    required String position,
    required String location,
    required String jobType,
    required List<String> categories,
    required String jobDescription,
    required List<String> requirements,
    required List<String> facilities,
    required String salary,
    required String aboutCompany,
    required String industry,
    required String website,
    required List<String> companyGalleryPaths,
  }) async {
    progressValue.value = 0.0;

    Get.dialog(
      Center(
        child: Container(
          width: Get.width * 0.8,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: progressValue,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          color: const Color(0xFF6750A4),
                          backgroundColor:
                              const Color(0xFF6750A4).withOpacity(0.1),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Harap bersabar, ini memakan sedikit waktu...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Color(0xFF6750A4),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isLoading.value = true;

      // Dapatkan email pengguna saat ini
      final String? email = auth.currentUser?.email;
      if (email == null) {
        throw Exception("User not logged in.");
      }
      progressValue.value = 0.1;

      // Pastikan daftar pekerjaan sudah diambil
      if (jobs.isEmpty) {
        await fetchJobs();
      }
      progressValue.value = 0.2;

      // Validasi: Cek apakah job position sudah ada (case insensitive)
      final bool isDuplicate = jobs.any((job) =>
          (job['position'] ?? '').toString().toLowerCase() ==
          position.toLowerCase());
      if (isDuplicate) {
        throw Exception("Job position already exists.");
      }
      progressValue.value = 0.3;

      // Data recruiter harus tersedia
      if (recruiterData.isEmpty) {
        await fetchRecruiterData();
      }
      progressValue.value = 0.4;

      // Ambil data recruiter dari Firestore
      final companyName = recruiterData['company_name'] ?? 'Unknown Company';
      final companyLogoPath = recruiterData['profile_image'] ?? '';

      // Generate idjob
      final random = Random();
      final String idjob =
          List.generate(10, (_) => String.fromCharCode(65 + random.nextInt(26)))
              .join();

      // Buat data pekerjaan baru
      final newJob = {
        'idjob': idjob,
        'position': position,
        'companyName': companyName,
        'location': location,
        'companyLogoPath': companyLogoPath,
        'jobType': jobType,
        'categories': categories,
        'jobDetails': {
          'jobDescription': jobDescription,
          'requirements': requirements,
          'location': location,
          'facilities': facilities,
          'companyDetails': {
            'aboutCompany': aboutCompany,
            'website': website,
            'industry': industry,
            'companyGalleryPaths': companyGalleryPaths,
          },
        },
        'salary': salary,
        'isApplied': false,
        'applyStatus': 'inProcess',
        'isRecommended': false,
        'isSaved': false,
      };

      // Simpan pekerjaan ke Firestore
      final jobsDocRef = firestore.collection('Jobs').doc(email);
      await jobsDocRef.set(
        {
          'jobs': FieldValue.arrayUnion([newJob]),
        },
        SetOptions(merge: true),
      );
      progressValue.value = 0.5;

      // Tambahkan ke daftar jobs lokal
      jobs.add(newJob);

      // Proses cleaning file yang tidak digunakan
      print("🧹 Starting cleaning process...");
      await _cleanUnusedGalleryImages(email);
      progressValue.value = 1.0;

      Get.back(); // Tutup dialog
      Get.snackbar('Success', 'Job added successfully.');
    } catch (e) {
      Get.back(); // Tutup dialog jika terjadi error
      Get.snackbar('Error', 'Failed to add job: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi mengambil semua pekerjaan recruiter dari Firestore
  Future<void> fetchJobs() async {
    try {
      isLoading.value = true;

      final String? email = auth.currentUser?.email;
      if (email == null) {
        throw Exception("User not logged in.");
      }

      final jobsDoc = await firestore.collection('Jobs').doc(email).get();
      if (!jobsDoc.exists) {
        jobs.value = [];
      } else {
        final jobsData = jobsDoc.data()?['jobs'] as List<dynamic>? ?? [];
        jobs.value = jobsData.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch jobs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi memperbarui pekerjaan tertentu
  final progressValue = ValueNotifier<double>(0.0);

  Future<void> updateJob(int jobIndex, Map<String, dynamic> updatedFields) async {
  final String? email = auth.currentUser?.email;
  if (email == null) {
    throw Exception("User not logged in.");
  }

  final jobsDocRef = firestore.collection('Jobs').doc(email);
  final jobsSnapshot = await jobsDocRef.get();

  if (!jobsSnapshot.exists) {
    throw Exception("No jobs found for the current user.");
  }

  final List<dynamic> allJobs = jobsSnapshot.data()?['jobs'] ?? [];
  if (jobIndex < 0 || jobIndex >= allJobs.length) {
    throw Exception("Invalid job index.");
  }

  final Map<String, dynamic> jobData = Map<String, dynamic>.from(allJobs[jobIndex]);

  // Update hanya field yang diberikan tanpa mengganti seluruh struktur
  updatedFields.forEach((key, value) {
    if (key.contains('.')) {
      // Untuk nested key seperti "jobDetails.requirements"
      final keys = key.split('.');
      var currentMap = jobData;
      for (var i = 0; i < keys.length - 1; i++) {
        currentMap = currentMap[keys[i]] as Map<String, dynamic>;
      }
      currentMap[keys.last] = value;
    } else {
      // Untuk key di level atas
      jobData[key] = value;
    }
  });

  // Replace job yang diupdate di array
  allJobs[jobIndex] = jobData;

  // Simpan kembali ke Firestore
  await jobsDocRef.update({'jobs': allJobs});
}


  Future<void> updateJob2(
      int jobIndex, Map<String, dynamic> updatedFields) async {
    progressValue.value = 0.0;

    Get.dialog(
      Center(
        child: Container(
          width: Get.width * 0.8,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: progressValue,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          color: const Color(0xFF6750A4),
                          backgroundColor:
                              const Color(0xFF6750A4).withOpacity(0.1),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Harap bersabar, ini memakan sedikit waktu...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Color(0xFF6750A4),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isLoading.value = true;

      final String? email = auth.currentUser?.email;
      if (email == null) {
        throw Exception("User not logged in.");
      }
      progressValue.value = 0.1;

      final jobsDocRef = firestore.collection('Jobs').doc(email);

      // Ambil data asli dari Firestore
      final jobsDoc = await jobsDocRef.get();
      if (!jobsDoc.exists) {
        throw Exception("No jobs found for this recruiter.");
      }

      final jobsData = jobsDoc.data()?['jobs'] as List<dynamic>? ?? [];
      if (jobIndex >= jobsData.length) {
        throw Exception("Invalid job index.");
      }

      final originalJob = jobsData[jobIndex];

      // Bangun data baru dengan struktur dari `addJob`
      final updatedJob = <String, dynamic>{
        ...originalJob,
        ...updatedFields,
        'jobDetails': <String, dynamic>{
          ...originalJob['jobDetails'] ?? {},
          ...updatedFields['jobDetails'] ?? {},
          'companyDetails': <String, dynamic>{
            ...originalJob['jobDetails']?['companyDetails'] ?? {},
            ...updatedFields['jobDetails']?['companyDetails'] ?? {},
          },
        },
      };

      // Debugging: Print data untuk memastikan hasil akhir
      print("🧐 ORIGINAL JOB AT INDEX $jobIndex BEFORE UPDATE:");
      print(originalJob);
      print("✏️ FINAL UPDATED JOB DATA TO APPLY:");
      print(updatedJob);

      // Update data di Firestore
      final Map<String, dynamic> partialUpdate = {
        'jobs.$jobIndex': updatedJob,
      };
      await jobsDocRef.update(partialUpdate);
      progressValue.value = 0.5;

      print("🔥 PARTIAL FIRESTORE UPDATE SUCCESS!");

      Get.back(); // Close loading dialog
      Get.snackbar(
        'Success',
        'Job updated successfully.',
        icon: const Icon(Icons.check_circle, color: Colors.white),
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      print("❌ ERROR DURING PARTIAL UPDATE: $e");
      Get.snackbar(
        'Error',
        'Failed to update job: $e',
        icon: const Icon(Icons.error_outline, color: Colors.white),
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

// Fungsi untuk menggabungkan map
  Map<String, dynamic> _mergeMaps(
      Map<String, dynamic> original, Map<String, dynamic> updates) {
    final merged = Map<String, dynamic>.from(original);

    updates.forEach((key, value) {
      if (value is Map && original[key] is Map) {
        // Rekursif untuk merge nested map
        merged[key] = _mergeMaps(original[key] as Map<String, dynamic>,
            value as Map<String, dynamic>);
      } else {
        // Overwrite value
        merged[key] = value;
      }
    });

    return merged;
  }

  // Fungsi menghapus pekerjaan tertentu
  Future<void> deleteJob(int jobIndex) async {
    try {
      isLoading.value = true;

      final String? email = auth.currentUser?.email;
      if (email == null) {
        throw Exception("User not logged in.");
      }

      final jobsDocRef = firestore.collection('Jobs').doc(email);
      final jobsDoc = await jobsDocRef.get();

      if (!jobsDoc.exists) {
        throw Exception("No jobs found for this recruiter.");
      }

      final jobsData = jobsDoc.data()?['jobs'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> updatedJobs =
          jobsData.cast<Map<String, dynamic>>();

      if (jobIndex >= updatedJobs.length) {
        throw Exception("Invalid job index.");
      }

      updatedJobs.removeAt(jobIndex);

      await jobsDocRef.update({'jobs': updatedJobs});
      jobs.value = updatedJobs;

      Get.snackbar('Success', 'Job deleted successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete job: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi mengambil data recruiter dari Firestore
  Future<void> fetchRecruiterData() async {
    try {
      isLoading.value = true;

      final String? email = auth.currentUser?.email;
      if (email == null) {
        throw Exception("User not logged in.");
      }

      final recruiterDoc =
          await firestore.collection('Accounts').doc(email).get();

      if (recruiterDoc.exists) {
        recruiterData.value = recruiterDoc.data() ?? {};
      } else {
        recruiterData.value = {};
        throw Exception("Recruiter profile not found.");
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch recruiter data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi memilih dan mengunggah gambar
  Future<String?> pickAndUploadImage({
    required String email,
    int? jobIndex, // Argumen opsional untuk menentukan pekerjaan
  }) async {
    try {
      // Pilih file gambar dari galeri
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        return null; // User batal memilih gambar
      }

      final File file = File(pickedFile.path);

      // Buat nama unik untuk file
      final String uniqueFileName =
          DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = storage
          .ref()
          .child('gallery_images')
          .child(email)
          .child('$uniqueFileName.jpg');

      // Unggah file ke Firebase Storage
      await ref.putFile(file);

      // Dapatkan URL download dari file yang diunggah
      final String downloadUrl = await ref.getDownloadURL();

      print("✅ Image uploaded to $email folder: $downloadUrl");

      // Jika jobIndex diberikan, tambahkan URL ke galleryPaths pekerjaan tersebut
      if (jobIndex != null) {
        print("🔄 Updating galleryPaths for job at index $jobIndex...");

        final jobsDocRef = firestore.collection('Jobs').doc(email);
        final jobsDoc = await jobsDocRef.get();

        if (!jobsDoc.exists) {
          throw Exception("Jobs document not found.");
        }

        final jobsData = jobsDoc.data()?['jobs'] as List<dynamic>? ?? [];
        final List<Map<String, dynamic>> jobs =
            jobsData.cast<Map<String, dynamic>>();

        if (jobIndex >= jobs.length) {
          throw Exception("Invalid job index.");
        }

        // Ambil galleryPaths lama
        final List<String> currentGalleryPaths = jobs[jobIndex]['jobDetails']
                    ['companyDetails']['companyGalleryPaths']
                ?.cast<String>() ??
            [];

        // Tambahkan URL baru jika belum ada
        final updatedGalleryPaths = [...currentGalleryPaths, downloadUrl];

        // Perbarui jobs dengan galleryPaths terbaru
        jobs[jobIndex]['jobDetails']['companyDetails']['companyGalleryPaths'] =
            updatedGalleryPaths;

        await jobsDocRef.update({'jobs': jobs});

        print(
            "✅ Gallery paths updated successfully for job at index $jobIndex.");
      }

      // Kembalikan URL untuk kasus penggunaan lain
      return downloadUrl;
    } catch (e) {
      print("❗ Error uploading image: $e");
      return null;
    }
  }

// Fungsi untuk membersihkan file yang tidak terpakai
  Future<void> _cleanUnusedGalleryImages(String email) async {
    try {
      print("🧹 Cleaning started for email: $email");

      // Ambil semua URL yang digunakan dari Firestore
      final List<String> usedPaths = await _fetchUsedGalleryPaths(email);

      print("🔗 Used paths from Jobs:");
      for (final path in usedPaths) {
        print("- $path");
      }

      // Referensi ke folder email di Storage
      final folderRef = storage.ref().child('gallery_images').child(email);

      // Hapus file yang tidak digunakan
      print("🔍 Checking and cleaning unused files:");
      final ListResult result = await folderRef.listAll();

      for (final fileRef in result.items) {
        final String fileUrl = await fileRef.getDownloadURL();
        if (!usedPaths.contains(fileUrl)) {
          print("❌ Deleting unused file: ${fileRef.fullPath}");
          await fileRef.delete();
        } else {
          print("✅ File in use, keeping: ${fileRef.fullPath}");
        }
      }

      print("✅ Cleaning completed for email: $email");
    } catch (e) {
      print("❗ Error during cleaning: $e");
    }
  }

// Fungsi untuk mengambil semua URL gambar yang digunakan dari Firestore
  Future<List<String>> _fetchUsedGalleryPaths(String email) async {
    final List<String> usedPaths = [];

    try {
      final jobsDoc = await firestore.collection('Jobs').doc(email).get();

      if (jobsDoc.exists) {
        final jobsData = jobsDoc.data()?['jobs'] as List<dynamic>? ?? [];
        for (final job in jobsData) {
          final List<dynamic> galleryPaths = job['jobDetails']
                  ?['companyDetails']?['companyGalleryPaths'] ??
              [];
          usedPaths.addAll(galleryPaths.cast<String>());
        }
      }

      if (usedPaths.isEmpty) {
        print("❗ No used paths found for email: $email in Jobs.");
      }
    } catch (e) {
      print("❗ Error fetching used paths: $e");
    }

    return usedPaths;
  }
}
