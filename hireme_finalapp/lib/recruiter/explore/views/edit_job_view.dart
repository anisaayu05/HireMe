import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/job_controller.dart';
import 'package:HireMe_Id/data/job_categories.dart';

class EditJobView extends StatelessWidget {
  final JobController jobController = Get.put(JobController());

  // Controllers untuk form fields
  final TextEditingController positionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController jobDescriptionController =
      TextEditingController();
  final TextEditingController requirementsController = TextEditingController();
  final TextEditingController facilitiesController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController aboutCompanyController = TextEditingController();
  final TextEditingController industryController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final RxString selectedJobType = ''.obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxList<String> galleryImageUrls = <String>[].obs;

  // Job index dari Get.arguments
  late final int jobIndex;
  late final Map<String, dynamic> jobData;

  EditJobView() {
    final arguments = Get.arguments;
    jobIndex = arguments['index'];
    jobData = arguments['job'];
    _initializeFields();
  }

  void _initializeFields() {
    positionController.text = jobData['position'] ?? '';
    locationController.text = jobData['location'] ?? '';
    jobDescriptionController.text =
        jobData['jobDetails']['jobDescription'] ?? '';
    requirementsController.text =
        (jobData['jobDetails']['requirements'] ?? []).join(', ');
    facilitiesController.text =
        (jobData['jobDetails']['facilities'] ?? []).join(', ');
    salaryController.text = jobData['salary'] ?? '';
    aboutCompanyController.text =
        jobData['jobDetails']['companyDetails']['aboutCompany'] ?? '';
    industryController.text =
        jobData['jobDetails']['companyDetails']['industry'] ?? '';
    websiteController.text =
        jobData['jobDetails']['companyDetails']['website'] ?? '';
    selectedJobType.value = jobData['jobType'] ?? '';
    selectedCategories.value =
        List<String>.from(jobData['categories'] ?? <String>[]);
    galleryImageUrls.value =
        List<String>.from(jobData['jobDetails']['companyDetails']
                ['companyGalleryPaths'] ??
            []);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (jobController.recruiterData.isEmpty) {
      jobController.fetchRecruiterData();
    }
  });
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
  title: const Text(
    'Edit Job',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: Colors.black,
    ),
  ),
  backgroundColor: Colors.white,
  elevation: 1,
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () => Get.back(),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh, color: Color(0xFF6B34BE)),
      tooltip: 'Refresh Data',
      onPressed: () async {
        try {
          // Tampilkan loading dialog
          Get.dialog(
            Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF6B34BE),
              ),
            ),
            barrierDismissible: false,
          );

          // Panggil fungsi refresh data
          final jobController = Get.find<JobController>();
          await jobController.fetchRecruiterData();
          await jobController.fetchJobs();

          // Tutup loading dialog
          Get.back();

          Get.snackbar(
            'Success',
            'Data successfully refreshed.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.black,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        } catch (e) {
          Get.back(); // Tutup loading dialog jika terjadi error
          Get.snackbar(
            'Error',
            'Failed to refresh data: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            colorText: Colors.black,
            icon: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
      },
    ),
  ],
  bottom: const TabBar(
    labelColor: Color(0xFF6B34BE),
    unselectedLabelColor: Colors.grey,
    indicatorColor: Color(0xFF6B34BE),
    tabs: [
      Tab(text: 'Company', icon: Icon(Icons.business)),
      Tab(text: 'Job Details', icon: Icon(Icons.work)),
      Tab(text: 'Additional', icon: Icon(Icons.more_horiz)),
    ],
  ),
),

        body: TabBarView(
          children: [
            _buildCompanyTab(),
            _buildJobDetailsTab(),
            _buildAdditionalTab(),
          ],
        ),
        bottomNavigationBar: _buildSaveButton(),
      ),
    );
  }

  // Save Button untuk Update
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleUpdate(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B34BE),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Update Job',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

 void _handleUpdate() async {
  if (!_validateInputs()) {
    return;
  }

  // Ambil data yang diubah dari form
  final updatedFields = {
    'position': positionController.text.trim(),
    'location': locationController.text.trim(),
    'jobType': selectedJobType.value,
    'categories': selectedCategories.toList(),
    'salary': salaryController.text.trim(),
    'jobDetails.jobDescription': jobDescriptionController.text.trim(),
    'jobDetails.requirements': requirementsController.text
        .split(',')
        .map((e) => e.trim())
        .toList(),
    'jobDetails.facilities': facilitiesController.text
        .split(',')
        .map((e) => e.trim())
        .toList(),
    'jobDetails.companyDetails.aboutCompany':
        aboutCompanyController.text.trim(),
    'jobDetails.companyDetails.industry': industryController.text.trim(),
    'jobDetails.companyDetails.website': websiteController.text.trim(),
    'jobDetails.companyDetails.companyGalleryPaths': galleryImageUrls.toList(),
  };

  try {
    // Panggil fungsi update di controller
    await jobController.updateJob(jobIndex, updatedFields);
    Get.snackbar(
      'Success',
      'Job updated successfully!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
    );
    Get.back(); // Kembali ke halaman sebelumnya
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to update job. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
    );
  }
}




  // Validasi form tetap sama seperti sebelumnya
  bool _validateInputs() {
    final List<String> emptyFields = [];

    void checkField(String fieldName, String value) {
      if (value.trim().isEmpty) {
        emptyFields.add(fieldName);
      }
    }

    // Basic Job Info
    checkField('Job Position', positionController.text);
    checkField('Location', locationController.text);
    checkField('Salary', salaryController.text);

    // Dropdowns
    if (selectedJobType.value.isEmpty) emptyFields.add('Job Type');
    if (selectedCategories.isEmpty) {
      emptyFields.add(
          'Job Categories'); // Tambahkan ke daftar field kosong jika belum ada kategori terpilih
    }

    // Job Details
    checkField('Job Description', jobDescriptionController.text);
    checkField('Requirements', requirementsController.text);

    // Company Info
    checkField('Industry', industryController.text);
    checkField('Website', websiteController.text);
    checkField('About Company', aboutCompanyController.text);

    // Benefits
    checkField('Benefits & Facilities', facilitiesController.text);

    // Gallery
    if (galleryImageUrls.isEmpty) {
      emptyFields.add('Company Gallery Images');
    }

    if (emptyFields.isNotEmpty) {
      Get.snackbar(
        'Incomplete Form',
        'Please fill in the following fields:\n${emptyFields.join('\n')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return false;
    }

    return true;
  }


  // Tab Widgets tetap sama seperti di AddJobView
  Widget _buildCompanyTab() {
    final recruiterData = jobController.recruiterData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Company Logo/Image
                CircleAvatar(
                  radius: 50,
                  backgroundImage: recruiterData['profile_image'] != null &&
                          recruiterData['profile_image'].isNotEmpty
                      ? NetworkImage(recruiterData['profile_image'])
                      : null,
                  backgroundColor: const Color(0xFF6B34BE),
                  child: recruiterData['profile_image'] == null ||
                          recruiterData['profile_image'].isEmpty
                      ? const Icon(Icons.business,
                          size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 24),

                // Company Information Fields
                _buildReadOnlyField(
                  label: 'Company Name',
                  value: recruiterData['company_name'] ?? 'Unknown Company',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'Industry',
                  hintText: 'e.g., Technology, Healthcare, Finance',
                  controller: industryController,
                  icon: Icons.category,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'Website',
                  hintText: 'e.g., https://www.company.com',
                  controller: websiteController,
                  icon: Icons.language,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'About Company',
                  hintText: 'Describe your company, culture, and mission...',
                  controller: aboutCompanyController,
                  icon: Icons.info,
                  maxLines: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Company Gallery Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Gallery',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B34BE),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPickImage(
  label: 'Add Company Images',
  icon: Icons.image_outlined,
  imageUrls: galleryImageUrls,
  email: FirebaseAuth.instance.currentUser?.email ?? 'recruiter@example.com',
  jobIndex: jobIndex, // Pastikan ini diteruskan
),



              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickImage({
  required String label,
  required IconData icon,
  required RxList<String> imageUrls,
  required String email,
  int? jobIndex, // Menentukan pekerjaan, opsional
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B34BE),
        ),
      ),
      const SizedBox(height: 8),

      // Upload Button
      GestureDetector(
        onTap: () async {
          final imageUrl = await jobController.pickAndUploadImage(
            email: email,
            jobIndex: jobIndex, // Kirim jobIndex jika ada
          );

          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        },
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Center(
            child: Icon(Icons.add_photo_alternate_outlined,
                size: 50, color: Color(0xFF6B34BE)),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Image Preview Grid
      Obx(() {
        if (imageUrls.isEmpty) {
          return const Text(
            'No images uploaded yet.',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: imageUrls.map((url) {
            return Stack(
              children: [
                // Image Preview
                GestureDetector(
                  onTap: () {
                    Get.dialog(
                      Dialog(
                        child: Container(
                          width: Get.width * 0.8,
                          height: Get.width * 0.8,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Delete Button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete Image'),
                          content: const Text(
                              'Are you sure you want to delete this image?'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                imageUrls.remove(url);
                                Get.back();
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      }),
    ],
  );
}

  Widget _buildJobDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basic Job Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B34BE),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Job Position',
                  hintText: 'e.g., Senior Software Engineer',
                  controller: positionController,
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Location',
                  hintText: 'e.g., Jakarta, Indonesia',
                  controller: locationController,
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Salary Range',
                  hintText: 'e.g., IDR 15,000,000 - 25,000,000',
                  controller: salaryController,
                  icon: Icons.monetization_on,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Job Type',
                  items: ['Full-time', 'Part-time', 'Contract', 'Freelance'],
                  selectedItem: selectedJobType,
                ),
                const SizedBox(height: 16),
                _buildMultipleChoiceField(
                  label: 'Job Category',
                  items: jobCategoriesData
                      .map((category) => category.name)
                      .toList(),
                  selectedItems:
                      selectedCategories, // RxList<String> untuk menyimpan pilihan
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B34BE),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Description',
                  hintText:
                      'Describe the role, responsibilities, and what the job entails...',
                  controller: jobDescriptionController,
                  icon: Icons.description,
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Requirements',
                  hintText:
                      'List the required skills, experience, and qualifications...',
                  controller: requirementsController,
                  icon: Icons.list,
                  maxLines: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Benefits & Facilities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B34BE),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Benefits',
                  hintText:
                      'e.g., Health Insurance, Annual Bonus, Training Program...',
                  controller: facilitiesController,
                  icon: Icons.card_giftcard,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF6B34BE)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      controller: TextEditingController(text: value),
      style: const TextStyle(color: Colors.black87, fontSize: 16),
    );
  }
  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF6B34BE)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B34BE)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(color: Colors.black87, fontSize: 16),
    );
  }

  Widget _buildMultipleChoiceField({
    required String label,
    required List<String> items,
    required RxList<String>
        selectedItems, // List untuk menyimpan kategori yang dipilih
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B34BE),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Tampilkan dialog multiple choice
            Get.dialog(
              AlertDialog(
                title: Text('Choose $label'),
                content: SingleChildScrollView(
                  child: Column(
                    children: items.map((item) {
                      return Obx(() => CheckboxListTile(
                            value: selectedItems.contains(item),
                            onChanged: (isSelected) {
                              if (isSelected ?? false) {
                                selectedItems.add(item);
                              } else {
                                selectedItems.remove(item);
                              }
                            },
                            title: Text(item),
                          ));
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(), // Tutup dialog
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
          child: SizedBox(
            width: double.infinity, // Menjadikan selebar layar
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Obx(() {
                if (selectedItems.isEmpty) {
                  return Text(
                    'Choose $label',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  );
                } else {
                  return Text(
                    selectedItems.join(', '),
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  );
                }
              }),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required RxString selectedItem,
  }) {
    return Obx(() => DropdownButtonFormField<String>(
          value: selectedItem.value.isNotEmpty ? selectedItem.value : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Choose $label',
            labelStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon:
                const Icon(Icons.category_outlined, color: Color(0xFF6B34BE)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B34BE)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: (value) {
            selectedItem.value = value!;
          },
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B34BE)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ));
  }

}
