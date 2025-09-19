import 'package:flutter/foundation.dart';
import 'package:gad_app_team/models/mongo_service.dart';

class MongoProvider with ChangeNotifier {
  final MongoService _svc = MongoService.instance;

  String? _userId;
  bool _ready = false;
  String _userName = '';
  int _daysSinceJoin = 0;

  bool get isReady => _ready;
  String get userName => _userName;
  int get daysSinceJoin => _daysSinceJoin;

  /// DB 오픈 → 사용자 문서 보장(upsert) → 사용자 정보 로드
  Future<void> init(String userId, {String? defaultName}) async {
    debugPrint('usrId: $userId');
    _userId = userId;
    await _svc.open();
    await _svc.ensureUserDoc(userId: userId, name: defaultName);
    await _loadFromMongo(userId);
    _ready = true;
    notifyListeners();
  }

  Future<void> reload([String? userId]) async {
    final uid = userId ?? _userId;
    if (uid == null) return;
    await _loadFromMongo(uid);
    notifyListeners();
  }

  Future<void> _loadFromMongo(String userId) async {
    final doc = await _svc.fetchUser(userId: userId);
    if (doc == null) {
      _userName = '';
      _daysSinceJoin = 0;
      return;
    }

    final Map<String, dynamic>? user =
      doc['user'] is Map ? Map<String, dynamic>.from(doc['user'] as Map) : null;

    // 이름
    final dynamic nameField = user?['name'];
    _userName = nameField is String ? nameField : '';
    debugPrint('name: $_userName');

    // 가입일(D+1)
    final dynamic rawCreated = user?['createdAt'];
    DateTime? createdAt;
    if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else if (rawCreated is String) {
      try {
        createdAt = DateTime.parse(rawCreated);
      } catch (_) {}
    }
    if (createdAt != null) {
      final now = DateTime.now().toUtc();
      final c = createdAt.toUtc();
      _daysSinceJoin = now.difference(c).inDays + 1;
    } else {
      _daysSinceJoin = 0;
    }
    debugPrint('account_createdAt: $rawCreated');
  }

  @override
  void dispose() {
    _svc.close();
    super.dispose();
  }
}