import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import '../../shared/widgets/gj_avatar_menu.dart';
import '../../shared/widgets/gj_button.dart';
import '../../shared/widgets/gj_card.dart';
import '../../shared/widgets/gj_carousel.dart';
import '../../shared/widgets/gj_data_table.dart';
import '../../shared/widgets/gj_drawer.dart';
import '../../shared/widgets/gj_footer.dart';
import '../../shared/widgets/gj_header.dart';
import '../../shared/widgets/gj_input.dart';
import '../../shared/widgets/gj_notification_bell.dart';
import '../../shared/widgets/gj_skeleton.dart';
import '../../shared/widgets/gj_status_badge.dart';
import '../../shared/widgets/gj_stepper.dart';
import '../../shared/widgets/gj_tabs.dart';
import '../../shared/widgets/gj_tag.dart';
import '../../shared/widgets/gj_timeline.dart';

/// Galeria de componentes (`/dev/components`): o "Storybook" do Guia Jovem.
/// Mostra todas as variantes e estados dos componentes base para
/// comparação com o protótipo aprovado (design system, seção 7.3).
class DevComponentsPage extends StatefulWidget {
  const DevComponentsPage({super.key});

  @override
  State<DevComponentsPage> createState() => _DevComponentsPageState();
}

class _DevComponentsPageState extends State<DevComponentsPage> {
  int _tabIndex = 0;
  final int _stepperIndex = 1;
  int _tabelaPagina = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeria de componentes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GJSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'GJButton',
              child: Wrap(
                spacing: GJSpace.s4,
                runSpacing: GJSpace.s4,
                children: [
                  GJButton(label: 'Primary', onPressed: () {}),
                  GJButton(label: 'Secondary', variant: GJButtonVariant.secondary, onPressed: () {}),
                  GJButton(label: 'Ghost', variant: GJButtonVariant.ghost, onPressed: () {}),
                  GJButton(label: 'Danger', variant: GJButtonVariant.danger, onPressed: () {}),
                  GJButton(label: 'Entrar com Google', variant: GJButtonVariant.google, onPressed: () {}),
                  GJButton(label: 'Financiamento', variant: GJButtonVariant.financiamento, onPressed: () {}),
                  const GJButton(label: 'Desabilitado'),
                  const GJButton(label: 'Carregando', loading: true),
                  GJButton(label: 'Retangular', shape: GJButtonShape.rect, onPressed: () {}),
                  GJButton(label: 'Pequeno', size: GJButtonSize.sm, onPressed: () {}),
                  GJButton(label: 'Grande', size: GJButtonSize.lg, onPressed: () {}),
                  GJButton(label: 'Com ícone', icon: Symbols.search, onPressed: () {}),
                ],
              ),
            ),
            const _Section(
              title: 'GJInput',
              child: Wrap(
                spacing: GJSpace.s6,
                runSpacing: GJSpace.s6,
                children: [
                  SizedBox(width: 280, child: GJInput(label: 'Nome', hint: 'Digite seu nome')),
                  SizedBox(
                    width: 280,
                    child: GJInput(label: 'Senha', obscureText: true, hint: '7 ou mais caracteres'),
                  ),
                  SizedBox(
                    width: 280,
                    child: GJInput(
                      label: 'E-mail',
                      icon: Symbols.mail,
                      errorText: 'Informe um e-mail válido',
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: GJInput(label: 'Somente leitura', readOnly: true, hint: 'Valor fixo'),
                  ),
                  SizedBox(
                    width: 280,
                    child: GJInput(
                      label: 'Painel',
                      variant: GJInputVariant.painel,
                      helperText: 'Visual usado dentro dos painéis administrativos',
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'GJCard',
              child: Wrap(
                spacing: GJSpace.s6,
                runSpacing: GJSpace.s6,
                children: [
                  SizedBox(
                    width: 260,
                    child: GJCard(
                      onTap: () {},
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card base', style: GJTypography.h4()),
                          const SizedBox(height: GJSpace.s2),
                          Text('Fundo surface.low, com hover.', style: GJTypography.bodySm()),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: GJCard(
                      variant: GJCardVariant.elevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card elevated', style: GJTypography.h4()),
                          const SizedBox(height: GJSpace.s2),
                          Text('Usado em painéis administrativos.', style: GJTypography.bodySm()),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: GJCard.universidade(
                      nomeFantasia: 'Fatec Sorocaba',
                      logoUrl: 'assets/img/logos/fatec.svg',
                      cidade: 'Sorocaba',
                      estado: 'SP',
                      mediaAvaliacao: 4.6,
                      totalAvaliacoes: 128,
                      tags: const [GJTag(label: 'ENEM', tone: GJTagTone.entrada), GJTag(label: 'ProUni', tone: GJTagTone.bolsa)],
                      onTap: () {},
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: GJCard.programa(
                      imagemUrl: 'assets/img/programas/enem.svg',
                      icone: Symbols.school,
                      cor: GJColors.primary,
                      sigla: 'ENEM',
                      nome: 'Exame Nacional do Ensino Médio',
                      descricao: 'A principal porta de entrada para o ensino superior no Brasil.',
                      onTap: () {},
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: GJCard.curso(
                      nome: 'Farmácia',
                      ilustracao: 'assets/img/areas/saude.svg',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'GJCarousel',
              child: GJCarousel(
                titulo: 'Faculdades',
                onVerTodas: () {},
                itemCount: 4,
                itemWidth: 240,
                itemBuilder: (context, index) => GJCard.universidade(
                  nomeFantasia: 'Universidade ${index + 1}',
                  cidade: 'São Paulo',
                  estado: 'SP',
                  mediaAvaliacao: 4.5,
                  totalAvaliacoes: 20 + index,
                  tags: const [GJTag(label: 'ENEM', tone: GJTagTone.entrada)],
                  onTap: () {},
                ),
              ),
            ),
            const _Section(
              title: 'GJTag',
              child: Wrap(
                spacing: GJSpace.s2,
                runSpacing: GJSpace.s2,
                children: [
                  GJTag(label: 'Programa de Entrada', tone: GJTagTone.entrada),
                  GJTag(label: 'Bolsa de Estudo', tone: GJTagTone.bolsa),
                  GJTag(label: 'Financiamento', tone: GJTagTone.financiamento),
                  GJTag(label: 'Aprovada', tone: GJTagTone.success),
                  GJTag(label: 'Em análise', tone: GJTagTone.warning),
                  GJTag(label: 'Reprovada', tone: GJTagTone.error),
                  GJTag(label: 'Filtro', tone: GJTagTone.neutral),
                ],
              ),
            ),
            _Section(
              title: 'GJTabs',
              child: GJTabs(
                tabs: const [
                  GJTabItem(label: 'Informações', icon: Symbols.info),
                  GJTabItem(label: 'Cursos', icon: Symbols.menu_book),
                  GJTabItem(label: 'Campus', icon: Symbols.location_on),
                ],
                selectedIndex: _tabIndex,
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
            ),
            _Section(
              title: 'GJStepper',
              child: GJStepper(
                labels: const ['Dados', 'Programas', 'Campus'],
                currentIndex: _stepperIndex,
              ),
            ),
            const _Section(
              title: 'GJTimeline',
              child: SizedBox(
                width: 320,
                child: GJTimeline(
                  itens: [
                    GJTimelineItem(mes: 'mai', dia: '25', titulo: 'Início das inscrições', descricao: 'Página do Participante', concluido: true),
                    GJTimelineItem(mes: 'nov', dia: '08', titulo: 'Primeiro dia de prova', descricao: 'Linguagens, Humanas e Redação'),
                    GJTimelineItem(mes: 'nov', dia: '15', titulo: 'Segundo dia de prova', descricao: 'Matemática e Natureza'),
                  ],
                ),
              ),
            ),
            const _Section(
              title: 'GJStatusBadge',
              child: Wrap(
                spacing: GJSpace.s3,
                runSpacing: GJSpace.s3,
                children: [
                  GJStatusBadge(label: 'Publicado e Ativo', tone: GJStatusTone.success, pulsante: true),
                  GJStatusBadge(label: 'Em análise', tone: GJStatusTone.warning),
                  GJStatusBadge(label: 'Reprovada', tone: GJStatusTone.error),
                ],
              ),
            ),
            const _Section(
              title: 'GJSkeleton',
              child: Wrap(
                spacing: GJSpace.s6,
                runSpacing: GJSpace.s6,
                children: [
                  SizedBox(width: 220, child: GJSkeletonCard()),
                  SizedBox(width: 220, child: GJSkeleton(height: 44, radius: 12)),
                ],
              ),
            ),
            _Section(
              title: 'GJHeader',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visitante', style: GJTypography.label()),
                  const SizedBox(height: GJSpace.s2),
                  GJHeader.visitante(
                    navItems: [
                      GJHeaderNavItem(label: 'Início', ativo: true, onTap: () {}),
                      GJHeaderNavItem(label: 'Programas de Entrada', onTap: () {}),
                      GJHeaderNavItem(label: 'Universidades', onTap: () {}),
                    ],
                    onEntrar: () {},
                  ),
                  const SizedBox(height: GJSpace.s6),
                  Text('Logado', style: GJTypography.label()),
                  const SizedBox(height: GJSpace.s2),
                  GJHeader.logado(
                    navItems: [
                      GJHeaderNavItem(label: 'Início', onTap: () {}),
                      GJHeaderNavItem(label: 'Universidades', ativo: true, onTap: () {}),
                    ],
                    notificationBell: GJNotificationBell(
                      naoLidas: 3,
                      notificacoes: const [
                        GJNotificationItem(titulo: 'Sua universidade foi aprovada', mensagem: 'A página da Fatec já está visível para os estudantes.', tempoRelativo: 'há 2 horas'),
                        GJNotificationItem(titulo: 'Nova sugestão recebida', mensagem: 'Lucas enviou uma sugestão sobre o curso de ADS.', tempoRelativo: 'ontem'),
                        GJNotificationItem(titulo: 'Sugestão respondida', mensagem: 'Sua sugestão sobre horários foi aprovada.', tempoRelativo: 'há 3 dias', lida: true),
                      ],
                      onMarcarTodasComoLidas: () {},
                    ),
                    avatarMenu: GJAvatarMenu(
                      iniciais: 'MS',
                      itens: [
                        GJAvatarMenuItem(label: 'Visualizar Perfil', icon: Symbols.person, onTap: () {}),
                        GJAvatarMenuItem(label: 'Painel Administrativo', icon: Symbols.dashboard, onTap: () {}),
                        GJAvatarMenuItem(label: 'Desligar', icon: Symbols.logout, onTap: () {}),
                        GJAvatarMenuItem(label: 'Excluir Conta', icon: Symbols.delete, destructivo: true, dividerAcima: true, onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: GJSpace.s6),
                  Text('Painel', style: GJTypography.label()),
                  const SizedBox(height: GJSpace.s2),
                  GJHeader.painel(
                    tituloPainel: 'Painel da Universidade',
                    avatarMenu: GJAvatarMenu(
                      iniciais: 'FS',
                      itens: [GJAvatarMenuItem(label: 'Visualizar Perfil', icon: Symbols.person, onTap: () {})],
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'GJFooter',
              child: GJFooter(
                links: [
                  GJFooterLink(label: 'Sobre', onTap: () {}),
                  GJFooterLink(label: 'Contato', onTap: () {}),
                  GJFooterLink(label: 'Privacidade', onTap: () {}),
                  GJFooterLink(label: 'Termos', onTap: () {}),
                ],
              ),
            ),
            _Section(
              title: 'GJDrawer',
              child: GJButton(
                label: 'Abrir GJDrawer',
                variant: GJButtonVariant.secondary,
                onPressed: () => GJDrawer.show(
                  context,
                  titulo: 'Novo curso',
                  acoes: [
                    GJButton(label: 'Cancelar', variant: GJButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
                    GJButton(label: 'Salvar', onPressed: () => Navigator.of(context).pop()),
                  ],
                  child: const GJInput(label: 'Nome do curso', hint: 'Análise e Desenvolvimento de Sistemas'),
                ),
              ),
            ),
            _Section(
              title: 'GJDataTable',
              child: GJDataTable(
                buscaHint: 'Buscar curso',
                acaoPrimariaLabel: 'Novo curso',
                onAcaoPrimaria: () {},
                paginaAtual: _tabelaPagina,
                totalPaginas: 3,
                onPaginaChanged: (pagina) => setState(() => _tabelaPagina = pagina),
                colunas: const [
                  GJDataColumn('Nome', flex: 2),
                  GJDataColumn('Área'),
                  GJDataColumn('Grau'),
                ],
                linhas: const [
                  [Text('Administração'), Text('Negócios'), Text('Bacharelado')],
                  [Text('Farmácia'), Text('Saúde'), Text('Bacharelado')],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GJTypography.h2()),
          const SizedBox(height: GJSpace.s2),
          Container(height: 1, color: GJColors.surfaceDim),
          const SizedBox(height: GJSpace.s6),
          child,
        ],
      ),
    );
  }
}
