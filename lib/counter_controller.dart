import 'package:flutter/material.dart';

class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int _step = 0;
  int get value => _counter; // Getter untuk akses data
  List<List<String>> tracker_list = [];
  List<String> tracked_list = [];

  void increment() {
    _counter += _step;
    update_list("Increment");
  }

  void decrement() {
    if (_counter > 0) _counter -= _step;
    update_list("Decrement");
  }

  void reset() {
    _counter = 0;
    _step = 0;
    _step += 0;
    update_list("Reset");
  }

  void setStep(int step) {
    if (step > 0) {
      _step = step;
    }
  }

  void update_list(String action) {
    final time = DateTime.now().toLocal().toString().substring(11, 19);
    String logMessage = "$action at $time";
    tracked_list.add(logMessage);
    if (action == "Reset") {
      tracker_list.add(List.from(tracked_list));
      tracked_list.clear();
    }
  }
}
