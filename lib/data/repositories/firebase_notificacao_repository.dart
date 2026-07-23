import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/repositories/notificacao_repository.dart';

class FirebaseNotificacaoRepository implements NotificacaoRepository {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<String>? _refreshSub;
  String? _usuarioId;

  FirebaseNotificacaoRepository({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> registrarToken(String usuarioId) async {
    _usuarioId = usuarioId;

    // Pede permissão (iOS e Android 13+). Em plataformas onde já está
    // concedida, retorna sem prompt.
    await _messaging.requestPermission();

    final token = await _messaging.getToken();
    if (token != null) {
      await _salvar(usuarioId, token);
    }

    // Mantém o token atualizado se o FCM gerar um novo (só uma assinatura).
    _refreshSub ??= _messaging.onTokenRefresh.listen((novo) {
      final id = _usuarioId;
      if (id != null) _salvar(id, novo);
    });
  }

  Future<void> _salvar(String usuarioId, String token) async {
    await _firestore.collection('usuarios').doc(usuarioId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
