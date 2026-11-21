import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_drawer.dart';
import '../../../../shared/widgets/gj_editor_texto_formatado.dart';
import '../../../../shared/widgets/gj_input.dart';

/// Abre um formulário no painel lateral (GJDrawer, seção 3.10). O
/// formulário fecha a si mesmo com `Navigator.pop(resultado)` ao salvar.
Future<T?> abrirFormulario<T>(BuildContext context, {required String titulo, required Widget formulario}) {
  return GJDrawer.show<T>(context, titulo: titulo, child: formulario);
}

/// Mensagem para o usuário: na validação, a do primeiro campo recusado.
String mensagemDaApi(ApiException erro) {
  if (erro.code == 'VALIDATION_ERROR' && erro.details.isNotEmpty) {
    final primeiro = erro.details.first;
    if (primeiro is Map && primeiro['mensagem'] is String) return primeiro['mensagem'] as String;
  }
  return erro.message;
}

/// Erros de validação da API por campo (`details[].campo`).
Map<String, String> errosPorCampo(ApiException erro) {
  if (erro.code != 'VALIDATION_ERROR') return const {};
  return {
    for (final detalhe in erro.details)
      if (detalhe is Map && detalhe['campo'] is String) detalhe['campo'] as String: '${detalhe['mensagem']}',
  };
}

/// Texto vazio vira null no corpo enviado (a API limpa o campo).
String? textoOuNulo(TextEditingController controller) {
  final texto = controller.text.trim();
  return texto.isEmpty ? null : texto;
}

class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.rotulo,
    required this.controller,
    this.erro,
    this.dica,
    this.maxLength,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.inputFormatters,
  });

  final String rotulo;
  final TextEditingController controller;
  final String? erro;
  final String? dica;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: GJInput(
        label: rotulo,
        controller: controller,
        errorText: erro,
        hint: dica,
        maxLength: maxLength,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        inputFormatters: inputFormatters,
      ),
    );
  }
}

/// Texto longo com formatação simples (descrição, requisitos, como
/// funciona, "Sobre"): barra de formatação, pré-visualização e contador.
class CampoTextoLongo extends StatelessWidget {
  const CampoTextoLongo({super.key, required this.rotulo, required this.controller, this.erro, this.campoKey});

  final String rotulo;
  final TextEditingController controller;
  final String? erro;
  final Key? campoKey;

  @override
  Widget build(BuildContext context) {
    return GJEditorTextoFormatado(rotulo: rotulo, controller: controller, erro: erro, campoKey: campoKey);
  }
}

class CampoSelecao<T> extends StatelessWidget {
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    this.erro,
    this.enabled = true,
  });

  final String rotulo;
  final T? valor;
  final Map<T?, String> opcoes;
  final ValueChanged<T?> onChanged;
  final String? erro;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: DropdownButtonFormField<T?>(
        value: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder(), errorText: erro),
        items: [
          for (final opcao in opcoes.entries)
            DropdownMenuItem<T?>(value: opcao.key, child: Text(opcao.value, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

/// Rodapé do formulário: mensagem geral de erro, Cancelar e Salvar.
class RodapeFormulario extends StatelessWidget {
  const RodapeFormulario({
    super.key,
    required this.salvando,
    required this.onSalvar,
    this.erro,
    this.rotuloSalvar = 'Salvar',
  });

  final bool salvando;
  final VoidCallback onSalvar;
  final String? erro;
  final String rotuloSalvar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (erro != null) ...[
          Text(erro!, style: GJTypography.label(color: GJColors.error)),
          const SizedBox(height: GJSpace.s3),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: salvando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            const SizedBox(width: GJSpace.s3),
            GJButton(label: rotuloSalvar, loading: salvando, onPressed: salvando ? null : onSalvar),
          ],
        ),
      ],
    );
  }
}
