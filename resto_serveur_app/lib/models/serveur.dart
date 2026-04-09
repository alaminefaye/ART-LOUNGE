/// Model representing a waiter/server user
class Serveur {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;
  final bool hasPin;

  Serveur({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.roles = const [],
    this.hasPin = false,
  });

  factory Serveur.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    List<String> rolesList = [];
    if (json['roles'] != null) {
      final roles = json['roles'];
      if (roles is List) {
        for (var role in roles) {
          if (role is String) {
            rolesList.add(role);
          } else if (role is Map && role['name'] != null) {
            rolesList.add(role['name'] as String);
          }
        }
      }
    }

    return Serveur(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roles: rolesList,
      hasPin: json['has_pin'] as bool? ?? false,
    );
  }

  /// Returns a copy with updated hasPin value
  Serveur copyWith({bool? hasPin}) {
    return Serveur(
      id: id,
      name: name,
      email: email,
      phone: phone,
      roles: roles,
      hasPin: hasPin ?? this.hasPin,
    );
  }

  bool hasRole(String role) => roles.contains(role);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
