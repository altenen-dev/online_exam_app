import 'package:flutter/material.dart';
import 'package:Online_Exam_App/models/examProvider.dart';

class SolvedExamPage extends StatelessWidget {
  final Exam exam;

  const SolvedExamPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${exam.title} - Solution')),
      body: ListView.builder(
        itemCount: exam.questions.length,
        itemBuilder: (context, index) {
          final question = exam.questions[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(question['question']),
                  SizedBox(height: 16),
                  ...question['options'].map<Widget>((option) => ListTile(
                        title: Text(option),
                        leading: option == question['correctAnswer']
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.radio_button_unchecked),
                      )),
                  SizedBox(height: 16),
                  Text(
                    'Explanation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(question['explanation'] ?? 'No explanation provided.'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
