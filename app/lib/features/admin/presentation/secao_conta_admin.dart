import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../auth/data/session_controller.dart';
import '../../auth/presentation/widgets/alterar_senha_dialog.dart';
import '../../auth/presentation/widgets/excluir_conta_dialog.dart';

/// Conta do administrador (RF09, Quadro 13): editar o nome, alterar senha
/// (T21) e sair com confirmação (RF06), como a seção Conta do painel da
/// universidade. O `/perfil` da conta de administrador abre esta seção.
class SecaoContaAdmin extends StatefulWidget {
  const SecaoContaAdmin({super.key});

  @override
  State<SecaoContaAdmin> createState() => _SecaoContaAdminState();
}

class _SecaoContaAdminState extends State<SecaoContaAdmin> {
  final _nomeController = TextEditingController();
  bool _editando = false;
  bool _salvando = false;
  String? _erroNome;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _comecarEdicao() {
    setState(() {
      _nomeController.text = sessionController.usuario?.nome ?? '';
      _erroNome = null;
      _editando = true;
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _erroNome = 'Informe o nome');
      return;
    }
    setState(() {
      _salvando = true;
      _erroNome = null;
    });
    try {
      await sessionController.atualizarNome(nome);
      if (!mounted) return;
      setState(() => _editando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
    } on ApiException catch (erro) {
      if (!mounted) return;
      final doCampo = erro.details
          .whereType<Map<dynamic, dynamic>>()
          .where((detalhe) => detalhe['campo'] == 'nome')
          .map((detalhe) => detalhe['mensagem'] as String?)
          .firstOrNull;
      setState(() => _erroNome = doCampo ?? erro.message);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = sessionController.usuario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Conta', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s2),
        Text('Dados de acesso da sua conta de administrador.', style: GJTypography.body()),
        const SizedBox(height: GJSpace.s6),
        if (_editando) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GJInput(label: 'Nome', controller: _nomeController, errorText: _erroNome),
            ),
          ),
          const SizedBox(height: GJSpace.s4),
          Wrap(
            spacing: GJSpace.s3,
            runSpacing: GJSpace.s3,
            children: [
              GJButton(label: 'Salvar', loading: _salvando, onPressed: _salvando ? null : _salvar),
              GJButton(
                label: 'Cancelar',
                variant: GJButtonVariant.secondary,
                onPressed: _salvando ? null : () => setState(() => _editando = false),
              ),
            ],
          ),
        ] else if (usuario != null) ...[
          Text(usuario.nome, style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s1),
          Text(usuario.email, style: GJTypography.bodySm()),
        ],
        const SizedBox(height: GJSpace.s6),
        Wrap(
          spacing: GJSpace.s3,
          runSpacing: GJSpace.s3,
          children: [
            if (!_editando)
              GJButton(
                label: 'Editar nome',
                icon: Symbols.edit,
                variant: GJButtonVariant.secondary,
                onPressed: _comecarEdicao,
              ),
            GJButton(
              label: 'Alterar senha',
              icon: Symbols.lock,
              variant: GJButtonVariant.secondary,
              onPressed: () => mostrarDialogoAlterarSenha(context),
            ),
            GJButton(
              label: 'Sair',
              icon: Symbols.logout,
              variant: GJButtonVariant.secondary,
              onPressed: () => mostrarDialogoSair(context),
            ),
          ],
        ),
      ],
    );
  }
}
