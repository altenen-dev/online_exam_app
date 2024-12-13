# Online Exam App

## Description

This project is a Flutter-based mobile application developed for ITCS444. It's designed to facilitate online exams, providing features for both students and instructors. The app includes user authentication, exam creation, participation, and result viewing functionalities.

## Features

- User Authentication (Login/Signup)
- Role-based access (Student/Instructor)
- Exam Creation (for Instructors)
- Exam Participation (for Students)
- Real-time exam taking experience
- Result viewing and analysis
- Profile management
- Secure data handling with Firebase

## Screenshots

Here are some screenshots showcasing the key features of our Online Exam App:

| ![Screenshot 1]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture1.png) | ![Screenshot 2]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture2.png) | ![Screenshot 3]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture3.png) |
|:-----------------------------------:|:-----------------------------------:|:-----------------------------------:|
|            Login Screen              |            Sign up Screen              |         Exams Screen               |

| ![Screenshot 4]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture4.png) | ![Screenshot 5]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture5.png) | ![Screenshot 6]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture6.png) |
|:-----------------------------------:|:-----------------------------------:|:-----------------------------------:|
|          Profile Management           |            Exam Taking          |        Results View            |



| ![Screenshot 7]([images/](https://github.com/altenen-dev/online_exam_app/blob/master/images/)picture7.png) | 
|:-----------------------------------:|
          Exam Taking           

## Technologies Used

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

## Setup and Installation

1. **Clone the repository**
   ```
   git clone https://github.com/your-username/itcs444-online-exam-app.git
   ```

2. **Install dependencies**
   Navigate to the project directory and run:
   ```
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/)
   - Add an Android and/or iOS app to your Firebase project
   - Download the `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS) and place it in the appropriate directory in your Flutter project
   - Enable Authentication, Cloud Firestore, and Storage in your Firebase project

4. **Run the app**
   ```
   flutter run
   ```

## Project Structure

- `lib/`
  - `main.dart`: Entry point of the application
  - `auth.dart`: Handles authentication logic
  - `login.dart`: Login page UI and logic
  - `signup.dart`: Signup page UI and logic
  - `attachment.dart`: Handles file attachments and uploads
  - (Other files for exam creation, participation, results, etc.)

## Contributing

Contributions to improve the app are welcome. Please follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature-branch`)
3. Make your changes and commit (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature-branch`)
5. Create a new Pull Request

## License

[MIT License](LICENSE)

---

This project is part of the ITCS444 course requirements.

