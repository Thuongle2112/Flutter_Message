import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.createdAt,
    super.friendIds,
    super.friendRequestIds,
  });

  factory AppUserModel.fromEntity(AppUser user) {
    return AppUserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      friendIds: user.friendIds,
      friendRequestIds: user.friendRequestIds,
    );
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt']
              : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
          : DateTime.now(),
      friendIds:
          map['friendIds'] != null ? List<String>.from(map['friendIds']) : [],
      friendRequestIds: map['friendRequestIds'] != null
          ? List<String>.from(map['friendRequestIds'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'friendIds': friendIds,
      'friendRequestIds': friendRequestIds,
    };
  }

  AppUserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    List<String>? friendIds,
    List<String>? friendRequestIds,
  }) {
    return AppUserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      friendIds: friendIds ?? this.friendIds,
      friendRequestIds: friendRequestIds ?? this.friendRequestIds,
    );
  }
}
