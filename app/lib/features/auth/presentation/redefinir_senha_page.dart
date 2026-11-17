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
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../data/auth_repository.dart';
import 'widgets/gj_auth_background.dart';

/// T25 Redefinir senha (`/redefinir-senha?token=...`).
class RedefinirSenhaPage extends StatefulWidget {
  const RedefinirSenhaPage({super.key, required this.token});

  final String? token;

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  String? _erroSenha;
  String? _erroConfirmar;
  String? _erroGeral;
  bool _enviando = false;
  bool _sucesso = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    setState(() {
      _erroSenha = _senhaController.text.length < 7 ? 'Informe uma senha com 7 ou mais caracteres' : null;
      _erroConfirmar = _confirmarController.text != _senhaController.text ? 'As senhas não coincidem' : null;
      _erroGeral = null;
    });
    if (_erroSenha != null || _erroConfirmar != null) return;

    setState(() => _enviando = true);
    try {
      await authRepository.resetPassword(token: widget.token!, novaSenha: _senhaController.text);
      setState(() => _sucesso = true);
    } on ApiException catch (erro) {
      setState(() => _erroGeral = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: GJAuthBackground(
        circulos: [gjCirculoDecorativo(right: -120, top: -140, tamanho: 320)],
        child: Container(
          width: isMobile ? double.infinity : 520,
          padding: const EdgeInsets.all(GJSpace.s8),
          decoration: BoxDecoration(
            color: GJColors.surfaceLowest,
            borderRadius: GJRadius.borderXl,
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: widget.token == null || widget.token!.isEmpty
              ? _semToken(context)
              : _sucesso
                  ? _sucessoConteudo(context)
                  : _formulario(),
        ),
      ),
    );
  }

  Widget _semToken(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GJEmptyState(
          titulo: 'Link inválido ou expirado',
          texto: 'Solicite um novo link de recuperação de senha.',
          icone: Symbols.error,
        ),
        GJButton(label: 'Solicitar novo link', onPressed: () => context.go('/recuperar-senha')),
      ],
    );
  }

  Widget _sucessoConteudo(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: GJColors.successContainer, shape: BoxShape.circle),
          child: const Icon(Symbols.check_circle, size: 36, color: GJColors.success, fill: 1),
        ),
        const SizedBox(height: GJSpace.s4),
        Text('Senha redefinida', style: GJTypography.h2(size: 24), textAlign: TextAlign.center),
        const SizedBox(height: GJSpace.s2),
        Text('Você já pode entrar com sua nova senha.', style: GJTypography.body(), textAlign: TextAlign.center),
        const SizedBox(height: GJSpace.s6),
        GJButton(label: 'Ir para o login', expand: true, onPressed: () => context.go('/login')),
      ],
    );
  }

  Widget _formulario() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 48, child: SvgPicture.asset(GJBrand.logo)),
        const SizedBox(height: GJSpace.s4),
        Text('Redefinir senha', style: GJTypography.h1(size: 26), textAlign: TextAlign.center),
        const SizedBox(height: GJSpace.s1),
        Text('Crie uma nova senha para acessar sua conta.', style: GJTypography.bodySm(), textAlign: TextAlign.center),
        const SizedBox(height: GJSpace.s6),
        if (_erroGeral != null) ...[
          Container(
            padding: const EdgeInsets.all(GJSpace.s4),
            decoration: BoxDecoration(color: GJColors.errorContainer, borderRadius: GJRadius.borderMd),
            child: Text(_erroGeral!, style: GJTypography.label(color: GJColors.error)),
          ),
          const SizedBox(height: GJSpace.s4),
        ],
        GJInput(
          label: 'Nova senha',
          controller: _senhaController,
          obscureText: true,
          errorText: _erroSenha,
          helperText: _erroSenha == null ? '7 ou mais caracteres' : null,
        ),
        const SizedBox(height: GJSpace.s3),
        GJInput(label: 'Confirmar senha', controller: _confirmarController, obscureText: true, errorText: _erroConfirmar),
        const SizedBox(height: GJSpace.s4),
        GJButton(label: 'Redefinir senha', expand: true, loading: _enviando, onPressed: _enviando ? null : _redefinir),
      ],
    );
  }
}
