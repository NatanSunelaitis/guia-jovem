import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/formatar_data.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/domain/universidade_admin.dart';
import '../../admin/presentation/widgets/confirmacao_dialogs.dart';
import '../../auth/data/session_controller.dart';

/// T23 provisório (Pendência 3): mostra a situação do cadastro da
/// universidade (RF23), lida da API a cada abertura (a sessão guarda o
/// status do momento do login), e o atalho para as sugestões recebidas.
/// As abas do painel (informações, cursos, campus, programas, bolsas) ficam
/// para outra rodada.
class PainelUniversidadePage extends StatefulWidget {
  const PainelUniversidadePage({super.key});

  @override
  State<PainelUniversidadePage> createState() => _PainelUniversidadePageState();
}

class _PainelUniversidadePageState extends State<PainelUniversidadePage> {
  Future<UniversidadeCadastro>? _future;

  @override
  void initState() {
    super.initState();
    _future = _buscar();
  }

  Future<UniversidadeCadastro>? _buscar() {
    final universidadeId = sessionController.usuario?.universidade?.id;
    return universidadeId == null ? null : adminRepository.cadastro(universidadeId);
  }

  void _carregar() => setState(() => _future = _buscar());

  ({IconData icone, Color cor, Color fundo, String titulo, String texto}) _situacao(UniversidadeCadastro cadastro) {
    final nome = cadastro.nomeFantasia;
    return switch (cadastro.status) {
      StatusUniversidade.pendente => (
          icone: Symbols.hourglass_top,
          cor: GJColors.warning,
          fundo: GJColors.warningContainer,
          titulo: 'Cadastro em análise',
          texto: 'A equipe Guia Jovem está analisando o cadastro de $nome, enviado em '
              '${formatarData(cadastro.criadoEm)}. A análise leva até 15 dias. Enquanto isso, a página da '
              'universidade não aparece no site. Você recebe uma notificação e um e-mail com o resultado.',
        ),
      StatusUniversidade.reprovada => (
          icone: Symbols.cancel,
          cor: GJColors.errorOnContainer,
          fundo: GJColors.errorContainer,
          titulo: 'Cadastro reprovado',
          texto: 'O cadastro de $nome não foi aprovado e a página não aparece no site.',
        ),
      StatusUniversidade.inativa => (
          icone: Symbols.visibility_off,
          cor: GJColors.textSecondary,
          fundo: GJColors.surface,
          titulo: 'Universidade inativa',
          texto: '$nome foi inativada e não aparece no site. Em caso de dúvida, entre em contato com a equipe '
              'Guia Jovem.',
        ),
      StatusUniversidade.aprovada => (
          icone: Symbols.verified,
          cor: GJColors.success,
          fundo: GJColors.successContainer,
          titulo: 'Página publicada',
          texto: '$nome está aprovada e aparece na pesquisa do Guia Jovem'
              '${cadastro.aprovadoEm == null ? '' : ' desde ${formatarData(cadastro.aprovadoEm!)}'}.',
        ),
    };
  }

  Widget _cartaoSituacao(UniversidadeCadastro cadastro) {
    final situacao = _situacao(cadastro);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: situacao.fundo, borderRadius: GJRadius.borderLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(situacao.icone, color: situacao.cor, size: 28),
          const SizedBox(width: GJSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: GJSpace.s3,
                  runSpacing: GJSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(situacao.titulo, style: GJTypography.h4()),
                    badgeStatusUniversidade(cadastro.status),
                  ],
                ),
                const SizedBox(height: GJSpace.s2),
                Text(situacao.texto, style: GJTypography.body()),
                if (cadastro.status == StatusUniversidade.reprovada) ...[
                  const SizedBox(height: GJSpace.s3),
                  Text('Motivo informado pela equipe', style: GJTypography.label()),
                  const SizedBox(height: GJSpace.s1),
                  SelectableText(
                    cadastro.motivoReprovacao ?? 'Motivo não informado.',
                    style: GJTypography.body().copyWith(color: GJColors.errorOnContainer),
                  ),
                ],
                if (cadastro.status == StatusUniversidade.aprovada) ...[
                  const SizedBox(height: GJSpace.s4),
                  GJButton(
                    label: 'Ver página pública',
                    icon: Symbols.open_in_new,
                    variant: GJButtonVariant.secondary,
                    size: GJButtonSize.sm,
                    onPressed: () => context.go('/universidades/${cadastro.id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _situacaoCarregada() {
    if (_future == null) {
      return const GJEmptyState(
        titulo: 'Universidade não encontrada',
        texto: 'Esta conta não está vinculada a uma universidade.',
        icone: Symbols.account_balance,
      );
    }
    return FutureBuilder<UniversidadeCadastro>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GJSkeleton(height: 140);
        }
        if (snapshot.hasError) {
          final erro = snapshot.error;
          return GJEmptyState(
            titulo: 'Não foi possível carregar a situação do cadastro',
            texto: erro is ApiException ? erro.message : null,
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: _carregar,
          );
        }
        return _cartaoSituacao(snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      tituloPainel: 'Painel de Administração da Universidade',
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Painel da Universidade', style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s6),
              _situacaoCarregada(),
              const SizedBox(height: GJSpace.s8),
              Row(
                children: [
                  const Icon(Symbols.construction, color: GJColors.textDisabled),
                  const SizedBox(width: GJSpace.s3),
                  Expanded(
                    child: Text(
                      'As abas do painel (informações, cursos, campus, programas e bolsas) ainda não foram construídas.',
                      style: GJTypography.body().copyWith(color: GJColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GJSpace.s6),
              GJButton(
                label: 'Sugestões recebidas',
                icon: Symbols.forum,
                onPressed: () => context.go('/sugestoes-recebidas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
