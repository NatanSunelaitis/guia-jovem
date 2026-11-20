import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/utils/formatar_data.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../auth/data/session_controller.dart';
import '../../auth/presentation/widgets/alterar_senha_dialog.dart';
import '../../auth/presentation/widgets/excluir_conta_dialog.dart';
import '../../universidades/domain/avaliacao.dart';
import '../data/painel_universidade_repository.dart';
import 'widgets/faixa_situacao.dart';

/// Avaliações que os alunos deixaram para a universidade (RF01), somente
/// leitura, em qualquer situação do cadastro.
class SecaoAvaliacoesRecebidas extends StatefulWidget {
  const SecaoAvaliacoesRecebidas({super.key, required this.universidadeId});

  final int universidadeId;

  @override
  State<SecaoAvaliacoesRecebidas> createState() => _SecaoAvaliacoesRecebidasState();
}

class _SecaoAvaliacoesRecebidasState extends State<SecaoAvaliacoesRecebidas> {
  int _pagina = 1;
  late Future<PaginatedResult<Avaliacao>> _future = _buscar();

  Future<PaginatedResult<Avaliacao>> _buscar() => painelUniversidadeRepository.avaliacoes(widget.universidadeId, page: _pagina);

  void _irPara(int pagina) => setState(() {
        _pagina = pagina;
        _future = _buscar();
      });

  Widget _avaliacao(Avaliacao avaliacao) {
    return Container(
      margin: const EdgeInsets.only(bottom: GJSpace.s3),
      padding: const EdgeInsets.all(GJSpace.s4),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderMd,
        border: Border.all(color: GJColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  Symbols.star,
                  size: GJSpace.s4,
                  fill: i <= avaliacao.nota ? 1 : 0,
                  color: i <= avaliacao.nota ? GJColors.rating : GJColors.border,
                ),
              const SizedBox(width: GJSpace.s2),
              Expanded(
                child: Text(
                  '${avaliacao.autor ?? 'Conta excluída'} · ${formatarData(avaliacao.criadoEm)}',
                  style: GJTypography.caption(),
                ),
              ),
            ],
          ),
          if (avaliacao.comentario != null && avaliacao.comentario!.isNotEmpty) ...[
            const SizedBox(height: GJSpace.s2),
            Text(avaliacao.comentario!, style: GJTypography.body()),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoSecao(
          titulo: 'Avaliações recebidas',
          subtitulo: 'Notas e comentários dos estudantes. Só o primeiro nome do autor aparece.',
        ),
        FutureBuilder<PaginatedResult<Avaliacao>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const GJSkeleton(height: GJSpace.s24);
            if (snapshot.hasError) {
              final erro = snapshot.error;
              return GJEmptyState(
                titulo: 'Não foi possível carregar',
                texto: erro is ApiException ? erro.message : null,
                icone: Symbols.wifi_off,
                acaoLabel: 'Tentar novamente',
                onAcao: () => _irPara(_pagina),
              );
            }
            final resultado = snapshot.data!;
            if (resultado.data.isEmpty) {
              return const GJEmptyState(
                titulo: 'Nenhuma avaliação recebida',
                texto: 'As avaliações aparecem aqui quando os estudantes avaliarem a universidade.',
                icone: Symbols.star,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final avaliacao in resultado.data) _avaliacao(avaliacao),
                if (resultado.totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Página anterior',
                        icon: const Icon(Symbols.chevron_left),
                        onPressed: _pagina > 1 ? () => _irPara(_pagina - 1) : null,
                      ),
                      Text('Página $_pagina de ${resultado.totalPages}', style: GJTypography.bodySm()),
                      IconButton(
                        tooltip: 'Próxima página',
                        icon: const Icon(Symbols.chevron_right),
                        onPressed: _pagina < resultado.totalPages ? () => _irPara(_pagina + 1) : null,
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Conta (RF09, Quadro 13): alterar senha (T21), sair com confirmação (RF06)
/// e excluir conta (T22), que inativa a universidade e encerra a sessão.
/// Disponível em qualquer situação do cadastro.
class SecaoConta extends StatelessWidget {
  const SecaoConta({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = sessionController.usuario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoSecao(titulo: 'Conta', subtitulo: 'Acesso da conta que administra a universidade.'),
        if (usuario != null) ...[
          Text(usuario.nome, style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s1),
          Text(usuario.email, style: GJTypography.bodySm()),
          const SizedBox(height: GJSpace.s6),
        ],
        Wrap(
          spacing: GJSpace.s3,
          runSpacing: GJSpace.s3,
          children: [
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
            GJButton(
              label: 'Excluir conta',
              icon: Symbols.delete,
              variant: GJButtonVariant.danger,
              onPressed: () => mostrarDialogoExcluirConta(
                context,
                aviso: 'A universidade fica inativa e deixa de aparecer no site. Os dados da instituição são '
                    'mantidos, mas esta conta é apagada.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
