import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_user.dart';

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriendsEvent extends FriendsEvent {
  final String userId;

  const LoadFriendsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadFriendRequestsEvent extends FriendsEvent {
  final String userId;

  const LoadFriendRequestsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SendFriendRequestEvent extends FriendsEvent {
  final String senderId;
  final String receiverId;

  const SendFriendRequestEvent(this.senderId, this.receiverId);

  @override
  List<Object?> get props => [senderId, receiverId];
}

class AcceptFriendRequestEvent extends FriendsEvent {
  final String userId;
  final String requesterId;

  const AcceptFriendRequestEvent(this.userId, this.requesterId);

  @override
  List<Object?> get props => [userId, requesterId];
}

class StartChatEvent extends FriendsEvent {
  final AppUser friend;

  const StartChatEvent(this.friend);

  @override
  List<Object?> get props => [friend];
}