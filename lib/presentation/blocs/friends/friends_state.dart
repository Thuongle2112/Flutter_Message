import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_user.dart';

abstract class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => [];
}

class FriendsInitial extends FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<AppUser> friends;

  const FriendsLoaded(this.friends);

  @override
  List<Object?> get props => [friends];
}

class FriendRequestsLoaded extends FriendsState {
  final List<AppUser> requesters;

  const FriendRequestsLoaded(this.requesters);

  @override
  List<Object?> get props => [requesters];
}

class FriendRequestSent extends FriendsState {}

class FriendRequestAccepted extends FriendsState {}

class FriendsError extends FriendsState {
  final String message;

  const FriendsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatStarted extends FriendsState {
  final AppUser friend;
  final String conversationId;

  const ChatStarted(this.friend, this.conversationId);

  @override
  List<Object?> get props => [friend, conversationId];
}