import 'package:flutter/material.dart';

class EditAnswerKeyArgs {
  final String quizId;
  final String quizName;

  const EditAnswerKeyArgs({
    required this.quizId,
    required this.quizName,
  });
}

class EditAnswerKeyPage extends StatelessWidget {
  final EditAnswerKeyArgs? args;

  const EditAnswerKeyPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final quizName = args?.quizName ?? 'Unknown Quiz';

    return Scaffold(
      appBar: AppBar(
        title: Text('Answer Key - $quizName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save answer key
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Answer key editor will be implemented here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
