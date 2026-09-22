import 'package:akillisletme/product/enum/view_state.dart';
import 'package:akillisletme/product/widget/state/app_empty_view.dart';
import 'package:akillisletme/product/widget/state/app_error_view.dart';
import 'package:akillisletme/product/widget/state/app_loading_view.dart';
import 'package:flutter/material.dart';

/// Dort durumu (loading / error / empty / data) tek yerde ele alan gecis
/// widget'i. Her ekranda ayni `if (isLoading) ... else if (isError) ...`
/// zincirini yeniden yazmayi onler.
///
/// ```dart
/// BlocBuilder<TaskCubit, TaskState>(
///   builder: (context, state) => AppStateView(
///     state: ViewState.from(
///       isLoading: state.isLoading,
///       hasError: state.errorMessage != null,
///       isEmpty: state.tasks.isEmpty,
///     ),
///     errorMessage: state.errorMessage,
///     onRetry: context.read<TaskCubit>().load,
///     builder: () => TaskList(tasks: state.tasks),
///   ),
/// )
/// ```
///
/// [builder] yalnizca veri durumunda calisir; boylece bos/hata durumunda
/// listeye guvenle `state.items.first` gibi erisen kod yazilabilir.
class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.state,
    required this.builder,
    super.key,
    this.onRetry,
    this.errorTitle,
    this.errorMessage,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingPlaceholder,
  });

  final ViewState state;

  /// Veri durumunda cizilecek icerik.
  final Widget Function() builder;

  final VoidCallback? onRetry;
  final String? errorTitle;

  /// Yerellestirilmis kullanici mesaji — ham exception metni degil.
  final String? errorMessage;

  final String? emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  /// Iskelet (shimmer) placeholder. Verilmezse ortalanmis gosterge cizilir.
  final Widget? loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewState.loading => loadingPlaceholder ?? const AppLoadingView(),
      ViewState.error => AppErrorView(
        title: errorTitle,
        message: errorMessage,
        onRetry: onRetry,
      ),
      ViewState.empty => AppEmptyView(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      ),
      ViewState.data => builder(),
    };
  }
}
