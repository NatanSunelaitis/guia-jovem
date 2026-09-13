import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_brand.dart';
import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_input.dart';
import '../data/auth_repository.dart';
import 'widgets/gj_auth_background.dart';

/// T26 Esqueci minha senha (`/recuperar-senha`). A API sempre responde 200
/// (RNF/seção 6, regra 4: nunca revela se o e-mail existe), então a
/// mensagem de sucesso é sempre a mesma, neutra.
class EsqueciSenhaPage extends StatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  final _emailController = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    try {
      await authRepository.forgotPassword(_emailController.text.trim());
    } catch (_) {
      // Resposta é sempre neutra: mesmo se a chamada falhar, não revelamos detalhes.
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
          _enviado = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: GJAuthBackground(
        circulos: [gjCirculoDecorativo(left: -120, bottom: -160, tamanho: 320)],
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
              SizedBox(height: 48, child: SvgPicture.asset(GJBrand.logoStacked)),
              const SizedBox(height: GJSpace.s4),
              Text('Esqueci minha senha', style: GJTypography.h1(size: 26), textAlign: TextAlign.center),
              const SizedBox(height: GJSpace.s1),
              Text(
                'Informe o e-mail cadastrado e enviaremos um link para você criar uma nova senha.',
                style: GJTypography.bodySm(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GJSpace.s6),
              if (_enviado)
                Container(
                  padding: const EdgeInsets.all(GJSpace.s4),
                  decoration: BoxDecoration(color: GJColors.primaryFixed, borderRadius: GJRadius.borderMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Symbols.mail, size: 20, color: GJColors.primary),
                      const SizedBox(width: GJSpace.s3),
                      Expanded(
                        child: Text(
                          'Se houver uma conta com esse e-mail, você receberá o link de recuperação em alguns minutos. Confira também a caixa de spam.',
                          style: GJTypography.label(color: GJColors.primary),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                GJInput(label: 'E-mail', hint: 'seu@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: GJSpace.s4),
                GJButton(label: 'Enviar link de recuperação', expand: true, loading: _enviando, onPressed: _enviando ? null : _enviar),
              ],
              const SizedBox(height: GJSpace.s4),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Voltar para o login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
