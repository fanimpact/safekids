import '../models/activity_draft.dart';

class ActivityController {
  ActivityController._();

  static final ActivityController instance =
      ActivityController._();

  ActivityDraft draft = ActivityDraft();

  void reset() {
    draft = ActivityDraft();
  }
}