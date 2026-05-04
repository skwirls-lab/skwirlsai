import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Show a snackbar at the top of the screen so it doesn't cover the input area.
void showTopSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  final mq = MediaQuery.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: mq.size.height - mq.padding.top - 120,
        left: 16,
        right: 16,
      ),
      dismissDirection: DismissDirection.up,
      duration: const Duration(seconds: 3),
    ),
  );
}
