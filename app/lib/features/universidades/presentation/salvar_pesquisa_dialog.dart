import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../favoritos/data/favoritos_repository.dart';
import '../../favoritos/domain/pesquisa_salva.dart';

/// Pede o nome e salva os filtros atuais da pesquisa de universidades.
/// Nome repetido (409) mostra a mensagem da API e mantém o diálogo aberto.
/// Retorna a pesquisa salva ou null se o aluno cancelou.
Future<PesquisaSalva?> mostrarDialogoSalvarPesquisa(BuildContext context, {required Map<String, dynamic> parametros}) {
  return showDialog<PesquisaSalva>(
    context: context,
    builder: (context) => _SalvarPesquisaDialog(parametros: parametros),
  );
}

class _SalvarPesquisaDialog extends StatefulWidget {
  const _SalvarPesquisaDialog({required this.parametros});

  final Map<String, dynamic> parametros;

  @override
  State<_SalvarPesquisaDialog> createState() => _SalvarPesquisaDialogState();
}

class _SalvarPesquisaDialogState extends State<_SalvarPesquisaDialog> {
  final _nomeController = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Informe um nome para a pesquisa');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final salva = await favoritosRepository.salvarPesquisa(nome: nome, parametros: widget.parametros);
      if (!mounted) return;
      Navigator.of(context).pop(salva);
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(GJSpace.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Salvar pesquisa', style: GJTypography.h4())),
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Symbols.close)),
                ],
              ),
              const SizedBox(height: GJSpace.s2),
              Text('Dê um nome para encontrar esta pesquisa depois no seu perfil.', style: GJTypography.bodySm()),
              const SizedBox(height: GJSpace.s4),
              GJInput(
                label: 'Nome da pesquisa',
                hint: 'Ex.: Públicas em Sorocaba',
                controller: _nomeController,
                errorText: _erro,
              ),
              const SizedBox(height: GJSpace.s6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GJButton(label: 'Cancelar', variant: GJButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: GJSpace.s3),
                  GJButton(label: 'Salvar', icon: Symbols.bookmark_add, onPressed: _enviando ? null : _salvar),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
