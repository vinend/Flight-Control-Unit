Berikut adalah README yang telah diperbarui dalam Bahasa Indonesia sesuai dengan permintaan Anda:

---

# ✈️ Flight Control Unit (FCU) - Proyek Akhir Desain Sistem Digital

Selamat datang di repositori proyek **Flight Control Unit**! Proyek ini berfokus pada perancangan sistem kontrol penerbangan untuk UAV kecil menggunakan VHDL. Proyek ini mencakup implementasi PID controller dan modul-modul terkait untuk stabilisasi dan navigasi UAV.

## 🚀 Deskripsi Proyek

**Flight Control Unit (FCU)** berfungsi sebagai sistem saraf pusat bagi UAV, menerima input dari komputer atau mikrokontroler untuk mengendalikan berbagai aktuator seperti motor dan servo. Hal ini memungkinkan UAV mencapai trajektori, ketinggian, dan kecepatan yang diinginkan.

Komponen utama dari FCU adalah **Modul PID Controller**, yang menggunakan algoritma Proportional-Integral-Derivative (PID) untuk memastikan penerbangan yang stabil. PID controller menyesuaikan kecepatan motor untuk mempertahankan posisi atau kecepatan yang diinginkan, mengoreksi kesalahan secara real-time.

Sistem ini juga mengintegrasikan **Modul Pemrosesan Sinyal** untuk memproses data dari berbagai sensor, seperti **LiDAR**, yang mengukur ketinggian dan memberikan umpan balik waktu nyata ke sistem kontrol. Berdasarkan data ini, sinyal kontrol dihasilkan untuk menyesuaikan jalur penerbangan UAV.

### Modul dan Fitur Utama:
1. **Modul PID Controller**: Mengimplementasikan logika PID untuk stabilitas penerbangan dan navigasi.
2. **State Machines**: Mengelola transisi antar fase penerbangan.
3. **Unit Pemrosesan Sensor**: Menerima dan memproses data sensor, seperti LiDAR, untuk menentukan ketinggian UAV dan membantu menjaga penerbangan yang stabil.
4. **Modul Kontrol Aktuator**: Mengirimkan sinyal PWM (Pulse Width Modulation) untuk mengontrol motor, menyesuaikan kecepatan berdasarkan output PID atau perintah kontrol.

Tujuan dari proyek ini adalah untuk membuat sistem kontrol penerbangan yang sangat responsif dan stabil yang mampu mengendalikan dinamika penerbangan UAV secara otonom.

## Anggota Kelompok Proyek
1. **Andi Muhammad Alvin Farhansyah** - 2306161933 👑💯
2. **Ibnu Zaky Fauzi** - 2306161870
3. **Samih Bassam** - 2306250623
4. **Daffa Bagus Dhinanto** - 2306250756

Kelompok: **PA22**

## 🗂️ Struktur Proyek
- **/src**: Berisi file VHDL untuk implementasi PID Controller, state machines, dan modul lainnya.
- **/testbenches**: Berisi file testbench untuk menguji masing-masing modul.
- **/docs**: Dokumentasi proyek, termasuk diagram, flowchart, dan laporan.
- **/simulations**: Hasil simulasi dan output untuk analisis lebih lanjut.

---