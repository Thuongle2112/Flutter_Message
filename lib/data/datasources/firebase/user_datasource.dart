import '../../../domain/entities/app_user.dart';

abstract class UserDataSource {
  Future<AppUser?> getUserById(String userId);
  Future<List<AppUser>> searchUsers(String query);
  Future<List<AppUser>> getFriends(String userId);
  Future<List<AppUser>> getFriendRequests(String userId);
  Future<void> sendFriendRequest(String senderId, String receiverId);
  Future<void> acceptFriendRequest(String userId, String requesterId);
  Future<void> updateUser(AppUser user);
}