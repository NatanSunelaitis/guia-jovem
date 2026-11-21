import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_texto_formatado.dart';
import '../../admin/domain/universidade_admin.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../admin/presentation/widgets/formulario_universidade.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'widgets/faixa_situacao.dart';
import '../../../shared/widgets/gj_aviso.dart';

/// T23.1 Dados da instituição (RF18): identidade, contato, descrição e
/// links, editados no mesmo formulário do administrador (PATCH
/// /universidades/:id), e o card "Desempenho da página" com as visitas dos
/// últimos 30 dias e a média das avaliações.
class SecaoDadosInstituicao extends StatefulWidget {
  const SecaoDadosInstituicao({super.key, required this.cadastro, required this.acesso, required this.onAlterado});

  final UniversidadeCadastro cadastro;
  final AcessoPainel acesso;
  final ValueChanged<UniversidadeCadastro> onAlterado;

  @override
  State<SecaoDadosInstituicao> createState() => _SecaoDadosInstituicaoState();
}

class _SecaoDadosInstituicaoState extends State<SecaoDadosInstituicao> {
  late final Future<EstatisticaUniversidade> _estatisticas = painelUniversidadeRepository.estatisticas(widget.cadastro.id);

  Future<void> _editar() async {
    final salvo = await abrirFormulario<UniversidadeCadastro>(
      context,
      titulo: 'Editar dados da instituição',
      formulario: FormularioUniversidade(cadastro: widget.cadastro),
    );
    if (salvo == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).aviso('Dados da instituição atualizados.');
    widget.onAlterado(salvo);
  }

  Widget _dado(String rotulo, String? valor) => SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: GJTypography.caption()),
            const SizedBox(height: GJSpace.s1),
            SelectableText(valor == null || valor.isEmpty ? '-' : valor, style: GJTypography.body()),
          ],
        ),
      );

  Widget _cartao({required String titulo, required Widget conteudo}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GJSpace.s6),
        decoration: BoxDecoration(
          color: GJColors.surfaceLowest,
          borderRadius: GJRadius.borderLg,
          border: Border.all(color: GJColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(titulo, style: GJTypography.h4()), const SizedBox(height: GJSpace.s4), conteudo],
        ),
      );

  Widget _desempenho() {
    return FutureBuilder<EstatisticaUniversidade>(
      future: _estatisticas,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const GJSkeleton(height: GJSpace.s12);
        if (snapshot.hasError) {
          return Text('Não foi possível carregar as estatísticas.', style: GJTypography.bodySm());
        }
        final estatistica = snapshot.data!;
        final media = estatistica.mediaAvaliacao;
        return Wrap(
          spacing: GJSpace.s6,
          runSpacing: GJSpace.s4,
          children: [
            _dado('Visitas à página nos últimos 30 dias', '${estatistica.visitas}'),
            _dado(
              'Média das avaliações',
              media == null
                  ? 'Sem avaliações'
                  : '${media.toStringAsFixed(1).replaceAll('.', ',')} (${estatistica.totalAvaliacoes} '
                      '${estatistica.totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'})',
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cadastro = widget.cadastro;
    final aviso = widget.acesso.avisoLeitura(cadastro: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoSecao(
          titulo: 'Dados da instituição',
          subtitulo: 'Identidade, contato, descrição e links que aparecem na página da universidade.',
          acao: widget.acesso.editaCadastro
              ? GJButton(label: 'Editar dados', icon: Symbols.edit, onPressed: _editar)
              : null,
        ),
        if (aviso != null) AvisoSomenteLeitura(aviso),
        _cartao(
          titulo: 'Identidade institucional',
          conteudo: Wrap(
            spacing: GJSpace.s6,
            runSpacing: GJSpace.s4,
            children: [
              _dado('Nome fantasia', cadastro.nomeFantasia),
              _dado('Razão social', cadastro.razaoSocial),
              _dado('CNPJ', formatarCnpj(cadastro.cnpj)),
              _dado('Natureza', rotuloNatureza(cadastro.natureza)),
              _dado('Telefone principal', cadastro.telefonePrincipal),
              _dado('Campus principal', cadastro.campusPrincipalNome),
            ],
          ),
        ),
        const SizedBox(height: GJSpace.s4),
        _cartao(
          titulo: 'Descrição e links',
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Sobre" formatado, como aparece na página pública.
              if (cadastro.descricao == null || cadastro.descricao!.trim().isEmpty)
                Text('Sem descrição.', style: GJTypography.body())
              else
                GJTextoFormatado(cadastro.descricao),
              const SizedBox(height: GJSpace.s4),
              Wrap(
                spacing: GJSpace.s6,
                runSpacing: GJSpace.s4,
                children: [
                  _dado('Página oficial', cadastro.linkPagina),
                  _dado('Simulados anteriores', cadastro.linkSimulados),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: GJSpace.s4),
        _cartao(titulo: 'Desempenho da página', conteudo: _desempenho()),
      ],
    );
  }
}
