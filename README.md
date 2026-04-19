# Proyek 4: Collaborative Logbook & Pengolahan Citra Digital (PCD)
Aplikasi ini merupakan sistem logbook berbasis offline-first yang terintegrasi dengan sensor kamera (Smart-Patrol Vision) dan algoritma Pengolahan Citra Digital (PCD) secara native. Proyek ini dikembangkan oleh Andreas Devan untuk memenuhi persyaratan Evaluasi Tengah Semester (ETS) mata kuliah Praktikum PCD di Politeknik Negeri Bandung (Polban).

Deskripsi Sistem
Sistem ini menjembatani aliran video mentah dari perangkat keras (hardware stream) dengan manipulasi matriks piksel secara langsung pada sisi klien (client-side). Seluruh proses pemrosesan citra—termasuk pemfilteran spasial (konvolusi) dan operasi titik dasar—dieksekusi di dalam ekosistem Dart tanpa memerlukan backend Python terpisah. Hal ini dilakukan untuk mengoptimalkan efisiensi dan menjaga kelancaran antarmuka (User Interface).

Fitur Utama
Offline-First Logbook: Penyimpanan data lokal instan menggunakan basis data NoSQL (Hive) untuk menjamin ketersediaan data secara luring.

Smart-Patrol Vision: Antarmuka pemindaian kamera khusus untuk memvisualisasikan penargetan objek kerusakan jalan (berdasarkan spesifikasi RDD-2022).

Manipulasi Piksel Native: Implementasi filter spasial (Konvolusi/Sharpening) dan operasi logika/aritmatika (Kontras, Kecerahan, Grayscale, Inversi) menggunakan pustaka image.

Panduan Instalasi dan Kompilasi
Catatan Penting: Untuk memastikan ukuran file kompresi (.zip) tetap di bawah batas maksimal 100MB sesuai instruksi pengumpulan ETS, direktori cache kompilasi seperti build/ dan .dart_tool/ telah dihapus secara sengaja dari repositori ini.

Silakan ikuti langkah-langkah berikut untuk memulihkan dependensi dan menjalankan aplikasi:

Prasyarat Lingkungan
Flutter SDK (mendukung versi ^3.10.7)

Perangkat fisik Android/iOS atau Emulator yang telah dikonfigurasi untuk memiliki akses kamera aktif.

Langkah-langkah Menjalankan Aplikasi
Ekstraksi Berkas: Ekstrak berkas [PCD2026_2A_001_D3_2024]_ETS.zip ke dalam direktori kerja lokal Anda.

Pemulihan Dependensi: Buka terminal, navigasikan ke direktori root proyek, dan jalankan perintah berikut untuk mengunduh seluruh package yang dibutuhkan (termasuk camera dan image):

Bash
flutter pub get
Verifikasi Konfigurasi Lingkungan: Pastikan berkas .env sudah berada di root direktori proyek. Berkas ini esensial karena memuat kredensial login simulasi (seperti username: admin / password: 123) serta konfigurasi tingkat sistem lainnya.

Kompilasi dan Jalankan: Lakukan proses build dan luncurkan aplikasi ke perangkat yang terhubung menggunakan perintah:

Bash
flutter run
Catatan Evaluasi Penyimpanan
Sesuai dengan praktik rekayasa perangkat lunak yang baik, gambar hasil manipulasi PCD tidak diunggah langsung dalam bentuk biner (blob) ke dalam basis data awan (MongoDB). Hal ini diterapkan untuk menghindari risiko melampaui batas ukuran dokumen (16MB BSON limit) dan menghemat ruang penyimpanan. Gambar akan disimpan secara aman pada memori internal perangkat (on-device storage), dan aplikasi hanya akan mencatat lintasan (file path) gambar tersebut ke dalam entri logbook lokal.
