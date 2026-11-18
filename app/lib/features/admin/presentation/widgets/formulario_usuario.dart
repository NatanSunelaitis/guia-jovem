import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../auth/domain/usuario_sessao.dart';
import '../../data/admin_repository.dart';
import '../../domain/usuario_admin.dart';
import 'confirmacao_dialogs.dart';
import 'formulario.dart';

/// "Novo usuário" e edição de perfil (RF09, Quadro 14). O perfil vai entre
/// Aluno e Administrador: a conta de universidade só nasce pelo cadastro da
/// universidade e não muda de perfil. A própria conta edita o nome, não o
/// perfil, e a regra do último administrador vem da API (409).
class FormularioUsuario extends StatefulWidget {
  const FormularioUsuario({super.key, this.usuario, this.ehPropriaConta = false});

  final UsuarioAdmin? usuario;
  final bool ehPropriaConta;

  @override
  State<FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<FormularioUsuario> {
  late final _nome = TextEditingController(text: widget.usuario?.nome);
  final _email = TextEditingController();
  final _senha = TextEditingController();
  late TipoUsuario _tipo = widget.usuario?.tipoUsuario ?? TipoUsuario.aluno;

  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  bool get _novo => widget.usuario == null;
  bool get _perfilEditavel =>
      _novo || (widget.usuario!.tipoUsuario != TipoUsuario.universidade && !widget.ehPropriaConta);

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Informe o nome';
    if (_novo) {
      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim())) erros['email'] = 'Informe um e-mail válido';
      if (_senha.text.length < 7) erros['senha'] = 'Informe uma senha com 7 ou mais caracteres';
    }
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    setState(() => _salvando = true);
    try {
      final salvo = _novo
          ? await adminRepository.criarUsuario(
              nome: _nome.text.trim(),
              email: _email.text.trim(),
              senha: _senha.text,
              tipo: _tipo,
            )
          : await adminRepository.atualizarUsuario(
              widget.usuario!.id,
              nome: _nome.text.trim(),
              tipo: _perfilEditavel && _tipo != widget.usuario!.tipoUsuario ? _tipo : null,
            );
      if (mounted) Navigator.of(context).pop(salvo);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      if (erro.code == 'ULTIMO_ADMINISTRADOR') {
        await mostrarAcaoBloqueada(context, erro.message);
        return;
      }
      setState(() {
        _erros = {...errosPorCampo(erro), if (erro.code == 'EMAIL_EM_USO') 'email': erro.message};
        _erroGeral = mensagemDaApi(erro);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome', controller: _nome, erro: _erros['nome'], maxLength: 100),
        if (_novo) ...[
          CampoTexto(
            rotulo: 'E-mail',
            controller: _email,
            erro: _erros['email'],
            keyboardType: TextInputType.emailAddress,
            maxLength: 100,
          ),
          CampoTexto(rotulo: 'Senha inicial', controller: _senha, erro: _erros['senha'], obscureText: true),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text('E-mail: ${usuario!.email}', style: GJTypography.bodySm()),
          ),
        if (_perfilEditavel)
          CampoSelecao<TipoUsuario>(
            key: const Key('usuario-perfil'),
            rotulo: 'Perfil',
            valor: _tipo,
            opcoes: {
              TipoUsuario.aluno: rotuloTipoUsuario(TipoUsuario.aluno),
              TipoUsuario.admin: rotuloTipoUsuario(TipoUsuario.admin),
            },
            onChanged: (valor) => setState(() => _tipo = valor ?? _tipo),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text(
              usuario!.tipoUsuario == TipoUsuario.universidade
                  ? 'Perfil: Universidade. A conta de universidade não muda de perfil.'
                  : 'Perfil: ${rotuloTipoUsuario(usuario.tipoUsuario)}. Para mudar o perfil da própria conta, peça a outro administrador.',
              style: GJTypography.bodySm(),
            ),
          ),
        RodapeFormulario(
          salvando: _salvando,
          onSalvar: _salvar,
          erro: _erroGeral,
          rotuloSalvar: _novo ? 'Criar usuário' : 'Salvar',
        ),
      ],
    );
  }
}
