import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/aviso.dart';
import '../../domain/repositories/aviso_repository.dart';

class FirestoreAvisoRepository implements AvisoRepository {
  final FirebaseFirestore _firestore;

  FirestoreAvisoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _avisosRef => _firestore.collection('avisos');

  @override
  Stream<List<Aviso>> get avisosRecentes {
    return _avisosRef
        .orderBy('criadoEm', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Aviso(
                id: doc.id,
                titulo: data['titulo'] as String,
                mensagem: data['mensagem'] as String,
                criadoEm: (data['criadoEm'] as Timestamp).toDate(),
              );
            }).toList());
  }

  @override
  Future<void> enviarAviso({required String titulo, required String mensagem}) async {
    // A criação deste documento dispara a Cloud Function `onAvisoCriado`
    // (ver functions/src/index.ts), que envia a notificação push via FCM
    // para todas as alunas ativas.
    await _avisosRef.add({
      'titulo': titulo,
      'mensagem': mensagem,
      'criadoEm': Timestamp.fromDate(DateTime.now()),
    });
  }
}
