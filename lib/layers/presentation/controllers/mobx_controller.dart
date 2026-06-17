import 'package:mobx/mobx.dart';

abstract class MobxController {
  final Observable<bool> isLoading = Observable(false);
  final Observable<String?> errorMessage = Observable(null);

  void setLoading(bool value) {
    runInAction(() => isLoading.value = value);
  }

  void setError(String? message) {
    runInAction(() => errorMessage.value = message);
  }
}
