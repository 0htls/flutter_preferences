import 'dart:async';
import 'dart:collection';

class Task {
  Task(this._callback);

  final _completer = Completer<void>();

  Future<void> get future => _completer.future;

  final Future<void> Function() _callback;

  void _run() {
    _callback().then((_) => _completer.complete());
  }
}

class TaskQueue {
  final _pending = Queue<Task>();

  Task? _current;

  void _runTask(Task task) {
    _current = task;
    task._run();
    task.future.whenComplete(() {
      _current = null;
      if (_pending.isNotEmpty) {
        _runTask(_pending.removeFirst());
      }
    });
  }

  void add(Task task) {
    if (_current == null) {
      _runTask(task);
    } else {
      _pending.add(task);
    }
  }
}