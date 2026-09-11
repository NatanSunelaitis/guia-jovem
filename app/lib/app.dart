import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/gj_theme.dart';

class GuiaJovemApp extends StatelessWidget {
  const GuiaJovemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Guia Jovem',
      debugShowCheckedModeBanner: false,
      theme: GJTheme.light,
      routerConfig: appRouter,
    );
  }
}
