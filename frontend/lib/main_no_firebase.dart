import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

void main() {
  runApp(const ExcellenceCoachingHubApp());
}

class ExcellenceCoachingHubApp extends StatelessWidget {
  const ExcellenceCoachingHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excellence Coaching Hub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excellence Coaching Hub'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show settings dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('App Status'),
                    content: const Text(
                      'Firebase connection: Not initialized\n'
                      'This is a test version to verify UI works\n'
                      'Full functionality requires Firebase setup'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              
              // App Title
              const Text(
                'Excellence Coaching Hub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              
              const Text(
                'Your Learning Platform',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // Feature Cards
              _buildFeatureCard(
                context,
                icon: Icons.book,
                title: 'Online Courses',
                subtitle: 'Access comprehensive learning materials',
                color: Colors.blue,
              ),
              const SizedBox(height: 15),
              
              _buildFeatureCard(
                context,
                icon: Icons.quiz,
                title: 'Practice Exams',
                subtitle: 'Test your knowledge with quizzes',
                color: Colors.green,
              ),
              const SizedBox(height: 15),
              
              _buildFeatureCard(
                context,
                icon: Icons.bar_chart,
                title: 'Progress Tracking',
                subtitle: 'Monitor your learning journey',
                color: Colors.orange,
              ),
              const SizedBox(height: 30),
              
              // Status Indicator
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'UI is working correctly!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation to ${['Home', 'Courses', 'Exams', 'Profile'][index]}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color}) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title feature'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}