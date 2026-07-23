import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

/// Coleção `usuarios` no Firestore, documento com o mesmo id do
/// FirebaseAuth (uid). Isso simplifica as regras de segurança:
/// `request.auth.uid == resource.id` para acesso aos próprios dados.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<Usuario?> get usuarioAtual {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _buscarUsuarioNoFirestore(fbUser.uid);
    });
  }

  Future<Usuario?> _buscarUsuarioNoFirestore(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Usuario(
      id: doc.id,
      nome: data['nome'] as String,
      email: data['email'] as String,
      telefone: data['telefone'] as String?,
      fotoUrl: data['fotoUrl'] as String?,
      tipo: (data['tipo'] as String) == 'professora'
          ? TipoUsuario.professora
          : TipoUsuario.aluna,
      periodoFixo: data['periodoFixo'] as String?,
      diaFixo: data['diaFixo'] as String?,
      turmaId: data['turmaId'] as String?,
      pacoteAtualId: data['pacoteAtualId'] as String?,
      dataInicio: (data['dataInicio'] as Timestamp?)?.toDate(),
      aulasPorMes: (data['aulasPorMes'] as num?)?.toInt() ?? 4,
    );
  }

  @override
  Future<Usuario> loginComEmailSenha(String email, String senha) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    final usuario = await _buscarUsuarioNoFirestore(cred.user!.uid);
    if (usuario == null) {
      throw Exception('Usuário autenticado mas sem perfil no Firestore.');
    }
    return usuario;
  }

  @override
  Future<Usuario> loginComGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Login com Google cancelado.');

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final usuario = await _buscarUsuarioNoFirestore(cred.user!.uid);
    if (usuario == null) {
      throw Exception(
        'Conta Google sem perfil vinculado. Peça para a professora cadastrar você primeiro.',
      );
    }
    return usuario;
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> criarContaAluna({
    required String nome,
    required String email,
  }) async {
    // TODO: em produção, isso deve rodar numa Cloud Function com
    // privilégios de admin (Firebase Admin SDK), para não expor a
    // criação de contas de terceiros no cliente. Aqui fica o esqueleto
    // do fluxo esperado:
    // 1. Function cria o usuário no Firebase Auth com senha temporária.
    // 2. Function cria o documento em `usuarios` com tipo: 'aluna'.
    // 3. Function envia e-mail de boas-vindas com link de "definir senha".
    throw UnimplementedError(
      'Implementar via Cloud Function callable `criarContaAluna`.',
    );
  }
}
