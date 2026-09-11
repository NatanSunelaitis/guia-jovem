import 'package:go_router/go_router.dart';

import '../../features/dev_components/dev_components_page.dart';

/// Rotas do app. Enquanto docs/prototipo/ estiver vazio, a única rota
/// disponível é a galeria de componentes (`/dev/components`).
final appRouter = GoRouter(
  initialLocation: '/dev/components',
  routes: [
    GoRoute(
      path: '/dev/components',
      builder: (context, state) => const DevComponentsPage(),
    ),
  ],
);
