import 'package:flutter/widgets.dart';

import 'preferences.dart';

abstract class PreferenceListenable<T> implements Listenable {
  T get();

  void set(T newValue);
}

class PreferenceNotifier<T>
    with ChangeNotifier
    implements PreferenceListenable<T> {
  PreferenceNotifier({
    required this.key,
    required this.defaultValue,
    Preferences? prefs,
  })  : _prefs = prefs;

  final Preferences? _prefs;

  Preferences get prefs => _prefs ?? Preferences.instance;

  final String key;

  final T defaultValue;

  bool _isInitialized = false;

  T? _cache;

  @override
  T get() {
    if (!_isInitialized) {
      _isInitialized = true;
      _cache = prefs.get<T?>(key);
    }

    return _cache ?? defaultValue;
  }

  @override
  void set(T newValue) {
    if (_cache == newValue) {
      return;
    }

    prefs.edit((editor) {
      editor.put(key, newValue);
    });
    _cache = newValue;
    notifyListeners();
  }
}

typedef PreferenceValueWidgetBuilder<T> = Widget Function(BuildContext, T);

class PreferenceBuilder<T> extends StatefulWidget {
  const PreferenceBuilder({
    Key? key,
    required this.notifier,
    required this.builder,
  }) : super(key: key);

  final PreferenceListenable<T> notifier;

  final PreferenceValueWidgetBuilder<T> builder;

  @override
  State<PreferenceBuilder<T>> createState() => _PreferenceBuilderState<T>();
}

class _PreferenceBuilderState<T> extends State<PreferenceBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.notifier.get();
    widget.notifier.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(PreferenceBuilder<T> oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_valueChanged);
      value = widget.notifier.get();
      widget.notifier.addListener(_valueChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      value = widget.notifier.get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value);
  }
}

class MultiPreferenceBuilder extends StatefulWidget {
  const MultiPreferenceBuilder({
    Key? key,
    this.listenable0,
    this.listenable1,
    this.listenable2,
    this.listenable3,
    this.listenable4,
    this.listenable5,
    required this.build,
  }) : super(key: key);

  final PreferenceListenable? listenable0;
  final PreferenceListenable? listenable1;
  final PreferenceListenable? listenable2;
  final PreferenceListenable? listenable3;
  final PreferenceListenable? listenable4;
  final PreferenceListenable? listenable5;

  final Function(BuildContext context) build;

  @override
  State<MultiPreferenceBuilder> createState() => _MultiPreferenceBuilderState();
}

class _MultiPreferenceBuilderState extends State<MultiPreferenceBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable0?.addListener(_listener);
    widget.listenable1?.addListener(_listener);
    widget.listenable2?.addListener(_listener);
    widget.listenable3?.addListener(_listener);
    widget.listenable4?.addListener(_listener);
    widget.listenable5?.addListener(_listener);
  }

  @override
  void didUpdateWidget(MultiPreferenceBuilder oldWidget) {
    if (oldWidget.listenable0 != widget.listenable0) {
      oldWidget.listenable0?.removeListener(_listener);
      widget.listenable0?.addListener(_listener);
    }
    if (oldWidget.listenable1 != widget.listenable1) {
      oldWidget.listenable1?.removeListener(_listener);
      widget.listenable1?.addListener(_listener);
    }
    if (oldWidget.listenable2 != widget.listenable2) {
      oldWidget.listenable2?.removeListener(_listener);
      widget.listenable2?.addListener(_listener);
    }
    if (oldWidget.listenable3 != widget.listenable3) {
      oldWidget.listenable3?.removeListener(_listener);
      widget.listenable3?.addListener(_listener);
    }
    if (oldWidget.listenable4 != widget.listenable4) {
      oldWidget.listenable4?.removeListener(_listener);
      widget.listenable4?.addListener(_listener);
    }
    if (oldWidget.listenable5 != widget.listenable5) {
      oldWidget.listenable5?.removeListener(_listener);
      widget.listenable5?.addListener(_listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.listenable0?.removeListener(_listener);
    widget.listenable1?.removeListener(_listener);
    widget.listenable2?.removeListener(_listener);
    widget.listenable3?.removeListener(_listener);
    widget.listenable4?.removeListener(_listener);
    widget.listenable5?.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}

