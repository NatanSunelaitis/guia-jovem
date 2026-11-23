import 'package:app/features/admin/presentation/painel_admin_page.dart';
import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/shared/widgets/gj_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'mock_auth_api.dart';
import 'pump_with_router.dart';

final adminDeTeste =
    UsuarioSessao(id: 99, nome: 'Equipe Guia Jovem', email: 'admin@guiajovem.com.br', tipoUsuario: TipoUsuario.admin);

final semNotificacoes =
    RespostaFalsa(envelope(<dynamic>[], {'page': 1, 'pageSize': 10, 'total': 0, 'totalPages': 1, 'naoLidas': 0}));

Map<String, dynamic> paginaDe(List<Map<String, dynamic>> itens, {int totalPages = 1}) =>
    envelope(itens, {'page': 1, 'pageSize': 20, 'total': itens.length, 'totalPages': totalPages});

RespostaFalsa erroDaApi(String code, String message, {int status = 409, List<dynamic> details = const []}) =>
    RespostaFalsa(
      {
        'error': {'code': code, 'message': message, 'details': details},
      },
      status: status,
    );

/// Requisições do [mockAuthApiRotas] com o método e o fim do caminho.
List<RequisicaoFeita> requisicoes(String metodo, String sufixo) => [
      for (final r in requisicoesAuthApi)
        if (r.method == metodo && r.uri.path.endsWith(sufixo)) RequisicaoFeita(r.uri.queryParameters, r.data),
    ];

class RequisicaoFeita {
  RequisicaoFeita(this.query, this.corpo);
  final Map<String, String> query;
  final dynamic corpo;
}

/// Campo de texto de um GJInput (o rótulo fica fora do TextField).
Finder campo(String rotulo) =>
    find.descendant(of: find.widgetWithText(GJInput, rotulo), matching: find.byType(TextField));

/// Monta o painel do administrador na seção da URL, com sessão de admin.
Future<void> pumpPainelAdmin(WidgetTester tester, String local) async {
  sessionController.redefinirParaTestes(usuario: adminDeTeste);
  await pumpComRouter(
    tester,
    initialLocation: local,
    rotas: {
      '/admin/universidades/:id': (context) => PainelAdminPage(
            secao: SecaoAdmin.universidades,
            universidadeId: int.parse(GoRouterState.of(context).pathParameters['id']!),
          ),
      '/admin/:secao': (context) => PainelAdminPage(
            key: ValueKey(GoRouterState.of(context).pathParameters['secao']),
            secao: SecaoAdmin.doCaminho(GoRouterState.of(context).pathParameters['secao']),
          ),
    },
  );
  await tester.pumpAndSettle();
}

/// Escolhe uma opção de um DropdownButtonFormField pela [chave] (a lista
/// fica abaixo do rótulo, dentro do campo com a chave).
Future<void> escolher(WidgetTester tester, Key chave, String opcao) async {
  final lista = find.descendant(of: find.byKey(chave), matching: find.byWidgetPredicate((w) => w is DropdownButtonFormField));
  final alvo = lista.evaluate().isEmpty ? find.byKey(chave) : lista.first;
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcao).last);
  await tester.pumpAndSettle();
}

/// Toca no botão com o [rotulo] dentro do diálogo de confirmação aberto.
Future<void> confirmarNoDialogo(WidgetTester tester, String rotulo) async {
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(rotulo)));
  await tester.pumpAndSettle();
}
