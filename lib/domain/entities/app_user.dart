import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> friendIds;
  final List<String> friendRequestIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.friendIds = const [],
    this.friendRequestIds = const [],
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    List<String>? friendIds,
    List<String>? friendRequestIds,
  }) {
    return AppUser(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: this.createdAt,
      friendIds: friendIds ?? this.friendIds,
      friendRequestIds: friendRequestIds ?? this.friendRequestIds,
    );
  }

  @override
  List<Object?> get props => [id, name, email, photoUrl, createdAt, friendIds, friendRequestIds];
}