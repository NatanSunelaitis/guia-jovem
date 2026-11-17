import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_input.dart';
import '../../../auth/data/session_controller.dart';
import '../../../auth/domain/usuario_sessao.dart';
import '../../../auth/presentation/widgets/alterar_senha_dialog.dart';
import '../../../auth/presentation/widgets/excluir_conta_dialog.dart';

/// T16 (Figura 25): foto ou iniciais, nome, e-mail e as ações da conta
/// (editar dados, alterar senha, sair e excluir conta). Só o nome é
/// editável; o e-mail identifica a conta (inclusive no login com Google).
class DadosPerfilCard extends StatefulWidget {
  const DadosPerfilCard({super.key, required this.usuario});

  final UsuarioSessao usuario;

  @override
  State<DadosPerfilCard> createState() => _DadosPerfilCardState();
}

class _DadosPerfilCardState extends State<DadosPerfilCard> {
  bool _editando = false;
  bool _salvando = false;
  String? _erroNome;
  late final _nomeController = TextEditingController(text: widget.usuario.nome);
  late final _emailController = TextEditingController(text: widget.usuario.email);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _comecarEdicao() {
    setState(() {
      _nomeController.text = widget.usuario.nome;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados.')));
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
    final usuario = widget.usuario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s8),
      decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarPerfil(usuario: usuario),
          const SizedBox(height: GJSpace.s4),
          if (_editando) ..._formulario(usuario) else ..._resumo(usuario),
        ],
      ),
    );
  }

  List<Widget> _resumo(UsuarioSessao usuario) => [
        Text(usuario.nome, style: GJTypography.h3(), textAlign: TextAlign.center),
        const SizedBox(height: GJSpace.s1),
        Text(usuario.email, style: GJTypography.bodySm(), textAlign: TextAlign.center),
        const SizedBox(height: GJSpace.s6),
        GJButton(
          label: 'Editar perfil',
          icon: Symbols.edit,
          variant: GJButtonVariant.secondary,
          expand: true,
          onPressed: _comecarEdicao,
        ),
        const SizedBox(height: GJSpace.s3),
        GJButton(
          label: 'Alterar senha',
          icon: Symbols.lock,
          variant: GJButtonVariant.secondary,
          expand: true,
          onPressed: () => mostrarDialogoAlterarSenha(context),
        ),
        const SizedBox(height: GJSpace.s3),
        GJButton(
          label: 'Sair',
          icon: Symbols.logout,
          variant: GJButtonVariant.danger,
          expand: true,
          onPressed: () => mostrarDialogoDesligar(context),
        ),
        const SizedBox(height: GJSpace.s3),
        GJButton(
          label: 'Excluir conta',
          icon: Symbols.delete,
          variant: GJButtonVariant.ghost,
          expand: true,
          onPressed: () => mostrarDialogoExcluirConta(context),
        ),
      ];

  List<Widget> _formulario(UsuarioSessao usuario) => [
        GJInput(label: 'Nome', controller: _nomeController, maxLength: 100, errorText: _erroNome, enabled: !_salvando),
        const SizedBox(height: GJSpace.s3),
        GJInput(
          label: 'E-mail',
          controller: _emailController,
          readOnly: true,
          helperText: 'O e-mail não pode ser alterado.',
        ),
        const SizedBox(height: GJSpace.s6),
        GJButton(label: 'Salvar', icon: Symbols.check, expand: true, loading: _salvando, onPressed: _salvando ? null : _salvar),
        const SizedBox(height: GJSpace.s3),
        GJButton(
          label: 'Cancelar',
          variant: GJButtonVariant.ghost,
          expand: true,
          onPressed: _salvando ? null : () => setState(() => _editando = false),
        ),
      ];
}

/// Foto do usuário (hoje só vem do login com Google; não há upload) ou as
/// iniciais do nome sobre a cor primária.
class _AvatarPerfil extends StatelessWidget {
  const _AvatarPerfil({required this.usuario});

  final UsuarioSessao usuario;

  String get _iniciais {
    final palavras = usuario.nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (palavras.isEmpty) return '?';
    final primeira = palavras.first[0];
    final ultima = palavras.length > 1 ? palavras.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = usuario.fotoUrl;
    return CircleAvatar(
      radius: GJSpace.s12,
      backgroundColor: GJColors.primaryContainer,
      backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
      child: fotoUrl == null ? Text(_iniciais, style: GJTypography.h2(size: 32).copyWith(color: GJColors.primaryOn)) : null,
    );
  }
}
