# 💎 TIKTOK AUTO STREAK PRO • IOS DYLIB TWEAK (CHO ESIGN) 💎

Dự án mã nguồn Tweak Dylib tự động giữ chuỗi TikTok dành cho iPhone (iOS), tương thích hoàn toàn với tính năng **"Tiêm Dylib" (Inject Dylib)** của ứng dụng **ESign**.

---

## 📂 Danh mục file trong thư mục:
* [TikTokStreak.m](file:///c:/Users/BaoLong/Desktop/tạm/chuoitik/tiktok_streak_dylib/TikTokStreak.m): Mã nguồn Objective-C chính của Tweak (tạo nút bong bóng nổi 🔥, quét icon chuỗi, tự động gửi tin nhắn và quay lại).
* [Makefile](file:///c:/Users/BaoLong/Desktop/tạm/chuoitik/tiktok_streak_dylib/Makefile): Cấu hình biên dịch bằng Theos trên macOS/Linux.
* [.github/workflows/build.yml](file:///c:/Users/BaoLong/Desktop/tạm/chuoitik/tiktok_streak_dylib/.github/workflows/build.yml): Tự động hóa build bằng GitHub Actions (không cần máy tính Mac, chỉ cần đẩy lên GitHub là tải được file `.dylib` về máy).

---

## 🚀 Cách 1: Build tự động lấy file `.dylib` bằng GitHub Actions (Khuyên dùng khi dùng Windows)
Vì bạn đang dùng máy tính Windows, cách đơn giản nhất để có file `TikTokStreak.dylib` chuẩn Apple ARM64:
1. Tạo 1 repository mới trên GitHub (Private hoặc Public).
2. Tải toàn bộ thư mục `tiktok_streak_dylib` này lên GitHub.
3. Chuyển sang tab **Actions** trên GitHub ➔ Chọn workflow **Build TikTokStreak Dylib for iOS** ➔ Bấm **Run workflow**.
4. Đợi khoảng 30 giây, GitHub (chạy macOS với Xcode chính thức) sẽ tự động biên dịch xong.
5. Vào mục **Artifacts** tải file `TikTokStreak-dylib.zip` về máy, giải nén ra sẽ có file `TikTokStreak.dylib`.

---

## 🛠 Cách 2: Tự build trên máy Mac qua Terminal
Nếu bạn có máy Mac, chỉ cần mở Terminal trong thư mục này và chạy lệnh:
```bash
xcrun -sdk iphoneos clang -dynamiclib \
  -arch arm64 -arch arm64e \
  -miphoneos-version-min=14.0 \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -fobjc-arc -O3 \
  TikTokStreak.m -o TikTokStreak.dylib
```
File `TikTokStreak.dylib` sẽ được xuất ra ngay lập tức.

---

## 📲 HƯỚNG DẪN TIÊM VÀO TIKTOK TRÊN APP ESIGN

1. **Chuẩn bị:**
   * 1 file **`TikTok.ipa`** (tải từ các kho ipa uy tín như CyPwn, KamoHacks, v.v.).
   * File **`TikTokStreak.dylib`** vừa xuất ở trên.
   * Gửi cả 2 file vào iPhone (qua AirDrop, Telegram, Google Drive hoặc lưu vào app **Tệp**).

2. **Tiêm Dylib trong ESign:**
   * Mở app **ESign** trên iPhone.
   * Vào tab **Ứng dụng** (Apps) ➔ Bấm dấu `+` ở góc trên để thêm file `TikTok.ipa`.
   * Nhấn giữ hoặc chạm vào file `TikTok.ipa` ➔ Chọn **Nhập thư viện (Tiêm Dylib / Add Library)**.
   * Chọn file `TikTokStreak.dylib`.
   * ESign sẽ tự động chèn thư viện vào binary của TikTok.

3. **Ký và Cài đặt:**
   * Bấm nút **Ký (Signature)** trong ESign.
   * Chọn chứng chỉ số P12 của bạn.
   * Bấm **Cài đặt (Install)** để đưa app TikTok đã tích hợp tool lên màn hình chính.

4. **Sử dụng:**
   * Mở ứng dụng TikTok vừa cài đặt.
   * Trên màn hình sẽ xuất hiện một **nút bong bóng nổi hình ngọn lửa 🔥**.
   * Chuyển vào tab **Hộp thư (Inbox)** của TikTok.
   * Chạm vào nút 🔥 ➔ Bấm **▶ Bắt Đầu**. Tool sẽ tự động quét bạn bè có icon 🔥 và gửi tin nhắn giữ chuỗi liên tục!
