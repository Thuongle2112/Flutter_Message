import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/chat_message/start_chat_with_friend_usecase.dart';
import '../../../domain/usecases/friends/accept_friend_request_usecase.dart';
import '../../../domain/usecases/friends/get_friend_requests_usecase.dart';
import '../../../domain/usecases/friends/get_friends_usecase.dart';
import '../../../domain/usecases/friends/send_friend_request_usecase.dart';
import 'friends_event.dart';
import 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final GetFriendsUseCase getFriends;
  final GetFriendRequestsUseCase getFriendRequests;
  final SendFriendRequestUseCase sendFriendRequest;
  final AcceptFriendRequestUseCase acceptFriendRequest;
  final StartChatWithFriendUseCase startChatWithFriend;
  final FirebaseAuth _firebaseAuth;

  FriendsBloc({
    required this.getFriends,
    required this.getFriendRequests,
    required this.sendFriendRequest,
    required this.acceptFriendRequest,
    required this.startChatWithFriend,
    FirebaseAuth? firebaseAuth,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(FriendsInitial()) {
    on<LoadFriendsEvent>(_onLoadFriends);
    on<LoadFriendRequestsEvent>(_onLoadFriendRequests);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<StartChatEvent>(_onStartChat);
  }

  Future<void> _onLoadFriends(
    LoadFriendsEvent event,
    Emitter<FriendsState> emit,
  ) async {
    emit(FriendsLoading());
    try {
      final friends = await getFriends(event.userId);
      emit(FriendsLoaded(friends));
    } catch (e) {
      emit(FriendsError('Failed to load friends: $e'));
    }
  }

  Future<void> _onLoadFriendRequests(
    LoadFriendRequestsEvent event,
    Emitter<FriendsState> emit,
  ) async {
    emit(FriendsLoading());
    try {
      final requests = await getFriendRequests(event.userId);
      emit(FriendRequestsLoaded(requests));
    } catch (e) {
      emit(FriendsError('Failed to load friend requests: $e'));
    }
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await sendFriendRequest(event.senderId, event.receiverId);
      emit(FriendRequestSent());
    } catch (e) {
      emit(FriendsError('Failed to send friend request: $e'));
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await acceptFriendRequest(event.userId, event.requesterId);
      emit(FriendRequestAccepted());

      // Reload friends list after accepting
      final friends = await getFriends(event.userId);
      emit(FriendsLoaded(friends));
    } catch (e) {
      emit(FriendsError('Failed to accept friend request: $e'));
    }
  }

  Future<void> _onStartChat(
    StartChatEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      // Extract the user ID from the AppUser object
      final friendId = event.friend.id;

      // Get the current user's ID using FirebaseAuth
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId == null) {
        emit(FriendsError('User not logged in.'));
        return;
      }

      // Pass both arguments to startChatWithFriend
      final conversationId = await startChatWithFriend(currentUserId, friendId);
      emit(ChatStarted(event.friend, conversationId));
    } catch (e) {
      emit(FriendsError('Failed to start chat: $e'));
    }
  }
}
