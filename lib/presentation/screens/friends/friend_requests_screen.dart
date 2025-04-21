import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/friends/friends_bloc.dart';
import '../../blocs/friends/friends_event.dart';
import '../../blocs/friends/friends_state.dart';
import '../../widgets/user_avatar.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<FriendsBloc>().add(LoadFriendRequestsEvent(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view friend requests'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: BlocConsumer<FriendsBloc, FriendsState>(
        listener: (context, state) {
          if (state is FriendsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is FriendRequestAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request accepted!')),
            );
            // Reload friend requests list
            context.read<FriendsBloc>().add(LoadFriendRequestsEvent(authState.user.id));
          }
        },
        builder: (context, state) {
          if (state is FriendsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is FriendRequestsLoaded) {
            if (state.requesters.isEmpty) {
              return const Center(
                child: Text('No friend requests at the moment'),
              );
            }

            return ListView.builder(
              itemCount: state.requesters.length,
              itemBuilder: (context, index) {
                final requester = state.requesters[index];
                return _buildFriendRequestItem(requester, authState.user.id);
              },
            );
          }

          return const Center(
            child: Text('Unable to load friend requests'),
          );
        },
      ),
    );
  }

  Widget _buildFriendRequestItem(AppUser requester, String currentUserId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: UserAvatar(
          photoUrl: requester.photoUrl,
          username: requester.name,
        ),
        title: Text(requester.name),
        subtitle: Text(requester.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(requester.id, currentUserId),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _declineRequest(requester.id),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRequest(String requesterId, String currentUserId) {
    context.read<FriendsBloc>().add(
      AcceptFriendRequestEvent(currentUserId, requesterId),
    );
  }

  void _declineRequest(String requesterId) {
    // You would need to implement this functionality
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Decline functionality not implemented yet')),
    );
  }
}