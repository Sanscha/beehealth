class UserProfile {
  final String email;
  final String username;
  final String firstName;
  final String lastName;

  UserProfile({
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      email: map['email'],
      username: map['username'],
      firstName: map['firstName'],
      lastName: map['lastName'],
    );
  }
}