import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/app/router/app_router.dart';
import 'package:fleettrack/app/theme/app_theme.dart';

class FleetTrackApp extends ConsumerWidget {
  const FleetTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FleetTrack - Transport Attendance & Payroll',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
