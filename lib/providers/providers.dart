import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/firestore_aula_repository.dart';
import '../data/repositories/firestore_aviso_repository.dart';
import '../data/repositories/firestore_pacote_repository.dart';
import '../data/repositories/firebase_notificacao_repository.dart';
import '../data/repositories/firestore_pagamento_repository.dart';
import '../data/repositories/firestore_turma_repository.dart';
import '../domain/entities/aula.dart';
import '../domain/entities/aviso.dart';
import '../domain/entities/pacote.dart';
import '../domain/entities/pagamento.dart';
import '../domain/entities/turma.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/aula_repository.dart';
import '../domain/repositories/aviso_repository.dart';
import '../domain/repositories/pacote_repository.dart';
import '../domain/repositories/notificacao_repository.dart';
import '../domain/repositories/pagamento_repository.dart';
import '../domain/repositories/turma_repository.dart';

// ---------- Repositórios ----------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final turmaRepositoryProvider = Provider<TurmaRepository>((ref) {
  return FirestoreTurmaRepository();
});

final aulaRepositoryProvider = Provider<AulaRepository>((ref) {
  return FirestoreAulaRepository(
    turmaRepository: ref.watch(turmaRepositoryProvider),
  );
});

final pacoteRepositoryProvider = Provider<PacoteRepository>((ref) {
  return FirestorePacoteRepository();
});

final pagamentoRepositoryProvider = Provider<PagamentoRepository>((ref) {
  return FirestorePagamentoRepository();
});

final avisoRepositoryProvider = Provider<AvisoRepository>((ref) {
  return FirestoreAvisoRepository();
});

final notificacaoRepositoryProvider = Provider<NotificacaoRepository>((ref) {
  return FirebaseNotificacaoRepository();
});

// ---------- Autenticação ----------

/// Stream do usuário logado — é a base do GoRouter redirect (guards).
final usuarioAtualProvider = StreamProvider<Usuario?>((ref) {
  return ref.watch(authRepositoryProvider).usuarioAtual;
});

// ---------- Aluna ----------

final aulasDaAlunaProvider =
    StreamProvider.family<List<Aula>, ({String alunaId, DateTime mes})>((ref, params) {
  return ref
      .watch(aulaRepositoryProvider)
      .aulasDaAluna(params.alunaId, mesReferencia: params.mes);
});

final disponibilidadeDoDiaProvider =
    FutureProvider.family<List<DisponibilidadePeriodo>, DateTime>((ref, dia) {
  return ref.watch(turmaRepositoryProvider).disponibilidadePorDia(dia);
});

final saldoPacoteDaAlunaProvider =
    StreamProvider.family<SaldoPacote, String>((ref, alunaId) {
  return ref.watch(pacoteRepositoryProvider).saldoDe(alunaId);
});

final pagamentosDaAlunaProvider =
    StreamProvider.family<List<Pagamento>, String>((ref, alunaId) {
  return ref.watch(pagamentoRepositoryProvider).pagamentosDaAluna(alunaId);
});

final avisosRecentesProvider = StreamProvider<List<Aviso>>((ref) {
  return ref.watch(avisoRepositoryProvider).avisosRecentes;
});

/// Vagas liberadas (uma aluna recusou) ainda em aberto — a primeira que
/// aceitar leva. Mostradas para todas as alunas.
final ofertasAbertasProvider = StreamProvider<List<OfertaVaga>>((ref) {
  return ref.watch(aulaRepositoryProvider).ofertasAbertas();
});

// ---------- Professora ----------

final turmasProvider = StreamProvider<List<Turma>>((ref) {
  return ref.watch(turmaRepositoryProvider).todasTurmas;
});

final todasAsAulasDoMesProvider =
    StreamProvider.family<List<Aula>, DateTime>((ref, mes) {
  return ref.watch(aulaRepositoryProvider).todasAsAulas(mesReferencia: mes);
});

final solicitacoesPendentesProvider =
    StreamProvider<List<SolicitacaoRemarcacao>>((ref) {
  return ref.watch(aulaRepositoryProvider).solicitacoesPendentes();
});

final pagamentosPendentesProvider = StreamProvider<List<Pagamento>>((ref) {
  return ref.watch(pagamentoRepositoryProvider).todosPendentesOuAtrasados();
});
