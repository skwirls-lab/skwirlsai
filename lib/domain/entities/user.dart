class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  factory AppUser.anonymous() => const AppUser(
        id: 'anonymous',
        email: '',
        displayName: 'Local User',
        isAnonymous: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isAnonymous': isAnonymous,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
        isAnonymous: json['isAnonymous'] as bool? ?? false,
      );
}
