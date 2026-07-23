enum TipoUsuario { professora, aluna }

/// Entidade de domínio — representa um usuário autenticado (professora ou aluna).
/// Mantida livre de dependências do Firebase (Clean Architecture).
class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final TipoUsuario tipo;

  // Campos específicos de aluna (nulos para professora)
  final String? periodoFixo; // 'manha' | 'tarde' | 'noite'
  final String? diaFixo; // 'segunda' | 'terca' | 'quarta' | 'quinta'
  final String? turmaId;
  final String? pacoteAtualId;
  final DateTime? dataInicio;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoUrl,
    required this.tipo,
    this.periodoFixo,
    this.diaFixo,
    this.turmaId,
    this.pacoteAtualId,
    this.dataInicio,
  });

  bool get isProfessora => tipo == TipoUsuario.professora;
  bool get isAluna => tipo == TipoUsuario.aluna;
}
