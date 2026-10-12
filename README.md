# DYN MUSIC

Ứng dụng Flutter nghe nhạc trực tuyến trên Android, sử dụng `just_audio`,
Firebase Authentication và Cloud Firestore. Firebase project:
`music-app-th6-719a9`; Android package: `com.example.th6_2324801030035`.

## Chức năng

- Màn hình Khám phá: danh sách có ảnh, tên bài hát, nghệ sĩ; tìm theo tên/nghệ sĩ,
  hỗ trợ tìm tiếng Việt không dấu; phát cả danh sách hoặc một bài tìm được.
- Trình phát: ảnh bìa, tên/nghệ sĩ, thanh thời gian có thể tua; Play/Pause,
  Next/Previous, phát ngẫu nhiên, lặp danh sách, chọn bài trong hàng đợi.
- Một player dùng chung; mini-player tiếp tục hoạt động khi chuyển màn hình.
- Stream trực tiếp qua URL HTTPS, không có thao tác tải/lưu MP3 vào máy.
- Đăng ký bằng tên, email, mật khẩu; đăng nhập/đăng xuất bằng Firebase Auth.
- Đăng nhập Google bằng Google Sign-In và Firebase credential. Hồ sơ được lưu
  tại `users/{uid}` khi đăng ký, đăng nhập hoặc khôi phục phiên đã lưu.
- Thích/bỏ thích bài hát; playlist cá nhân: tạo, đổi tên, xóa, thêm/bỏ bài,
  phát playlist theo thứ tự đã lưu. Dữ liệu được lưu và đồng bộ theo UID.
- Có trạng thái tải, lỗi mạng/thử lại, danh sách rỗng và ảnh bìa dự phòng.
  Chưa đăng nhập vẫn có thể nghe nhạc.
- Tài khoản → Giao diện: chọn Hệ thống, Sáng hoặc Tối. Lựa chọn được lưu trên
  thiết bị và áp dụng cho toàn bộ ứng dụng; đổi giao diện vẫn tiếp tục phát nhạc.

## Chạy ứng dụng

Yêu cầu Flutter và Android SDK. Cấu hình Firebase của bản này dành cho Android
(API 24 trở lên). Mở máy ảo hoặc kết nối điện thoại rồi chạy:

```powershell
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Thay `emulator-5554` bằng ID thiết bị của bạn. Có thể mở máy ảo đã có bằng
`flutter emulators --launch Medium_Phone`. Nếu ADB báo `unauthorized`, xác nhận
Allow USB debugging trên thiết bị trước khi chạy.

Để thử chức năng cá nhân: tab Tài khoản → Đăng nhập / Đăng ký → Đăng ký.
Hoặc chọn **Tiếp tục với Google**, rồi chọn tài khoản trong cửa sổ Google.
Sau đó nhấn trái tim ở bài hát, hoặc menu bài hát → Thêm vào playlist.
Tab Thư viện hiển thị bài yêu thích và playlist đã lưu. Đăng xuất rồi đăng nhập
lại cùng tài khoản để xem dữ liệu còn được giữ.

Build APK để nộp hoặc cài thử:

```powershell
flutter build apk --debug
```

Kết quả: `build/app/outputs/flutter-apk/app-debug.apk`.

## Backend và dữ liệu mẫu

Bản demo dùng phương án URL MP3 public của đề: nhạc có lời tiếng Anh do ca sĩ
**Josh Woodward** cung cấp qua HTTPS;
Firestore lưu metadata và thư viện cá nhân, Firebase Auth quản lý tài khoản.
Màn hình Khám phá có **10 bài đầy đủ** từ năm album, gồm Rebound, Wade,
The Box, The Long Fade, Swansong, 20/20, California Lullabye, Bags of Water,
Already There và Let It In. Tên, nghệ sĩ, thể loại, MP3 và ảnh album lấy từ
[website chính thức](https://www.joshwoodward.com/). Nhạc được chia sẻ theo
[CC BY 4.0 với yêu cầu ghi công](https://www.joshwoodward.com/faq).
Player ghi tên bài, nghệ sĩ, nguồn và liên kết giấy phép.

Sáu bài SoundHelix cũ vẫn giữ ID và URL nguyên bản, đặt `isVisible: false` để
không hiện trong Khám phá. Bài cũ đã nằm trong yêu thích/playlist vẫn phát đúng
nhạc; không dùng lại ID cũ cho bài mới.

Metadata hiện tại được ghi lại trong `tool/music_catalogue.json`, thông tin
kiểm tra HTTP và giấy phép ở `tool/artist_catalogue_candidates.json`. Các bản
sao ảnh album trong `assets/covers/` giữ ảnh hiển thị cả khi ảnh mạng đang tải
hoặc lỗi. MP3 chỉ được stream trực tuyến, không lưu file nhạc trong app.

Firestore database `(default)` nằm tại Singapore (`asia-southeast1`).
Mỗi document trong `songs` có 4 trường string bắt buộc và `genre` tùy chọn:

| Trường | Nội dung |
| --- | --- |
| `title` | Tên bài hát |
| `artist` | Tên nghệ sĩ |
| `imageUrl` | URL ảnh PNG/JPEG |
| `audioUrl` | URL stream MP3 HTTPS |
| `genre` | Thể loại (string tùy chọn) |
| `isVisible` | Hiển thị ở Khám phá (bool, mặc định true khi thiếu) |
| `sourceUrl` | Trang bài hát/nghệ sĩ để ghi nguồn (string tùy chọn) |
| `licenseUrl` | Liên kết giấy phép (string tùy chọn) |

Quản trị viên thêm bài bằng Firebase Console. Khi sửa danh mục, nhấn nút tải lại
hoặc kéo xuống ở Khám phá. App không có quyền sửa danh mục bài hát.

Cấu trúc dữ liệu cá nhân:

```text
songs/{songId}
  title, artist, imageUrl, audioUrl
  genre, isVisible, sourceUrl, licenseUrl (tùy chọn)
users/{uid}
  uid, name, email, createdAt
users/{uid}/favorites/{songId}
  songId, createdAt
users/{uid}/playlists/{playlistId}
  name, songIds[], createdAt, updatedAt
```

Playlist có tối đa 100 bài, tên dài 1–60 ký tự. UID lấy từ Firebase Auth;
Rules chỉ cho tài khoản đó đọc/ghi thư viện của mình. `createdAt`/`updatedAt`
dùng thời gian máy chủ cho dữ liệu mới. Hồ sơ giữ nguyên `createdAt` khi đăng
nhập lại; hồ sơ bổ sung cho tài khoản cũ dùng ngày tạo tài khoản từ Auth.
Hồ sơ có đúng `uid`, `name`, `email`, `createdAt`; không lưu mật khẩu trong
Firestore. Metadata bài hát công khai chỉ được đọc.

Firebase Console → Authentication → Sign-in method cần bật **Email/Password**.
Đăng nhập Google cần bật provider **Google**. Không cần bật Email link.
Android đã đăng ký SHA-1/SHA-256 của debug keystore hiện tại và cấu hình
`google-services.json` có Android OAuth client và web OAuth client. Nếu chạy
trên máy khác hoặc đổi khóa ký APK, thêm fingerprint của khóa đó trong Firebase
Project settings → Your apps → Android rồi tải lại file cấu hình.
Google Sign-In lấy cấu hình web client từ Google Services plugin, không dùng
client ID Android làm server client ID. Triển khai Rules khi thay đổi:

```powershell
firebase.cmd deploy --only firestore:rules --project music-app-th6-719a9
```

Bản này dùng gói Spark và chưa lưu file trong Firebase Storage. Nếu cần chuyển
sang Storage, tải MP3/ảnh lên Storage rồi thay `audioUrl`/`imageUrl` bằng URL
của file; player vẫn dùng cùng luồng stream. Firebase Storage hiện yêu cầu gói
Blaze theo [thông báo của Firebase](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).

## Mã nguồn chính

- `lib/main.dart`: khởi tạo Firebase, tải danh mục, vòng đời controller.
- `lib/screens/`: từng màn hình giao diện tiếng Việt.
- `lib/services/audio_service.dart`, `audio_engine.dart`: hàng đợi và `just_audio`.
- `lib/services/auth_service.dart`, `playlist_service.dart`: Firebase Auth,
  Firestore, thư viện cá nhân và xử lý chuyển tài khoản.
- `lib/services/user_profile_service.dart`: tạo/cập nhật hồ sơ người dùng,
  giữ ngày tạo và xử lý giao dịch Firestore.
- `lib/services/theme_service.dart`: lưu lựa chọn sáng/tối trên thiết bị.
- `lib/models/`: dữ liệu bài hát, playlist và người dùng.
- `lib/services/firebase_service.dart`, `lib/firebase_options.dart`: cấu hình/kết nối.
- `firestore.rules`: quyền truy cập và kiểm tra dữ liệu.

```text
lib/
  main.dart
  firebase_options.dart
  models/
    song_model.dart
    playlist_model.dart
    user_model.dart
  screens/
    home_screen.dart
    player_screen.dart
    library_screen.dart
    playlist_screen.dart
    favorites_screen.dart
    account_screen.dart
    login_screen.dart
    register_screen.dart
  services/
    firebase_service.dart
    audio_service.dart
    audio_engine.dart
    auth_service.dart
    playlist_service.dart
    user_profile_service.dart
    theme_service.dart
  widgets/
    song_tile.dart
    song_credits.dart
    mini_player.dart
    album_cover.dart
    auth_form.dart
    playback_control_icon.dart
    playlist_actions.dart
    section_header.dart
    empty_panel.dart
    error_notice.dart
  theme/
    music_theme.dart
  utils/
    music_helpers.dart
```

Các màn hình đăng nhập/đăng ký dùng chung `AuthForm`. `FavoritesScreen` dùng lại
bố cục danh sách của `PlaylistScreen`. Các service giữ player và dữ liệu tài
khoản dùng chung để việc chuyển màn hình không làm mất trạng thái.

Android đã có quyền Internet, Google Services plugin và
`android/app/google-services.json`. `firebase_options.dart` khớp file cấu hình
Android đã tải. Khi chuyển sang Firebase project khác hoặc thêm nền tảng:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project YOUR_PROJECT --platforms=android
```

Không đặt khóa service account quản trị vào app.

## Kiểm tra

```powershell
flutter analyze
flutter test test/widget_test.dart
```

Chỉ giữ một file `test/widget_test.dart`, kiểm tra tên DYN MUSIC và giao diện
khởi động, đang tải, lỗi kết nối. Test giả lập bước khởi tạo Firebase, không
kết nối hoặc ghi dữ liệu lên Firebase thật.

Để kiểm tra chức năng thực tế, chạy ứng dụng trên Android rồi thử nghe nhạc,
đăng nhập, thích bài hát và lưu playlist.

Tài liệu: [Firebase cho Flutter](https://firebase.google.com/docs/flutter/setup),
[Đăng nhập email/mật khẩu](https://firebase.google.com/docs/auth/flutter/password-auth),
[just_audio](https://pub.dev/packages/just_audio).
