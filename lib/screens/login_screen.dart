import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_management/core/constants.dart';
import 'package:money_management/screens/book_list_screen.dart';
import 'package:money_management/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String error = '';

  Future<void> login(BuildContext context) async {
    setState(() {
      isLoading = true;
      error = '';
    });

    // Validate inputs first
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        isLoading = false;
        error = 'Please fill in all fields';
      });
      return;
    }

    try {
      print('Attempting login...');
      print('Base URL: $baseUrl');

      // Try different login endpoint variations
      final endpoints = [
        '$baseUrl/login',
        '$baseUrl/auth/login',
        '$baseUrl/api/login',
        '$baseUrl/api/auth/login',
        '$baseUrl/signin',
      ];

      http.Response? successResponse;
      bool serverResponding = false;
      bool allEndpointsMissingToken = true;

      for (String endpoint in endpoints) {
        print('Trying login endpoint: $endpoint');

        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailController.text.trim(),
              'password': passwordController.text,
            }),
          );

          serverResponding = true;
          print(
            'Response from $endpoint: ${response.statusCode} - ${response.body}',
          );

          // If we get a successful response
          if (response.statusCode >= 200 && response.statusCode < 300) {
            successResponse = response;
            allEndpointsMissingToken = false;
            break;
          }
          // If we get a meaningful error (not just "missing token")
          else if (response.statusCode == 400 || response.statusCode == 401) {
            if (!response.body.contains('missing token')) {
              successResponse = response;
              allEndpointsMissingToken = false;
              break;
            }
          }
          // Check if this specific endpoint returns "missing token"
          else if (!response.body.contains('missing token')) {
            allEndpointsMissingToken = false;
          }
        } catch (e) {
          print('Error with login endpoint $endpoint: $e');
          continue;
        }
      }

      setState(() {
        isLoading = false;
      });

      if (successResponse != null) {
        print('Using response from successful login endpoint');
        print('Final login response status: ${successResponse.statusCode}');
        print('Final login response body: ${successResponse.body}');

        if (successResponse.statusCode >= 200 &&
            successResponse.statusCode < 300) {
          try {
            final data = jsonDecode(successResponse.body);
            final token = data['token'];
            if (token != null) {
              print('Login successful, navigating to book list');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BookListScreen(token: token)),
              );
              return;
            } else {
              setState(() {
                error = 'Login response missing token';
              });
              return;
            }
          } catch (e) {
            setState(() {
              error = 'Invalid login response format';
            });
            return;
          }
        } else {
          // Handle server error
          String errorMessage = 'Login failed';
          try {
            final responseData = jsonDecode(successResponse.body);
            if (responseData is Map<String, dynamic>) {
              errorMessage =
                  responseData['message'] ??
                  responseData['error'] ??
                  'Invalid credentials';
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } catch (e) {
            errorMessage = successResponse.body.isNotEmpty
                ? successResponse.body
                : 'Login failed';
          }

          setState(() {
            error = errorMessage;
          });
          return;
        }
      }

      // If all endpoints return "missing token", show development mode option
      if (serverResponding && allEndpointsMissingToken) {
        setState(() {
          error =
              'Server Error: All login endpoints require authentication.\n\n'
              'This is a backend configuration issue. For development purposes, '
              'tap "Dev Mode" to simulate successful login.';
        });
      } else {
        setState(() {
          error = serverResponding
              ? 'Login failed: Server configuration error.'
              : 'Unable to connect to server. Please check if the server is running at $baseUrl';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Network error: $e';
      });
    }
  }

  // Development mode login simulation
  Future<void> loginDevMode() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
    });

    print('Development mode login for: ${emailController.text}');

    // Show success message and navigate with a mock token
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Development Mode: Login simulated successfully!'),
        backgroundColor: Colors.orange,
      ),
    );

    // Use a mock token for development
    const mockToken = 'dev_mode_token_12345';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BookListScreen(token: mockToken)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => login(context),
                    child: Text("Login"),
                  ),
                  // Show development mode button if server has auth issues
                  if (error.contains('Server Error: All login endpoints'))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: loginDevMode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Dev Mode (Simulate Login)'),
                      ),
                    ),
                ],
              ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupScreen()),
                );
              },
              child: Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
