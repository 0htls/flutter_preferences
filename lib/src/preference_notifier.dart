import 'package:flutter/foundation.dart';

abstract class PreferenceNotifier<T> implements Listenable {
  T get();

  Future<void> set(T newValue);
}

class PreferenceInt extends PreferenceNotifier<int> with ChangeNotifier {
  @override
  int get() {
    throw UnimplementedError();
  }

  @override
  Future<void> set(int newValue) {
    throw UnimplementedError();
  }
}

class PreferenceDouble {

}
