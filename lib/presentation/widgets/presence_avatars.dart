import 'package:flutter/material.dart';

/// Presence avatars widget showing active collaborators
class PresenceAvatars extends StatelessWidget {
  final List<Map<String, dynamic>> presences;
  final Function(String userId)? onAvatarTap;

  const PresenceAvatars({
    super.key,
    required this.presences,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    if (presences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const Text('Active: '),
        const SizedBox(width: 8),
        ...presences.map((presence) {
          final userId = presence['user_id'] as String? ?? '';
          final avatarUrl = presence['avatar_url'] as String?;
          final fullName = presence['full_name'] as String? ?? 'U';

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: onAvatarTap != null ? () => onAvatarTap!(userId) : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(fullName[0].toUpperCase())
                        : null,
                  ),
                  // Online indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

