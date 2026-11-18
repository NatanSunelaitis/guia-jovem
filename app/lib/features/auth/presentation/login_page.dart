import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

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

/// T09 Login (`/login`, Figura 22).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.redirecionarPara});

  final String? redirecionarPara;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  String? _erro;
  bool _enviando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await sessionController.login(email: _emailController.text.trim(), senha: _senhaController.text);
      if (!mounted) return;
      context.go(widget.redirecionarPara ?? '/');
    } on ApiException catch (erro) {
      setState(() => _erro = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _entrarComGoogle(String idToken) async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await sessionController.loginComGoogle(idToken);
      if (!mounted) return;
      context.go(widget.redirecionarPara ?? '/');
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _falhaDoGoogle(String mensagem) {
    if (mounted) setState(() => _erro = mensagem);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: GJAuthBackground(
        circulos: [
          gjCirculoDecorativo(left: -120, top: -80, tamanho: 320),
          gjCirculoDecorativo(right: -140, bottom: -160, tamanho: 360),
        ],
        child: Container(
          width: isMobile ? double.infinity : 520,
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
              Text('Acesse sua conta!', style: GJTypography.h1(size: 28), textAlign: TextAlign.center),
              const SizedBox(height: GJSpace.s1),
              Text(
                'Para acessar sua conta no Guia Jovem, entre com seu e-mail e senha',
                style: GJTypography.bodySm(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GJSpace.s6),
              if (_erro != null) ...[
                Container(
                  padding: const EdgeInsets.all(GJSpace.s4),
                  decoration: BoxDecoration(color: GJColors.errorContainer, borderRadius: GJRadius.borderMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Symbols.error, size: 20, color: GJColors.error),
                      const SizedBox(width: GJSpace.s3),
                      Expanded(
                        child: Text(_erro!, style: GJTypography.label(color: GJColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GJSpace.s4),
              ],
              GJInput(label: 'E-mail', hint: 'seu@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: GJSpace.s4),
              GJInput(label: 'Senha', hint: 'Sua senha', controller: _senhaController, obscureText: true),
              const SizedBox(height: GJSpace.s2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/recuperar-senha'),
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              const SizedBox(height: GJSpace.s2),
              GJButton(label: 'Acessar minha conta', expand: true, loading: _enviando, onPressed: _enviando ? null : _entrar),
              // RF05: o botão do Google só existe quando o app foi compilado
              // com GOOGLE_CLIENT_ID (README, "Login com Google").
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
              const SizedBox(height: GJSpace.s4),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('Ainda não tem conta? ', style: GJTypography.bodySm()),
                  GestureDetector(
                    onTap: () => context.go('/cadastro'),
                    child: Text('Criar uma conta', style: GJTypography.label(color: GJColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
