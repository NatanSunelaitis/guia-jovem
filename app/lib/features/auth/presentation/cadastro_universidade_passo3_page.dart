import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/estados_brasil.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../shared/widgets/gj_input.dart';
import '../data/cadastro_universidade_state.dart';
import '../data/session_controller.dart';
import 'widgets/cadastro_universidade_shell.dart';
import '../../../shared/utils/mascaras.dart';

/// T15 Cadastro de Universidade, passo 3 de 3: primeiro campus
/// (`/cadastro/universidade/campus`, Figura 30).
class CadastroUniversidadePasso3Page extends StatefulWidget {
  const CadastroUniversidadePasso3Page({super.key});

  @override
  State<CadastroUniversidadePasso3Page> createState() => _CadastroUniversidadePasso3PageState();
}

class _CadastroUniversidadePasso3PageState extends State<CadastroUniversidadePasso3Page> {
  final _nomeController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  String? _estadoSelecionado;

  String? _erroNome;
  String? _erroLogradouro;
  String? _erroNumero;
  String? _erroBairro;
  String? _erroCidade;
  String? _erroEstado;
  String? _erroGeral;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final estado = cadastroUniversidadeState;
    _nomeController.text = estado.nomeCampus;
    _logradouroController.text = estado.logradouro;
    _numeroController.text = estado.numero;
    _complementoController.text = estado.complemento;
    _bairroController.text = estado.bairro;
    _cidadeController.text = estado.cidade;
    _cepController.text = estado.cep;
    _telefoneController.text = estado.telefoneCampus;
    _estadoSelecionado = estado.estado.isEmpty ? null : estado.estado;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _cepController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _salvarNoEstado() {
    final estado = cadastroUniversidadeState;
    estado.nomeCampus = _nomeController.text.trim();
    estado.logradouro = _logradouroController.text.trim();
    estado.numero = _numeroController.text.trim();
    estado.complemento = _complementoController.text.trim();
    estado.bairro = _bairroController.text.trim();
    estado.cidade = _cidadeController.text.trim();
    estado.cep = _cepController.text.trim();
    estado.telefoneCampus = _telefoneController.text.trim();
    estado.estado = _estadoSelecionado ?? '';
  }

  void _voltar() {
    _salvarNoEstado();
    context.go('/cadastro/universidade/programas');
  }

  bool _validar() {
    setState(() {
      _erroNome = _nomeController.text.trim().isEmpty ? 'Informe o nome do campus' : null;
      _erroLogradouro = _logradouroController.text.trim().isEmpty ? 'Informe o logradouro' : null;
      _erroNumero = _numeroController.text.trim().isEmpty ? 'Informe o número' : null;
      _erroBairro = _bairroController.text.trim().isEmpty ? 'Informe o bairro' : null;
      _erroCidade = _cidadeController.text.trim().isEmpty ? 'Informe a cidade' : null;
      _erroEstado = _estadoSelecionado == null ? 'Selecione o estado' : null;
    });
    return [_erroNome, _erroLogradouro, _erroNumero, _erroBairro, _erroCidade, _erroEstado].every((e) => e == null);
  }

  Future<void> _cadastrar() async {
    setState(() => _erroGeral = null);
    if (!_validar()) return;

    _salvarNoEstado();
    setState(() => _enviando = true);
    try {
      await sessionController.registrarUniversidade(cadastroUniversidadeState.paraCorpoDaRequisicao());
      if (!mounted) return;
      cadastroUniversidadeState.reiniciar();
      context.go('/cadastro/universidade/sucesso');
    } on ApiException catch (erro) {
      setState(() => _erroGeral = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    Widget linha(List<Widget> campos) {
      if (isMobile) {
        return Column(children: [for (final c in campos) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s4), child: c)]);
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: GJSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < campos.length; i++) ...[
              if (i > 0) const SizedBox(width: GJSpace.s5),
              Expanded(child: campos[i]),
            ],
          ],
        ),
      );
    }

    return CadastroUniversidadeShell(
      passoAtual: 3,
      titulo: 'Cadastre seu primeiro Campus!',
      aoVoltar: _voltar,
      aoAvancar: _cadastrar,
      rotuloAvancar: 'Cadastrar',
      avancarCarregando: _enviando,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_erroGeral != null) ...[
            Text(_erroGeral!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: GJSpace.s3),
          ],
          linha([GJInput(label: 'Nome do campus', hint: 'Fatec Sorocaba', controller: _nomeController, errorText: _erroNome)]),
          linha([
            GJInput(label: 'Logradouro', hint: 'Av. Engenheiro Carlos Reinaldo Mendes', controller: _logradouroController, errorText: _erroLogradouro),
            GJInput(label: 'Número', hint: '2015', controller: _numeroController, errorText: _erroNumero),
          ]),
          linha([
            GJInput(label: 'Complemento', hint: 'Bloco B', controller: _complementoController),
            GJInput(label: 'Bairro', hint: 'Alto da Boa Vista', controller: _bairroController, errorText: _erroBairro),
          ]),
          linha([
            GJInput(label: 'Cidade', hint: 'Sorocaba', controller: _cidadeController, errorText: _erroCidade),
            _campoEstado(),
          ]),
          linha([
            GJInput(label: 'CEP', hint: '00000-000', controller: _cepController, inputFormatters: [CepInputFormatter()]),
            GJInput(label: 'Telefone', hint: '(00) 0000-0000', controller: _telefoneController),
          ]),
        ],
      ),
    );
  }

  Widget _campoEstado() {
    return DropdownButtonFormField<String>(
      value: _estadoSelecionado,
      decoration: InputDecoration(labelText: 'Estado', border: const OutlineInputBorder(), errorText: _erroEstado),
      items: [for (final uf in estadosBrasil) DropdownMenuItem(value: uf, child: Text(uf))],
      onChanged: (valor) => setState(() => _estadoSelecionado = valor),
    );
  }
}
