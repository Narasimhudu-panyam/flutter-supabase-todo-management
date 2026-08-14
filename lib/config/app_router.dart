import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/update_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/tasks/create_task_screen.dart';
import '../screens/tasks/edit_task_screen.dart';
import '../screens/tasks/task_details_screen.dart';
import '../screens/tasks/task_history_screen.dart';
import '../models/task_model.dart';
import '../screens/splash/splash_screen.dart';

class AppRouter {
  static const splash = "/";
  static const login = "/login";
  static const register = "/register";
  static const forgotPassword = "/forgot-password";
  static const updatePassword = "/update-password";
  static const home = "/home";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case updatePassword:
        return MaterialPageRoute(builder: (_) => const UpdatePasswordScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/tasks/create':
        return MaterialPageRoute(builder: (_) => const CreateTaskScreen());
      case '/tasks/edit':
        return MaterialPageRoute(
          builder: (_) =>
              EditTaskScreen(task: settings.arguments! as TaskModel),
        );
      case '/details':
        return MaterialPageRoute(
          builder: (_) =>
              TaskDetailsScreen(task: settings.arguments! as TaskModel),
        );
      case '/history':
        return MaterialPageRoute(
          builder: (_) =>
              TaskHistoryScreen(taskId: settings.arguments! as String),
        );

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
