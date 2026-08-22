class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: (json['token_type'] as String?) ?? 'bearer',
      );
}

class AIAnalysisResponse {
  final String id;
  final String characterId;
  final String sourceType;
  final String? sourceId;
  final String content;
  final String modelUsed;
  final DateTime createdAt;

  const AIAnalysisResponse({
    required this.id,
    required this.characterId,
    required this.sourceType,
    this.sourceId,
    required this.content,
    required this.modelUsed,
    required this.createdAt,
  });

  factory AIAnalysisResponse.fromJson(Map<String, dynamic> json) => AIAnalysisResponse(
        id: json['id'] as String,
        characterId: json['character_id'] as String,
        sourceType: json['source_type'] as String,
        sourceId: json['source_id'] as String?,
        content: json['content'] as String,
        modelUsed: json['model_used'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
