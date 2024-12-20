import 'package:HireMe_Id/utils/setup_mic.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../data/job_data.dart'; // Import untuk data pekerjaan
import '../../browse/views/browse_3_view.dart'; // Import halaman Browse3View
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeViewNonLogin extends StatefulWidget {
  @override
  _HomeViewNonLoginState createState() => _HomeViewNonLoginState();
}

class _HomeViewNonLoginState extends State<HomeViewNonLogin> {
  final HomeController controller = Get.put(HomeController());
  final AuthController authController = Get.put(AuthController());

  final TextEditingController _searchController = TextEditingController();
  List<Job> searchResults = [];
  bool isSearching = false;

  // Tambahkan variabel Speech-to-Text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText(); // Inisialisasi Speech-to-Text
    // Minta izin microphone
  }

  void handleSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        searchResults = jobList
            .where((job) =>
                job.position.toLowerCase().contains(query.toLowerCase()))
            .toList();
        isSearching = true;
      });
    } else {
      resetSearch();
    }
  }

  void resetSearch() {
    setState(() {
      _searchController.clear();
      searchResults = [];
      isSearching = false;
    });
  }

  // Tambahkan fungsi untuk memulai dan menghentikan Speech-to-Text
  Future<void> _startListening() async {
    if (!_isListening && await _speech.initialize()) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          handleSearch(result
              .recognizedWords); // Memulai pencarian berdasarkan hasil suara
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Text
                  const Text(
                    "HireMe.id",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Find Your Dream Job Here!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Search Box
                  Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 30, color: Color(0xFF6B34BE)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: handleSearch,
                            decoration: const InputDecoration(
                              hintText: "Search for jobs...",
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
                          ),
                        ),
                        if (isSearching)
                          GestureDetector(
                            onTap: resetSearch,
                            child: const Icon(Icons.close,
                                color: Colors.grey, size: 20),
                          ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            final mic =
                                SpeechService(); // Memanggil SpeechService
                            if (mic.isListening) {
                              mic.stopListening();
                            } else {
                              await mic.startListening((result) {
                                setState(() {
                                  _searchController.text = result;
                                  handleSearch(
                                      result); // Proses pencarian otomatis
                                });
                              });
                            }
                            setState(() {}); // Untuk update UI status icon mic
                          },
                          child: Icon(
                            SpeechService().isListening
                                ? Icons.mic
                                : Icons.mic_none,
                            size: 30,
                            color: SpeechService().isListening
                                ? Colors.red
                                : const Color(0xFF6B34BE),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Content based on Search
                  if (isSearching)
                    searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              "No jobs found.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final job = searchResults[index];
                              return GestureDetector(
                                onTap: () {
                                  Get.to(() => Browse3View(job: job));
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: job.companyLogoPath.startsWith('http')
    ? Image.network(
        job.companyLogoPath,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default_logo.png', // gambar default jika error
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          );
        },
      )
    : Image.asset(
        job.companyLogoPath,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
      ),
),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                job.position,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${job.companyName} • ${job.location}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                  else
                    Column(
                      children: [
                        // Image with Shadow
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.25,
                              maxWidth: MediaQuery.of(context).size.width,
                            ),
                            child: Image.asset(
                              'assets/images/homepage-image.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subtitle Text
                        const Text(
                          "Explore thousands of job offers from top companies.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // Popular Jobs Image
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.25,
                              maxWidth: MediaQuery.of(context).size.width,
                            ),
                            child: Image.asset(
                              'assets/images/most-popular-job.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Get.toNamed(AppRoutes.createAccount);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B34BE),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {
                                authController.loginWithGoogle_job();
                                Get.toNamed(AppRoutes.homeLogin);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(15),
                                side: const BorderSide(color: Colors.white),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/google.png',
                                  height: 25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
