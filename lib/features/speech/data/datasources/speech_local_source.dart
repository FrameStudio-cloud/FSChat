import 'package:isar/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../models/speech_session_model.dart';

class SpeechLocalSource {
  Isar get _isar => IsarService.instance;

  Stream<List<SpeechSession>> watchSessions(String userId) {
    return _isar.speechSessions
        .where()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true)
        .map((list) =>
            [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<List<SpeechSession>> getAllSessions(String userId) async {
    return _isar.speechSessions.where().userIdEqualTo(userId).findAll();
  }

  Future<SpeechSession?> getBySessionId(String sessionId) async {
    return _isar.speechSessions.where().sessionIdEqualTo(sessionId).findFirst();
  }

  Future<void> putSession(SpeechSession session) async {
    await _isar.writeTxn(() async {
      await _isar.speechSessions.put(session);
    });
  }

  Future<void> deleteSession(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.speechSessions.delete(id);
    });
  }
}
