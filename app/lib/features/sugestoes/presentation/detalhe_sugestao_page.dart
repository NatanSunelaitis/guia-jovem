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
import '../../auth/data/session_controller.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../data/sugestoes_repository.dart';
import '../domain/sugestao.dart';
import 'widgets/sugestao_card.dart';
import '../../../shared/widgets/gj_aviso.dart';

/// `/sugestoes/:id`: detalhe da sugestão para o autor e para o destinatário
/// (aberto pela notificação, RF14). O destinatário avalia aqui enquanto ela
/// está em análise (RF15): aprovar ou reprovar, sempre com resposta.
class DetalheSugestaoPage extends StatefulWidget {
  const DetalheSugestaoPage({super.key, required this.id});

  final int id;

  @override
  State<DetalheSugestaoPage> createState() => _DetalheSugestaoPageState();
}

class _DetalheSugestaoPageState extends State<DetalheSugestaoPage> {
  late Future<Sugestao> _future = sugestoesRepository.detalhe(widget.id);

  bool get _ehAluno => sessionController.usuario?.tipoUsuario == TipoUsuario.aluno;

  void _recarregar() {
    setState(() {
      _future = sugestoesRepository.detalhe(widget.id);
    });
  }

  void _aoAvaliar(Sugestao avaliada) {
    setState(() {
      _future = Future.value(avaliada);
    });
  }

  Widget _voltar() {
    return TextButton.icon(
      onPressed: () => context.go(_ehAluno ? '/perfil?aba=sugestoes' : '/sugestoes-recebidas'),
      icon: const Icon(Symbols.arrow_back, size: 18),
      label: Text(_ehAluno ? 'Voltar para o perfil' : 'Voltar para sugestões recebidas'),
    );
  }

  Widget _conteudo(Sugestao sugestao) {
    final recebida = sugestao.autorNome != null || !_ehAluno;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: GJSpace.s3,
          runSpacing: GJSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(sugestao.titulo, style: GJTypography.h2()),
            SugestaoStatusBadge(status: sugestao.status),
          ],
        ),
        const SizedBox(height: GJSpace.s2),
        Text(
          [
            'Enviada em ${formatarData(sugestao.criadoEm)}',
            if (recebida) 'De: ${sugestao.autorNome ?? 'Usuário removido'}',
            'Para: ${sugestao.destino}',
          ].join(' · '),
          style: GJTypography.caption(),
        ),
        const SizedBox(height: GJSpace.s6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GJSpace.s6),
          decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg),
          child: SelectableText(sugestao.texto, style: GJTypography.body()),
        ),
        const SizedBox(height: GJSpace.s6),
        if (sugestao.resposta != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GJSpace.s6),
            decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resposta', style: GJTypography.h4()),
                const SizedBox(height: GJSpace.s2),
                SelectableText(sugestao.resposta!, style: GJTypography.body()),
                if (sugestao.avaliadoEm != null) ...[
                  const SizedBox(height: GJSpace.s2),
                  Text('Respondida em ${formatarData(sugestao.avaliadoEm!)}', style: GJTypography.caption()),
                ],
              ],
            ),
          )
        else if (sugestao.podeAvaliar)
          AvaliarSugestaoForm(sugestao: sugestao, onAvaliada: _aoAvaliar)
        else
          Row(
            children: [
              const Icon(Symbols.hourglass_top, color: GJColors.textDisabled),
              const SizedBox(width: GJSpace.s3),
              Expanded(
                child: Text(
                  'Ainda em análise. Você recebe uma notificação quando houver resposta.',
                  style: GJTypography.body().copyWith(color: GJColors.textSecondary),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _voltar(),
                const SizedBox(height: GJSpace.s4),
                FutureBuilder<Sugestao>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Column(
                        children: [
                          GJSkeleton(height: GJSpace.s12),
                          SizedBox(height: GJSpace.s4),
                          GJSkeleton(height: GJSpace.s24 * 2),
                        ],
                      );
                    }
                    if (snapshot.hasError) {
                      final erro = snapshot.error;
                      if (erro is ApiException && (erro.code == 'FORBIDDEN' || erro.code == 'NOT_FOUND')) {
                        return const GJEmptyState(
                          titulo: 'Sugestão indisponível',
                          texto: 'Ela não existe ou não foi enviada por você nem para você.',
                          icone: Symbols.lock,
                        );
                      }
                      return GJEmptyState(
                        titulo: 'Não foi possível carregar',
                        texto: erro is ApiException ? erro.message : 'Tente novamente.',
                        icone: Symbols.wifi_off,
                        acaoLabel: 'Tentar novamente',
                        onAcao: _recarregar,
                      );
                    }
                    return _conteudo(snapshot.data!);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formulário de avaliação (RF15): escolha Aprovar ou Reprovar e a resposta.
class AvaliarSugestaoForm extends StatefulWidget {
  const AvaliarSugestaoForm({super.key, required this.sugestao, required this.onAvaliada});

  final Sugestao sugestao;
  final ValueChanged<Sugestao> onAvaliada;

  @override
  State<AvaliarSugestaoForm> createState() => _AvaliarSugestaoFormState();
}

class _AvaliarSugestaoFormState extends State<AvaliarSugestaoForm> {
  final _respostaController = TextEditingController();
  StatusSugestao? _decisao;
  bool _enviando = false;
  String? _erroResposta;
  String? _erroGeral;

  @override
  void dispose() {
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final resposta = _respostaController.text.trim();
    if (resposta.isEmpty) {
      setState(() => _erroResposta = 'Escreva a resposta para o autor');
      return;
    }

    setState(() {
      _enviando = true;
      _erroResposta = null;
      _erroGeral = null;
    });

    final mensageiro = ScaffoldMessenger.of(context);
    try {
      final avaliada = await sugestoesRepository.avaliar(widget.sugestao.id, status: _decisao!, resposta: resposta);
      mensageiro.aviso('Avaliação enviada. O autor foi notificado.');
      widget.onAvaliada(avaliada);
    } on ApiException catch (erro) {
      if (!mounted) return;
      if (erro.code == 'SUGESTAO_JA_AVALIADA') {
        // Outra pessoa avaliou antes: mostra a avaliação que valeu.
        mensageiro.aviso(erro.message, tipo: GJAvisoTipo.erro);
        try {
          widget.onAvaliada(await sugestoesRepository.detalhe(widget.sugestao.id));
          return;
        } on ApiException {
          // Fica no formulário com a mensagem abaixo.
        }
      }
      if (mounted) {
        setState(() {
          _erroGeral = erro.message;
          _enviando = false;
        });
      }
    }
  }

  Widget _opcao(StatusSugestao status, String rotulo, IconData icone, Color cor) {
    final selecionada = _decisao == status;
    return ChoiceChip(
      selected: selecionada,
      onSelected: _enviando ? null : (_) => setState(() => _decisao = status),
      avatar: Icon(icone, size: 18, color: selecionada ? Colors.white : cor),
      label: Text(rotulo),
      labelStyle: GJTypography.label(color: selecionada ? Colors.white : GJColors.textPrimary),
      selectedColor: cor,
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderLg,
        border: Border.all(color: GJColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avaliar sugestão', style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s1),
          Text('O autor recebe uma notificação com o resultado e a resposta.', style: GJTypography.bodySm()),
          const SizedBox(height: GJSpace.s4),
          Wrap(
            spacing: GJSpace.s3,
            runSpacing: GJSpace.s2,
            children: [
              _opcao(StatusSugestao.aprovada, 'Aprovar', Symbols.check_circle, GJColors.success),
              _opcao(StatusSugestao.reprovada, 'Reprovar', Symbols.cancel, GJColors.error),
            ],
          ),
          const SizedBox(height: GJSpace.s4),
          TextField(
            key: const Key('resposta-sugestao'),
            controller: _respostaController,
            style: GJTypography.body(),
            enabled: !_enviando,
            maxLength: 2000,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              filled: true,
              fillColor: GJColors.surfaceLow,
              border: OutlineInputBorder(borderRadius: GJRadius.borderMd, borderSide: BorderSide.none),
              hintText: 'Resposta para o autor',
              hintStyle: GJTypography.body().copyWith(color: GJColors.textDisabled),
              errorText: _erroResposta,
            ),
          ),
          if (_erroGeral != null) ...[
            const SizedBox(height: GJSpace.s2),
            Text(_erroGeral!, style: GJTypography.label(color: GJColors.error)),
          ],
          const SizedBox(height: GJSpace.s4),
          Align(
            alignment: Alignment.centerRight,
            child: GJButton(
              label: 'Enviar avaliação',
              loading: _enviando,
              onPressed: _decisao == null || _enviando ? null : _enviar,
            ),
          ),
        ],
      ),
    );
  }
}
