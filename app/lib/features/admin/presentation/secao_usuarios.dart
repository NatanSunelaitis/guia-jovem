import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/utils/formatar_data.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_status_badge.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../../auth/data/session_controller.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../data/admin_repository.dart';
import '../domain/usuario_admin.dart';
import 'widgets/confirmacao_dialogs.dart';

/// T24.2 Usuários (RF09, Quadro 14): busca, filtros por perfil e situação,
/// e ativar ou inativar contas. A única conta de administrador ativa não
/// pode ser inativada: a API responde 409 e o painel explica o bloqueio.
class SecaoUsuarios extends StatefulWidget {
  const SecaoUsuarios({super.key});

  @override
  State<SecaoUsuarios> createState() => _SecaoUsuariosState();
}

class _SecaoUsuariosState extends State<SecaoUsuarios> {
  String _busca = '';
  TipoUsuario? _tipo;
  bool? _ativo;
  int _pagina = 1;
  Timer? _atrasoBusca;

  List<UsuarioAdmin> _itens = const [];
  int _totalPaginas = 1;
  bool _carregando = true;
  ApiException? _erro;
  final Set<int> _alterando = {};
  int _requisicao = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _atrasoBusca?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final requisicao = ++_requisicao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultado = await adminRepository.usuarios(busca: _busca, tipo: _tipo, ativo: _ativo, page: _pagina);
      if (!mounted || requisicao != _requisicao) return;
      setState(() {
        _itens = resultado.data;
        _totalPaginas = resultado.totalPages;
      });
    } on ApiException catch (erro) {
      if (mounted && requisicao == _requisicao) setState(() => _erro = erro);
    } finally {
      if (mounted && requisicao == _requisicao) setState(() => _carregando = false);
    }
  }

  void _buscar(String texto) {
    _atrasoBusca?.cancel();
    _atrasoBusca = Timer(const Duration(milliseconds: 400), () {
      _busca = texto.trim();
      _pagina = 1;
      _carregar();
    });
  }

  void _filtrar(VoidCallback mudar) {
    setState(() {
      mudar();
      _pagina = 1;
    });
    _carregar();
  }

  Future<void> _alterarSituacao(UsuarioAdmin usuario) async {
    final ativar = !usuario.ativo;
    final confirmou = await confirmarAcao(
      context,
      titulo: ativar ? 'Ativar conta' : 'Inativar conta',
      texto: ativar
          ? '${usuario.nome} volta a poder entrar no Guia Jovem.'
          : '${usuario.nome} não consegue mais entrar no Guia Jovem até a conta ser ativada de novo.',
      rotuloConfirmar: ativar ? 'Ativar' : 'Inativar',
      destrutiva: !ativar,
    );
    if (!confirmou) return;
    if (!mounted) return;

    final mensageiro = ScaffoldMessenger.of(context);
    setState(() => _alterando.add(usuario.id));
    try {
      final atualizado = await adminRepository.alterarSituacao(usuario.id, ativo: ativar);
      if (!mounted) return;
      setState(() => _itens = [for (final item in _itens) item.id == atualizado.id ? atualizado : item]);
      mensageiro.showSnackBar(SnackBar(content: Text(ativar ? 'Conta ativada.' : 'Conta inativada.')));
    } on ApiException catch (erro) {
      if (!mounted) return;
      // Libera o botão antes do aviso: o diálogo fica aberto até o "Entendi".
      setState(() => _alterando.remove(usuario.id));
      if (erro.code == 'ULTIMO_ADMINISTRADOR') {
        await mostrarAcaoBloqueada(context, erro.message);
      } else {
        mensageiro.showSnackBar(SnackBar(content: Text(erro.message)));
      }
    } finally {
      if (mounted) setState(() => _alterando.remove(usuario.id));
    }
  }

  Widget _acao(UsuarioAdmin usuario) {
    // A própria conta sai pelo menu do avatar (Excluir Conta), não por aqui:
    // inativar a si mesmo derrubaria a sessão no meio do uso.
    if (usuario.id == sessionController.usuario?.id) {
      return Text('Sua conta', style: GJTypography.bodySm());
    }
    return GJButton(
      label: usuario.ativo ? 'Inativar' : 'Ativar',
      size: GJButtonSize.sm,
      variant: usuario.ativo ? GJButtonVariant.secondary : GJButtonVariant.primary,
      loading: _alterando.contains(usuario.id),
      onPressed: _alterando.contains(usuario.id) ? null : () => _alterarSituacao(usuario),
    );
  }

  Widget _filtros() {
    return Wrap(
      spacing: GJSpace.s4,
      runSpacing: GJSpace.s3,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<TipoUsuario?>(
            key: const Key('filtro-perfil'),
            isExpanded: true,
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Perfil', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos os perfis')),
              for (final tipo in TipoUsuario.values)
                DropdownMenuItem(value: tipo, child: Text(rotuloTipoUsuario(tipo))),
            ],
            onChanged: (valor) => _filtrar(() => _tipo = valor),
          ),
        ),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<bool?>(
            key: const Key('filtro-situacao'),
            isExpanded: true,
            value: _ativo,
            decoration: const InputDecoration(labelText: 'Situação', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas as situações')),
              DropdownMenuItem(value: true, child: Text('Ativos')),
              DropdownMenuItem(value: false, child: Text('Inativos')),
            ],
            onChanged: (valor) => _filtrar(() => _ativo = valor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final semFiltros = _busca.isEmpty && _tipo == null && _ativo == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Usuários', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        _filtros(),
        const SizedBox(height: GJSpace.s4),
        if (_erro != null)
          GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: _erro!.message,
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: _carregar,
          )
        else
          GJDataTable(
            buscaHint: 'Buscar por nome ou e-mail',
            onBuscaChanged: _buscar,
            colunas: const [
              GJDataColumn('Nome', flex: 3),
              GJDataColumn('E-mail', flex: 4),
              GJDataColumn('Perfil', flex: 2),
              GJDataColumn('Situação', flex: 2),
              GJDataColumn('Criado em', flex: 2),
              GJDataColumn('Ações', flex: 2),
            ],
            linhas: _carregando && _itens.isEmpty
                ? [
                    for (var i = 0; i < 3; i++)
                      [for (var c = 0; c < 6; c++) const GJSkeleton(height: GJSpace.s4)],
                  ]
                : [
                    for (final usuario in _itens)
                      [
                        Text(usuario.nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
                        Text(usuario.email, style: GJTypography.bodySm(), overflow: TextOverflow.ellipsis),
                        encolherSePreciso(GJTag(label: rotuloTipoUsuario(usuario.tipoUsuario))),
                        encolherSePreciso(
                          GJStatusBadge(
                            label: usuario.ativo ? 'Ativo' : 'Inativo',
                            tone: usuario.ativo ? GJStatusTone.success : GJStatusTone.neutral,
                          ),
                        ),
                        Text(formatarData(usuario.criadoEm), style: GJTypography.bodySm()),
                        encolherSePreciso(_acao(usuario)),
                      ],
                  ],
            vazio: GJEmptyState(
              titulo: 'Nenhum usuário encontrado',
              texto: semFiltros ? null : 'Revise o termo pesquisado ou limpe os filtros.',
              icone: Symbols.person_search,
            ),
            paginaAtual: _pagina,
            totalPaginas: _totalPaginas,
            onPaginaChanged: (pagina) {
              setState(() => _pagina = pagina);
              _carregar();
            },
          ),
      ],
    );
  }
}
