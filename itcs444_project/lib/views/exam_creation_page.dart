import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Online_Exam_App/logic/attachment.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:provider/provider.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:uuid/uuid.dart';

class ExamCreationPage extends StatefulWidget {
  const ExamCreationPage({super.key});

  @override
  _ExamCreationPageState createState() => _ExamCreationPageState();
}

class _ExamCreationPageState extends State<ExamCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxAttemptsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _displayStyle = 'all'; // Default display style
  bool _questionShuffle = false;
  GlobalKey<AnimatedListState> animatedListKey = GlobalKey();
  final List<Map<String, dynamic>> _questions = [];
  Widget buildQuestionListTile(
      Map<String, dynamic> question, Animation<double> animation, int index) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: Card(
        child: ListTile(
          title: Text(question['text']),
          subtitle: Text('${question['type']}, Marks:  ${question['marks']}'),
          trailing: IconButton(
              onPressed: () {
                setState(() {
                  removeQuestion(index);
                });
              },
              icon: Icon(
                Icons.remove,
                color: Colors.red,
              )),
        ),
      ),
    );
  }

  void removeQuestion(int index) {
    final removedItem = _questions[index];
    _questions.removeAt(index);
    animatedListKey.currentState!.removeItem(
        index,
        (context, animation) =>
            buildQuestionListTile(removedItem, animation, index));
  }

  void addQuestion(Map<String, dynamic> question) {
    _questions.add(question);
    animatedListKey.currentState!.insertItem(_questions.length - 1);
  }

  XFile? selectedImage;
  final uuid = Uuid();
  var examId;
  @override
  void initState() {
    examId = uuid.v4();
  }

  void _pickDate({required bool isStartDate}) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        final selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = selectedDateTime;
          } else {
            _endDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _addQuestion(String examId) async {
    final questionId = uuid.v4();
    final newQuestion = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        final questionController = TextEditingController();
        final marksController = TextEditingController();
        String? selectedType;
        String? correctAnswer;
        bool picked = false;
        final List<String> mcqOptions = List.filled(4, '', growable: false);
        Future<void> pickImage() async {
          final picker = ImagePicker();
          final pickedFile =
              await picker.pickImage(source: ImageSource.gallery);

          if (pickedFile != null) {
            setState(() {
              picked = true; // Mark that an image has been picked
              selectedImage = pickedFile; // Store the file (mobile)
            });
          } else {}
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Question'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    TextField(
                      controller: questionController,
                      decoration:
                          InputDecoration(labelText: 'Enter question text'),
                    ),
                    SizedBox(height: 10),
                    // Marks
                    TextField(
                      controller: marksController,
                      decoration: InputDecoration(labelText: 'Marks'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    // Image Upload
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: pickImage,
                          child: Text('Upload Image'),
                        ),
                        SizedBox(width: 10),
                        if (picked)
                          Text('Image selected',
                              style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Question Type
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: [
                        DropdownMenuItem(value: 'MCQ', child: Text('MCQ')),
                        DropdownMenuItem(value: 'T/F', child: Text('T/F')),
                        DropdownMenuItem(
                            value: 'short answer', child: Text('Short Answer')),
                        DropdownMenuItem(value: 'essay', child: Text('Essay')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                          correctAnswer =
                              null; // Reset correct answer for new type
                        });
                      },
                      decoration: InputDecoration(labelText: 'Question Type'),
                    ),
                    SizedBox(height: 10),
                    // MCQ Options
                    if (selectedType == 'MCQ')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < 4; i++)
                            TextField(
                              decoration: InputDecoration(
                                labelText:
                                    'Option ${i + 1} ${i > 1 ? "(optional)" : ""}',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (mcqOptions.contains(value)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Duplicate options are not allowed')),
                                    );
                                  } else {
                                    mcqOptions[i] = value;
                                    if (!mcqOptions.contains(correctAnswer)) {
                                      correctAnswer =
                                          null; // Reset correct answer if invalid
                                    }
                                  }
                                });
                              },
                            ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: correctAnswer,
                            items: mcqOptions
                                .where((option) => option.isNotEmpty)
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                correctAnswer = value;
                              });
                            },
                            decoration:
                                InputDecoration(labelText: 'Correct Answer'),
                          ),
                        ],
                      ),
                    // T/F Correct Answer
                    if (selectedType == 'T/F')
                      DropdownButtonFormField<String>(
                        value: correctAnswer,
                        items: [
                          DropdownMenuItem(value: 'true', child: Text('True')),
                          DropdownMenuItem(
                              value: 'false', child: Text('False')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            correctAnswer = value;
                          });
                        },
                        decoration:
                            InputDecoration(labelText: 'Correct Answer'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (questionController.text.isEmpty ||
                        marksController.text.isEmpty ||
                        selectedType == null ||
                        (selectedType == 'MCQ' &&
                            (mcqOptions
                                        .where((option) => option.isNotEmpty)
                                        .length <
                                    2 ||
                                correctAnswer == null)) ||
                        (selectedType == 'T/F' && correctAnswer == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Please complete all required fields')),
                      );
                      return;
                    } else if (int.parse(marksController.text) <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Marks should be greater than zero!')),
                      );
                      return;
                    }
                    Map<String, Object?> question;
                    if (selectedImage == null) {
                      question = {
                        'id': questionId,
                        'text': questionController.text,
                        'marks': int.parse(marksController.text),
                        'type': selectedType,
                        'options': selectedType == 'MCQ'
                            ? mcqOptions
                                .where((option) => option.isNotEmpty)
                                .toList()
                            : null,
                        'correct answer': correctAnswer,
                        'image path': null,
                      };
                    } else {
                      question = {
                        'id': questionId,
                        'text': questionController.text,
                        'marks': int.parse(marksController.text),
                        'type': selectedType,
                        'options': selectedType == 'MCQ'
                            ? mcqOptions
                                .where((option) => option.isNotEmpty)
                                .toList()
                            : null,
                        'correct answer': correctAnswer,
                        'image path': 'examsImgs/$examId/$questionId.jpg',
                      };
                    }
                    Navigator.of(context).pop(question);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (newQuestion != null) {
      setState(() {
        addQuestion(newQuestion);
      });
    }
  }

  Future<void> _saveExam(String examId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }
    // Upload images for all questions
    for (final question in _questions) {
      if (question['image path'] != null) {
        final imagePath = question['image path'] as String;
        try {
          String? uploadedUrl;
          if (kIsWeb) {
            uploadedUrl = await uploadImageWeb(
              selectedImage!, // Use XFile for web upload
              'examsImgs/$examId/${question['id']}.jpg',
            );
          } else {
            uploadedUrl = await uploadImage(
              File(imagePath), // Use File for mobile upload
              'examsImgs/$examId/${question['id']}.jpg',
            );
          }

          if (uploadedUrl == null) {
            throw Exception('Failed to upload image for question.');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
          return;
        }
      }
    }

    Exam newExam = Exam(
      id: examId,
      title: _titleController.text,
      duration: int.parse(_durationController.text),
      maxAttempts: int.parse(_maxAttemptsController.text),
      start: _startDate!,
      end: _endDate!,
      questions: _questions,
      creatorId: currentUser!.uid,
      displayStyle: _displayStyle,
      questionShuffle: _questionShuffle,
    );

    try {
      await examProvider.addExam(newExam, examId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exam created successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Exam')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Exam Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Exam Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the duration';
                  } else if (int.parse(value) <= 0) {
                    return 'duration must be greater than zero.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _maxAttemptsController,
                decoration: InputDecoration(
                  labelText: 'Max Attempts',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the maximum attempts';
                  } else if (int.parse(value) <= 0) {
                    return 'maximum attempts must be greater than zero.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(
                  _startDate == null
                      ? 'Select Start Date & Time'
                      : 'Start: ${_startDate.toString()}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDate(isStartDate: true),
              ),
              ListTile(
                title: Text(
                  _endDate == null
                      ? 'Select End Date & Time'
                      : 'End: ${_endDate.toString()}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDate(isStartDate: false),
              ),
              DropdownButtonFormField<String>(
                value: _displayStyle,
                decoration:
                    InputDecoration(labelText: 'Question Display Style'),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All Questions')),
                  DropdownMenuItem(value: 'one', child: Text('One by One')),
                ],
                onChanged: (value) {
                  setState(() {
                    _displayStyle = value!;
                  });
                },
              ),
              SizedBox(height: 5),
              SwitchListTile(
                title: Text("Shuffle Questions"),
                value: _questionShuffle,
                onChanged: (value) {
                  setState(() {
                    _questionShuffle = value;
                  });
                },
              ),

              SizedBox(height: 10),
              Text(
                'Questions (${_questions.length}):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // here animation limit
              SizedBox(
                height: 200,
                child: AnimatedList(
                  key: animatedListKey,
                  initialItemCount: _questions.length,
                  itemBuilder: (context, index, animation) {
                    return buildQuestionListTile(
                        _questions[index], animation, index);
                  },
                ),
              ),
              ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Question'),
                  onPressed: () {
                    _addQuestion(examId);
                  }),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _saveExam(examId);
                  },
                  child: Text('Create Exam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
