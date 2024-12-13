import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class QuestionWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final int index;
  final String answer;
  final Function(String) onChanged;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.index,
    required this.answer,
    required this.onChanged,
  });

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    if (widget.question['type'] == 'essay' ||
        widget.question['type'] == 'short answer') {
      _textController = TextEditingController(text: widget.answer);
    }
  }

  @override
  void didUpdateWidget(covariant QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.question['type'] == 'essay' ||
            widget.question['type'] == 'short answer') &&
        widget.answer != oldWidget.answer &&
        widget.answer != (_textController?.text ?? '')) {
      _textController?.text = widget.answer;
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  Widget _buildAnswerWidget() {
    switch (widget.question['type']) {
      case 'MCQ':
        return Column(
          children: (widget.question['options'] as List<dynamic>).map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: widget.answer,
              onChanged: (value) => widget.onChanged(value!),
            );
          }).toList(),
        );
      case 'T/F':
        return Column(
          children: ['True', 'False'].map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option.toLowerCase(),
              groupValue: widget.answer,
              onChanged: (value) => widget.onChanged(value!),
            );
          }).toList(),
        );
      case 'essay':
      case 'short answer':
        return Directionality(
          textDirection:
              TextDirection.ltr, // Ensure left-to-right text direction
          child: TextField(
            maxLines: widget.question['type'] == 'essay' ? 5 : 2,
            decoration: InputDecoration(
              hintText: 'Enter your answer here',
              border: OutlineInputBorder(),
            ),
            controller: _textController,
            onChanged: widget.onChanged,
          ),
        );
      default:
        return Text('Unsupported question type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question ${widget.index + 1}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(widget.question['text']),
        SizedBox(height: 16),
        widget.question['image path'] != null
            ? FutureBuilder<String>(
                future: _getImageUrl(widget.question['image path']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error loading image');
                  } else if (snapshot.hasData) {
                    return Image.network(snapshot.data!);
                  } else {
                    return SizedBox();
                  }
                },
              )
            : SizedBox(),
        SizedBox(height: 16),
        _buildAnswerWidget(),
        SizedBox(height: 24),
      ],
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    final ref = FirebaseStorage.instance.ref().child(imagePath);
    return await ref.getDownloadURL();
  }
}
