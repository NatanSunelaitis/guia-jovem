import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../admin/domain/cadastros.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../perfil/presentation/widgets/secao_carregavel.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'widgets/faixa_situacao.dart';
import '../../../shared/widgets/gj_aviso.dart';

const _grupos = [
  (TipoPrograma.entrada, 'Programas de entrada'),
  (TipoPrograma.financiamento, 'Financiamento'),
  (TipoPrograma.bolsa, 'Bolsas de estudo nacionais'),
];

/// T23.4 e T23.5 Programas aceitos (RF12, RF13, RF17): marca e desmarca os
/// programas globais de entrada, financiamento e bolsa. A observação aparece
/// na página pública ao lado do programa. "Salvar" envia o conjunto inteiro.
class SecaoProgramasAceitos extends StatefulWidget {
  const SecaoProgramasAceitos({super.key, required this.universidadeId, required this.acesso});

  final int universidadeId;
  final AcessoPainel acesso;

  @override
  State<SecaoProgramasAceitos> createState() => _SecaoProgramasAceitosState();
}

class _SecaoProgramasAceitosState extends State<SecaoProgramasAceitos> {
  late Future<List<ProgramaAceito>> _future = _buscar();
  final Map<int, TextEditingController> _observacoes = {};
  final Set<int> _marcados = {};
  bool _salvando = false;
  String? _erro;

  Future<List<ProgramaAceito>> _buscar() async {
    final programas = await painelUniversidadeRepository.programas(widget.universidadeId);
    _aplicar(programas);
    return programas;
  }

  void _aplicar(List<ProgramaAceito> programas) {
    _marcados
      ..clear()
      ..addAll([for (final p in programas) if (p.aceito) p.id]);
    for (final programa in programas) {
      (_observacoes[programa.id] ??= TextEditingController()).text = programa.observacao ?? '';
    }
  }

  void _recarregar() => setState(() {
        _future = _buscar();
      });

  @override
  void dispose() {
    for (final controller in _observacoes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final programas = await painelUniversidadeRepository.definirProgramas(widget.universidadeId, {
        for (final id in _marcados) id: textoOuNulo(_observacoes[id]!),
      });
      if (!mounted) return;
      setState(() {
        _aplicar(programas);
        _future = Future.value(programas);
      });
      ScaffoldMessenger.of(context).aviso('Programas aceitos atualizados.');
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = mensagemDaApi(erro));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _programa(ProgramaAceito programa, bool edita) {
    final marcado = _marcados.contains(programa.id);
    return Container(
      margin: const EdgeInsets.only(bottom: GJSpace.s3),
      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s4, vertical: GJSpace.s2),
      decoration: BoxDecoration(
        color: marcado ? GJColors.primaryFixed : GJColors.surfaceLowest,
        borderRadius: GJRadius.borderMd,
        border: Border.all(color: GJColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            key: Key('programa-${programa.id}'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: marcado,
            title: Text(programa.sigla == null ? programa.nome : '${programa.sigla} · ${programa.nome}'),
            onChanged: edita
                ? (valor) => setState(() => valor == true ? _marcados.add(programa.id) : _marcados.remove(programa.id))
                : null,
          ),
          if (marcado)
            CampoTexto(
              rotulo: 'Observação (opcional)',
              controller: _observacoes[programa.id]!,
              dica: 'Ex.: aceito em todos os cursos',
              maxLength: 255,
              enabled: edita,
            ),
        ],
      ),
    );
  }

  Widget _lista(List<ProgramaAceito> programas) {
    final edita = widget.acesso.editaDominio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (tipo, titulo) in _grupos)
          if (programas.any((p) => p.tipo == tipo)) ...[
            Text(titulo, style: GJTypography.h4()),
            const SizedBox(height: GJSpace.s3),
            for (final programa in programas.where((p) => p.tipo == tipo)) _programa(programa, edita),
            const SizedBox(height: GJSpace.s4),
          ],
        if (_erro != null) ...[
          Text(_erro!, style: GJTypography.label(color: GJColors.error)),
          const SizedBox(height: GJSpace.s3),
        ],
        if (edita)
          Align(
            alignment: Alignment.centerRight,
            child: GJButton(label: 'Salvar', loading: _salvando, onPressed: _salvando ? null : _salvar),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final aviso = widget.acesso.avisoLeitura(cadastro: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoSecao(
          titulo: 'Programas aceitos',
          subtitulo: 'Marque os programas aceitos pela instituição. A observação aparece na página pública ao lado '
              'do programa.',
        ),
        if (aviso != null) AvisoSomenteLeitura(aviso),
        SecaoCarregavel<ProgramaAceito>(
          future: _future,
          onTentarNovamente: _recarregar,
          vazio: const GJEmptyState(titulo: 'Nenhum programa cadastrado pela equipe Guia Jovem', icone: Symbols.school),
          construir: _lista,
        ),
      ],
    );
  }
}
