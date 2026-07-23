import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final FirebaseFunctions _functions;

  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _functions = functions ?? FirebaseFunctions.instance;

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
  Future<NovaContaAluna> criarContaAluna({
    required String nome,
    required String email,
    String? telefone,
    String? turmaId,
    String? diaFixo,
    String? periodoFixo,
    int aulasPorMes = 4,
  }) async {
    // Chama a Cloud Function `criarContaAluna`, que roda com privilégios de
    // admin: cria o usuário no Firebase Auth, grava o perfil em `usuarios`
    // com tipo 'aluna' e devolve um link para a aluna definir a senha.
    try {
      final callable = _functions.httpsCallable('criarContaAluna');
      final res = await callable.call<Map<String, dynamic>>({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'turmaId': turmaId,
        'diaFixo': diaFixo,
        'periodoFixo': periodoFixo,
        'aulasPorMes': aulasPorMes,
      });
      final data = res.data;
      return NovaContaAluna(
        uid: data['uid'] as String,
        linkDefinirSenha: data['linkDefinirSenha'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Não foi possível cadastrar a aluna.');
    }
  }
}
