import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/agora_config.dart';
import '../data/datasources/firebase/agora_chat_datasource.dart';
import '../data/datasources/firebase/agora_chat_datasource_impl.dart';
import '../data/datasources/firebase/auth_datasource.dart';
import '../data/datasources/firebase/auth_datasource_impl.dart';
import '../data/datasources/firebase/user_datasource.dart';
import '../data/datasources/firebase/user_datasource_impl.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/message_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';

import '../data/services/agora_chat_rest_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/message_repository.dart';
import '../domain/repositories/user_repository.dart';

import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';

import '../domain/usecases/chat_message/get_conversations_usecase.dart';
import '../domain/usecases/chat_message/get_messages_usecase.dart';
import '../domain/usecases/chat_message/mark_conversation_read_usecase.dart';
import '../domain/usecases/chat_message/send_message_usecase.dart';
import '../domain/usecases/chat_message/start_chat_with_friend_usecase.dart';

import '../domain/usecases/friends/accept_friend_request_usecase.dart';
import '../domain/usecases/friends/get_friend_requests_usecase.dart';
import '../domain/usecases/friends/get_friends_usecase.dart';
import '../domain/usecases/friends/send_friend_request_usecase.dart';

import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/chat/chat_bloc.dart';
import '../presentation/blocs/friends/friends_bloc.dart';
import '../presentation/blocs/user/user_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  //=========================================================================
  // External Dependencies
  //=========================================================================
  // Firebase
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  //=========================================================================
  // Services
  //=========================================================================
  // Đăng ký AgoraChatRESTService trước khi sử dụng nó
  sl.registerLazySingleton(() => AgoraChatRESTService());

  //=========================================================================
  // Data Sources
  //=========================================================================
  // Auth
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(sl<FirebaseAuth>()),
  );

  // User
  sl.registerLazySingleton<UserDataSource>(
    () => UserDataSourceImpl(sl<FirebaseFirestore>()),
  );

  // Agora Chat - Chỉ đăng ký MỘT lần
  sl.registerLazySingleton<AgoraChatDataSource>(
    () => AgoraChatDataSourceImpl(
      appKey: AgoraConfig.appKey,
      restService: sl<AgoraChatRESTService>(),
    ),
  );

  //=========================================================================
  // Repositories
  //=========================================================================
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthDataSource>()),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<UserDataSource>()),
  );

  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(chatDataSource: sl<AgoraChatDataSource>()),
  );

  //=========================================================================
  // Use Cases
  //=========================================================================
  // Auth Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));

  // Friend Use Cases
  sl.registerLazySingleton(() => GetFriendsUseCase(sl<UserRepository>()));
  sl.registerLazySingleton(
      () => GetFriendRequestsUseCase(sl<UserRepository>()));
  sl.registerLazySingleton(
      () => SendFriendRequestUseCase(sl<UserRepository>()));
  sl.registerLazySingleton(
      () => AcceptFriendRequestUseCase(sl<UserRepository>()));

  // Message Use Cases
  sl.registerLazySingleton(() => GetMessagesUseCase(sl<MessageRepository>()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl<MessageRepository>()));
  sl.registerLazySingleton(
      () => GetConversationsUseCase(sl<MessageRepository>()));
  sl.registerLazySingleton(
      () => MarkConversationReadUseCase(sl<MessageRepository>()));
  sl.registerLazySingleton(
      () => StartChatWithFriendUseCase(sl<MessageRepository>()));

  //=========================================================================
  // BLoCs
  //=========================================================================
  sl.registerFactory(
    () => AuthBloc(
      login: sl<LoginUseCase>(),
      register: sl<RegisterUseCase>(),
      logout: sl<LogoutUseCase>(),
      getCurrentUser: sl<GetCurrentUserUseCase>(),
    ),
  );

  sl.registerFactory(
    () => UserBloc(
      userRepository: sl<UserRepository>(),
    ),
  );

  sl.registerFactory(
    () => FriendsBloc(
      getFriends: sl<GetFriendsUseCase>(),
      getFriendRequests: sl<GetFriendRequestsUseCase>(),
      sendFriendRequest: sl<SendFriendRequestUseCase>(),
      acceptFriendRequest: sl<AcceptFriendRequestUseCase>(),
      startChatWithFriend: sl<StartChatWithFriendUseCase>(),
    ),
  );

  sl.registerFactory(
    () => ChatBloc(
      getMessages: sl<GetMessagesUseCase>(),
      sendMessage: sl<SendMessageUseCase>(),
      getConversations: sl<GetConversationsUseCase>(),
      markConversationRead: sl<MarkConversationReadUseCase>(),
      authBloc: sl<AuthBloc>(),
      messageRepository: sl<MessageRepository>(),
    ),
  );
}
