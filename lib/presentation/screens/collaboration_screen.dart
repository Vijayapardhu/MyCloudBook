import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../blocs/collab/collab_bloc.dart';
import '../blocs/chat/chat_bloc.dart';
import '../widgets/presence_avatars.dart';

class CollaborationScreen extends StatefulWidget {
  final String noteId;

  const CollaborationScreen({
    super.key,
    required this.noteId,
  });

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<Map<String, dynamic>> _presences = [];

  @override
  void initState() {
    super.initState();
    // Load collaborators
    context.read<CollabBloc>().add(LoadCollaborators(widget.noteId));
    // Stream chat messages
    context.read<ChatBloc>().add(StreamMessages(widget.noteId));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _inviteCollaborator() async {
    final emailController = TextEditingController();
    String selectedRole = 'viewer';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Collaborator'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  DropdownMenuItem(value: 'commenter', child: Text('Commenter')),
                  DropdownMenuItem(value: 'editor', child: Text('Editor')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value ?? 'viewer';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty) {
      context.read<CollabBloc>().add(
        InviteUser(
          noteId: widget.noteId,
          userEmail: emailController.text.trim(),
          role: selectedRole,
        ),
      );
    }
  }

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    _chatController.clear();
    context.read<ChatBloc>().add(
      SendMessage(
        noteId: widget.noteId,
        message: message,
      ),
    );

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _inviteCollaborator,
            tooltip: 'Invite collaborator',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collaborators section
          BlocBuilder<CollabBloc, CollabState>(
            builder: (context, collabState) {
              if (collabState is CollabLoading) {
                return const LinearProgressIndicator();
              }

              if (collabState is CollabError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Text('Error: ${collabState.message}'),
                );
              }

              if (collabState is CollabLoaded) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collaborators (${collabState.collaborators.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: collabState.collaborators.isEmpty
                            ? const Center(child: Text('No collaborators yet'))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: collabState.collaborators.length,
                                itemBuilder: (context, index) {
                                  final collab = collabState.collaborators[index];
                                  final profile = collab['profiles'] as Map<String, dynamic>?;
                                  final role = collab['role'] as String;
                                  final collaborationId = collab['id'] as String;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      avatar: CircleAvatar(
                                        backgroundImage: profile?['avatar_url'] != null
                                            ? NetworkImage(profile!['avatar_url'] as String)
                                            : null,
                                        child: profile?['avatar_url'] == null
                                            ? Text(
                                                (profile?['full_name'] as String? ??
                                                        profile?['email'] as String? ??
                                                        'U')[0]
                                                    .toUpperCase(),
                                              )
                                            : null,
                                      ),
                                      label: Text(
                                        profile?['full_name'] as String? ??
                                            profile?['email'] as String? ??
                                            'Unknown',
                                      ),
                                      deleteIcon: Tooltip(
                                        message: 'Role: $role',
                                        child: const Icon(Icons.info_outline, size: 16),
                                      ),
                                      onDeleted: () {
                                        context.read<CollabBloc>().add(
                                          RemoveCollaborator(collaborationId),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      PresenceAvatars(presences: _presences),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          const Divider(),

          // Chat section
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, chatState) {
                if (chatState is ChatInitial || chatState is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatState is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${chatState.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(StreamMessages(widget.noteId));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (chatState is ChatLoaded) {
                  if (chatState.messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      final userId = message['user_id'] as String?;
                      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                      final isOwnMessage = userId == currentUserId;
                      final messageText = message['message'] as String? ?? '';
                      final createdAt = message['created_at'] as String?;
                      DateTime? dateTime;
                      if (createdAt != null) {
                        try {
                          dateTime = DateTime.parse(createdAt);
                        } catch (_) {}
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment:
                              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isOwnMessage)
                              CircleAvatar(
                                radius: 16,
                                child: Text(
                                  message['user_id']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                ),
                              ),
                            if (!isOwnMessage) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwnMessage
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      messageText,
                                      style: TextStyle(
                                        color: isOwnMessage
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    if (dateTime != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isOwnMessage
                                              ? Colors.white70
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (isOwnMessage) const SizedBox(width: 8),
                            if (isOwnMessage)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  currentUserId?.substring(0, 1).toUpperCase() ?? 'U',
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Chat input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
