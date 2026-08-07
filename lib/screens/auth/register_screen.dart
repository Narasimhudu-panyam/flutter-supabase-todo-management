import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

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
  bool _hidePassword = true;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContent = true);
    });
  }

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
          content: Text(
            'Account created. Check your email to confirm it, then sign in.',
          ),
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
        const SnackBar(
          content: Text(
            'Unable to create the account. Please try again later.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected sign-up failure: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create the account. Try again.'),
        ),
      );
    }
  }

  String _signupErrorMessage(AuthApiException error) {
    final message = error.message.toLowerCase();

    if (error.statusCode == '429' || message.contains('rate limit')) {
      return 'Too many confirmation emails were requested. Please wait before trying again.';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
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
        message.contains('already registered') ||
        message.contains('already exists');

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1224), Color(0xFF111827), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _showContent ? 1 : 0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .24),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Create account',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter your details to start organizing your day.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              validator: Validators.fullName,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: _hidePassword,
                              validator: Validators.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _hidePassword = !_hidePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 26),
                            CustomButton(
                              text: 'Create account',
                              loading: auth.isLoading,
                              onPressed: _register,
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRouter.login,
                                    );
                                  },
                                  child: const Text('Sign in'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
