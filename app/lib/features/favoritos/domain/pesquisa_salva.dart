/// Pesquisa de universidades salva pelo aluno (classe pesquisaSalva).
/// [parametros] são os filtros de GET /universidades, já validados pela API.
class PesquisaSalva {
  PesquisaSalva({required this.id, required this.nome, required this.parametros, required this.criadoEm});

  factory PesquisaSalva.fromJson(Map<String, dynamic> json) => PesquisaSalva(
        id: json['id'] as int,
        nome: json['nome'] as String,
        parametros: Map<String, dynamic>.from(json['parametros'] as Map? ?? const {}),
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  final int id;
  final String nome;
  final Map<String, dynamic> parametros;
  final DateTime criadoEm;

  /// Filtros no formato de query string, o mesmo que a pesquisa aceita
  /// em `filtrosIniciais` (`/universidades?cidade=...`).
  Map<String, String> get filtrosComoTexto => {
        for (final entrada in parametros.entries)
          if (entrada.value != null) entrada.key: entrada.value.toString(),
      };
}
