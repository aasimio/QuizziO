import 'package:flutter/material.dart';

class ScanPapersArgs {
  final String quizId;
  final String quizName;

  const ScanPapersArgs({
    required this.quizId,
    required this.quizName,
  });
}

class ScanPapersPage extends StatelessWidget {
  final ScanPapersArgs? args;

  const ScanPapersPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final quizName = args?.quizName ?? 'Unknown Quiz';

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan - $quizName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Camera scanner will be implemented here',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
