// part of 'home_bloc.dart';
//
// abstract class HomeEvent extends Equatable {
//   @override
//   List<Object?> get props => [];
// }
//
// class SendFriendRequestEvent extends HomeEvent {
//   final String currentUserId;
//   final String targetUserId;
//
//   SendFriendRequestEvent(this.currentUserId, this.targetUserId);
//
//   @override
//   List<Object?> get props => [currentUserId, targetUserId];
// }
//
// class AcceptFriendRequestEvent extends HomeEvent {
//   final String currentUserId;
//   final String requesterId;
//
//   AcceptFriendRequestEvent(this.currentUserId, this.requesterId);
//
//   @override
//   List<Object?> get props => [currentUserId, requesterId];
// }
//
// class LoadFriendsEvent extends HomeEvent {
//   final String userId;
//
//   LoadFriendsEvent(this.userId);
// }
//
// class LoadFriendRequestsEvent extends HomeEvent {
//   final String userId;
//
//   LoadFriendRequestsEvent(this.userId);
// }
//
// class UpdateFriendsEvent extends HomeEvent {
//   final List<AppUser> friends;
//
//   UpdateFriendsEvent(this.friends);
//
//   @override
//   List<Object?> get props => [friends];
// }
//
// class UpdateFriendRequestsEvent extends HomeEvent {
//   final List<AppUser> requests;
//
//   UpdateFriendRequestsEvent(this.requests);
//
//   @override
//   List<Object?> get props => [requests];
// }
