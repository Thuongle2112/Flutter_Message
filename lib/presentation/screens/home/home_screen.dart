// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../../../domain/entities/app_user.dart';
// import '../../blocs/home/home_bloc.dart';
// import '../chat/chat_screen.dart';
// import '../login/login_screen.dart';
//
// class HomeScreen extends StatefulWidget {
//   final AppUser user;
//
//   const HomeScreen({super.key, required this.user});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final _controller = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     final bloc = context.read<HomeBloc>();
//     bloc.add(LoadFriendsEvent(widget.user.uid));
//     bloc.add(LoadFriendRequestsEvent(widget.user.uid));
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _sendFriendRequest() {
//     final targetId = _controller.text.trim();
//     if (targetId.isNotEmpty) {
//       context.read<HomeBloc>().add(
//             SendFriendRequestEvent(widget.user.uid, targetId),
//           );
//       _controller.clear();
//     }
//   }
//
//   void _logout() async {
//     await FirebaseAuth.instance.signOut();
//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (route) => false,
//     );
//   }
//
//   String _getConversationId(String userId1, String userId2) {
//     final ids = [userId1, userId2]..sort();
//     return ids.join('_');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Xin chào ${widget.user.email}'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//           )
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Gửi yêu cầu kết bạn
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       labelText: 'Nhập UID hoặc Email',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.person_add),
//                   onPressed: _sendFriendRequest,
//                 )
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             // Danh sách yêu cầu kết bạn
//             BlocBuilder<HomeBloc, HomeState>(
//               buildWhen: (prev, curr) =>
//                   curr is FriendRequestsLoaded || curr is FriendRequestsLoading,
//               builder: (context, state) {
//                 if (state is FriendRequestsLoading) {
//                   return const CircularProgressIndicator();
//                 } else if (state is FriendRequestsLoaded) {
//                   if (state.requests.isEmpty) {
//                     return const Text("Không có yêu cầu kết bạn");
//                   }
//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Yêu cầu kết bạn:",
//                           style: TextStyle(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 8),
//                       ...state.requests.map(
//                         (user) => ListTile(
//                           leading: const Icon(Icons.person),
//                           title: Text(user.email),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.check),
//                             onPressed: () {
//                               context.read<HomeBloc>().add(
//                                     AcceptFriendRequestEvent(
//                                         widget.user.uid, user.uid),
//                                   );
//                             },
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//             const SizedBox(height: 20),
//
//             // Danh sách bạn bè
//             Expanded(
//               child: BlocBuilder<HomeBloc, HomeState>(
//                 buildWhen: (prev, curr) =>
//                     curr is FriendsLoaded || curr is FriendsLoading,
//                 builder: (context, state) {
//                   if (state is FriendsLoading) {
//                     return const Center(child: CircularProgressIndicator());
//                   } else if (state is FriendsLoaded) {
//                     if (state.friends.isEmpty) {
//                       return const Center(
//                           child: Text("Bạn chưa có bạn bè nào."));
//                     }
//                     return ListView.builder(
//                       itemCount: state.friends.length,
//                       itemBuilder: (context, index) {
//                         final friend = state.friends[index];
//                         return ListTile(
//                           leading: const Icon(Icons.person),
//                           title: Text(friend.email),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.chat),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => ChatScreen(
//                                     friendId: friend.uid,
//                                     friendName: friend.email,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         );
//                       },
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
