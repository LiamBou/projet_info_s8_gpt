class Suggestion {
  final String username;
  final String description;
  final String date;

  Suggestion(
      {required this.username, required this.description, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'description': description,
      'date': date,
    };
  }

  factory Suggestion.fromMap(Map<String, dynamic> map) {
    return Suggestion(
      username: map['username'],
      description: map['description'],
      date: map['date'],
    );
  }
}
