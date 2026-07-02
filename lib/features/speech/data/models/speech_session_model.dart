import 'package:isar/isar.dart';

part 'speech_session_model.g.dart';

@collection
class SpeechSession {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionId;

  @Index()
  late String userId;

  late String title;

  String? localAudioPath;

  late int duration;

  String? transcript;
  int? wordCount;
  int? fillerWordCount;
  int? pace;
  int? score;

  late DateTime createdAt;
}
