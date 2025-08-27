# DoNow – AI-Powered Productivity & Task Management App
---
# Once you clone this repo 
- add **.env** file in your main branch i.e where your pubspec.yaml file is
- and add **GEMINI_API_KEY=YOURGeminiAPI** inside the file
---
## Overview
DoNow is an intelligent task management and productivity enhancement application designed to help users overcome procrastination and optimize their daily schedules. By leveraging Machine Learning (ML), Firebase, and Flutter, the app provides personalized reminders, adaptive task scheduling, and behavioral insights to ensure tasks are completed efficiently.

---

## Purpose
The primary goal of DoNow is to provide a **real-time productivity companion** that not only tracks tasks but also predicts procrastination patterns and intervenes with timely reminders, motivational prompts, and schedule adjustments. 

---

## Target Users
- **Students** – Managing academic schedules, assignments, and exams.
- **Professionals** – Balancing project deadlines, meetings, and work-life priorities.
- **Freelancers & Creatives** – Organizing tasks across multiple clients and projects.
- **Anyone Seeking to Beat Procrastination** – Users who want more than a static to-do list.

---

## Key Features
1. **Smart Task Planning** – Users can add tasks with deadlines; app generates personalized timetables.
2. **Behavioral Tracking** – Detects unproductive app usage and prompts corrective actions.
3. **Real-Time Notifications** – Reminds users when tasks start or are due.
4. **Adaptive Scheduling** – Extends task duration if time is wasted, recalculating the plan.
5. **Seamless User Experience** – Flutter-based cross-platform design with smooth animations.
6. **Cloud Integration** – Firebase for authentication, task storage, and real-time sync.
7. **Machine Learning Insights** – Predicts procrastination patterns and suggests improvements.

---

## Technology Stack
- **Frontend Mobile**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, FCM Notifications)
- **Machine Learning**: Python-based ML model (future integration)
- **Database**: Firestore (NoSQL)
- **Version Control**: GitHub

---

## Workflow Overview
1. User enters a task & deadline.
2. App creates a timetable and sends reminders.
3. If user opens unproductive apps, warning is triggered.
4. Wasted time is tracked and task duration is adjusted.
5. At task completion, user confirms or extends time.
6. Completed tasks move to a “Success” dashboard for progress tracking.

---

## Installation
### **Prerequisites**
- Flutter SDK installed
- Firebase project configured
- VS Code / Android Studio for development

### **Steps**
```bash
git clone https://github.com/Umar9304/DoNow.git
cd DoNow
flutter pub get
flutter run
