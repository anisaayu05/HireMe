# HireMe - Aplikasi Pencarian Pekerjaan

## Deskripsi Proyek

Proyek ini adalah bagian dari mata kuliah Pemrograman Mobile untuk mengajarkan pengembangan aplikasi mobile dengan **Flutter**. Fokus utama mencakup **navigasi**, **state management**, dan **akses data**.

### Tautan Prototipe Figma
Untuk melihat prototipe aplikasi HireMe, silakan kunjungi: [Figma Prototype](https://www.figma.com/design/bCdjLRwIq7X6V5IIX8K3rW/HireMe-App?node-id=0-1&t=FbXNFhbINDSmzJEv-1) <!-- Tambahkan tautan prototipe Figma yang sesuai -->

---

## Deskripsi Aplikasi

**HireMe** adalah platform modern yang dirancang untuk membantu pengguna dalam mencari pekerjaan secara efisien. Dengan antarmuka pengguna yang intuitif, aplikasi ini menggunakan Flutter untuk memberikan pengalaman pengguna yang mulus di perangkat mobile. Fokus utama aplikasi ini meliputi:

- **Navigasi** yang mudah
- **Manajemen status** yang efektif
- **Akses data** yang aman

---

## Navigasi

Aplikasi ini memiliki **navigation bar** yang terdiri dari empat tab yang dapat diakses pengguna:

1. **Home**
2. **Browse**
3. **Applied**
4. **Profile**

---

## Halaman dan Fungsionalitas

### 1. Home

- **Fitur Utama**: Menampilkan tombol **Browse Pekerjaan** yang mengarahkan pengguna ke halaman **Browse**.
- **Informasi**: Keterangan tentang berbagai situs pencarian pekerjaan, termasuk **LinkedIn**.
- **Pengguna Belum Mendaftar**: Menampilkan pesan yang mendorong pengguna untuk **Create Akun** agar dapat mengakses semua fitur aplikasi.
- **Desain UI**: Desain antarmuka yang menarik secara visual dengan warna cerah dan elemen yang jelas.

### 2. Browse

- **Pengguna Belum Login**: Masih dapat melihat daftar pekerjaan, tetapi tidak dapat melihat rincian atau melamar pekerjaan.
- **Pengguna Setelah Login**: Memiliki akses penuh ke rincian pekerjaan, termasuk:
  - **Judul Pekerjaan**
  - **Deskripsi Pekerjaan**
  - **Persyaratan**
  - **Deskripsi Perusahaan**
  - **Tombol Lamaran** untuk memulai proses aplikasi.
  
#### Proses Melamar Pekerjaan

1. **Mengisi Formulir Lamaran**: Pengguna mengisi informasi pribadi, pengalaman kerja, dan pendidikan.
2. **Upload CV**: CV diunggah dalam format PDF atau DOCX dengan instruksi yang jelas.
3. **Konfirmasi Lamaran**: Pengguna menerima konfirmasi setelah melamar.

### 3. Applied

- **Pengguna Belum Login**: Halaman tidak dapat diakses.
- **Pengguna Setelah Login**: Dapat melihat daftar pekerjaan yang telah dilamar dan status setiap lamaran:
  - **Status Lamaran**: Menampilkan status apakah dalam proses, diterima, atau ditolak.
  - **Riwayat Lamaran**: Melihat waktu dan tanggal lamaran, serta opsi untuk mengulangi atau membatalkan lamaran.
- **Desain yang Intuitif**: Tabel atau daftar yang jelas untuk menampilkan informasi.

### 4. Profile

- **Pengguna Belum Login**: Tidak dapat mengakses halaman.
- **Pengguna Setelah Login**: Dapat memperbarui informasi akun seperti nama, email, foto profil, dan preferensi pencarian pekerjaan.
- **Riwayat dan Notifikasi**: Melihat notifikasi terkait lamaran dan pembaruan dari perusahaan.

---

## Verifikasi Dua Langkah (OTP)

Fitur keamanan tambahan yang membantu melindungi akun pengguna.

- **Tujuan OTP**: Mengurangi risiko pencurian identitas dengan memastikan hanya pengguna sah yang dapat mengakses akun.
- **Implementasi**:
  - OTP dikirim melalui **SMS** atau **email** setelah login.
  - Pengguna dapat memilih metode pengiriman OTP saat membuat akun.
- **Manfaat**: Pengguna merasa lebih aman dan memiliki kontrol lebih besar atas akses ke akun.

---

## Kesimpulan

Aplikasi HireMe dirancang untuk memberikan pengalaman pencarian pekerjaan yang **efektif** dan **aman** bagi pengguna. Dengan navigasi yang jelas, antarmuka yang menarik, fitur keamanan yang kuat, dan proses lamaran yang mudah, pengguna dapat menjelajahi dan melamar pekerjaan dengan percaya diri.
