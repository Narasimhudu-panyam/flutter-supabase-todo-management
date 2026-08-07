import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (context.read<AuthProvider>().isLoading) return;

    try {
      final response = await context.read<AuthProvider>().register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully.')),
        );
        Navigator.pushReplacementNamed(context, AppRouter.home);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Check your email to confirm it, then sign in.'),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRouter.login);
    } on AuthApiException catch (error, stackTrace) {
      debugPrint('Sign-up failed: ${error.message}\n$stackTrace');

      if (!mounted) return;

      _showSignupError(error);
    } on AuthException catch (error, stackTrace) {
      debugPrint('Sign-up failed: ${error.message}\n$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create the account. Please try again later.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected sign-up failure: $error\n$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create the account. Try again.')),
      );
    }
  }

  String _signupErrorMessage(AuthApiException error) {
    final message = error.message.toLowerCase();

    if (error.statusCode == '429' || message.contains('rate limit')) {
      return 'Too many confirmation emails were requested. Please wait before trying again.';
    }
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'An account already exists for this email. Please sign in instead.';
    }
    if (message.contains('password')) {
      return 'Choose a stronger password and try again.';
    }

    return 'Unable to create the account. Please check your details and try again.';
  }

  void _showSignupError(AuthApiException error) {
    final message = error.message.toLowerCase();
    final accountExists =
        message.contains('already registered') || message.contains('already exists');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_signupErrorMessage(error)),
        action: accountExists
            ? SnackBarAction(
                label: 'Login',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRouter.login);
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: Validators.fullName,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                validator: Validators.password,
              ),

              const SizedBox(height: 35),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Register"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
