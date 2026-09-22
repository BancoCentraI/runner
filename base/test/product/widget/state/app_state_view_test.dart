import 'package:akillisletme/product/enum/view_state.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/state/app_empty_view.dart';
import 'package:akillisletme/product/widget/state/app_error_view.dart';
import 'package:akillisletme/product/widget/state/app_loading_view.dart';
import 'package:akillisletme/product/widget/state/app_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/pump_app.dart';

void main() {
  setUpAll(initializeTestBindings);

  Widget buildSubject(ViewState state, {VoidCallback? onRetry}) {
    return AppStateView(
      state: state,
      onRetry: onRetry,
      builder: () => const Text('veri'),
    );
  }

  testWidgets('loading durumunda gosterge cizer, builder calismaz', (
    tester,
  ) async {
    await tester.pumpApp(buildSubject(ViewState.loading));

    expect(find.byType(AppLoadingView), findsOneWidget);
    expect(find.text('veri'), findsNothing);
  });

  testWidgets('loadingPlaceholder verilirse gostergenin yerine gecer', (
    tester,
  ) async {
    await tester.pumpApp(
      AppStateView(
        state: ViewState.loading,
        loadingPlaceholder: const Text('iskelet'),
        builder: () => const Text('veri'),
      ),
    );

    expect(find.text('iskelet'), findsOneWidget);
    expect(find.byType(AppLoadingView), findsNothing);
  });

  testWidgets('error durumunda hata gorunumu cizer ve retry tetiklenir', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpApp(
      buildSubject(ViewState.error, onRetry: () => retryCount++),
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('veri'), findsNothing);

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('onRetry verilmezse aksiyon butonu cizilmez', (tester) async {
    await tester.pumpApp(buildSubject(ViewState.error));

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.byType(AppPrimaryButton), findsNothing);
  });

  testWidgets('empty durumu hata degil — bos gorunum cizer', (tester) async {
    await tester.pumpApp(buildSubject(ViewState.empty));

    expect(find.byType(AppEmptyView), findsOneWidget);
    expect(find.byType(AppErrorView), findsNothing);
  });

  testWidgets('data durumunda builder cizilir', (tester) async {
    await tester.pumpApp(buildSubject(ViewState.data));

    expect(find.text('veri'), findsOneWidget);
    expect(find.byType(AppLoadingView), findsNothing);
    expect(find.byType(AppErrorView), findsNothing);
    expect(find.byType(AppEmptyView), findsNothing);
  });

  testWidgets('dark temada da cizilir', (tester) async {
    await tester.pumpApp(
      buildSubject(ViewState.empty),
      themeMode: ThemeMode.dark,
    );

    expect(find.byType(AppEmptyView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
