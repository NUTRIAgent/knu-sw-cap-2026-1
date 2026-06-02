// 회원가입 검증 범위 회귀 테스트
//
// 한 필드 입력 시 건드리지 않은 다른 필드까지 검증 에러가 표시되던 문제
// (Form 레벨 AutovalidateMode.onUserInteraction)의 수정을 검증합니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/screens/signup_screen.dart';

void main() {
  Future<void> pumpSignupScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
  }

  // 필드 순서: 이메일(0), 비밀번호(1), 비밀번호 확인(2), 닉네임(3)
  Finder emailField() => find.byType(TextFormField).at(0);
  Finder passwordField() => find.byType(TextFormField).at(1);

  testWidgets('이메일 입력 시 건드리지 않은 다른 필드에는 에러가 표시되지 않는다',
      (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    await tester.enterText(emailField(), 'test@example.com');
    await tester.pump();

    expect(find.text('비밀번호를 입력해 주세요.'), findsNothing);
    expect(find.text('비밀번호 확인을 입력해 주세요.'), findsNothing);
    expect(find.text('닉네임을 입력해 주세요.'), findsNothing);
    expect(find.text('성별을 선택해 주세요.'), findsNothing);
  });

  testWidgets('잘못된 이메일 형식은 이메일 필드에만 에러가 표시된다',
      (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    await tester.enterText(emailField(), 'invalid-email');
    await tester.pump();

    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsNothing);
    expect(find.text('닉네임을 입력해 주세요.'), findsNothing);
  });

  testWidgets('비밀번호 입력 시 건드리지 않은 비밀번호 확인 필드에는 에러가 표시되지 않는다',
      (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    await tester.enterText(passwordField(), 'abcd1234!');
    await tester.pump();

    expect(find.text('비밀번호 확인을 입력해 주세요.'), findsNothing);
    expect(find.text('비밀번호가 일치하지 않습니다.'), findsNothing);
  });

  testWidgets('제출 시에는 빈 필드 전체에 검증 에러가 표시된다', (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    await tester.ensureVisible(find.text('가입 완료하기'));
    await tester.tap(find.text('가입 완료하기'));
    await tester.pump();

    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호 확인을 입력해 주세요.'), findsOneWidget);
    expect(find.text('닉네임을 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('비밀번호 확인 입력 후 비밀번호를 바꾸면 불일치 에러가 실시간 갱신된다',
      (WidgetTester tester) async {
    await pumpSignupScreen(tester);

    final confirmField = find.byType(TextFormField).at(2);
    await tester.enterText(passwordField(), 'abcd1234!');
    await tester.enterText(confirmField, 'abcd1234!');
    await tester.pump();
    expect(find.text('비밀번호가 일치하지 않습니다.'), findsNothing);

    // 확인 칸은 그대로 두고 비밀번호만 변경 → 확인 칸이 자동 재검증되어야 함
    await tester.enterText(passwordField(), 'abcd1234!@');
    await tester.pump();
    expect(find.text('비밀번호가 일치하지 않습니다.'), findsOneWidget);
  });
}
