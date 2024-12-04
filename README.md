# Flight Control Unit - Final Project Perancangan Sistem Digital
## Nama Anggota Kelompok
1. Andi Muhammad Alvin Farhansyah - 2306161933
2. Ibnu Zaky Fauzi - 2306161870
3. Samih Bassam - 2306250623
4. Daffa Bagus Dhiananto - 2306250756

FCU (Flight Unit Controller) merupakan komponen yang essential yang dipakai pada pesawat-pesawat tanpa awak yang kecil. Dimana FCU akan menjadi  'sistem saraf' bagi pesawat tanpa awak kita, yang akan menerima perintah dari komputer atau mikrokontroller untuk mengatur servo ataupun motor dari unit terbang sehingga dia pergi ke arah, altittude, atau kecepatan yang kita inginkan. Untuk detail pemrogramannya, FCU ini akan memiliki PID Controller Module, yang akan mengimplementasikan PID Controller Logic (Proportional, Integral, Derivative calculations) untuk stabilitas dan navigasi dari unit terbang kita. FCU juga akan memiliki 4 state machine, yaitu Idle, Takeoff, Hover, Cruise, Land. FCU juga memiliki unit processing signal, dimana dia akan mendapatkan sinyal dari sensor seperti LiDAR  untuk mengukur ketinggiannya. Untuk module control actuator, pada setiap motor dalam unit terbang kita, akan dikirimkan sinyal PWM (Pulse Width Modulation) untuk kontrol kecepatan dengan inputnya dari output PID atau sinyal control. Untuk komunikasi data bisa berupa SPI Slave.
