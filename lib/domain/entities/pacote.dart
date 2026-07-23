/// Um pacote contratado pela aluna (ex: 4, 8, 12, 20 aulas).
/// O saldo é sempre calculado, nunca armazenado direto, para evitar
/// dessincronia com as aulas realmente usadas (ver PacoteRepository.saldoDe).
class Pacote {
  final String id;
  final String nome; // "Pacote 8 aulas"
  final int quantidadeAulas;
  final double valor;

  const Pacote({
    required this.id,
    required this.nome,
    required this.quantidadeAulas,
    required this.valor,
  });
}

/// Vínculo entre uma aluna e o pacote que ela contratou num período.
class PacoteContratado {
  final String id;
  final String alunaId;
  final String pacoteId;
  final DateTime contratadoEm;
  final DateTime validoAte;

  const PacoteContratado({
    required this.id,
    required this.alunaId,
    required this.pacoteId,
    required this.contratadoEm,
    required this.validoAte,
  });
}

class SaldoPacote {
  final int totalDoPacote;
  final int utilizadas;
  int get restantes => (totalDoPacote - utilizadas).clamp(0, totalDoPacote);

  const SaldoPacote({required this.totalDoPacote, required this.utilizadas});
}
