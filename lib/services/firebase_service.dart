import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/song_model.dart';

typedef FirebaseInitializer = Future<void> Function();
typedef SongLoader = Future<List<SongModel>> Function();

const _connectionTimeout = Duration(seconds: 15);

Future<void> initializeFirebaseApp() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(_connectionTimeout);
  }
}

Future<List<SongModel>> loadSongsFromFirestore() async {
  // Read from the server so a successful check confirms live connectivity.
  final snapshot = await FirebaseFirestore.instance
      .collection('songs')
      .get(const GetOptions(source: Source.server))
      .timeout(_connectionTimeout);

  final songs = snapshot.docs
      .map((document) => SongModel.fromFirestore(document.id, document.data()))
      .toList();
  songs.sort((first, second) => first.id.compareTo(second.id));
  return songs;
}
