import 'dart:math';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// MongoService
/// -------------
/// mongo_dart 기반의 간단한 래퍼입니다. 연결 관리/컬렉션 핸들/도메인 유틸을
/// 한 곳에서 관리하여 앱 코드의 의존성을 줄입니다.
///
/// 포함 기능
/// - 연결(URI 구성 + TLS 옵션) 및 users 컬렉션 핸들 보관
/// - 사용자 조회/생성/필드 업데이트
/// - Custom ABC Chip 읽기/추가/삭제 (연속 번호 seq 관리 포함)
/// - ABC Model(일기) 삽입 및 그룹 업데이트
class MongoService {
  Db? _db;
  DbCollection? _users;

  MongoService._();
  static final MongoService instance = MongoService._();
  
  static final String _envUrl = dotenv.env['MONGO_URL'] ?? '';
  static final String _envTlsInsecure = dotenv.env['MONGO_TLS_INSECURE'] ?? 'false';

  /// 접속 URI 구성
  /// - 기본은 SRV 문자열 사용
  /// - 명시적으로 tls=true (필요 시 tlsAllowInvalidCertificates) 부여
  static String _buildUri() {
    final base = _envUrl.isNotEmpty
        ? _envUrl
        : '';

    final sep = base.contains('?') ? '&' : '?';
    final insecure = _envTlsInsecure.toLowerCase() == 'true';
    final tlsParams =
        'tls=true${insecure ? '&tlsAllowInvalidCertificates=true' : ''}';

    return '$base$sep$tlsParams';
  }

  /// DB 연결을 보장합니다. 이미 연결되어 있다면 재사용합니다.
  Future<void> _ensureOpen() async {
    if (_db != null && _db!.isConnected) return;

    // 이전 세션이 남아있다면 안전 종료
    try {
      await _db?.close();
    } catch (_) {}

    final db = await Db.create(_buildUri());
    try {
      await db.open();
    } on ConnectionException catch (_) {
      rethrow; // 상위에서 처리
    }

    _db = db;
    _users = db.collection('users');

    // (선택) 인덱스 — 실패해도 앱 동작에는 영향 없음
    try {
      await _users!.createIndex(keys: {'email': 1}, unique: true);
      // 배열 내부 필드는 별도 인덱스 불필요
    } catch (_) {}
  }

  // ===== 내부 유틸 =====

  /// 사용자 키 정규화: 24-hex면 ObjectId, 아니면 문자열 그대로 반환
  dynamic _userKey(String userId) {
    final isHex24 =
        userId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(userId);
    return isHex24 ? ObjectId.fromHexString(userId) : userId;
  }

  Future<void> appendScreenTime({
    required String userId,
    required DateTime startTime,
    DateTime? backgroundStart,
    DateTime? backgroundEnd,
    required DateTime endTime,
    required double durationMinutes,
  }) async {
    await ensureUserDoc(userId: userId);
    await _ensureOpen();
    final key = _userKey(userId);
    final entry = <String, dynamic>{
      'startTime': startTime.toUtc(),
      'endTime': endTime.toUtc(),
      'durationMinutes': durationMinutes,
    };
    if (backgroundStart != null) {
      entry['backgroundStart'] = backgroundStart.toUtc();
    }
    if (backgroundEnd != null) {
      entry['backgroundEnd'] = backgroundEnd.toUtc();
    }
    await _users!.updateOne(
      where.eq('_id', key),
      ModifierBuilder().push('user.screenTime', entry),
    ); 
  }


  /// CustomChip 카운터 필드명 (타입별)
  String _customChipCounterField(String type) => 'seq_customTags_$type';

  /// CustomChip 기본 ID 생성 규칙 (예: a001, ce012)
  String _customChipId(String type, int seq) =>
      '$type${seq.toString().padLeft(3, '0')}';

  int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// chip의 seq를 다양한 필드에서 추론합니다.
  int _chipSeq(Map<String, dynamic> chip) {
    final seqValue = chip['seq'];
    final seq = _intFrom(seqValue);
    if (seq > 0) return seq;

    final idValue = chip['tagId'] ?? chip['id'];
    if (idValue is String) {
      final match = RegExp(r'(\d+)$').firstMatch(idValue);
      if (match != null) return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  /// 문서에서 custom chip 배열들을 평탄화 추출
  List<Map<String, dynamic>> _customChipsFromDoc(Map<String, dynamic>? doc) {
    if (doc == null) return const [];
    final result = <Map<String, dynamic>>[];

    void collect(dynamic raw) {
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            result.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    collect(doc['customTags']);
    collect(doc['custom_abc_chips']);

    final rawUser = doc['user'];
    if (rawUser is Map) {
      final userMap = Map<String, dynamic>.from(rawUser);
      collect(userMap['customTags']);
      collect(userMap['custom_abc_chips']);
    }

    return result;
  }

  int _maxSeqFromChips(List<Map<String, dynamic>> chips, {String? type}) {
    int maxSeq = 0;
    for (final chip in chips) {
      if (type != null) {
        final chipType = chip['type']?.toString().toLowerCase();
        if (chipType != type.toLowerCase()) continue;
      }
      maxSeq = max(maxSeq, _chipSeq(chip));
    }
    return maxSeq;
  }

  int _maxSeqFromDiaries(dynamic diaries) {
    if (diaries is! List) return 0;
    int maxSeq = 0;
    for (final item in diaries) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final seqField = map['seq'];
      final seqNum = _intFrom(seqField);
      maxSeq = max(maxSeq, seqNum);

      final extId = map['externalId'];
      if (extId is String) {
        final match = RegExp(r'(\d+)$').firstMatch(extId);
        if (match != null) {
          final parsed = int.tryParse(match.group(1)!);
          if (parsed != null) maxSeq = max(maxSeq, parsed);
        }
      }
    }
    return maxSeq;
  }

  // ===== Public: 연결 열고 닫기 =====

  Future<void> open() async => _ensureOpen();

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _users = null;
  }

  // ===== Users: 조회/생성/업데이트 =====

  /// users 컬렉션에서 _id로 사용자 문서를 가져옵니다.
  /// - 24-hex(ObjectId) 또는 문자열 _id를 모두 지원합니다.
  /// - 추가로 patient_id 문자열 키도 보조 조회합니다.
  Future<Map<String, dynamic>?> fetchUser({required String userId}) async {
    await _ensureOpen();

    // 1) 24-hex면 ObjectId로 시도
    if (userId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(userId)) {
      try {
        final oid = ObjectId.fromHexString(userId);
        final byOid = await _users!.findOne(where.eq('_id', oid));
        if (byOid != null) return byOid;
      } catch (_) {
        // 무시하고 문자열 비교로 진행
      }
    }

    // 2) 문자열 _id
    final byId = await _users!.findOne(where.eq('_id', userId));
    if (byId != null) return byId;

    // 3) patient_id 보조 키
    final byPatientId = await _users!.findOne(where.eq('patient_id', userId));
    return byPatientId;
  }

  /// 이메일로 사용자 조회(중복 방지 위해 소문자/trim)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    await _ensureOpen();
    final normalized = email.trim().toLowerCase();
    return _users!.findOne(where.eq('user.email', normalized));
  }

  /// (호환용) 기존 API — 내부적으로 getUserByEmail을 위임 호출합니다.
  Future<Map<String, dynamic>?> findUserByEmail({required String email}) async {
    return getUserByEmail(email);
  }

  /// 새 사용자 생성 (비밀번호는 이미 해시/솔트 적용된 값 전달 전제)
  Future<ObjectId> createUser({
    required String email,
    required String name,
    required String password,
  }) async {
    await _ensureOpen();
    final oid = ObjectId();
    final now = DateTime.now();
    final doc = <String, dynamic>{
      '_id': oid,
      'patient_id': oid.oid,
      'seq_diaries': 0,
      'seq_customTags_a': 0,
      'seq_customTags_b': 0,
      'seq_customTags_cp': 0,
      'seq_customTags_ce': 0,
      'seq_customTags_cb': 0,
      'user': <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'password': password,
        'createdAt': now,
        'diaries': <Map<String, dynamic>>[],
        'customTags': <Map<String, dynamic>>[],
        'screenTime': <Map<String, dynamic>>[],
      },
    };
    await _users!.insertOne(doc);
    return oid;
  }

  /// 사용자 문서를 upsert로 보장합니다(없으면 생성)
  Future<void> ensureUserDoc({
    required String userId,
    String? name,
    String? email,
  }) async {
    await _ensureOpen();
    final dynamic key = _userKey(userId);

    await _users!.updateOne(
      where.eq('_id', key),
      ModifierBuilder()
        ..setOnInsert('_id', key)
        ..setOnInsert('patient_id', userId)
        ..setOnInsert('seq_diaries', 0)
        ..setOnInsert('seq_customTags_a', 0)
        ..setOnInsert('seq_customTags_b', 0)
        ..setOnInsert('seq_customTags_cp', 0)
        ..setOnInsert('seq_customTags_ce', 0)
        ..setOnInsert('seq_customTags_cb', 0)
        ..setOnInsert('user', <String, dynamic>{
          'name': (name ?? '').trim(),
          if (email != null) 'email': email.trim().toLowerCase(),
          'createdAt': DateTime.now(),
          'diaries': <Map<String, dynamic>>[],
          'customTags': <Map<String, dynamic>>[],
        'screenTime': <Map<String, dynamic>>[],
        }),
      upsert: true,
    );
  }

  /// 최상위 필드 또는 user.* 하위 필드 업데이트(일부 보호 필드 제외)
  Future<void> updateUserFields({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await _ensureOpen();
    if (updates.isEmpty) return;

    // 보호/정규화 처리
    updates.remove('createdAt');
    final now = DateTime.now();
    final key = _userKey(userId);

    final setTop = <String, dynamic>{};
    final setUser = <String, dynamic>{};

    updates.forEach((k, v) {
      switch (k) {
        case 'name':
        case 'email':
        case 'surveyCompleted':
        case 'completedWeek':
          setUser['user.$k'] = v;
          break;
        case 'updatedAt':
          // 무시: 아래에서 user.updatedAt 일괄 세팅
          break;
        default:
          setTop[k] = v;
      }
    });

    setUser['user.updatedAt'] = now;

    final updateDoc = <String, dynamic>{};
    if (setTop.isNotEmpty) updateDoc[r'$set'] = setTop;
    if (setUser.isNotEmpty) {
      final merged =
          (updateDoc[r'$set'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      merged.addAll(setUser);
      updateDoc[r'$set'] = merged;
    }

    if (updateDoc.isEmpty) return;
    await _users!.updateOne(where.eq('_id', key), updateDoc);
  }

  // ===== Custom ABC Chips =====

  /// 사용자 정의 ABC 칩 전체 조회(정렬/필드 보정 포함)
  Future<List<Map<String, dynamic>>> fetchCustomAbcChips({
    required String userId,
  }) async {
    await _ensureOpen();
    final doc = await _users!.findOne(where.eq('_id', _userKey(userId)));
    if (doc == null) return [];

    final list = _customChipsFromDoc(doc);
    list.sort((a, b) => _chipSeq(a).compareTo(_chipSeq(b)));

    for (final chip in list) {
      chip['seq'] = _chipSeq(chip);
      chip['name'] ??= chip['label'];
      chip['label'] ??= chip['name'];
      chip['tagId'] ??= chip['id'];
      chip['id'] ??= chip['tagId'];
    }
    return list;
  }

  /// 사용자 정의 ABC 칩 추가 (중복 방지 + 연속 seq 보장)
  Future<void> addCustomAbcChip({
    required String userId,
    required String type,
    required String name,
    required DateTime createdAt,
  }) async {
    await ensureUserDoc(userId: userId);

    final key = _userKey(userId);
    final normalizedType = type.toLowerCase();

    // 1) 중복 검사
    final docForDup = await _users!.findOne(where.eq('_id', key));
    final existingChips = _customChipsFromDoc(docForDup);
    final hasDup = existingChips.any((m) {
      final chipType = m['type']?.toString().toLowerCase();
      if (chipType != normalizedType) return false;
      final existingName = (m['name'] ?? m['label'])?.toString();
      return existingName == name;
    });
    if (hasDup) return; // 이미 존재 → 아무 것도 하지 않음

    // 2) 카운터 증가 (레거시 카운터 동시 유지)
    final counterField = _customChipCounterField(normalizedType);
    final legacyCounterField = 'seq_customTags_$normalizedType';

    final incMap = <String, int>{counterField: 1};
    if (legacyCounterField != counterField &&
        docForDup != null &&
        docForDup[legacyCounterField] != null) {
      incMap[legacyCounterField] = 1;
    }

    final after = await _users!.findAndModify(
      query: where.eq('_id', key).map,
      update: {r'$inc': incMap},
      returnNew: true,
      upsert: true,
    );

    // 3) seq 결정: 우선 카운터 → 없으면 기존 칩에서 최대값+1
    int seq = _intFrom(after?[counterField]);
    if (seq <= 0) seq = _intFrom(after?[legacyCounterField]);
    if (seq <= 0) seq = _maxSeqFromChips(existingChips, type: normalizedType) + 1;

    // 4) 카운터 동기화(명시 세팅)
    await _users!.updateOne(where.eq('_id', key), {
      r'$set': {
        counterField: seq,
        if (legacyCounterField != counterField) legacyCounterField: seq,
      },
    });

    // 5) 배열 push
    await _users!.updateOne(
      where.eq('_id', key),
      ModifierBuilder().push('user.customTags', {
        'tagId': _customChipId(normalizedType, seq),
        'type': normalizedType,
        'name': name,
        'createdAt': createdAt.toUtc(),
      }),
    );
  }

  /// 사용자 정의 ABC 칩 삭제(타입+이름 기준)
  Future<void> deleteCustomAbcChip({
    required String userId,
    required String type,
    required String name,
  }) async {
    await ensureUserDoc(userId: userId);
    await _users!.updateOne(where.eq('_id', _userKey(userId)), {
      r'$pull': {
        'user.customTags': {
          'type': type,
          'name': name,
        },
      },
    });
  }

  // ===== ABC Model =====

  /// ABC 모델(일기)을 user.diaries 배열에 삽입하고 externalId를 반환합니다.
  /// - seq_diaries를 우선 사용하되, 문서 상태에 따라 안전하게 보정합니다.
  Future<String> insertAbcModel({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await ensureUserDoc(userId: userId);

    final key = _userKey(userId);

    // 1) 카운터 증가 및 현재값 확보
    final after = await _users!.findAndModify(
      query: where.eq('_id', key).map,
      update: {
        r'$inc': {'seq_diaries': 1},
      },
      returnNew: true,
      upsert: true,
    );

    int seq = _intFrom(after?['seq_diaries']);

    // 2) 필요 시 보정: 현재 문서에서 최대 seq+1 계산
    if (seq <= 0) {
      final currentDoc = await _users!.findOne(where.eq('_id', key));
      int maxSeq = 0;
      if (currentDoc != null) {
        final rawUser = currentDoc['user'];
        if (rawUser is Map) {
          maxSeq = max(maxSeq, _maxSeqFromDiaries(rawUser['diaries']));
        }
        maxSeq = max(maxSeq, _maxSeqFromDiaries(currentDoc['diaries']));
      }
      seq = max(maxSeq + 1, 1);
    }

    // 3) externalId 구성
    final externalId = (data['externalId'] is String &&
            (data['externalId'] as String).isNotEmpty)
        ? data['externalId'] as String
        : 'diary_${seq.toString().padLeft(5, '0')}';

    // 4) payload 정리
    final sanitized = Map<String, dynamic>.from(data)..remove('externalId');
    final payload = <String, dynamic>{'externalId': externalId, ...sanitized};
    payload['createdAt'] ??= DateTime.now();

    // 5) push + 카운터 일치화
    await _users!.updateOne(
      where.eq('_id', key),
      ModifierBuilder().push('user.diaries', payload),
    );

    await _users!.updateOne(where.eq('_id', key), {
      r'$set': {'seq_diaries': seq},
    });

    return externalId; // 문서이름으로 사용
  }

  /// ABC 모델의 groupId를 업데이트합니다.
  Future<void> updateAbcModelGroup({
    required String userId,
    required String abcId, // externalId 또는 seq 문자열
    required String groupId,
  }) async {
    await ensureUserDoc(userId: userId);

    // 배열에서 대상 요소의 인덱스를 찾아 점 표기법으로 업데이트
    final userDoc = await _users!.findOne(where.eq('_id', _userKey(userId)));
    if (userDoc == null) return;

    Map<String, dynamic>? userMap;
    final dynamic rawUser = userDoc['user'];
    if (rawUser is Map) {
      userMap = Map<String, dynamic>.from(rawUser);
    }

    final models = (userMap?['diaries'] as List?) ?? const [];
    final idx = models.indexWhere((e) {
      final m = Map<String, dynamic>.from(e as Map);

      // externalId 우선
      final extId = m['externalId']?.toString();
      if (extId != null && extId.isNotEmpty && extId == abcId) return true;

      // seq 보조(숫자/문자 모두 지원)
      final seqValue = m['seq'];
      if (seqValue is int && seqValue.toString() == abcId) return true;
      if (seqValue is String && seqValue == abcId) return true;
      return false;
    });

    if (idx < 0) return;

    await _users!.updateOne(where.eq('_id', _userKey(userId)), {
      r'$set': {
        'user.diaries.$idx.groupId': groupId,
        'user.diaries.$idx.updatedAt': DateTime.now(),
      },
    });
  }
}