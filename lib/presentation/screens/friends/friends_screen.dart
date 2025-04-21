import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/friends/friends_bloc.dart';
import '../../blocs/friends/friends_event.dart';
import '../../blocs/friends/friends_state.dart';
import '../../widgets/friend_item.dart';
import '../chat/chat_screen.dart';
import 'friend_requests_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<FriendsBloc>().add(LoadFriendsEvent(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FriendRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<FriendsBloc, FriendsState>(
        listener: (context, state) {
          if (state is FriendsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ChatStarted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: state.conversationId,
                  currentUserId: authState.user.id,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FriendsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is FriendsLoaded) {
            if (state.friends.isEmpty) {
              return const Center(
                child: Text('No friends yet. Add some!'),
              );
            }

            return ListView.builder(
              itemCount: state.friends.length,
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                return FriendItem(
                  user: friend,
                  onTap: () {
                    context.read<FriendsBloc>().add(StartChatEvent(friend));
                  },
                );
              },
            );
          }

          return const Center(
            child: Text('No friends available'),
          );
        },
      ),
    );
  }
}
