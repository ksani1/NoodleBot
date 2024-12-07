class User {
  final String username;
  final String password;

  User({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    if (json['username'] == null || json['password'] == null) {
      throw ArgumentError('Invalid JSON structure: Missing username or password');
    }

    return User(
      username: json['username'],
      password: json['password'],
    );
  }

  bool isValid() {
    return username.isNotEmpty && password.isNotEmpty;
  }

  bool isPasswordStrong() {
    return password.length >= 8; 
  }
}
