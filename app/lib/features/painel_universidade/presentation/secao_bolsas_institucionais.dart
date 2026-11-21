import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/utils/texto_formatado.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../admin/presentation/widgets/confirmacao_dialogs.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../perfil/presentation/widgets/secao_carregavel.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'widgets/faixa_situacao.dart';

/// T23.5 Bolsas da instituição (RF11): bolsas próprias da universidade,
/// visíveis só na página dela (com a tag "Bolsa institucional"). As bolsas
/// nacionais aceitas, como o ProUni, ficam em "Programas aceitos".
class SecaoBolsasInstitucionais extends StatefulWidget {
  const SecaoBolsasInstitucionais({super.key, required this.universidadeId, required this.acesso});

  final int universidadeId;
  final AcessoPainel acesso;

  @override
  State<SecaoBolsasInstitucionais> createState() => _SecaoBolsasInstitucionaisState();
}

class _SecaoBolsasInstitucionaisState extends State<SecaoBolsasInstitucionais> {
  late Future<List<BolsaInstitucional>> _future = _buscar();

  Future<List<BolsaInstitucional>> _buscar() => painelUniversidadeRepository.bolsas(widget.universidadeId);

  void _recarregar() => setState(() {
        _future = _buscar();
      });

  Future<void> _abrirFormulario([BolsaInstitucional? bolsa]) async {
    final salvo = await abrirFormulario<bool>(
      context,
      titulo: bolsa == null ? 'Nova bolsa' : 'Editar bolsa',
      formulario: FormularioBolsa(universidadeId: widget.universidadeId, bolsa: bolsa),
    );
    if (salvo != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bolsa == null ? 'Bolsa criada.' : 'Bolsa atualizada.')));
    _recarregar();
  }

  Future<void> _excluir(BolsaInstitucional bolsa) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir bolsa',
      texto: '${bolsa.nome} deixa de aparecer na página da universidade.',
      rotuloConfirmar: 'Excluir',
      destrutiva: true,
    );
    if (!confirmou) return;
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await painelUniversidadeRepository.excluirBolsa(widget.universidadeId, bolsa.id);
      if (!mounted) return;
      mensageiro.showSnackBar(const SnackBar(content: Text('Bolsa excluída.')));
      _recarregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      await mostrarAcaoBloqueada(context, erro.message);
    }
  }

  Widget _tabela(List<BolsaInstitucional> bolsas) {
    final edita = widget.acesso.editaDominio;
    return GJDataTable(
      acaoPrimariaLabel: edita ? 'Nova bolsa' : null,
      onAcaoPrimaria: edita ? () => _abrirFormulario() : null,
      colunas: [
        const GJDataColumn('Nome', flex: 3),
        const GJDataColumn('Descrição', flex: 4),
        const GJDataColumn('Link', flex: 3),
        if (edita) const GJDataColumn('Ações', flex: 2),
      ],
      linhas: [
        for (final bolsa in bolsas)
          [
            Text(bolsa.nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
            Text(resumoTextoFormatado(bolsa.descricao, limite: 160), style: GJTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(bolsa.linkOficial ?? '-', style: GJTypography.bodySm(), overflow: TextOverflow.ellipsis),
            if (edita)
              Row(
                children: [
                  IconButton(tooltip: 'Editar ${bolsa.nome}', icon: const Icon(Symbols.edit), onPressed: () => _abrirFormulario(bolsa)),
                  IconButton(tooltip: 'Excluir ${bolsa.nome}', icon: const Icon(Symbols.delete), onPressed: () => _excluir(bolsa)),
                ],
              ),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final aviso = widget.acesso.avisoLeitura(cadastro: false);
    final edita = widget.acesso.editaDominio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoSecao(
          titulo: 'Bolsas institucionais',
          subtitulo: 'Bolsas oferecidas pela própria instituição. Elas aparecem só na página da universidade.',
        ),
        if (aviso != null) AvisoSomenteLeitura(aviso),
        SecaoCarregavel<BolsaInstitucional>(
          future: _future,
          onTentarNovamente: _recarregar,
          vazio: GJEmptyState(
            titulo: 'Nenhuma bolsa institucional',
            texto: 'Cadastre as bolsas próprias da instituição, como descontos por mérito.',
            icone: Symbols.workspace_premium,
            acaoLabel: edita ? 'Nova bolsa' : null,
            onAcao: edita ? () => _abrirFormulario() : null,
          ),
          construir: _tabela,
        ),
      ],
    );
  }
}

/// Nome, descrição, requisitos, como funciona e link da bolsa (T23.5).
class FormularioBolsa extends StatefulWidget {
  const FormularioBolsa({super.key, required this.universidadeId, this.bolsa});

  final int universidadeId;
  final BolsaInstitucional? bolsa;

  @override
  State<FormularioBolsa> createState() => _FormularioBolsaState();
}

class _FormularioBolsaState extends State<FormularioBolsa> {
  late final _nome = TextEditingController(text: widget.bolsa?.nome);
  late final _descricao = TextEditingController(text: widget.bolsa?.descricao);
  late final _requisitos = TextEditingController(text: widget.bolsa?.requisitos);
  late final _comoFunciona = TextEditingController(text: widget.bolsa?.comoFunciona);
  late final _link = TextEditingController(text: widget.bolsa?.linkOficial);

  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_nome, _descricao, _requisitos, _comoFunciona, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final erros = <String, String>{
      if (_nome.text.trim().isEmpty) 'nome': 'Informe o nome da bolsa',
      if (_descricao.text.trim().isEmpty) 'descricao': 'Informe a descrição',
    };
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    final dados = {
      'nome': _nome.text.trim(),
      'descricao': _descricao.text.trim(),
      'requisitos': textoOuNulo(_requisitos),
      'comoFunciona': textoOuNulo(_comoFunciona),
      'linkOficial': textoOuNulo(_link),
    };
    setState(() => _salvando = true);
    try {
      if (widget.bolsa == null) {
        await painelUniversidadeRepository.criarBolsa(widget.universidadeId, dados);
      } else {
        await painelUniversidadeRepository.atualizarBolsa(widget.universidadeId, widget.bolsa!.id, dados);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erros = errosPorCampo(erro);
        _erroGeral = mensagemDaApi(erro);
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome da bolsa', controller: _nome, erro: _erros['nome'], maxLength: 100),
        CampoTextoLongo(rotulo: 'Descrição', controller: _descricao, erro: _erros['descricao'], campoKey: const Key('bolsa-descricao')),
        CampoTextoLongo(rotulo: 'Requisitos', controller: _requisitos, erro: _erros['requisitos']),
        CampoTextoLongo(rotulo: 'Como funciona', controller: _comoFunciona, erro: _erros['comoFunciona']),
        CampoTexto(rotulo: 'Link', controller: _link, erro: _erros['linkOficial'], dica: 'https://'),
        RodapeFormulario(salvando: _salvando, onSalvar: _salvar, erro: _erroGeral, rotuloSalvar: 'Salvar bolsa'),
      ],
    );
  }
}
