import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/gj_theme.dart';
import 'features/auth/data/session_controller.dart';

class GuiaJovemApp extends StatefulWidget {
  const GuiaJovemApp({super.key});

  @override
  State<GuiaJovemApp> createState() => _GuiaJovemAppState();
}

class _GuiaJovemAppState extends State<GuiaJovemApp> {
  @override
  void initState() {
    super.initState();
    // O router já lida com `sessionController.carregando` no redirect
    // (não redireciona enquanto o bootstrap não termina), então não é
    // preciso esperar aqui antes de montar o MaterialApp.
    sessionController.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Guia Jovem',
      debugShowCheckedModeBanner: false,
      theme: GJTheme.light,
      routerConfig: appRouter,
      // Textos internos do Flutter (contador de caracteres, seletores de data,
      // leitores de tela) em português.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
