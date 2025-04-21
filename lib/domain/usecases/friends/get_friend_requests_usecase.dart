import '../../entities/app_user.dart';
import '../../repositories/user_repository.dart';

class GetFriendRequestsUseCase {
  final UserRepository repository;

  GetFriendRequestsUseCase(this.repository);

  Future<List<AppUser>> call(String userId) async {
    return await repository.getFriendRequests(userId);
  }
}