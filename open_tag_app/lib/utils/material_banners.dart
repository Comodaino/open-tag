import 'package:flutter/material.dart';
import 'package:open_tag_app/theme/app_theme.dart';

void showErrorBanner(BuildContext context, String message) async {
  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: Text(message, style: const TextStyle(color: AppTheme.white)),
      leading: const Icon(Icons.error_outline, color: AppTheme.white),
      backgroundColor: AppTheme.errorRed,
      elevation: 2,
      actions: const <Widget>[
        SizedBox(width: 8),
      ],
    ),
  );
  await Future.delayed(const Duration(seconds: 2));
  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
}

void showSuccessBanner(BuildContext context, String message) async {
  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: Text(message, style: const TextStyle(color: AppTheme.white)),
      leading: const Icon(Icons.check_circle_outline, color: AppTheme.white),
      backgroundColor: AppTheme.successGreen,
      elevation: 2,
      actions: const <Widget>[
        SizedBox(width: 8),
      ],
    ),
  );
  await Future.delayed(const Duration(seconds: 2));
  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
}