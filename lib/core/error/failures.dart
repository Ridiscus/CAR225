import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure([this.message = '']);

  @override
  List<Object> get props => [message];
}

// Erreurs de connexion serveur
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

// Erreurs de cache local
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

// Erreurs de connexion internet
class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}
