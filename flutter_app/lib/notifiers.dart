import 'package:flutter/foundation.dart';

/// 피드백 목록 새로고침 트리거 — MyPageScreen이 리슨, 피드백 저장 시 increment
final feedbackRefreshNotifier = ValueNotifier<int>(0);
