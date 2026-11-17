import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_input.dart';
import '../../data/auth_repository.dart';
import '../../data/session_controller.dart';

/// T21 Alterar Senha (modal, Figura 35), comum aos três perfis (perfil do
/// aluno, painel da universidade e do administrador). As mensagens de erro
/// são as da API, por campo quando ela indica o campo.
///
/// A API revoga todas as sessões ao trocar a senha, então, depois do
/// sucesso, a sessão local é encerrada e o usuário entra de novo com a
/// senha nova. Retorna true se a senha foi alterada.
Future<bool> mostrarDialogoAlterarSenha(BuildContext context) async {
  final alterou = await showDialog<bool>(context: context, builder: (context) => const _AlterarSenhaDialog());
  if (alterou != true) return false;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha alterada. Entre novamente com a nova senha.')),
    );
  }
  await sessionController.logout();
  return true;
}

class _AlterarSenhaDialog extends StatefulWidget {
  const _AlterarSenhaDialog();

  @override
  State<_AlterarSenhaDialog> createState() => _AlterarSenhaDialogState();
}

class _AlterarSenhaDialogState extends State<_AlterarSenhaDialog> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _enviando = false;

  // Erros por campo (details da API) e o erro geral (message).
  Map<String, String> _errosPorCampo = const {};
  String? _erroGeral;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _alterar() async {
    final usuario = sessionController.usuario;
    if (usuario == null) return;

    setState(() {
      _enviando = true;
      _errosPorCampo = const {};
      _erroGeral = null;
    });

    try {
      await authRepository.alterarSenha(
        usuario.id,
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
        confirmacao: _confirmacaoController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      final porCampo = <String, String>{
        for (final detalhe in erro.details)
          if (detalhe is Map && detalhe['campo'] is String && detalhe['mensagem'] is String)
            detalhe['campo'] as String: detalhe['mensagem'] as String,
      };
      setState(() {
        _errosPorCampo = porCampo;
        // A senha atual incorreta vem só na message; ela pertence ao campo.
        if (erro.code == 'SENHA_ATUAL_INVALIDA') {
          _errosPorCampo = {..._errosPorCampo, 'senhaAtual': erro.message};
        } else if (porCampo.isEmpty) {
          _erroGeral = erro.message;
        }
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(GJSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Alterar senha', style: GJTypography.h2(size: 22))),
                  GestureDetector(onTap: () => Navigator.of(context).pop(false), child: const Icon(Symbols.close)),
                ],
              ),
              const SizedBox(height: GJSpace.s4),
              GJInput(
                label: 'Senha atual',
                controller: _senhaAtualController,
                obscureText: true,
                errorText: _errosPorCampo['senhaAtual'],
              ),
              const SizedBox(height: GJSpace.s3),
              GJInput(
                label: 'Nova senha',
                controller: _novaSenhaController,
                obscureText: true,
                errorText: _errosPorCampo['novaSenha'],
                helperText: _errosPorCampo['novaSenha'] == null ? '7 ou mais caracteres' : null,
              ),
              const SizedBox(height: GJSpace.s3),
              GJInput(
                label: 'Confirmar nova senha',
                controller: _confirmacaoController,
                obscureText: true,
                errorText: _errosPorCampo['confirmacao'],
              ),
              if (_erroGeral != null) ...[
                const SizedBox(height: GJSpace.s3),
                Text(_erroGeral!, style: GJTypography.label(color: GJColors.error)),
              ],
              const SizedBox(height: GJSpace.s6),
              // Wrap (não Row): na largura do diálogo os dois botões podem não caber lado a lado.
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: GJSpace.s3,
                  runSpacing: GJSpace.s2,
                  children: [
                    GJButton(label: 'Cancelar', variant: GJButtonVariant.ghost, onPressed: () => Navigator.of(context).pop(false)),
                    GJButton(label: 'Alterar senha', loading: _enviando, onPressed: _enviando ? null : _alterar),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
