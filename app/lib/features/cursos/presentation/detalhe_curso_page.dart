import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/fotos.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_remote_or_asset_image.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../data/cursos_repository.dart';
import '../domain/curso.dart';

/// T06: aceita `id` (detalhe de uma oferta específica) ou `nome` ("em quais
/// universidades este curso está disponível", Figura 15).
class DetalheCursoPage extends StatefulWidget {
  const DetalheCursoPage.porId({super.key, required this.id}) : nome = null;

  const DetalheCursoPage.porNome({super.key, required this.nome}) : id = null;

  final int? id;
  final String? nome;

  @override
  State<DetalheCursoPage> createState() => _DetalheCursoPageState();
}

class _DetalheCursoPageState extends State<DetalheCursoPage> {
  late Future<CursoDetalhe>? _futurePorId;
  late Future<CursoPorNome>? _futurePorNome;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    if (widget.id != null) {
      _futurePorId = cursosRepository.detalhe(widget.id!);
      _futurePorNome = null;
    } else {
      _futurePorNome = cursosRepository.porNome(widget.nome!);
      _futurePorId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: widget.id != null ? _construirPorId() : _construirPorNome(),
    );
  }

  Widget _construirPorId() {
    return FutureBuilder<CursoDetalhe>(
      future: _futurePorId,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(GJSpace.s16), child: GJSkeletonCard());
        }
        if (snapshot.hasError) {
          return GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: () => setState(_carregar),
          );
        }

        final curso = snapshot.data!;
        final isMobile = MediaQuery.sizeOf(context).width < 600;

        return GJPageContainer(
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CabecalhoCurso(
                imagem: fotoCurso(nome: curso.nome, areaCurso: curso.areaCurso),
                children: [
              Text(curso.nome, style: GJTypography.display(size: isMobile ? 32 : 44)),
              const SizedBox(height: GJSpace.s2),
              Wrap(
                spacing: GJSpace.s4,
                children: [
                  if (curso.areaCurso != null) Text('Área: ${curso.areaCurso}', style: GJTypography.body()),
                  if (curso.grau != null) Text('Grau: ${curso.grau}', style: GJTypography.body()),
                  if (curso.modalidade != null) Text('Modalidade: ${curso.modalidade}', style: GJTypography.body()),
                  if (curso.duracaoSemestres != null)
                    Text('${curso.duracaoSemestres} semestres', style: GJTypography.body()),
                ],
              ),
              if (curso.descricao != null) ...[
                const SizedBox(height: GJSpace.s4),
                Text(curso.descricao!, style: GJTypography.body()),
              ],
                ],
              ),
              const SizedBox(height: GJSpace.s8),
              Text('Universidades que oferecem este curso', style: GJTypography.h2()),
              const SizedBox(height: GJSpace.s4),
              GJCard(
                onTap: () => context.go('/universidades/${curso.universidade.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(curso.universidade.nomeFantasia, style: GJTypography.h4()),
                          const SizedBox(height: GJSpace.s1),
                          for (final campus in curso.campus)
                            Text(
                              '${campus.nome} · ${campus.cidade}/${campus.estado}'
                              '${campus.turno != null ? ' · ${campus.turno}' : ''}',
                              style: GJTypography.bodySm(),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Symbols.chevron_right),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _construirPorNome() {
    return FutureBuilder<CursoPorNome>(
      future: _futurePorNome,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(GJSpace.s16), child: GJSkeletonCard());
        }
        if (snapshot.hasError) {
          return GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: () => setState(_carregar),
          );
        }

        final resultado = snapshot.data!;

        return GJPageContainer(
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CabecalhoCurso(
                imagem: fotoCurso(nome: resultado.nome, areaCurso: resultado.areaCurso),
                children: [
              Text(resultado.nome, style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s2),
              Text(
                'Em quais universidades este curso está disponível',
                style: GJTypography.body().copyWith(color: GJColors.textSecondary),
              ),
                ],
              ),
              const SizedBox(height: GJSpace.s6),
              if (resultado.universidades.isEmpty)
                const GJEmptyState(titulo: 'Nenhuma universidade oferece este curso no momento')
              else
                for (final item in resultado.universidades)
                  Padding(
                    padding: const EdgeInsets.only(bottom: GJSpace.s3),
                    child: GJCard(
                      onTap: () => context.go('/universidades/${item.universidade.id}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.universidade.nomeFantasia, style: GJTypography.h4()),
                                for (final campus in item.campus)
                                  Text('${campus.nome} · ${campus.cidade}/${campus.estado}', style: GJTypography.bodySm()),
                              ],
                            ),
                          ),
                          const Icon(Symbols.chevron_right),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
          ),
        );
      },
    );
  }
}

/// Cabeçalho do T06: texto à esquerda e a foto do curso (ou da área) à
/// direita, no mesmo arranjo do cabeçalho de programa. No celular, a foto
/// vem antes do texto.
class _CabecalhoCurso extends StatelessWidget {
  const _CabecalhoCurso({required this.imagem, required this.children});

  final String imagem;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    final foto = ClipRRect(
      borderRadius: GJRadius.borderXl,
      child: AspectRatio(aspectRatio: 16 / 10, child: GJRemoteOrAssetImage(url: imagem)),
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [foto, const SizedBox(height: GJSpace.s6), texto]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: texto),
        const SizedBox(width: GJSpace.s8),
        Expanded(flex: 2, child: foto),
      ],
    );
  }
}
