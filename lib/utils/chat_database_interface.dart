import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:projet_info_s8_gpt/models/chat.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';

class ChatDatabaseInterface {
  static final ChatDatabaseInterface instance =
      ChatDatabaseInterface._internal();

  static Database? _database;
  ChatDatabaseInterface._internal();

  static const String databaseName = 'chat.db';

  static const int versionNumber = 1;

  static const String colId = 'id';

  static const String chatTableName = 'Chat';
  static const String colMessage = 'message';
  static const String colIsUser = 'isUser';
  static const String colConversationId = 'conversationId';
  static const String colSentAt = 'sentAt';

  static const String conversationTableName = 'Conversation';
  static const String colName = 'name';

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    String path = join(await getDatabasesPath(), databaseName);
    // When the database is first created, create a table to store Notes.
    var db = await openDatabase(
      path,
      version: versionNumber,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return db;
  }

  _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $conversationTableName (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $chatTableName (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colMessage TEXT NOT NULL,
        $colIsUser INTEGER NOT NULL,
        $colConversationId INTEGER NOT NULL,
        $colSentAt TEXT NOT NULL,
        FOREIGN KEY ($colConversationId) REFERENCES $conversationTableName($colId) ON DELETE CASCADE
      )
    ''');

    // Insert default conversation
    await db.insert(
      conversationTableName,
      const Conversation(id: 0, name: 'Conversation').toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('''
        DROP TABLE IF EXISTS $chatTableName
      ''');

      await db.execute('''
        DROP TABLE IF EXISTS $conversationTableName
      ''');
      await _onCreate(db, newVersion);
    }
  }

  Future<List<Chat>> get chats async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(chatTableName);

    return maps.map((e) => Chat.fromMap(e)).toList();
  }

  Future<List<Chat>> chatsByConversation(String conversationId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      chatTableName,
      where: '$colConversationId = ?',
      whereArgs: [conversationId],
    );

    return maps.map((e) => Chat.fromMap(e)).toList();
  }

  Future<int> insertChat(Chat chat) async {
    final Database db = await database;
    return await db.insert(
      chatTableName,
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateChat(Chat chat) async {
    final Database db = await database;
    return await db.update(
      chatTableName,
      chat.toMap(),
      where: '$colId = ?',
      whereArgs: [chat.id],
    );
  }

  Future<int> deleteChat(int id) async {
    final Database db = await database;
    return await db.delete(
      chatTableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChatsByConversation(String conversationId) async {
    final Database db = await database;
    return await db.delete(
      chatTableName,
      where: '$colConversationId = ?',
      whereArgs: [conversationId],
    );
  }

  Future<List<Conversation>> get conversations async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(conversationTableName, orderBy: '$colId ASC');

    return maps.map((e) => Conversation.fromMap(e)).toList();
  }

  Future<int> insertConversation(Conversation conversation) async {
    final Database db = await database;
    return await db.insert(
      conversationTableName,
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateConversation(Conversation conversation) async {
    final Database db = await database;
    return await db.update(
      conversationTableName,
      conversation.toMap(),
      where: '$colId = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<int> deleteConversation(int id) async {
    final Database db = await database;
    return await db.delete(
      conversationTableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }
}
