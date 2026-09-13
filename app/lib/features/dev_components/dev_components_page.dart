import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import '../../shared/widgets/gj_button.dart';
import '../../shared/widgets/gj_card.dart';
import '../../shared/widgets/gj_input.dart';
import '../../shared/widgets/gj_tabs.dart';
import '../../shared/widgets/gj_tag.dart';

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
                ],
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
