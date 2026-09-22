import 'package:akillisletme/product/enum/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewState.from', () {
    test('yukleme her seyin onunde gelir', () {
      expect(
        ViewState.from(isLoading: true, hasError: true, isEmpty: true),
        ViewState.loading,
      );
    });

    test('hata bosluktan once gelir', () {
      expect(
        ViewState.from(isLoading: false, hasError: true, isEmpty: true),
        ViewState.error,
      );
    });

    test('bos liste hata degildir', () {
      expect(
        ViewState.from(isLoading: false, hasError: false, isEmpty: true),
        ViewState.empty,
      );
    });

    test('veri varsa data', () {
      expect(
        ViewState.from(isLoading: false, hasError: false, isEmpty: false),
        ViewState.data,
      );
    });
  });

  test('kisayol getter\'lari tek durumda true doner', () {
    expect(ViewState.loading.isLoading, isTrue);
    expect(ViewState.loading.isError, isFalse);
    expect(ViewState.error.isError, isTrue);
    expect(ViewState.empty.isEmpty, isTrue);
    expect(ViewState.data.isData, isTrue);
  });
}
