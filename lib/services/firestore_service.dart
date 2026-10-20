import 'package:gymgen_ai/models/assessment_model.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

class FirestoreService {
  FirestoreService._();

  static Future<void> saveAssessment(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final items =
        await LocalStorageService.instance.loadAssessmentHistory(uid);
    items.insert(0, data);
    await LocalStorageService.instance.saveAssessmentHistory(uid, items);
  }

  static Future<List<Map<String, dynamic>>> fetchAssessmentDocuments(
    String uid,
  ) =>
      LocalStorageService.instance.loadAssessmentHistory(uid);

  static Future<List<Assessment>> fetchAssessments(String uid) async {
    final items = await fetchAssessmentDocuments(uid);
    return items.map(Assessment.fromJson).toList();
  }
}
