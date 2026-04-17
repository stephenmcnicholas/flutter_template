import 'package:fytter/src/domain/auth_repository.dart';

import 'auth_repository_factory_stub.dart'
    if (dart.library.io) 'auth_repository_factory_io.dart'
    if (dart.library.html) 'auth_repository_factory_web.dart';

AuthRepository createAuthRepository() => createAuthRepositoryImpl();
