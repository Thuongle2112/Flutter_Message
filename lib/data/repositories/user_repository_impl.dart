import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase/user_datasource.dart';
import '../models/app_user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<AppUser?> getUserById(String userId) async {
    return await dataSource.getUserById(userId);
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    return await dataSource.searchUsers(query);
  }

  @override
  Future<List<AppUser>> getFriends(String userId) async {
    return await dataSource.getFriends(userId);
  }

  @override
  Future<List<AppUser>> getFriendRequests(String userId) async {
    return await dataSource.getFriendRequests(userId);
  }

  @override
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    await dataSource.sendFriendRequest(senderId, receiverId);
  }

  @override
  Future<void> acceptFriendRequest(String userId, String requesterId) async {
    await dataSource.acceptFriendRequest(userId, requesterId);
  }

  @override
  Future<void> updateUser(AppUser user) async {
    // Convert to AppUserModel if not already
    final userModel = user is AppUserModel
        ? user
        : AppUserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      friendIds: user.friendIds,
      friendRequestIds: user.friendRequestIds,
    );

    await dataSource.updateUser(userModel);
  }
}