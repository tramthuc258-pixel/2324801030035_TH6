import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

typedef ProfileUpdater = Map<String, dynamic> Function(
  Map<String, dynamic>? existing,
);

abstract class UserProfileStore {
  Future<Map<String, dynamic>> transact(String uid, ProfileUpdater update);
}

class FirestoreUserProfileStore implements UserProfileStore {
  FirestoreUserProfileStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>> transact(
    String uid,
    ProfileUpdater update,
  ) async {
    final document = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final previous = snapshot.data();
      final next = update(previous);
      if (!mapEquals(previous, next)) transaction.set(document, next);
    });
    // Resolve the first server timestamp before returning the profile to the UI.
    final saved = await document.get(const GetOptions(source: Source.server));
    final data = saved.data();
    if (data == null) {
      throw const FormatException('Không tìm thấy hồ sơ đã lưu.');
    }
    return data;
  }
}

class UserProfileService {
  UserProfileService({
    UserProfileStore? store,
    Object Function()? serverTimestamp,
  }) : _store = store ?? FirestoreUserProfileStore(),
       _serverTimestamp = serverTimestamp ?? FieldValue.serverTimestamp;

  final UserProfileStore _store;
  final Object Function() _serverTimestamp;

  Future<UserModel> ensureProfile(UserModel user) async {
    if (user.id.isEmpty || user.email.trim().isEmpty) {
      throw const FormatException('Tài khoản thiếu mã người dùng hoặc email.');
    }
    final data = await _store.transact(user.id, (previous) {
      final previousName = previous?['name'];
      var name = user.displayName.trim();
      if (name.isEmpty && previousName is String) name = previousName.trim();
      if (name.isEmpty) name = user.email.split('@').first;
      if (name.isEmpty) name = 'Người nghe nhạc';
      if (name.length > 60) name = name.substring(0, 60);
      final createdAt = previous?['createdAt'];
      return {
        'uid': user.id,
        'name': name,
        'email': user.email.trim(),
        'createdAt': createdAt is Timestamp || createdAt is DateTime
            ? createdAt
            : _serverTimestamp(),
      };
    });
    final createdAt = data['createdAt'];
    final timestamp = switch (createdAt) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      _ => throw const FormatException('Thời gian tạo hồ sơ chưa hợp lệ.'),
    };
    return UserModel(
      id: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['name'] as String,
      createdAt: timestamp,
    );
  }
}
