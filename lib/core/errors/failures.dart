import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  final String message;

  ServerFailure({this.message = 'Server failure'});

  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  CacheFailure({this.message = 'Cache failure'});

  @override
  List<Object> get props => [message];
}

class AuthFailure extends Failure {
  final String message;

  AuthFailure({this.message = 'Authentication failure'});

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;

  NetworkFailure({this.message = 'Network failure'});

  @override
  List<Object> get props => [message];
}