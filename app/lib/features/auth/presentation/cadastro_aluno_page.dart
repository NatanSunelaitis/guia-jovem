import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_brand.dart';
import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_input.dart';
import '../data/google_login.dart';
import '../data/session_controller.dart';
import 'widgets/gj_auth_background.dart';

/// T11 Cadastro de Aluno (`/cadastro/aluno`, Figura 24).
class CadastroAlunoPage extends StatefulWidget {
  const CadastroAlunoPage({super.key});

  @override
  State<CadastroAlunoPage> createState() => _CadastroAlunoPageState();
}

class _CadastroAlunoPageState extends State<CadastroAlunoPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  String? _erroNome;
  String? _erroEmail;
  String? _erroSenha;
  String? _erroConfirmar;
  String? _erroGeral;
  bool _enviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  bool _validar() {
    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailController.text.trim());

    setState(() {
      _erroNome = _nomeController.text.trim().isEmpty ? 'Informe o nome' : null;
      _erroEmail = emailValido ? null : 'Informe um e-mail válido';
      _erroSenha = _senhaController.text.length < 7 ? 'Informe uma senha com 7 ou mais caracteres' : null;
      _erroConfirmar = _confirmarSenhaController.text != _senhaController.text ? 'As senhas não coincidem' : null;
    });

    return _erroNome == null && _erroEmail == null && _erroSenha == null && _erroConfirmar == null;
  }

  Future<void> _criarConta() async {
    setState(() => _erroGeral = null);
    if (!_validar()) return;

    setState(() => _enviando = true);
    try {
      await sessionController.registrarAluno(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (erro) {
      setState(() => _erroGeral = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// RF05 e RF09: sem conta com o e-mail do Google, a API cria a conta de aluno.
  Future<void> _entrarComGoogle(String idToken) async {
    setState(() {
      _enviando = true;
      _erroGeral = null;
    });
    try {
      await sessionController.loginComGoogle(idToken);
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erroGeral = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _falhaDoGoogle(String mensagem) {
    if (mounted) setState(() => _erroGeral = mensagem);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: GJAuthBackground(
        circulos: [gjCirculoDecorativo(left: -120, bottom: -140, tamanho: 320)],
        child: Container(
          width: isMobile ? double.infinity : 560,
          padding: const EdgeInsets.all(GJSpace.s8),
          decoration: BoxDecoration(
            color: GJColors.surfaceLowest,
            borderRadius: GJRadius.borderXl,
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 56, child: SvgPicture.asset(GJBrand.logo)),
              const SizedBox(height: GJSpace.s4),
              Text('Vamos criar sua conta no Guia Jovem?', style: GJTypography.h1(size: 28), textAlign: TextAlign.center),
              const SizedBox(height: GJSpace.s1),
              Text('É só informar seu e-mail e uma senha.', style: GJTypography.bodySm(), textAlign: TextAlign.center),
              const SizedBox(height: GJSpace.s5),
              if (_erroGeral != null) ...[
                Container(
                  padding: const EdgeInsets.all(GJSpace.s4),
                  decoration: BoxDecoration(color: GJColors.errorContainer, borderRadius: GJRadius.borderMd),
                  child: Text(_erroGeral!, style: GJTypography.label(color: GJColors.error)),
                ),
                const SizedBox(height: GJSpace.s4),
              ],
              GJInput(
                label: 'Nome completo',
                hint: 'Como você quer ser chamado',
                controller: _nomeController,
                errorText: _erroNome,
              ),
              const SizedBox(height: GJSpace.s3),
              GJInput(
                label: 'E-mail',
                hint: 'seu@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _erroEmail,
              ),
              const SizedBox(height: GJSpace.s3),
              GJInput(
                label: 'Senha',
                hint: 'Sua senha',
                controller: _senhaController,
                obscureText: true,
                errorText: _erroSenha,
                helperText: _erroSenha == null ? '7 ou mais caracteres' : null,
              ),
              const SizedBox(height: GJSpace.s3),
              GJInput(
                label: 'Confirmar senha',
                hint: 'Repita a senha',
                controller: _confirmarSenhaController,
                obscureText: true,
                errorText: _erroConfirmar,
              ),
              const SizedBox(height: GJSpace.s4),
              GJButton(label: 'Criar conta', expand: true, loading: _enviando, onPressed: _enviando ? null : _criarConta),
              const SizedBox(height: GJSpace.s3),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('Se você já tem uma conta, ', style: GJTypography.bodySm()),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('entre por aqui', style: GJTypography.label(color: GJColors.primary)),
                  ),
                ],
              ),
              // O botão do Google só existe quando o app foi compilado com
              // GOOGLE_CLIENT_ID (README, "Login com Google").
              if (googleLogin.disponivel) ...[
                const SizedBox(height: GJSpace.s4),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3),
                      child: Text('OU', style: GJTypography.caption().copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: GJSpace.s4),
                googleLogin.botao(aoReceberToken: _entrarComGoogle, aoFalhar: _falhaDoGoogle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
