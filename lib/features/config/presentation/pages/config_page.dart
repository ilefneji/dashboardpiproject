import 'package:flutter/material.dart';
import 'package:constructiondashboard/core/widgets/app_shell.dart';

/// Empty Configuration Page
/// This page is intentionally left blank as requested
class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Center(
          child: Container(),
        ),
      ),
    );
  }
}
