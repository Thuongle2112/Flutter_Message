import '../../entities/app_user.dart';
import '../../repositories/user_repository.dart';

class GetFriendsUseCase {
  final UserRepository repository;

  GetFriendsUseCase(this.repository);

  Future<List<AppUser>> call(String userId) async {
    return await repository.getFriends(userId);
  }
}