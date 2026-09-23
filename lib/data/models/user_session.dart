import 'package:equatable/equatable.dart';

class UserSession extends Equatable {
  final int uid;
  final String name;
  final String login;
  final String baseUrl;
  final String database;

  final bool isInternalUser;

  const UserSession({
    required this.uid,
    required this.name,
    required this.login,
    required this.baseUrl,
    required this.database,
    required this.isInternalUser,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    uid: json['uid'] as int,
    name: json['name'] as String,
    login: json['login'] as String,
    baseUrl: json['baseUrl'] as String,
    database: json['database'] as String,
    isInternalUser: json['isInternalUser'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'login': login,
    'baseUrl': baseUrl,
    'database': database,
    'isInternalUser': isInternalUser,
  };

  @override
  List<Object?> get props => [uid, name, login, baseUrl, database, isInternalUser];
}
