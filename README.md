lib/
│
├── domain/                         # Domain Layer
│   ├── entities/                   # Enterprise business rules
│   │   ├── app_user.dart           # User entity
│   │   ├── message.dart            # Message entity
│   │   └── conversation.dart       # Conversation entity
│   │
│   ├── repositories/               # Repository interfaces
│   │   ├── auth_repository.dart    # Auth operations interface
│   │   ├── user_repository.dart    # User operations interface
│   │   └── message_repository.dart # Message operations interface
│   │
│   └── usecases/                   # Application business rules
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   ├── register_usecase.dart
│       │   ├── logout_usecase.dart
│       │   └── get_current_user_usecase.dart
│       │
│       ├── friends/
│       │   ├── get_friends_usecase.dart
│       │   ├── get_friend_requests_usecase.dart
│       │   ├── send_friend_request_usecase.dart
│       │   └── accept_friend_request_usecase.dart
│       │
│       └── chat_message/
│           ├── get_messages_usecase.dart
│           ├── send_message_usecase.dart
│           ├── get_conversations_usecase.dart
│           ├── mark_conversation_read_usecase.dart
│           └── start_chat_with_friend_usecase.dart
│
├── data/                           # Data Layer
│   ├── models/                     # Data models extending entities
│   │   ├── app_user_model.dart
│   │   ├── message_model.dart
│   │   └── conversation_model.dart
│   │
│   ├── repositories/               # Implementation of domain repositories
│   │   ├── auth_repository_impl.dart
│   │   ├── user_repository_impl.dart
│   │   └── message_repository_impl.dart
│   │
│   └── datasources/                # Data sources for fetching data
│       ├── firebase/
│       │   ├── auth_datasource.dart       # Firebase auth interface
│       │   ├── auth_datasource_impl.dart  # Implementation
│       │   ├── user_datasource.dart       # Firebase user data interface
│       │   ├── user_datasource_impl.dart  # Implementation
│       │   ├── agora_chat_datasource.dart # Agora Chat interface
│       │   └── agora_chat_datasource_impl.dart # Implementation
│       └── local/
│           └── local_storage_datasource.dart # Local storage if needed
│
├── presentation/                  # Presentation Layer
│   ├── blocs/                     # BLoC state management
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   │
│   │   ├── user/
│   │   │   ├── user_bloc.dart
│   │   │   ├── user_event.dart
│   │   │   └── user_state.dart
│   │   │
│   │   ├── friends/
│   │   │   ├── friends_bloc.dart
│   │   │   ├── friends_event.dart
│   │   │   └── friends_state.dart
│   │   │
│   │   └── chat/
│   │       ├── chat_bloc.dart
│   │       ├── chat_event.dart
│   │       └── chat_state.dart
│   │
│   ├── screens/                   # UI screens
│   │   ├── login/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   │
│   │   ├── friends/
│   │   │   ├── friends_screen.dart
│   │   │   └── friend_requests_screen.dart
│   │   │
│   │   ├── search/
│   │   │   └── user_search_screen.dart
│   │   │
│   │   ├── conversation/
│   │   │   └── conversations_screen.dart
│   │   │
│   │   └── chat/
│   │       ├── chat_screen.dart
│   │       └── voice_message_recorder.dart
│   │
│   └── widgets/                   # Reusable UI components
│       ├── message_bubble.dart
│       ├── user_avatar.dart
│       ├── friend_item.dart
│       ├── conversation_item.dart
│       └── voice_player.dart
│
├── core/                          # Core functionality
│   ├── constants/
│   │   └── app_constants.dart     # App-wide constants
│   │
│   ├── errors/
│   │   ├── failures.dart          # Domain failures
│   │   └── exceptions.dart        # Data exceptions
│   │
│   ├── network/
│   │   └── network_info.dart      # Network connectivity
│   │
│   └── usecase/
│       └── usecase.dart           # Base usecase interface
│
├── di/                            # Dependency injection
│   └── injection.dart             # Service locator setup
│
├── config/                        # App configuration
│   ├── routes.dart                # App navigation routes
│   ├── theme.dart                 # App theme
│   └── agora_config.dart          # Agora SDK configuration
│
└── main.dart                      # Entry point