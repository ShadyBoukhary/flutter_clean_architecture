import '../entities/user.dart';
import '../repositories/users_repository.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

class GetUserFutureUseCase extends FutureUseCase<GetUserFutureUseCaseResponse,
    GetUserFutureUseCaseParams> {
  final UsersRepository usersRepository;
  GetUserFutureUseCase(this.usersRepository);

  @override
  Future<GetUserFutureUseCaseResponse?> buildUseCaseFuture(
      GetUserFutureUseCaseParams? params) async {
    // get user
    final user = await usersRepository.getUser(params!.uid);
    logger.finest('GetUserFutureUseCase successful.');
    return GetUserFutureUseCaseResponse(user);
  }
}

/// Wrapping params inside an object makes it easier to change later
class GetUserFutureUseCaseParams {
  final String uid;
  GetUserFutureUseCaseParams(this.uid);
}

/// Wrapping response inside an object makes it easier to change later
class GetUserFutureUseCaseResponse {
  final User user;
  GetUserFutureUseCaseResponse(this.user);
}
