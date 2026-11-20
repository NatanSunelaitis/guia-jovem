import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_input.dart';
import '../data/cadastro_universidade_state.dart';
import 'widgets/cadastro_universidade_shell.dart';
import '../../../shared/utils/mascaras.dart';

/// T13 Cadastro de Universidade, passo 1 de 3: dados institucionais
/// (`/cadastro/universidade/dados`, Figura 28).
class CadastroUniversidadePasso1Page extends StatefulWidget {
  const CadastroUniversidadePasso1Page({super.key});

  @override
  State<CadastroUniversidadePasso1Page> createState() => _CadastroUniversidadePasso1PageState();
}

class _CadastroUniversidadePasso1PageState extends State<CadastroUniversidadePasso1Page> {
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _linkPaginaController = TextEditingController();
  final _linkSimuladosController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  String _natureza = 'P';

  String? _erroRazaoSocial;
  String? _erroNomeFantasia;
  String? _erroCnpj;
  String? _erroTelefone;
  String? _erroLinkPagina;
  String? _erroEmail;
  String? _erroSenha;
  String? _erroConfirmar;

  @override
  void initState() {
    super.initState();
    final estado = cadastroUniversidadeState;
    _razaoSocialController.text = estado.razaoSocial;
    _nomeFantasiaController.text = estado.nomeFantasia;
    _cnpjController.text = estado.cnpj;
    _telefoneController.text = estado.telefonePrincipal;
    _linkPaginaController.text = estado.linkPagina;
    _linkSimuladosController.text = estado.linkSimulados;
    _emailController.text = estado.email;
    _senhaController.text = estado.senha;
    _confirmarSenhaController.text = estado.senha;
    _natureza = estado.natureza;
  }

  @override
  void dispose() {
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _linkPaginaController.dispose();
    _linkSimuladosController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _salvarNoEstado() {
    final estado = cadastroUniversidadeState;
    estado.razaoSocial = _razaoSocialController.text.trim();
    estado.nomeFantasia = _nomeFantasiaController.text.trim();
    estado.cnpj = _cnpjController.text.trim();
    estado.telefonePrincipal = _telefoneController.text.trim();
    estado.linkPagina = _linkPaginaController.text.trim();
    estado.linkSimulados = _linkSimuladosController.text.trim();
    estado.email = _emailController.text.trim();
    estado.senha = _senhaController.text;
    estado.natureza = _natureza;
  }

  bool _validar() {
    final cnpjLimpo = _cnpjController.text.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailController.text.trim());

    setState(() {
      _erroRazaoSocial = _razaoSocialController.text.trim().isEmpty ? 'Informe a razão social' : null;
      _erroNomeFantasia = _nomeFantasiaController.text.trim().isEmpty ? 'Informe o nome fantasia' : null;
      _erroCnpj = cnpjLimpo.length != 14 ? 'O CNPJ deve ter 14 caracteres' : null;
      _erroTelefone = _telefoneController.text.trim().isEmpty ? 'Informe o telefone' : null;
      _erroLinkPagina = _linkPaginaController.text.trim().isEmpty ? 'Informe o link da página inicial' : null;
      _erroEmail = emailValido ? null : 'Informe um e-mail válido';
      _erroSenha = _senhaController.text.length < 7 ? 'Informe uma senha com 7 ou mais caracteres' : null;
      _erroConfirmar = _confirmarSenhaController.text != _senhaController.text ? 'As senhas não coincidem' : null;
    });

    return [_erroRazaoSocial, _erroNomeFantasia, _erroCnpj, _erroTelefone, _erroLinkPagina, _erroEmail, _erroSenha, _erroConfirmar]
        .every((e) => e == null);
  }

  void _proximo() {
    if (!_validar()) return;
    _salvarNoEstado();
    context.go('/cadastro/universidade/programas');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    Widget linha(List<Widget> campos) {
      if (isMobile) {
        return Column(children: [for (final c in campos) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s4), child: c)]);
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: GJSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < campos.length; i++) ...[
              if (i > 0) const SizedBox(width: GJSpace.s5),
              Expanded(child: campos[i]),
            ],
          ],
        ),
      );
    }

    return CadastroUniversidadeShell(
      passoAtual: 1,
      titulo: 'Cadastre sua Universidade!',
      aoAvancar: _proximo,
      rotuloAvancar: 'Próximo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          linha([
            GJInput(label: 'Razão social', hint: 'Nome legal da instituição', controller: _razaoSocialController, errorText: _erroRazaoSocial),
            GJInput(label: 'Nome fantasia', hint: 'Como a instituição é conhecida', controller: _nomeFantasiaController, errorText: _erroNomeFantasia),
          ]),
          linha([
            GJInput(
              label: 'CNPJ',
              hint: '00.000.000/0000-00',
              controller: _cnpjController,
              errorText: _erroCnpj,
              inputFormatters: [CnpjInputFormatter()],
            ),
            _campoNatureza(),
          ]),
          linha([
            GJInput(label: 'Telefone principal', hint: '(00) 0000-0000', controller: _telefoneController, errorText: _erroTelefone),
            GJInput(label: 'Link da página inicial da universidade', hint: 'https://', controller: _linkPaginaController, errorText: _erroLinkPagina),
          ]),
          linha([
            GJInput(
              label: 'Link da página de simulados anteriores (opcional)',
              hint: 'https://',
              controller: _linkSimuladosController,
            ),
          ]),
          linha([
            GJInput(label: 'E-mail para cadastro', hint: 'contato@instituicao.edu.br', controller: _emailController, errorText: _erroEmail),
          ]),
          linha([
            GJInput(label: 'Senha', controller: _senhaController, obscureText: true, errorText: _erroSenha, helperText: _erroSenha == null ? '7 ou mais caracteres' : null),
            GJInput(label: 'Confirmar senha', controller: _confirmarSenhaController, obscureText: true, errorText: _erroConfirmar),
          ]),
        ],
      ),
    );
  }

  Widget _campoNatureza() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: GJSpace.s1, bottom: GJSpace.s2),
          child: Text('Natureza', style: GJTypography.label()),
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              _opcaoNatureza('Pública', 'P'),
              const SizedBox(width: GJSpace.s5),
              _opcaoNatureza('Privada', 'V'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _opcaoNatureza(String rotulo, String valor) {
    return GestureDetector(
      onTap: () => setState(() => _natureza = valor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(value: valor, groupValue: _natureza, onChanged: (v) => setState(() => _natureza = v ?? 'P'), activeColor: GJColors.primary),
          Text(rotulo, style: GJTypography.body()),
        ],
      ),
    );
  }
}
