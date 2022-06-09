import 'dart:async';

import 'package:flutter/widgets.dart';

import 'preferences.dart';

extension PreferenceKeyExtension<R, P> on PreferenceKey<R, P> {
  R watch(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<PreferencesScope>(aspect: this);
    if (scope == null) {
      throw FlutterError('Required PreferenceScope!');
    }
    return scope.preferences.get(this);
  }

  R read({BuildContext? context}) {
    if (context != null) {
      final element = context.getElementForInheritedWidgetOfExactType<PreferencesScope>();
      if (element == null) {
        throw FlutterError('Required PreferencesScope!');
      }
      return (element.widget as PreferencesScope).preferences.get(this);
    } else {
      return Preferences.instance.get(this);
    }
  }

  void update(R newValue, {BuildContext? context}) {
    if (context != null) {
      final element = context.getElementForInheritedWidgetOfExactType<PreferencesScope>();
      if (element == null) {
        throw FlutterError('Required PreferencesScope!');
      }
      (element.widget as PreferencesScope).preferences.edit((editor) {
        editor.put(this, newValue);
      });
    } else {
      Preferences.instance.edit((editor) {
        editor.put(this, newValue);
      });
    }
  }
}

class PreferencesScope extends InheritedWidget {
  const PreferencesScope({
    super.key,
    required Widget child,
    required this.preferences,
  }) : super(child: child);

  final Preferences preferences;

  @override
  InheritedElement createElement() => _PreferencesScopeElement(this);

  @override
  bool updateShouldNotify(PreferencesScope oldWidget) {
    return preferences != oldWidget.preferences;
  }
}

class _PreferencesScopeElement extends InheritedElement {
  _PreferencesScopeElement(PreferencesScope widget) : super(widget) {
    _subscription = widget.preferences.events.listen(_handleNewEvent);
  }

  StreamSubscription<PreferencesEvent>? _subscription;
  PreferencesEvent? _pendingEvent;

  void _handleNewEvent(PreferencesEvent event) {
    _pendingEvent = event;
    markNeedsBuild();
  }

  @override
  void unmount() {
    _subscription?.cancel();
    super.unmount();
  }

  @override
  void update(PreferencesScope newWidget) {
    final oldPreferences = (widget as PreferencesScope).preferences;
    final newPreferences = newWidget.preferences;
    if (oldPreferences != newPreferences) {
      _subscription!.cancel();
      _subscription = newPreferences.events.listen(_handleNewEvent);
    }
    super.update(newWidget);
  }

  @override
  Widget build() {
    if (_pendingEvent != null) {
      notifyClients(widget as PreferencesScope);
    }
    return super.build();
  }

  @override
  void notifyClients(PreferencesScope oldWidget) {
    super.notifyClients(oldWidget);
    _pendingEvent = null;
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final keys =
        getDependencies(dependent) as Set<PreferenceKey<Object?, Object?>>? ??
            <PreferenceKey<Object?, Object?>>{};
    setDependencies(
      dependent,
      keys..add(aspect as PreferenceKey<Object?, Object?>),
    );
  }

  @override
  void notifyDependent(PreferencesScope oldWidget, Element dependent) {
    if (_pendingEvent == null || _pendingEvent!.forceUpdate) {
      dependent.didChangeDependencies();
      return;
    }
    final keys = getDependencies(dependent) as Set<PreferenceKey<Object?, Object?>>;
    assert(keys.isNotEmpty);
    for (final updatedKey in _pendingEvent!.updatedKeys) {
      if (keys.contains(updatedKey)) {
        dependent.didChangeDependencies();
        break;
      }
    }
  }
}
