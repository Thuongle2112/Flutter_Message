import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/conversation.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/conversation_item.dart';
import '../chat/chat_screen.dart';
import '../friends/friends_screen.dart';
import '../login/login_screen.dart';
import '../profile/profile_screen.dart';
import '../search/user_search_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _hasLoaded = false; // tránh gọi nhiều lần

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
        }

        if (authState is Authenticated && !_hasLoaded) {
          context.read<ChatBloc>().add(LoadConversationsEvent(authState.user.id));
          _hasLoaded = true;
        }
      },
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Conversations'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UserSearchScreen(),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: authState.user),
                      ),
                    );
                  } else if (value == 'logout') {
                    context.read<AuthBloc>().add(LogoutEvent());
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text('Profile'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is ChatLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is ChatConversationsLoaded) {
                if (state.conversations.isEmpty) {
                  return const Center(
                    child: Text('No conversations yet'),
                  );
                }

                return ListView.builder(
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    return ConversationItem(
                      conversation: conversation,
                      currentUserId: authState.user.id,
                      onTap: () => _openChat(conversation),
                    );
                  },
                );
              } else if (state is ChatError) {
                return Center(
                  child: Text('Error: ${state.message}'),
                );
              }

              return const Center(
                child: Text('No conversations available'),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FriendsScreen(),
                ),
              );
            },
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  void _openChat(Conversation conversation) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ChatBloc>().add(
        MarkConversationReadEvent(conversation.id),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            currentUserId: authState.user.id,
          ),
        ),
      );
    }
  }
}
