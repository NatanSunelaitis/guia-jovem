import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_aviso.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_lista_paginada.dart' show normalizarBusca;
import '../../../shared/widgets/gj_skeleton.dart';
import '../../painel_universidade/data/painel_universidade_repository.dart';
import '../../painel_universidade/domain/painel_universidade.dart';
import '../data/admin_repository.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastros.dart';
import '../domain/universidade_admin.dart';
import 'widgets/formulario.dart';

/// Formulário de curso do administrador e do painel da universidade (RF19,
/// RF20): nome com sugestão, área com as áreas existentes, grau, modalidade,
/// duração, nota do MEC, descrição e as ofertas (campus, turno e vagas).

const grausCurso = ['Bacharelado', 'Licenciatura', 'Tecnólogo'];
const modalidadesCurso = ['Presencial', 'EAD', 'Semipresencial'];

/// Campo "Nome" do cadastro de curso: enquanto a pessoa digita, sugere os
/// nomes que já existem no sistema, com quantas universidades usam cada um,
/// para os cursos iguais se juntarem na página pública. A sugestão é
/// opcional: qualquer nome pode ser salvo.
class CampoNomeCurso extends StatefulWidget {
  const CampoNomeCurso({super.key, required this.controller, this.erro});

  final TextEditingController controller;
  final String? erro;

  @override
  State<CampoNomeCurso> createState() => _CampoNomeCursoState();
}

class _CampoNomeCursoState extends State<CampoNomeCurso> {
  Timer? _atraso;
  late String _anterior = widget.controller.text;
  String? _escolhido;
  List<SugestaoNomeCurso> _sugestoes = const [];
  int _requisicao = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_aoDigitar);
  }

  @override
  void dispose() {
    _atraso?.cancel();
    widget.controller.removeListener(_aoDigitar);
    super.dispose();
  }

  void _aoDigitar() {
    final texto = widget.controller.text;
    if (texto == _anterior) return; // mudança só do cursor
    _anterior = texto;
    _atraso?.cancel();
    if (texto.trim().length < 2 || texto == _escolhido) {
      _requisicao++;
      if (_sugestoes.isNotEmpty) setState(() => _sugestoes = const []);
      return;
    }
    _atraso = Timer(const Duration(milliseconds: 300), () => _buscar(texto.trim()));
  }

  Future<void> _buscar(String texto) async {
    final requisicao = ++_requisicao;
    try {
      final sugestoes = await cadastrosRepository.sugestoesNomeCurso(texto);
      if (!mounted || requisicao != _requisicao) return;
      setState(() => _sugestoes = [for (final s in sugestoes) if (s.nome != widget.controller.text.trim()) s]);
    } on ApiException {
      // Sem sugestões o cadastro segue normalmente: o nome é digitado à mão.
      if (mounted && requisicao == _requisicao) setState(() => _sugestoes = const []);
    }
  }

  void _escolher(SugestaoNomeCurso sugestao) {
    _escolhido = sugestao.nome;
    widget.controller.value = TextEditingValue(
      text: sugestao.nome,
      selection: TextSelection.collapsed(offset: sugestao.nome.length),
    );
    setState(() => _sugestoes = const []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome', controller: widget.controller, erro: widget.erro, maxLength: 100),
        if (_sugestoes.isNotEmpty)
          Container(
            key: const Key('sugestoes-nome-curso'),
            margin: const EdgeInsets.only(bottom: GJSpace.s4),
            decoration: BoxDecoration(
              color: GJColors.surfaceLowest,
              borderRadius: GJRadius.borderMd,
              border: Border.all(color: GJColors.surfaceHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(GJSpace.s3, GJSpace.s3, GJSpace.s3, GJSpace.s1),
                  child: Text('Nomes já usados no Guia Jovem (escolher é opcional)', style: GJTypography.caption()),
                ),
                for (final sugestao in _sugestoes)
                  InkWell(
                    key: Key('sugestao-nome-${sugestao.nome}'),
                    onTap: () => _escolher(sugestao),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3, vertical: GJSpace.s2),
                      child: Row(
                        children: [
                          const Icon(Symbols.menu_book, size: 18, color: GJColors.textSecondary),
                          const SizedBox(width: GJSpace.s2),
                          Expanded(child: Text(sugestao.nome, style: GJTypography.body())),
                          Text(
                            sugestao.totalUniversidades == 1 ? '1 universidade' : '${sugestao.totalUniversidades} universidades',
                            style: GJTypography.bodySm(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Campo "Área" do cadastro de curso: as áreas que já existem no sistema
/// aparecem como opções (filtradas pelo que se digita, sem diferenciar
/// maiúsculas e acentos), e uma área nova pode ser digitada. Evita grafias
/// diferentes para a mesma área.
class CampoAreaCurso extends StatefulWidget {
  const CampoAreaCurso({super.key, required this.controller, this.erro});

  final TextEditingController controller;
  final String? erro;

  @override
  State<CampoAreaCurso> createState() => _CampoAreaCursoState();
}

class _CampoAreaCursoState extends State<CampoAreaCurso> {
  List<String> _areas = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_aoMudar);
    cadastrosRepository.areasCurso().then((areas) {
      if (mounted) setState(() => _areas = areas);
    }).catchError((Object _) {
      // Sem a lista, a área é digitada à mão.
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_aoMudar);
    super.dispose();
  }

  void _aoMudar() => setState(() {});

  void _escolher(String area) {
    widget.controller.value = TextEditingValue(text: area, selection: TextSelection.collapsed(offset: area.length));
  }

  @override
  Widget build(BuildContext context) {
    final texto = widget.controller.text.trim();
    final busca = normalizarBusca(texto);
    final exata = _areas.contains(texto);
    final equivalente = exata ? null : _areas.where((a) => normalizarBusca(a) == busca).firstOrNull;
    final opcoes = texto.isEmpty || exata ? _areas : [for (final a in _areas) if (normalizarBusca(a).contains(busca)) a];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(
          rotulo: 'Área',
          controller: widget.controller,
          erro: widget.erro,
          dica: _areas.isEmpty ? 'Ex.: Tecnologia' : 'Escolha abaixo ou digite uma área nova',
          maxLength: 100,
        ),
        if (opcoes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s3),
            child: Wrap(
              key: const Key('areas-existentes'),
              spacing: GJSpace.s2,
              runSpacing: GJSpace.s2,
              children: [
                for (final area in opcoes)
                  ChoiceChip(
                    key: Key('area-$area'),
                    label: Text(area),
                    selected: area == texto,
                    onSelected: (_) => _escolher(area),
                  ),
              ],
            ),
          ),
        if (equivalente != null)
          _Dica(
            chave: 'area-equivalente',
            icone: Symbols.warning,
            cor: GJColors.warning,
            texto: 'Já existe "$equivalente". Toque nela para usar a mesma grafia.',
          )
        else if (texto.isNotEmpty && !exata && _areas.isNotEmpty)
          _Dica(
            chave: 'area-nova',
            icone: Symbols.add_circle,
            cor: GJColors.textSecondary,
            texto: 'Área nova: "$texto". Ela passa a aparecer na lista depois de salvar.',
          ),
      ],
    );
  }
}

class _Dica extends StatelessWidget {
  const _Dica({required this.chave, required this.icone, required this.cor, required this.texto});

  final String chave;
  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key(chave),
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: GJSpace.s2),
          Expanded(child: Text(texto, style: GJTypography.caption(color: cor))),
        ],
      ),
    );
  }
}

/// Aviso depois de salvar pelo formulário: o curso sem oferta não aparece
/// em nenhum campus, então o aviso é de alerta e aponta o atalho da tabela.
void avisarCursoSalvo(ScaffoldMessengerState mensageiro, CursoAdmin curso, {required bool criado}) {
  if (curso.totalCampus == 0) {
    mensageiro.aviso(
      '${criado ? 'Curso criado' : 'Curso atualizado'} sem oferta: ele não aparece em nenhum campus. '
      'Use "Adicionar oferta" na tabela quando quiser incluir.',
      tipo: GJAvisoTipo.alerta,
    );
  } else {
    final ofertas = curso.totalCampus == 1 ? '1 oferta' : '${curso.totalCampus} ofertas';
    mensageiro.aviso('${criado ? 'Curso criado' : 'Curso atualizado'} com $ofertas.');
  }
}

/// Aviso da tabela de cursos para curso sem nenhuma oferta, com o atalho
/// para cadastrar a primeira.
class AvisoSemOferta extends StatelessWidget {
  const AvisoSemOferta({super.key, required this.onAdicionar});

  final VoidCallback? onAdicionar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Symbols.warning, size: 16, color: GJColors.warning),
            const SizedBox(width: GJSpace.s1),
            Expanded(
              child: Text('Sem oferta: não aparece em nenhum campus', style: GJTypography.caption(color: GJColors.warning)),
            ),
          ],
        ),
        if (onAdicionar != null)
          TextButton.icon(
            onPressed: onAdicionar,
            icon: const Icon(Symbols.add, size: 16),
            label: const Text('Adicionar oferta'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }
}

/// Uma oferta no formulário do curso: campus, turno e vagas. [original] é a
/// oferta já gravada (nula na oferta nova).
class _LinhaOferta {
  _LinhaOferta({this.original, int? campusId, String? turno, int? vagas})
      : campusId = campusId ?? original?.campusId,
        turno = turno ?? (turnosOferta.contains(original?.turno) ? original!.turno! : turnosOferta.first),
        vagas = TextEditingController(text: (vagas ?? original?.vagas)?.toString() ?? '');

  OfertaCurso? original;
  int? campusId;
  String turno;
  final TextEditingController vagas;
  String? erro;
  final chave = UniqueKey();

  int? get vagasNumero => vagas.text.trim().isEmpty ? null : int.tryParse(vagas.text.trim());
}

/// Criar ou editar curso, com a seção "Onde é oferecido" (campus, turno e
/// vagas de cada oferta). No novo, o administrador escolhe a universidade
/// (que não muda depois: as ofertas dependem dela); no painel da
/// universidade, [universidadeId] fixa a universidade.
///
/// Ao salvar, o curso é gravado primeiro e depois as ofertas, pelas rotas de
/// sempre. Se alguma oferta falhar, o curso fica salvo, o formulário passa a
/// editar esse curso e mostra o erro em cada oferta, sem perder o que foi
/// digitado. [novaOferta] já abre uma oferta em branco (atalho "Adicionar
/// oferta" da tabela).
class FormularioCurso extends StatefulWidget {
  const FormularioCurso({super.key, this.curso, this.universidadeId, this.novaOferta = false});

  final CursoAdmin? curso;
  final int? universidadeId;
  final bool novaOferta;

  @override
  State<FormularioCurso> createState() => _FormularioCursoState();
}

class _FormularioCursoState extends State<FormularioCurso> {
  late final _nome = TextEditingController(text: widget.curso?.nome);
  late final _area = TextEditingController(text: widget.curso?.areaCurso);
  late final _notaMec = TextEditingController(text: widget.curso?.notaMec);
  late final _duracao = TextEditingController(text: widget.curso?.duracaoSemestres?.toString());
  late final _descricao = TextEditingController(text: widget.curso?.descricao);
  late String? _grau = widget.curso?.grau;
  late String? _modalidade = widget.curso?.modalidade;
  late int? _universidadeId = widget.universidadeId ?? widget.curso?.universidadeId;

  /// Curso já gravado: o recebido para edição ou o criado neste formulário
  /// (depois de uma oferta falhar, salvar de novo edita em vez de criar).
  late CursoAdmin? _salvo = widget.curso;

  Future<List<UniversidadeAdminItem>>? _universidades;
  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  // Ofertas.
  List<CampusGestao>? _campi;
  bool _carregandoOfertas = false;
  String? _erroOfertas;
  final List<_LinhaOferta> _linhas = [];
  final List<OfertaCurso> _removidas = [];
  int _carga = 0;

  bool get _painelDaUniversidade => widget.universidadeId != null;

  @override
  void initState() {
    super.initState();
    if (widget.curso == null && widget.universidadeId == null) {
      _universidades = adminRepository.universidades(pageSize: 100).then((pagina) => pagina.resultado.data);
    }
    if (_universidadeId != null) _carregarOfertas();
  }

  @override
  void dispose() {
    for (final c in [_nome, _area, _notaMec, _duracao, _descricao]) {
      c.dispose();
    }
    for (final linha in _linhas) {
      linha.vagas.dispose();
    }
    super.dispose();
  }

  /// Campi da universidade e, na edição, as ofertas atuais do curso.
  Future<void> _carregarOfertas() async {
    final universidadeId = _universidadeId;
    if (universidadeId == null) return;
    final carga = ++_carga;
    setState(() {
      _carregandoOfertas = true;
      _erroOfertas = null;
    });
    try {
      final campi = await painelUniversidadeRepository.campus(universidadeId);
      var atuais = const <OfertaCurso>[];
      if (_salvo != null) {
        final cursos = await painelUniversidadeRepository.cursos(universidadeId);
        atuais = cursos.where((c) => c.id == _salvo!.id).firstOrNull?.ofertas ?? const [];
      }
      if (!mounted || carga != _carga) return;
      setState(() {
        _campi = campi;
        for (final linha in _linhas) {
          linha.vagas.dispose();
        }
        _linhas
          ..clear()
          ..addAll([for (final oferta in atuais) _LinhaOferta(original: oferta)]);
        _removidas.clear();
        if (widget.novaOferta && campi.length > _linhas.length) _linhas.add(_LinhaOferta());
      });
    } on ApiException catch (erro) {
      if (mounted && carga == _carga) setState(() => _erroOfertas = erro.message);
    } finally {
      if (mounted && carga == _carga) setState(() => _carregandoOfertas = false);
    }
  }

  void _adicionarOferta() => setState(() => _linhas.add(_LinhaOferta()));

  void _removerOferta(_LinhaOferta linha) {
    setState(() {
      _linhas.remove(linha);
      if (linha.original != null) _removidas.add(linha.original!);
    });
  }

  Map<String, String> _validar() {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Informe o nome do curso';
    if (_salvo == null && _universidadeId == null) erros['universidadeId'] = 'Escolha a universidade';
    final duracao = _duracao.text.trim();
    if (duracao.isNotEmpty) {
      final valor = int.tryParse(duracao);
      if (valor == null || valor < 1 || valor > 20) erros['duracaoSemestres'] = 'Use um número de 1 a 20';
    }
    return erros;
  }

  /// Confere cada oferta; devolve se todas estão prontas para enviar.
  bool _validarOfertas() {
    final usados = <int>{};
    var ok = true;
    for (final linha in _linhas) {
      linha.erro = null;
      final vagas = linha.vagas.text.trim();
      if (linha.campusId == null) {
        linha.erro = 'Escolha o campus';
      } else if (!usados.add(linha.campusId!)) {
        linha.erro = 'Este campus já está em outra oferta';
      } else if (vagas.isNotEmpty && (int.tryParse(vagas) == null || int.parse(vagas) < 0)) {
        linha.erro = 'Informe as vagas com um número';
      }
      if (linha.erro != null) ok = false;
    }
    return ok;
  }

  String _nomeDoCampus(int campusId) => _campi?.where((c) => c.id == campusId).firstOrNull?.nome ?? 'campus';

  /// Grava as ofertas que mudaram; devolve quantas falharam.
  Future<int> _salvarOfertas(int cursoId) async {
    var falhas = 0;
    for (final oferta in List.of(_removidas)) {
      try {
        await painelUniversidadeRepository.excluirOferta(cursoId, oferta.campusId);
        _removidas.remove(oferta);
      } on ApiException catch (erro) {
        falhas++;
        _erroGeral = 'Não foi possível remover a oferta em ${oferta.campusNome}: ${mensagemDaApi(erro)}';
      }
    }
    for (final linha in _linhas) {
      final original = linha.original;
      final vagas = linha.vagasNumero;
      try {
        if (original != null && original.campusId != linha.campusId) {
          // O campus da oferta não muda pela API: sai a antiga e entra a nova.
          await painelUniversidadeRepository.excluirOferta(cursoId, original.campusId);
          linha.original = null;
        }
        if (linha.original == null) {
          await painelUniversidadeRepository.criarOferta(cursoId, campusId: linha.campusId!, turno: linha.turno, vagas: vagas);
        } else if (original!.turno != linha.turno || original.vagas != vagas) {
          await painelUniversidadeRepository.atualizarOferta(cursoId, linha.campusId!, turno: linha.turno, vagas: vagas);
        }
        linha.original = OfertaCurso(
          cursoId: cursoId,
          campusId: linha.campusId!,
          campusNome: _nomeDoCampus(linha.campusId!),
          turno: linha.turno,
          vagas: vagas,
        );
      } on ApiException catch (erro) {
        falhas++;
        linha.erro = mensagemDaApi(erro);
      }
    }
    return falhas;
  }

  Future<void> _salvar() async {
    final erros = _validar();
    final ofertasOk = _validarOfertas();
    setState(() {
      _erros = erros;
      _erroGeral = ofertasOk ? null : 'Revise as ofertas indicadas.';
    });
    if (erros.isNotEmpty || !ofertasOk) return;

    final duracao = _duracao.text.trim();
    final dados = <String, dynamic>{
      'nome': _nome.text.trim(),
      'areaCurso': textoOuNulo(_area),
      'notaMec': textoOuNulo(_notaMec),
      'grau': _grau,
      'modalidade': _modalidade,
      'duracaoSemestres': duracao.isEmpty ? null : int.parse(duracao),
      'descricao': textoOuNulo(_descricao),
    };

    setState(() => _salvando = true);
    final CursoAdmin salvo;
    try {
      salvo = _salvo == null
          ? await cadastrosRepository.criarCurso(_universidadeId!, dados)
          : await cadastrosRepository.atualizarCurso(_salvo!.id, dados);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erros = errosPorCampo(erro);
        _erroGeral = mensagemDaApi(erro);
        _salvando = false;
      });
      return;
    }
    final criado = _salvo == null;
    _salvo = salvo;

    final falhas = await _salvarOfertas(salvo.id);
    if (!mounted) return;
    if (falhas == 0) {
      Navigator.of(context).pop(_comTotalDeOfertas(salvo));
      return;
    }
    setState(() {
      _salvando = false;
      _erroGeral = '${criado ? 'O curso foi criado' : 'O curso foi salvo'}, mas '
          '${falhas == 1 ? '1 oferta não foi salva' : '$falhas ofertas não foram salvas'}. '
          'Corrija o que está indicado e salve de novo, ou feche: o curso continua cadastrado.';
    });
  }

  /// O curso devolvido à tabela, com o total de ofertas gravadas (o aviso de
  /// "curso sem oferta" depende dele).
  CursoAdmin _comTotalDeOfertas(CursoAdmin curso) => CursoAdmin(
        id: curso.id,
        nome: curso.nome,
        universidadeId: curso.universidadeId,
        universidadeNome: curso.universidadeNome,
        totalCampus: _campi == null ? curso.totalCampus : _linhas.length,
        areaCurso: curso.areaCurso,
        notaMec: curso.notaMec,
        modalidade: curso.modalidade,
        grau: curso.grau,
        duracaoSemestres: curso.duracaoSemestres,
        descricao: curso.descricao,
      );

  Widget _seletorUniversidade() {
    return FutureBuilder<List<UniversidadeAdminItem>>(
      future: _universidades,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text('Não foi possível carregar as universidades.', style: GJTypography.bodySm()),
          );
        }
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.only(bottom: GJSpace.s4), child: GJSkeleton(height: 48));
        return CampoSelecao<int>(
          key: const Key('curso-universidade'),
          rotulo: 'Universidade',
          valor: _universidadeId,
          erro: _erros['universidadeId'],
          opcoes: {
            for (final u in snapshot.data!) u.id: '${u.nomeFantasia} (${rotuloStatusUniversidade(u.status)})',
          },
          onChanged: _salvo != null
              ? (_) {}
              : (valor) {
                  setState(() => _universidadeId = valor);
                  _carregarOfertas();
                },
        );
      },
    );
  }

  Widget _semCampus() {
    final universidadeId = _universidadeId;
    return Container(
      key: const Key('ofertas-sem-campus'),
      padding: const EdgeInsets.all(GJSpace.s4),
      decoration: BoxDecoration(color: GJColors.warningContainer, borderRadius: GJRadius.borderMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _painelDaUniversidade
                ? 'A universidade ainda não tem campus cadastrado. Cadastre um campus para informar onde o curso é oferecido; '
                    'o curso pode ser salvo agora e as ofertas, incluídas depois.'
                : 'Esta universidade ainda não tem campus cadastrado. O campus é cadastrado pela própria universidade, '
                    'no painel dela; o curso pode ser salvo agora e as ofertas, incluídas depois.',
            style: GJTypography.bodySm(color: GJColors.textPrimary),
          ),
          const SizedBox(height: GJSpace.s3),
          GJButton(
            label: _painelDaUniversidade ? 'Cadastrar campus' : 'Ver cadastro da universidade',
            icon: Symbols.arrow_forward,
            variant: GJButtonVariant.secondary,
            size: GJButtonSize.sm,
            onPressed: () {
              final destino = _painelDaUniversidade ? '/painel-universidade/campus' : '/admin/universidades/$universidadeId';
              final rotas = GoRouter.of(context);
              Navigator.of(context).pop();
              rotas.go(destino);
            },
          ),
        ],
      ),
    );
  }

  Widget _linhaOferta(int indice, _LinhaOferta linha) {
    final outros = {for (final l in _linhas) if (!identical(l, linha) && l.campusId != null) l.campusId!};
    final campi = [for (final c in _campi!) if (!outros.contains(c.id) || c.id == linha.campusId) c];
    return Container(
      key: linha.chave,
      margin: const EdgeInsets.only(bottom: GJSpace.s3),
      padding: const EdgeInsets.fromLTRB(GJSpace.s4, GJSpace.s3, GJSpace.s2, 0),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderMd,
        border: Border.all(color: linha.erro != null ? GJColors.error : GJColors.surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Oferta ${indice + 1}', style: GJTypography.label(color: GJColors.textPrimary))),
              IconButton(
                key: Key('remover-oferta-$indice'),
                tooltip: 'Remover oferta',
                icon: const Icon(Symbols.delete, size: 20),
                onPressed: _salvando ? null : () => _removerOferta(linha),
              ),
            ],
          ),
          CampoSelecao<int>(
            key: Key('oferta-campus-$indice'),
            rotulo: 'Campus',
            valor: linha.campusId,
            opcoes: {for (final c in campi) c.id: c.nome},
            onChanged: (valor) => setState(() => linha.campusId = valor),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CampoSelecao<String>(
                  key: Key('oferta-turno-$indice'),
                  rotulo: 'Turno',
                  valor: linha.turno,
                  opcoes: {for (final t in turnosOferta) t: t},
                  onChanged: (valor) => setState(() => linha.turno = valor ?? linha.turno),
                ),
              ),
              const SizedBox(width: GJSpace.s3),
              Expanded(
                child: CampoTexto(
                  key: Key('oferta-vagas-$indice'),
                  rotulo: 'Vagas',
                  controller: linha.vagas,
                  keyboardType: TextInputType.number,
                  dica: 'Opcional',
                ),
              ),
            ],
          ),
          if (linha.erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s3),
              child: Text(linha.erro!, key: Key('erro-oferta-$indice'), style: GJTypography.caption(color: GJColors.error)),
            ),
        ],
      ),
    );
  }

  Widget _secaoOfertas() {
    final Widget conteudo;
    if (_universidadeId == null) {
      conteudo = Text('Escolha a universidade para informar os campi onde o curso é oferecido.', style: GJTypography.bodySm());
    } else if (_carregandoOfertas && _campi == null) {
      conteudo = const GJSkeleton(height: GJSpace.s16);
    } else if (_erroOfertas != null) {
      conteudo = Row(
        children: [
          Expanded(child: Text('Não foi possível carregar os campi: $_erroOfertas', style: GJTypography.bodySm())),
          TextButton(onPressed: _carregarOfertas, child: const Text('Tentar novamente')),
        ],
      );
    } else if (_campi!.isEmpty) {
      conteudo = _semCampus();
    } else {
      conteudo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_linhas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s3),
              child: Text(
                'Nenhuma oferta: sem ela o curso não aparece em nenhum campus.',
                key: const Key('ofertas-vazias'),
                style: GJTypography.bodySm(),
              ),
            ),
          for (var i = 0; i < _linhas.length; i++) _linhaOferta(i, _linhas[i]),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('adicionar-oferta'),
              onPressed: _salvando || _linhas.length >= _campi!.length ? null : _adicionarOferta,
              icon: const Icon(Symbols.add, size: 18),
              label: Text(_linhas.isEmpty ? 'Adicionar oferta' : 'Adicionar outra oferta'),
            ),
          ),
          if (_linhas.length >= _campi!.length && _campi!.isNotEmpty)
            Text('O curso já está em todos os campi da universidade.', style: GJTypography.caption()),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: Column(
        key: const Key('secao-ofertas'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: GJSpace.s8),
          Text('Onde é oferecido', style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s1),
          Text('Opcional. Informe o campus, o turno e as vagas de cada oferta.', style: GJTypography.caption()),
          const SizedBox(height: GJSpace.s3),
          conteudo,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curso = _salvo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.curso == null && widget.universidadeId == null)
          _seletorUniversidade()
        else if (curso != null && widget.universidadeId == null)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text('Universidade: ${curso.universidadeNome}', style: GJTypography.bodySm()),
          ),
        CampoNomeCurso(controller: _nome, erro: _erros['nome']),
        CampoAreaCurso(controller: _area, erro: _erros['areaCurso']),
        CampoSelecao<String>(
          key: const Key('curso-grau'),
          rotulo: 'Grau',
          valor: grausCurso.contains(_grau) || _grau == null ? _grau : null,
          opcoes: {null: 'Não informado', for (final g in grausCurso) g: g},
          onChanged: (valor) => setState(() => _grau = valor),
        ),
        CampoSelecao<String>(
          key: const Key('curso-modalidade'),
          rotulo: 'Modalidade',
          valor: modalidadesCurso.contains(_modalidade) || _modalidade == null ? _modalidade : null,
          opcoes: {null: 'Não informada', for (final m in modalidadesCurso) m: m},
          onChanged: (valor) => setState(() => _modalidade = valor),
        ),
        CampoTexto(
          rotulo: 'Duração (semestres)',
          controller: _duracao,
          erro: _erros['duracaoSemestres'],
          keyboardType: TextInputType.number,
        ),
        CampoTexto(rotulo: 'Nota do MEC', controller: _notaMec, erro: _erros['notaMec'], maxLength: 100),
        CampoTextoLongo(rotulo: 'Descrição', controller: _descricao, erro: _erros['descricao']),
        _secaoOfertas(),
        RodapeFormulario(salvando: _salvando, onSalvar: _salvar, erro: _erroGeral),
      ],
    );
  }
}
