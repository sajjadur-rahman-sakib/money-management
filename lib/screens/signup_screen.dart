import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_management/core/constants.dart';
import 'package:money_management/screens/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String error = '';

  Future<void> register() async {
    setState(() {
      isLoading = true;
      error = ''; // Clear previous errors
    });

    // Validate inputs first
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        isLoading = false;
        error = 'Please fill in all fields';
      });
      return;
    }

    try {
      print('Attempting registration...');
      print('Base URL: $baseUrl');

      // Try different endpoint variations
      final endpoints = [
        '$baseUrl/register',
        '$baseUrl/auth/register',
        '$baseUrl/api/register',
        '$baseUrl/api/auth/register',
        '$baseUrl/signup',
        '$baseUrl/users/register',
      ];

      http.Response? successResponse;
      bool serverResponding = false;
      bool allEndpointsMissingToken = true;

      for (String endpoint in endpoints) {
        print('Trying endpoint: $endpoint');

        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': nameController.text.trim(),
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
          else if (response.statusCode == 400 || response.statusCode == 409) {
            successResponse = response;
            allEndpointsMissingToken = false;
            break;
          }
          // If it's not the generic "missing token" error
          else if (response.statusCode == 401 &&
              !response.body.contains('missing token')) {
            successResponse = response;
            allEndpointsMissingToken = false;
            break;
          }
          // Check if this specific endpoint returns "missing token"
          else if (!response.body.contains('missing token')) {
            allEndpointsMissingToken = false;
          }
        } catch (e) {
          print('Error with $endpoint: $e');
          continue;
        }
      }

      setState(() {
        isLoading = false;
      });

      if (successResponse != null) {
        print('Using response from successful endpoint');
        print('Final response status: ${successResponse.statusCode}');
        print('Final response body: ${successResponse.body}');

        if (successResponse.statusCode >= 200 &&
            successResponse.statusCode < 300) {
          print('Registration successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        } else {
          // Handle server error
          String errorMessage = 'Registration failed';
          try {
            final responseData = jsonDecode(successResponse.body);
            if (responseData is Map<String, dynamic>) {
              errorMessage =
                  responseData['message'] ??
                  responseData['error'] ??
                  'Registration failed';
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } catch (e) {
            errorMessage = successResponse.body.isNotEmpty
                ? successResponse.body
                : 'Registration failed';
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
              'Server Error: All registration endpoints require authentication.\n\n'
              'This is a backend configuration issue. For development purposes, '
              'tap "Dev Mode" to simulate successful registration.';
        });
      } else {
        setState(() {
          error = serverResponding
              ? 'Server configuration error: Registration endpoints have issues.'
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

  // Development mode registration simulation
  Future<void> registerDevMode() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
    });

    print('Development mode registration for: ${emailController.text}');

    // Show success message and navigate
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Development Mode: Registration simulated successfully!'),
        backgroundColor: Colors.orange,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: register,
                    child: const Text('Register'),
                  ),
                  // Show development mode button if server has auth issues
                  if (error.contains(
                    'Server Error: All registration endpoints',
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: registerDevMode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Dev Mode (Simulate Registration)'),
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
          ],
        ),
      ),
    );
  }
}
