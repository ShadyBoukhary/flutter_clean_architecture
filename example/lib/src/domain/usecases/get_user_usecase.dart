import 'dart:async';

import 'package:example/src/domain/entities/user.dart';
import 'package:example/src/domain/repositories/users_repository.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:rxdart/src/observables/observable.dart';

class GetUserUseCase extends UseCase<GetUserUseCaseResponse, GetUserUseCaseParams> {
  final UsersRepository usersRepository;
  GetUserUseCase(this.usersRepository);

  @override
  Future<Observable<GetUserUseCaseResponse>> buildUseCaseObservable(
      GetUserUseCaseParams params) async {
    final StreamController<GetUserUseCaseResponse> controller = StreamController();
    try {
      // get user
      User user = await usersRepository.getUser(params.uid);
      // Adding it triggers the .onNext() in the `Observer`
      // It is usually better to wrap the reponse inside a respose object.
      controller.add(GetUserUseCaseResponse(user));
      logger.finest('GetUserUseCase successful.');
      controller.close();
    } catch (e) {
      logger.severe('GetUserUseCase unsuccessful.');
      // Trigger .onError
      controller.addError(e);
    }
    return Observable(controller.stream);
  }
}

class GetUserUseCaseParams {
  final String uid;
  GetUserUseCaseParams(this.uid);
}

class GetUserUseCaseResponse {
  final User user;
  GetUserUseCaseResponse(this.user);
}

