class AuthUser {
  const AuthUser({
    this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
  });

  final String? id;
  final String email;
  final String firstName;
  final String lastName;

  String get fullName {
    final parts = [firstName, lastName].where((value) => value.trim().isNotEmpty);
    return parts.join(' ');
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final emailValue = json['email'] ?? json['mail'] ?? '';
    final firstNameValue = json['meno'] ?? json['firstName'] ?? '';
    final lastNameValue = json['priezvisko'] ?? json['lastName'] ?? '';

    return AuthUser(
      id: json['id']?.toString(),
      email: emailValue.toString(),
      firstName: firstNameValue.toString(),
      lastName: lastNameValue.toString(),
    );
  }
}
