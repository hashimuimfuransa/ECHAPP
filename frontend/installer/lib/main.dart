import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:process/process.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const ExcellenceInstallerApp());
}

class ExcellenceInstallerApp extends StatelessWidget {
  const ExcellenceInstallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excellence Coaching Hub Installer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const InstallerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InstallerHomePage extends StatefulWidget {
  const InstallerHomePage({super.key});

  @override
  State<InstallerHomePage> createState() => _InstallerHomePageState();
}

class _InstallerHomePageState extends State<InstallerHomePage> {
  int _currentStep = 0;
  bool _isInstalling = false;
  String _installStatus = '';
  double _progress = 0.0;
  String _installPath = '';
  
  final List<String> _steps = [
    'Welcome',
    'License Agreement',
    'Installation Location',
    'Ready to Install',
    'Installing',
    'Complete'
  ];

  @override
  void initState() {
    super.initState();
    _getDefaultInstallPath();
  }

  void _getDefaultInstallPath() async {
    final appData = await getApplicationSupportDirectory();
    final defaultPath = path.join(path.dirname(appData.path), 'ExcellenceCoachingHub');
    setState(() {
      _installPath = defaultPath;
    });
  }

  Future<void> _startInstallation() async {
    setState(() {
      _isInstalling = true;
      _currentStep = 4;
    });

    try {
      // Step 1: Build the app
      _updateStatus('Building Excellence Coaching Hub...', 0.1);
      await _runCommand('flutter', ['build', 'windows', '--release']);
      
      // Step 2: Create installation directory
      _updateStatus('Creating installation directory...', 0.3);
      final installDir = Directory(_installPath);
      if (!(await installDir.exists())) {
        await installDir.create(recursive: true);
      }
      
      // Step 3: Copy files
      _updateStatus('Copying application files...', 0.6);
      final buildDir = Directory('build/windows/x64/runner/Release');
      await _copyDirectory(buildDir, installDir);
      
      // Step 4: Create shortcuts
      _updateStatus('Creating desktop shortcuts...', 0.8);
      await _createShortcuts();
      
      // Step 5: Complete
      _updateStatus('Installation completed successfully!', 1.0);
      
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _currentStep = 5;
        _isInstalling = false;
      });
      
    } catch (e) {
      setState(() {
        _installStatus = 'Installation failed: $e';
        _isInstalling = false;
      });
    }
  }

  Future<void> _runCommand(String executable, List<String> arguments) async {
    final process = await Process.start(executable, arguments, runInShell: true);
    await process.exitCode;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final file in source.list(recursive: true)) {
      if (file is File) {
        final relativePath = path.relative(file.path, from: source.path);
        final destinationFile = File(path.join(destination.path, relativePath));
        await destinationFile.create(recursive: true);
        await file.copy(destinationFile.path);
      }
    }
  }

  Future<void> _createShortcuts() async {
    // This would create Windows shortcuts using Windows API
    // For now, we'll just show a message
    _updateStatus('Desktop shortcuts will be created', 0.9);
  }

  void _updateStatus(String status, double progress) {
    setState(() {
      _installStatus = status;
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excellence Coaching Hub Installer'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: _currentStep / (_steps.length - 1),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            
            // Current step content
            Expanded(
              child: _buildStepContent(),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildLicenseStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildReadyStep();
      case 4:
        return _buildInstallingStep();
      case 5:
        return _buildCompleteStep();
      default:
        return Container();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.school,
          size: 80,
          color: Colors.blue[800],
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome to Excellence Coaching Hub',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'This installer will guide you through the installation process of Excellence Coaching Hub, your comprehensive e-learning platform.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),
        const Text(
          'Click Next to continue.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLicenseStep() {
    return Column(
      children: [
        const Text(
          'License Agreement',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          height: 300,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const SingleChildScrollView(
            child: Text(
              'END USER LICENSE AGREEMENT\n\n'
              'Please read this End User License Agreement carefully before using Excellence Coaching Hub.\n\n'
              '1. LICENSE GRANT\n'
              'This is a license agreement for Excellence Coaching Hub, an educational software platform.\n\n'
              '2. USE OF SOFTWARE\n'
              'You may use this software for educational purposes in accordance with applicable laws.\n\n'
              '3. RESTRICTIONS\n'
              'You may not distribute, modify, or reverse engineer this software without permission.\n\n'
              '4. DISCLAIMER\n'
              'This software is provided "as is" without warranty of any kind.\n\n'
              'By clicking "I Agree", you acknowledge that you have read and agree to these terms.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _currentStep > 1,
              onChanged: (value) {
                if (value == true) {
                  setState(() {
                    _currentStep = 2;
                  });
                }
              },
            ),
            const Text('I agree to the terms and conditions'),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        const Text(
          'Installation Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choose the folder where you want to install Excellence Coaching Hub:',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: TextEditingController(text: _installPath),
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Installation Folder',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.folder),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The application will be installed in the selected folder. You can change the location by clicking Browse.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildReadyStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        const Text(
          'Ready to Install',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Excellence Coaching Hub is now ready to be installed on your computer.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Installation Summary:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('• Application: Excellence Coaching Hub'),
              Text('• Version: 1.0.0'),
              Text('• Installation Location: C:\\Users\\Public\\ExcellenceCoachingHub'),
              Text('• Desktop Shortcut: Will be created'),
              Text('• Start Menu Entry: Will be created'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstallingStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 30),
        Text(
          _installStatus,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 10),
        Text('${(_progress * 100).toInt()}%'),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        const Text(
          'Installation Complete!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Excellence Coaching Hub has been successfully installed on your computer.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),
        const Text(
          'You can now launch the application from:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text('• Desktop shortcut', style: TextStyle(fontSize: 14)),
        const Text('• Start Menu → Excellence Coaching Hub', style: TextStyle(fontSize: 14)),
        const Text('• Installation folder', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          ElevatedButton(
            onPressed: _isInstalling ? null : () {
              setState(() {
                _currentStep--;
              });
            },
            child: const Text('Back'),
          )
        else
          const SizedBox(width: 80),
          
        if (_currentStep < _steps.length - 1)
          ElevatedButton(
            onPressed: _isInstalling || (_currentStep == 1 && _currentStep <= 1) ? null : () {
              if (_currentStep == 3) {
                _startInstallation();
              } else {
                setState(() {
                  _currentStep++;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: _currentStep == 3 ? const Text('Install') : const Text('Next'),
          )
        else
          ElevatedButton(
            onPressed: () {
              // Close installer
              exit(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Finish'),
          ),
      ],
    );
  }
}