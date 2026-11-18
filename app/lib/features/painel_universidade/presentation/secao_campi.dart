import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/data/estados_brasil.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_status_badge.dart';
import '../../admin/presentation/widgets/confirmacao_dialogs.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../perfil/presentation/widgets/secao_carregavel.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'widgets/faixa_situacao.dart';

/// T23.3 Campi (RF21, RF22): tabela com nome, cidade, telefone, principal e
/// ações; o formulário completo de campus e endereço abre no painel lateral.
/// A API mantém exatamente um campus principal e não deixa excluir o único
/// campus, o principal nem um campus com cursos ofertados.
class SecaoCampi extends StatefulWidget {
  const SecaoCampi({super.key, required this.universidadeId, required this.acesso, this.onAlterado});

  final int universidadeId;
  final AcessoPainel acesso;

  /// O campus principal aparece nos dados da instituição.
  final VoidCallback? onAlterado;

  @override
  State<SecaoCampi> createState() => _SecaoCampiState();
}

class _SecaoCampiState extends State<SecaoCampi> {
  late Future<List<CampusGestao>> _future = _buscar();

  Future<List<CampusGestao>> _buscar() => painelUniversidadeRepository.campus(widget.universidadeId);

  void _recarregar() => setState(() {
        _future = _buscar();
      });

  Future<void> _abrirFormulario([CampusGestao? campus]) async {
    final salvo = await abrirFormulario<CampusGestao>(
      context,
      titulo: campus == null ? 'Novo campus' : 'Editar campus',
      formulario: FormularioCampus(universidadeId: widget.universidadeId, campus: campus),
    );
    if (salvo == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(campus == null ? 'Campus criado.' : 'Campus atualizado.')));
    _recarregar();
    widget.onAlterado?.call();
  }

  Future<void> _excluir(CampusGestao campus) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir campus',
      texto: '${campus.nome} deixa de aparecer na página da universidade.',
      rotuloConfirmar: 'Excluir',
      destrutiva: true,
    );
    if (!confirmou) return;
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await painelUniversidadeRepository.excluirCampus(campus.id);
      if (!mounted) return;
      mensageiro.showSnackBar(const SnackBar(content: Text('Campus excluído.')));
      _recarregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      await mostrarAcaoBloqueada(context, erro.message);
    }
  }

  Widget _tabela(List<CampusGestao> campi) {
    final edita = widget.acesso.editaCadastro;
    final unico = campi.length == 1;
    return GJDataTable(
      acaoPrimariaLabel: edita ? 'Novo campus' : null,
      onAcaoPrimaria: edita ? () => _abrirFormulario() : null,
      colunas: [
        const GJDataColumn('Nome', flex: 3),
        const GJDataColumn('Cidade / UF', flex: 2),
        const GJDataColumn('Telefone', flex: 2),
        const GJDataColumn('Principal', flex: 1),
        if (edita) const GJDataColumn('Ações', flex: 2),
      ],
      linhas: [
        for (final campus in campi)
          [
            Text(campus.nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
            Text(campus.cidadeUf, style: GJTypography.bodySm()),
            Text(campus.telefone ?? '-', style: GJTypography.bodySm()),
            campus.principal
                ? encolherSePreciso(const GJStatusBadge(label: 'Sim', tone: GJStatusTone.success))
                : Text('Não', style: GJTypography.bodySm()),
            if (edita)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Editar ${campus.nome}',
                    icon: const Icon(Symbols.edit),
                    onPressed: () => _abrirFormulario(campus),
                  ),
                  IconButton(
                    tooltip: unico ? 'A universidade precisa ter ao menos um campus' : 'Excluir ${campus.nome}',
                    icon: const Icon(Symbols.delete),
                    onPressed: unico ? null : () => _excluir(campus),
                  ),
                ],
              ),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final aviso = widget.acesso.avisoLeitura(cadastro: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoSecao(titulo: 'Campi', subtitulo: 'A universidade tem sempre um campus principal.'),
        if (aviso != null) AvisoSomenteLeitura(aviso),
        SecaoCarregavel<CampusGestao>(
          future: _future,
          onTentarNovamente: _recarregar,
          vazio: const GJEmptyState(titulo: 'Nenhum campus cadastrado', icone: Symbols.location_city),
          construir: _tabela,
        ),
      ],
    );
  }
}

/// Campus e endereço (Figura 30): nome, CNPJ opcional, endereço com CEP,
/// telefones, e-mail e campus principal.
class FormularioCampus extends StatefulWidget {
  const FormularioCampus({super.key, required this.universidadeId, this.campus});

  final int universidadeId;
  final CampusGestao? campus;

  @override
  State<FormularioCampus> createState() => _FormularioCampusState();
}

class _FormularioCampusState extends State<FormularioCampus> {
  late final _nome = TextEditingController(text: widget.campus?.nome);
  late final _cnpj = TextEditingController(text: widget.campus?.cnpj);
  late final _logradouro = TextEditingController(text: widget.campus?.endereco.logradouro);
  late final _numero = TextEditingController(text: widget.campus?.endereco.numero);
  late final _complemento = TextEditingController(text: widget.campus?.endereco.complemento);
  late final _bairro = TextEditingController(text: widget.campus?.endereco.bairro);
  late final _cep = TextEditingController(text: widget.campus?.endereco.cep);
  late final _cidade = TextEditingController(text: widget.campus?.endereco.cidade);
  late final _telefoneFixo = TextEditingController(text: widget.campus?.telefoneFixo);
  late final _telefoneCelular = TextEditingController(text: widget.campus?.telefoneCelular);
  late final _email = TextEditingController(text: widget.campus?.emailCampus);
  late String? _estado = widget.campus?.endereco.estado;
  late bool _principal = widget.campus?.principal ?? false;

  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  /// O principal só deixa de ser principal quando outro campus é marcado.
  bool get _ehOPrincipal => widget.campus?.principal ?? false;

  @override
  void dispose() {
    for (final c in [_nome, _cnpj, _logradouro, _numero, _complemento, _bairro, _cep, _cidade, _telefoneFixo, _telefoneCelular, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _validar() {
    final erros = <String, String>{};
    void obrigatorio(TextEditingController c, String campo, String mensagem) {
      if (c.text.trim().isEmpty) erros[campo] = mensagem;
    }

    obrigatorio(_nome, 'nome', 'Informe o nome do campus');
    obrigatorio(_logradouro, 'endereco.logradouro', 'Informe o logradouro');
    obrigatorio(_numero, 'endereco.numero', 'Informe o número');
    obrigatorio(_bairro, 'endereco.bairro', 'Informe o bairro');
    obrigatorio(_cidade, 'endereco.cidade', 'Informe a cidade');
    if (_estado == null) erros['endereco.estado'] = 'Escolha o estado';
    if (_cep.text.replaceAll(RegExp(r'\D'), '').length != 8) erros['endereco.cep'] = 'CEP deve ter 8 dígitos';
    final cnpj = _cnpj.text.replaceAll(RegExp(r'[.\-/\s]'), '');
    if (cnpj.isNotEmpty && cnpj.length != 14) erros['cnpj'] = 'O CNPJ do campus deve ter 14 caracteres';
    return erros;
  }

  Future<void> _salvar() async {
    final erros = _validar();
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    final dados = <String, dynamic>{
      'nome': _nome.text.trim(),
      'cnpj': textoOuNulo(_cnpj),
      'telefoneFixo': textoOuNulo(_telefoneFixo),
      'telefoneCelular': textoOuNulo(_telefoneCelular),
      'emailCampus': textoOuNulo(_email),
      // Desmarcar o principal não é enviado: a API exige marcar outro.
      if (_principal || !_ehOPrincipal) 'principal': _principal,
      'endereco': {
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'complemento': textoOuNulo(_complemento),
        'bairro': _bairro.text.trim(),
        'cidade': _cidade.text.trim(),
        'estado': _estado,
        'cep': _cep.text.trim(),
      },
    };

    setState(() => _salvando = true);
    try {
      final salvo = widget.campus == null
          ? await painelUniversidadeRepository.criarCampus(widget.universidadeId, dados)
          : await painelUniversidadeRepository.atualizarCampus(widget.campus!.id, dados);
      if (mounted) Navigator.of(context).pop(salvo);
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
        CampoTexto(rotulo: 'Nome do campus', controller: _nome, erro: _erros['nome'], maxLength: 100),
        CampoTexto(rotulo: 'CNPJ do campus (opcional)', controller: _cnpj, erro: _erros['cnpj']),
        CampoTexto(rotulo: 'Logradouro', controller: _logradouro, erro: _erros['endereco.logradouro'], maxLength: 100),
        CampoTexto(rotulo: 'Número', controller: _numero, erro: _erros['endereco.numero'], maxLength: 10),
        CampoTexto(rotulo: 'Complemento', controller: _complemento, erro: _erros['endereco.complemento'], maxLength: 100),
        CampoTexto(rotulo: 'Bairro', controller: _bairro, erro: _erros['endereco.bairro'], maxLength: 100),
        CampoTexto(rotulo: 'CEP', controller: _cep, erro: _erros['endereco.cep'], keyboardType: TextInputType.number),
        CampoTexto(rotulo: 'Cidade', controller: _cidade, erro: _erros['endereco.cidade'], maxLength: 100),
        CampoSelecao<String>(
          key: const Key('campus-estado'),
          rotulo: 'Estado',
          valor: _estado,
          erro: _erros['endereco.estado'],
          opcoes: {for (final uf in estadosBrasil) uf: uf},
          onChanged: (valor) => setState(() => _estado = valor),
        ),
        CampoTexto(rotulo: 'Telefone fixo', controller: _telefoneFixo, erro: _erros['telefoneFixo'], maxLength: 15),
        CampoTexto(rotulo: 'Telefone celular', controller: _telefoneCelular, erro: _erros['telefoneCelular'], maxLength: 15),
        CampoTexto(rotulo: 'E-mail do campus', controller: _email, erro: _erros['emailCampus'], maxLength: 100),
        CheckboxListTile(
          key: const Key('campus-principal'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _principal,
          title: const Text('Campus principal'),
          subtitle: Text(
            _ehOPrincipal
                ? 'Para trocar o principal, marque outro campus como principal.'
                : 'Marcar este campus desmarca o principal atual.',
            style: GJTypography.bodySm(),
          ),
          onChanged: _ehOPrincipal ? null : (valor) => setState(() => _principal = valor ?? false),
        ),
        const SizedBox(height: GJSpace.s4),
        RodapeFormulario(salvando: _salvando, onSalvar: _salvar, erro: _erroGeral, rotuloSalvar: 'Salvar campus'),
      ],
    );
  }
}
