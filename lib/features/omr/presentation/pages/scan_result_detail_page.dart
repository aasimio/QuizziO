import 'package:flutter/material.dart';

class ScanResultDetailArgs {
  final String scanResultId;
  final String quizId;

  const ScanResultDetailArgs({
    required this.scanResultId,
    required this.quizId,
  });
}

class ScanResultDetailPage extends StatelessWidget {
  final ScanResultDetailArgs? args;

  const ScanResultDetailPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share result
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Scan result details will be shown here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
