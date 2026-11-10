# NotchDrip — Inti

App notch macOS dengan data asli, bukan contoh. Nama NotchDrip masih placeholder — ganti kapan saja, cukup ubah target di `project.yml` dan bundle id.

## Modul inti

- **Musik** — membaca lagu yang sedang diputar di Spotify atau Music lewat AppleScript (judul, artis, album, durasi, posisi, status play/pause), dengan tombol prev / play-pause / next. Poll tiap 2 detik, hanya untuk app yang sedang berjalan (tidak me-launch Spotify/Music yang sedang mati).
- **Volume** — membaca dan mengatur volume output sistem lewat CoreAudio (channel kiri/kanan, rata-rata untuk baca, set keduanya untuk tulis), plus mute.
- **Brightness** — membaca dan mengatur brightness layar built-in lewat IOKit (`IODisplayConnect` + `kIODisplayBrightnessKey`).
- **Notifikasi** — membaca database Notification Center (`~/Library/Group Containers/group.com.apple.usernoted/db2/db`, tabel `record` + `app`, 7 hari terakhir, 20 item) secara read-only lewat SQLite. Judul/subjudul/isi diambil dari bplist di kolom `data`.

Animasi notch sama seperti prototipe sebelumnya: pill menetes dari notch, spring response 0.45 / damping 0.65, auto-tutup 3,8 detik. Geometri notch diukur saat runtime dari `safeAreaInsets.top` dan area kiri/kanan notch.

## Izin yang dibutuhkan

- **Automation** — macOS akan bertanya saat pertama kali musik dipakai (NotchDrip mengontrol Spotify / Music). Tanpa izin ini, kartu musik menampilkan "Tidak ada musik".
- **Full Disk Access** — untuk membaca database notifikasi (System Settings → Privacy & Security → Full Disk Access → NotchDrip). Tanpa ini, kartu notifikasi menampilkan panduan tersebut.
- Volume dan brightness tidak butuh izin tambahan.

## Cara menjalankan di Mac

```
brew install xcodegen
xcodegen
open NotchDrip.xcodeproj
```

Lalu Cmd+R. Yang muncul: pill di notch + panel "NotchDrip — Inti" berisi tombol dan status live tiap modul.

Build lewat GitHub Actions juga sudah disiapkan (`.github/workflows/build-macos.yml`): push ke `main` akan menghasilkan artefak `NotchDrip-macOS.zip`. Repo GitHub-nya masih harus dibuat dulu (lihat langkah di chat).

## Batasan yang sudah diketahui

- Brightness via IOKit di Apple Silicon/macOS baru kadang tidak bertahan (Apple mengarahkan ke private DisplayServices). Kalau slider brightness tidak berpengaruh di Mac ini, itu penyebabnya — langkah berikut adalah DisplayServices via `dlopen`.
- Artwork lagu belum ditampilkan (placeholder gradien). Posisi lagu diperbarui tiap 2 detik mengikuti poll.
- Tombol volume/brightness fisik di keyboard belum disadap (butuh Accessibility event tap) — perubahan lewat pill atau lewat keyboard tetap terbaca karena nilai di-poll.
- Notifikasi yang sudah dihapus dari Notification Center bisa masih muncul di `record` sampai dibersihkan sistem.

## Status build

Belum terverifikasi: tidak ada Xcode di VM ini. Build pertama (di Mac atau via Actions) adalah test compile-nya.
