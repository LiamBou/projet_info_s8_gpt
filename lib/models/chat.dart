class Chat {
  final int id;
  final int conversationId;
  final String message;
  final String sentAt;
  final bool isUser;

  const Chat(
      {required this.id,
      required this.conversationId,
      required this.message,
      required this.sentAt,
      required this.isUser});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'message': message,
      'sentAt': sentAt,
      'isUser': isUser ? 1 : 0,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      conversationId: map['conversationId'],
      message: map['message'],
      isUser: map['isUser'] == 1,
      sentAt: map['sentAt'],
    );
  }
}
