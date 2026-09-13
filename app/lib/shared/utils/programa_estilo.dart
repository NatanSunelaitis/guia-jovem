import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../widgets/gj_tag.dart';

/// Estilo visual por tipo/sigla de programa (seção 2.1 do design system):
/// cor e ícone usados em T01, T05 e T08. Centralizado para as três telas
/// não divergirem entre si.
Color corPrograma(String tipo) => switch (tipo) {
      'FINANCIAMENTO' => GJColors.tertiary,
      'BOLSA' => GJColors.secondary,
      _ => GJColors.primary,
    };

GJTagTone tonePrograma(String tipo) => switch (tipo) {
      'FINANCIAMENTO' => GJTagTone.financiamento,
      'BOLSA' => GJTagTone.bolsa,
      _ => GJTagTone.entrada,
    };

String rotuloTipoPrograma(String tipo) => switch (tipo) {
      'FINANCIAMENTO' => 'Financiamento Estudantil',
      'BOLSA' => 'Bolsa de Estudo',
      _ => 'Programa de Entrada',
    };

IconData iconePrograma(String? sigla, String tipo) => switch (sigla?.toUpperCase()) {
      'ENEM' => Symbols.school,
      'SISU' => Symbols.how_to_reg,
      'PROUNI' => Symbols.workspace_premium,
      'FIES' => Symbols.account_balance_wallet,
      'VESTIBULAR' => Symbols.edit_note,
      'PNAES' => Symbols.home_work,
      _ => switch (tipo) {
          'FINANCIAMENTO' => Symbols.account_balance_wallet,
          'BOLSA' => Symbols.workspace_premium,
          _ => Symbols.school,
        },
    };

/// Imagem local usada quando `imagemUrl` vem nula da API.
const String imagemProgramaPadrao = 'assets/img/programas/generico.svg';
