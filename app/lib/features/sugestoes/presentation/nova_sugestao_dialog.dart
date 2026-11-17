import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../universidades/data/universidades_repository.dart';
import '../../universidades/domain/universidade.dart';
import '../data/sugestoes_repository.dart';
import '../domain/sugestao.dart';

/// T20 Nova sugestão (RF08): título, texto e, opcionalmente, a universidade
/// de destino, buscada pelo nome. Sem universidade, vai para a equipe Guia
/// Jovem. Retorna a sugestão enviada, ou null se o aluno fechou o diálogo.
Future<Sugestao?> mostrarDialogoNovaSugestao(BuildContext context) {
  return showDialog<Sugestao>(context: context, builder: (context) => const _NovaSugestaoDialog());
}

/// Espera o aluno parar de digitar antes de pesquisar a universidade.
const atrasoBuscaUniversidade = Duration(milliseconds: 400);

class _NovaSugestaoDialog extends StatefulWidget {
  const _NovaSugestaoDialog();

  @override
  State<_NovaSugestaoDialog> createState() => _NovaSugestaoDialogState();
}

class _NovaSugestaoDialogState extends State<_NovaSugestaoDialog> {
  final _tituloController = TextEditingController();
  final _textoController = TextEditingController();
  final _buscaController = TextEditingController();

  Timer? _atrasoBusca;
  int _buscaAtual = 0;
  bool _buscando = false;
  List<UniversidadeResumo> _resultados = const [];
  UniversidadeResumo? _universidade;

  bool _enviando = false;
  Map<String, String> _errosCampo = const {};
  String? _erroGeral;

  @override
  void dispose() {
    _atrasoBusca?.cancel();
    _tituloController.dispose();
    _textoController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  void _aoDigitarBusca(String termo) {
    _atrasoBusca?.cancel();
    final limpo = termo.trim();
    if (limpo.length < 2) {
      setState(() {
        _resultados = const [];
        _buscando = false;
      });
      return;
    }
    _atrasoBusca = Timer(atrasoBuscaUniversidade, () => _buscar(limpo));
  }

  Future<void> _buscar(String termo) async {
    final busca = ++_buscaAtual;
    setState(() => _buscando = true);
    try {
      final pagina = await universidadesRepository.listar(FiltrosUniversidades(q: termo));
      if (!mounted || busca != _buscaAtual) return;
      setState(() => _resultados = pagina.data.take(5).toList());
    } on ApiException {
      if (mounted && busca == _buscaAtual) setState(() => _resultados = const []);
    } finally {
      if (mounted && busca == _buscaAtual) setState(() => _buscando = false);
    }
  }

  void _escolher(UniversidadeResumo universidade) {
    _atrasoBusca?.cancel();
    _buscaAtual++;
    _buscaController.clear();
    setState(() {
      _universidade = universidade;
      _resultados = const [];
      _buscando = false;
    });
  }

  Future<void> _enviar() async {
    final titulo = _tituloController.text.trim();
    final texto = _textoController.text.trim();
    final erros = {
      if (titulo.length < 3) 'titulo': 'Dê um título com pelo menos 3 caracteres',
      if (texto.length < 10) 'texto': 'Escreva a sugestão com pelo menos 10 caracteres',
    };
    if (erros.isNotEmpty) {
      setState(() {
        _errosCampo = erros;
        _erroGeral = null;
      });
      return;
    }

    setState(() {
      _enviando = true;
      _errosCampo = const {};
      _erroGeral = null;
    });

    try {
      final sugestao = await sugestoesRepository.enviar(
        titulo: titulo,
        texto: texto,
        universidadeId: _universidade?.id,
      );
      if (mounted) Navigator.of(context).pop(sugestao);
    } on ApiException catch (erro) {
      if (!mounted) return;
      final porCampo = <String, String>{
        for (final detalhe in erro.details.whereType<Map<String, dynamic>>())
          if (detalhe['campo'] is String) detalhe['campo'] as String: detalhe['mensagem'] as String? ?? erro.message,
      };
      setState(() {
        _errosCampo = porCampo;
        _erroGeral = porCampo.isEmpty || porCampo.containsKey('universidadeId') ? erro.message : null;
        _enviando = false;
      });
    }
  }

  Widget _destino() {
    final universidade = _universidade;
    if (universidade != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: GJSpace.s4, vertical: GJSpace.s3),
        decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderMd),
        child: Row(
          children: [
            const Icon(Symbols.account_balance, color: GJColors.primary),
            const SizedBox(width: GJSpace.s3),
            Expanded(child: Text('Para: ${universidade.nomeFantasia}', style: GJTypography.body())),
            IconButton(
              tooltip: 'Enviar para a equipe Guia Jovem',
              onPressed: _enviando ? null : () => setState(() => _universidade = null),
              icon: const Icon(Symbols.close),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GJInput(
          label: 'Universidade (opcional)',
          hint: 'Busque pelo nome',
          icon: Symbols.search,
          controller: _buscaController,
          enabled: !_enviando,
          helperText: 'Sem universidade, a sugestão vai para a equipe Guia Jovem.',
          onChanged: _aoDigitarBusca,
        ),
        if (_buscando)
          const Padding(
            padding: EdgeInsets.only(top: GJSpace.s2),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!_buscando && _buscaController.text.trim().length >= 2 && _resultados.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: GJSpace.s2),
            child: Text('Nenhuma universidade encontrada.', style: GJTypography.caption()),
          ),
        for (final resultado in _resultados)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: GJSpace.s2),
            leading: const Icon(Symbols.account_balance, size: 20),
            title: Text(resultado.nomeFantasia, style: GJTypography.bodySm(color: GJColors.textPrimary)),
            subtitle: resultado.cidade == null
                ? null
                : Text('${resultado.cidade}/${resultado.estado ?? ''}', style: GJTypography.caption()),
            onTap: () => _escolher(resultado),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      insetPadding: const EdgeInsets.all(GJSpace.s4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GJSpace.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Nova sugestão', style: GJTypography.h4())),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close),
                  ),
                ],
              ),
              const SizedBox(height: GJSpace.s2),
              Text(
                'Conte o que podemos melhorar. Você acompanha a resposta no seu perfil.',
                style: GJTypography.bodySm(),
              ),
              const SizedBox(height: GJSpace.s6),
              GJInput(
                label: 'Título',
                controller: _tituloController,
                maxLength: 100,
                enabled: !_enviando,
                errorText: _errosCampo['titulo'],
              ),
              const SizedBox(height: GJSpace.s4),
              Text('Sugestão', style: GJTypography.label()),
              const SizedBox(height: GJSpace.s2),
              TextField(
                key: const Key('texto-sugestao'),
                controller: _textoController,
                enabled: !_enviando,
                maxLength: 2000,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: GJColors.surfaceLow,
                  border: OutlineInputBorder(borderRadius: GJRadius.borderMd, borderSide: BorderSide.none),
                  hintText: 'Descreva sua ideia ou o problema encontrado',
                  errorText: _errosCampo['texto'],
                ),
              ),
              const SizedBox(height: GJSpace.s4),
              _destino(),
              if (_erroGeral != null) ...[
                const SizedBox(height: GJSpace.s3),
                Text(_erroGeral!, style: GJTypography.label(color: GJColors.error)),
              ],
              const SizedBox(height: GJSpace.s6),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: GJSpace.s3,
                runSpacing: GJSpace.s2,
                children: [
                  GJButton(
                    label: 'Cancelar',
                    variant: GJButtonVariant.ghost,
                    onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                  ),
                  GJButton(label: 'Enviar sugestão', loading: _enviando, onPressed: _enviando ? null : _enviar),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
