import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

// Main function to run the app
void main() {
  runApp(MyApp());
}

// MyApp Widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.orange),
      ),
      home: LoginScreen(),
    );
  }
}

// LoginScreen Widget
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void handleLoginButtonPress() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      final authResponse = await authenticateUser(username, password);
      if (authResponse) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(username: username)),
        );
      } else {
        _showErrorDialog('Authentication failed');
      }
    } catch (e) {
      _showErrorDialog('Error during authentication: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Icon(Icons.lock, size: 100, color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: handleLoginButtonPress,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// HomeScreen Widget
class HomeScreen extends StatefulWidget {
  final String username;
  HomeScreen({required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  List<dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(_controller);
    _controller.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await fetchData();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error fetching data: $e');
    }
  }

  Future<List<dynamic>?> fetchData() async {
    try {
      final response = await http.get(Uri.parse('https://internee.pk/data'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: Text('Welcome, ${widget.username}!')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _data != null
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        itemCount: _data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_data![index].toString()),
                          );
                        },
                      ),
                    ),
                  )
                : Text('No data available'),
      ),
    );
  }
}

// Authentication function
Future<bool> authenticateUser(String username, String password) async {
  final response = await http.post(
    Uri.parse('https://internee.pk/authenticate'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'username': username,
      'password': password,
    }),
  );

  return response.statusCode == 200;
}

// Widget Tests
void runAppWithTests() {
  group('Authentication Tests', () {
    test('Successful authentication', () async {
      final result = await authenticateUser('valid_username', 'valid_password');
      expect(result, true);
    });

    test('Failed authentication', () async {
      final result = await authenticateUser('invalid_username', 'invalid_password');
      expect(result, false);
    });
  });

  group('Widget Tests', () {
    testWidgets('Login screen has a login button', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Login button triggers login process', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.enterText(find.byType(TextFormField).at(0), 'valid_username');
      await tester.enterText(find.byType(TextFormField).at(1), 'valid_password');
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(find.text('Welcome, valid_username!'), findsOneWidget);
    });
  });
}
