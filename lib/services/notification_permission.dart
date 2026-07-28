import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

/// Android 13+ draws the playback notification, and with it the lock screen
/// transport controls, only while the user allows notifications. Audio keeps
/// playing either way, so a denial is silent unless the app points it out.

/// Asks for the permission and reports whether the app is still blocked.
///
/// Safe to call on every launch: once granted, the request resolves without
/// showing anything. Once denied, Android refuses to show the dialog ever
/// again, which leaves [openNotificationSettings] as the only way back.
Future<bool> requestNotificationPermission() async {
  if (!Platform.isAndroid) return false;
  final status = await Permission.notification.request();
  return !status.isGranted;
}

Future<bool> notificationsBlocked() async {
  if (!Platform.isAndroid) return false;
  return !await Permission.notification.isGranted;
}

/// Opens the system settings page where the user can undo a denial.
Future<void> openNotificationSettings() => openAppSettings();
