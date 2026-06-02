// 회원가입 화면 위젯 테스트
//
// 기존 Flutter 템플릿의 카운터 테스트는 실제 앱과 무관해 항상 실패했으므로
// 회원가입 화면 동작 검증 테스트로 교체했습니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/screens/signup_screen.dart';
import 'package:flutter_app/theme.dart';

void main() {
  Future<void> pumpSignupScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
  }

  // 필드 순서: 이메일(0), 비밀번호(1), 비밀번호 확인(2), 닉네임(3)
  Finder passwordField() => find.byType(TextFormField).at(1);
  Finder passwordConfirmField() => find.byType(TextFormField).at(2);

  testWidgets('회원가입 화면이 필수 요소와 함께 렌더링된다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    expect(find.text('가입 완료하기'), findsOneWidget);
    expect(find.text('중복확인'), findsNWidgets(2)); // 이메일, 닉네임
    expect(find.text('8자 이상 (최대 64자)'), findsOneWidget);
    expect(find.text('영문 포함'), findsOneWidget);
    expect(find.text('숫자 포함'), findsOneWidget);
    expect(find.text('특수문자 포함'), findsOneWidget);
  });

  testWidgets('비밀번호 조건 충족 시 체크리스트 항목이 초록색으로 바뀐다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    await tester.enterText(passwordField(), 'abcd1234!');
    await tester.pump();

    for (final label in ['8자 이상 (최대 64자)', '영문 포함', '숫자 포함', '특수문자 포함']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, Colors.green, reason: '$label 항목이 초록색이어야 합니다');
    }
  });

  testWidgets('조건 미충족 항목은 회색으로 남는다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    // 특수문자 없는 비밀번호
    await tester.enterText(passwordField(), 'abcd1234');
    await tester.pump();

    final specialChar = tester.widget<Text>(find.text('특수문자 포함'));
    expect(specialChar.style?.color, Colors.grey);

    final letter = tester.widget<Text>(find.text('영문 포함'));
    expect(letter.style?.color, Colors.green);
  });

  testWidgets('비밀번호 확인이 다르면 실시간으로 불일치 메시지가 표시된다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    await tester.enterText(passwordField(), 'abcd1234!');
    await tester.enterText(passwordConfirmField(), 'different1!');
    await tester.pump();

    expect(find.text('비밀번호가 일치하지 않습니다.'), findsOneWidget);

    // 동일하게 수정하면 메시지가 사라진다
    await tester.enterText(passwordConfirmField(), 'abcd1234!');
    await tester.pump();

    expect(find.text('비밀번호가 일치하지 않습니다.'), findsNothing);
  });

  // 모든 필드를 유효하게 채우고 성별까지 선택 (약관/중복확인은 별도)
  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(passwordField(), 'abcd1234!');
    await tester.enterText(passwordConfirmField(), 'abcd1234!');
    await tester.enterText(find.byType(TextFormField).at(3), '테스트닉네임');

    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('남성').last);
    await tester.pumpAndSettle();
  }

  testWidgets('약관 미동의 상태로 제출하면 안내 스낵바가 표시된다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);
    await fillValidForm(tester);

    await tester.ensureVisible(find.text('가입 완료하기'));
    await tester.tap(find.text('가입 완료하기'));
    await tester.pump();

    expect(find.text('필수 약관에 동의해 주세요.'), findsOneWidget);
  });

  testWidgets('전체 동의를 누르면 필수 약관이 모두 체크된다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    Color? agreementIconColor(String label) {
      final icon = tester.widget<Icon>(
        find
            .descendant(
              of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
              matching: find.byType(Icon),
            )
            .first,
      );
      return icon.color;
    }

    await tester.ensureVisible(find.text('전체 동의'));
    await tester.tap(find.text('전체 동의'));
    await tester.pump();

    expect(agreementIconColor('(필수) 서비스 이용약관 동의'), AppTheme.primaryColor);
    expect(agreementIconColor('(필수) 개인정보 수집·이용 동의'), AppTheme.primaryColor);

    // 다시 누르면 전부 해제된다
    await tester.tap(find.text('전체 동의'));
    await tester.pump();

    expect(agreementIconColor('(필수) 서비스 이용약관 동의'), isNot(AppTheme.primaryColor));
  });

  testWidgets('중복확인 없이 제출하면 안내 스낵바가 표시된다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);
    await fillValidForm(tester);

    // 약관 동의 후 중복확인 없이 제출
    await tester.ensureVisible(find.text('전체 동의'));
    await tester.tap(find.text('전체 동의'));
    await tester.pump();

    await tester.ensureVisible(find.text('가입 완료하기'));
    await tester.tap(find.text('가입 완료하기'));
    await tester.pump();

    expect(find.text('이메일 중복확인을 해주세요.'), findsOneWidget);
  });
}
