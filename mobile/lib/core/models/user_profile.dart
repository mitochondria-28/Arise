class UserProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String timezone;
  final String themePreference;

  const UserProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.timezone,
    required this.themePreference,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        timezone: json['timezone'] as String? ?? 'UTC',
        themePreference: json['theme_preference'] as String? ?? 'system',
      );
}

class MeResponse {
  final String id;
  final String email;
  final bool isActive;
  final bool isVerified;
  final String createdAt;
  final UserProfileModel? profile;

  const MeResponse({
    required this.id,
    required this.email,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    this.profile,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
        id: json['id'] as String,
        email: json['email'] as String,
        isActive: json['is_active'] as bool? ?? true,
        isVerified: json['is_verified'] as bool? ?? false,
        createdAt: json['created_at'] as String,
        profile: json['profile'] == null
            ? null
            : UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      );
}
