#!/bin/bash
# =====================================================================
# 시연용 푸시 알림 시뮬레이터 테스트 스크립트
# Xcode 14+ 필요 / iOS 시뮬레이터에서 알림 UI 확인용
# 실제 FCM 발송이 아닌 APNs 시뮬레이션 (UI 확인 목적)
# =====================================================================

BUNDLE_ID="com.nutria.FA"

# 페이로드 파일 생성
cat > /tmp/nutria_demo_push.apns << 'EOF'
{
  "aps": {
    "alert": {
      "title": "📊 양파 가격 변동",
      "body": "▲ 5.3% 변동 (1,200원 → 1,264원)"
    },
    "sound": "default",
    "badge": 1
  }
}
EOF

echo "시뮬레이터에 알림 발송 중..."
xcrun simctl push booted "$BUNDLE_ID" /tmp/nutria_demo_push.apns

if [ $? -eq 0 ]; then
  echo "✅ 알림 발송 완료"
else
  echo "❌ 실패 — 시뮬레이터가 실행 중인지, Bundle ID($BUNDLE_ID)가 맞는지 확인하세요"
fi
