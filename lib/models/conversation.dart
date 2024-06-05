class Conversation {
  final int id;
  final String name;

  const Conversation({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      name: map['name'],
    );
  }
}
