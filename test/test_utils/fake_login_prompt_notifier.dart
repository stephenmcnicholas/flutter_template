import 'package:fytter/src/providers/login_prompt_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLoginPromptNotifier extends LoginPromptNotifier {
  FakeLoginPromptNotifier._() : super();

  factory FakeLoginPromptNotifier() {
    SharedPreferences.setMockInitialValues({'loginPromptDismissed': true});
    SharedPrefs.instance.resetForTests();
    return FakeLoginPromptNotifier._();
  }
}
