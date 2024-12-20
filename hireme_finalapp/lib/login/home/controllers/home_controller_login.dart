 
import 'package:get/get.dart';

class HomeControllerLogin extends GetxController {
  // Variable untuk state atau data yang dibutuhkan di halaman Home
  var isLoading = false.obs;

  // Fungsi untuk fetch data dari Firestore atau API (contoh fungsi)
  void fetchData() async {
    isLoading.value = true;
    try {
      // Contoh logika untuk fetch data
      await Future.delayed(Duration(seconds: 2)); // Simulasi delay fetching data
      print("Data berhasil diambil");
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
