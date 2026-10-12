// Kiểm tra cơ bản màn hình khởi động của DYN MUSIC.
// Giả lập kết nối Firebase để test không cần Internet hoặc máy ảo.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th6_2324801030035/main.dart';

void main() {
  testWidgets('DYN MUSIC hiển thị trạng thái tải và lỗi kết nối', (
    tester,
  ) async {
    final connection = Completer<void>();

    await tester.pumpWidget(
      MyApp(
        initializeFirebase: () => connection.future,
        loadSongs: () async => [],
      ),
    );
    await tester.pump();

    expect(find.text('DYN MUSIC'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đang tải âm nhạc…'), findsOneWidget);

    connection.completeError(StateError('Giả lập mất kết nối'));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Chưa kết nối được dịch vụ'), findsOneWidget);
  });
}
