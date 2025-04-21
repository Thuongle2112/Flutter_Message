// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../domain/entities/app_user.dart';
// import '../../../domain/usecases/friends/accept_friend_request_usecase.dart';
// import '../../../domain/usecases/friends/get_friend_requests_usecase.dart';
// import '../../../domain/usecases/friends/get_friends_usecase.dart';
// import '../../../domain/usecases/friends/send_friend_request_usecase.dart';
//
// part 'home_event.dart';
// part 'home_state.dart';
//
// class HomeBloc extends Bloc<HomeEvent, HomeState> {
//   final SendFriendRequest sendFriendRequest;
//   final AcceptFriendRequest acceptFriendRequest;
//   final GetFriends getFriends;
//   final GetFriendRequests getFriendRequests;
//
//   HomeBloc({
//     required this.sendFriendRequest,
//     required this.acceptFriendRequest,
//     required this.getFriends,
//     required this.getFriendRequests,
//   }) : super(HomeInitial()) {
//     on<SendFriendRequestEvent>((event, emit) async {
//       await sendFriendRequest(event.currentUserId, event.targetUserId);
//     });
//
//     on<AcceptFriendRequestEvent>((event, emit) async {
//       await acceptFriendRequest(event.currentUserId, event.requesterId);
//     });
//
//     on<LoadFriendsEvent>((event, emit) {
//       emit(FriendsLoading());
//       getFriends(event.userId).listen((friends) {
//         add(UpdateFriendsEvent(friends));
//       });
//     });
//
//     on<LoadFriendRequestsEvent>((event, emit) {
//       emit(FriendRequestsLoading());
//       getFriendRequests(event.userId).listen((requests) {
//         add(UpdateFriendRequestsEvent(requests));
//       });
//     });
//
//     on<UpdateFriendsEvent>((event, emit) {
//       emit(FriendsLoaded(friends: event.friends));
//     });
//
//     on<UpdateFriendRequestsEvent>((event, emit) {
//       emit(FriendRequestsLoaded(requests: event.requests));
//     });
//   }
// }
