class Conversation {
  int? id;
  late final String name;
  bool? selected;

  Conversation({
    this.id,
    required this.name,
    required this.selected,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'selected': selected,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      name: map['name'],
      selected: map['selected'] == 1,
    );
  }
}
