import 'package:firebase_auth/firebase_auth.dart';
import 'package:fytter/src/data/firebase_auth_repository.dart';
import 'package:fytter/src/domain/auth_repository.dart';

AuthRepository createAuthRepositoryImpl() {
  return FirebaseAuthRepository(auth: FirebaseAuth.instance);
}
