import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/admin_repository.dart';
import '../../domain/universidade_admin.dart';
import 'formulario.dart';
import '../../../../shared/utils/mascaras.dart';

/// Administrador edita os dados institucionais (RF18). O status tem ações
/// próprias na tela de cadastro.
class FormularioUniversidade extends StatefulWidget {
  const FormularioUniversidade({super.key, required this.cadastro});

  final UniversidadeCadastro cadastro;

  @override
  State<FormularioUniversidade> createState() => _FormularioUniversidadeState();
}

class _FormularioUniversidadeState extends State<FormularioUniversidade> {
  late final _nomeFantasia = TextEditingController(text: widget.cadastro.nomeFantasia);
  late final _razaoSocial = TextEditingController(text: widget.cadastro.razaoSocial);
  late final _cnpj = TextEditingController(text: formatarCnpj(widget.cadastro.cnpj));
  late final _telefone = TextEditingController(text: widget.cadastro.telefonePrincipal);
  late final _linkPagina = TextEditingController(text: widget.cadastro.linkPagina);
  late final _linkSimulados = TextEditingController(text: widget.cadastro.linkSimulados);
  late final _descricao = TextEditingController(text: widget.cadastro.descricao);
  late String _natureza = widget.cadastro.natureza;

  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_nomeFantasia, _razaoSocial, _cnpj, _telefone, _linkPagina, _linkSimulados, _descricao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final erros = <String, String>{};
    if (_nomeFantasia.text.trim().isEmpty) erros['nomeFantasia'] = 'Informe o nome fantasia';
    if (_razaoSocial.text.trim().isEmpty) erros['razaoSocial'] = 'Informe a razão social';
    if (_cnpj.text.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').length != 14) erros['cnpj'] = 'O CNPJ deve ter 14 caracteres';
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    setState(() => _salvando = true);
    try {
      final salvo = await adminRepository.atualizarUniversidade(widget.cadastro.id, {
        'nomeFantasia': _nomeFantasia.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'cnpj': _cnpj.text.trim(),
        'natureza': _natureza,
        'telefonePrincipal': textoOuNulo(_telefone),
        'linkPagina': textoOuNulo(_linkPagina),
        'linkSimulados': textoOuNulo(_linkSimulados),
        'descricao': textoOuNulo(_descricao),
      });
      if (mounted) Navigator.of(context).pop(salvo);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erros = {...errosPorCampo(erro), if (erro.code == 'CNPJ_EM_USO') 'cnpj': erro.message};
        _erroGeral = mensagemDaApi(erro);
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome fantasia', controller: _nomeFantasia, erro: _erros['nomeFantasia'], maxLength: 100),
        CampoTexto(rotulo: 'Razão social', controller: _razaoSocial, erro: _erros['razaoSocial'], maxLength: 100),
        CampoTexto(rotulo: 'CNPJ', controller: _cnpj, erro: _erros['cnpj'], inputFormatters: [CnpjInputFormatter()]),
        CampoSelecao<String>(
          rotulo: 'Natureza',
          valor: _natureza,
          opcoes: const {'P': 'Pública', 'V': 'Privada'},
          onChanged: (valor) => setState(() => _natureza = valor ?? _natureza),
        ),
        CampoTexto(rotulo: 'Telefone principal', controller: _telefone, erro: _erros['telefonePrincipal'], maxLength: 15),
        CampoTexto(rotulo: 'Página oficial', controller: _linkPagina, erro: _erros['linkPagina'], dica: 'https://'),
        CampoTexto(rotulo: 'Simulados', controller: _linkSimulados, erro: _erros['linkSimulados'], dica: 'https://'),
        CampoTextoLongo(rotulo: 'Descrição', controller: _descricao, erro: _erros['descricao']),
        RodapeFormulario(salvando: _salvando, onSalvar: _salvar, erro: _erroGeral),
      ],
    );
  }
}
