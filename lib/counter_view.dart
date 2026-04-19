import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  dynamic showAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("Tidak"),
      onPressed: () => Navigator.of(context).pop(),
    );
    Widget continueButton = TextButton(
      child: Text("Ya"),
      onPressed: () {
        _controller.reset();
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Reset"),
      content: Text("Apakah kamu mau me-reset?"),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final step = int.tryParse(value);
                if (step != null) {
                  setState(() {
                    _controller.setStep(step);
                  });
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.tracked_list.length,

                itemBuilder: (context, index) {
                  return ListTile(title: Text(_controller.tracked_list[index]));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () => setState(() => _controller.increment()),
            backgroundColor: Color.fromARGB(255, 58, 183, 68),
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () => setState(() => _controller.decrement()),
            backgroundColor: Color.fromARGB(255, 183, 58, 58),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () => showAlertDialog(context),
            backgroundColor: Color.fromARGB(255, 172, 172, 172),
            child: const Icon(Icons.restart_alt),
          ),
        ],
      ),
    );
  }
}
