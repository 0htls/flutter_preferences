import 'dart:async';
import 'dart:collection';

class _Task {
  _Task(this.callback);

  final _completer = Completer<void>();

  Future<void> get future => _completer.future;

  final Future<void> Function() callback;

  void run() {
    callback().then((value) => _completer.complete());
  }
}

class TaskQueue {
  final _pending = Queue<_Task>();

  _Task? _current;

  void _runTask(_Task task) {
    _current = task;
    task.run();
    task.future.whenComplete(() {
      _current = null;
      if (_pending.isNotEmpty) {
        _runTask(_pending.removeFirst());
      }
    });
  }

  Future<void> add(Future<void> Function() callback) {
    final task = _Task(callback);
    if (_current == null) {
      _runTask(task);
    } else {
      _pending.add(task);
    }
    return task.future;
  }
}