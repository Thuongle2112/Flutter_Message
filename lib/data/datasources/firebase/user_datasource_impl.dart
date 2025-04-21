import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/app_user.dart';
import '../../models/app_user_model.dart';
import 'user_datasource.dart';

class UserDataSourceImpl implements UserDataSource {
  final FirebaseFirestore _firestore;

  UserDataSourceImpl(this._firestore);

  @override
  Future<AppUser?> getUserById(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      return AppUserModel.fromMap({
        ...docSnapshot.data()!,
        'id': userId,
      });
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      // Search by name or email
      final nameQuerySnapshot = await _firestore.collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      final emailQuerySnapshot = await _firestore.collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      final results = [...nameQuerySnapshot.docs, ...emailQuerySnapshot.docs]
          .map((doc) => AppUserModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      }))
          .toList();

      // Remove duplicates
      final uniqueResults = <AppUser>[];
      final ids = <String>{};

      for (var user in results) {
        if (!ids.contains(user.id)) {
          uniqueResults.add(user);
          ids.add(user.id);
        }
      }

      return uniqueResults;
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  @override
  Future<List<AppUser>> getFriends(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return [];
      }

      final user = AppUserModel.fromMap({
        ...userDoc.data()!,
        'id': userId,
      });

      if (user.friendIds.isEmpty) {
        return [];
      }

      // Get all friends at once
      final friendDocs = await _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: user.friendIds)
          .get();

      return friendDocs.docs
          .map((doc) => AppUserModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      }))
          .toList();
    } catch (e) {
      throw Exception('Error getting friends: $e');
    }
  }

  @override
  Future<List<AppUser>> getFriendRequests(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return [];
      }

      final user = AppUserModel.fromMap({
        ...userDoc.data()!,
        'id': userId,
      });

      if (user.friendRequestIds.isEmpty) {
        return [];
      }

      // Get all requesters at once
      final requesterDocs = await _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: user.friendRequestIds)
          .get();

      return requesterDocs.docs
          .map((doc) => AppUserModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      }))
          .toList();
    } catch (e) {
      throw Exception('Error getting friend requests: $e');
    }
  }

  @override
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // First check if already friends
      final receiver = await getUserById(receiverId);
      if (receiver == null) {
        throw Exception('Receiver user not found');
      }

      if (receiver.friendIds.contains(senderId)) {
        throw Exception('You are already friends with this user');
      }

      if (receiver.friendRequestIds.contains(senderId)) {
        throw Exception('Friend request already sent');
      }

      // Add sender to receiver's friend requests
      await _firestore.collection('users').doc(receiverId).update({
        'friendRequestIds': FieldValue.arrayUnion([senderId])
      });
    } catch (e) {
      throw Exception('Error sending friend request: $e');
    }
  }

  @override
  Future<void> acceptFriendRequest(String userId, String requesterId) async {
    try {
      // Use transaction to ensure both updates happen or neither does
      await _firestore.runTransaction((transaction) async {
        // Add each user to the other's friends
        final userRef = _firestore.collection('users').doc(userId);
        final requesterRef = _firestore.collection('users').doc(requesterId);

        final userDoc = await transaction.get(userRef);
        final requesterDoc = await transaction.get(requesterRef);

        if (!userDoc.exists || !requesterDoc.exists) {
          throw Exception('One or both users do not exist');
        }

        // Add to friends lists
        transaction.update(userRef, {
          'friendIds': FieldValue.arrayUnion([requesterId]),
          'friendRequestIds': FieldValue.arrayRemove([requesterId])
        });

        transaction.update(requesterRef, {
          'friendIds': FieldValue.arrayUnion([userId])
        });
      });
    } catch (e) {
      throw Exception('Error accepting friend request: $e');
    }
  }

  @override
  Future<void> updateUser(AppUser user) async {
    try {
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

      await _firestore.collection('users').doc(user.id).update(userModel.toMap());
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }
}