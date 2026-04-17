import 'package:fytter/src/data/web_auth_repository.dart';
import 'package:fytter/src/domain/auth_repository.dart';

AuthRepository createAuthRepositoryImpl() {
  return WebAuthRepository();
}
