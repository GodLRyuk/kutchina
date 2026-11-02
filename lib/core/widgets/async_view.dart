import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/services/api_services.dart';

/// Loads data once, shows spinner / error with Retry / pull-to-refresh.
/// Used by every new tab so loading behaviour is identical everywhere.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  /// Return true to show [emptyText] instead of [builder].
  final bool Function(T data)? isEmpty;
  final String emptyText;
  final IconData emptyIcon;

  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.emptyText = 'Nothing here yet.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load. Pull down to retry.';
        _loading = false;
      });
    }
  }

  Widget _scrollable(Widget child) => RefreshIndicator(
    onRefresh: reload,
    child: LayoutBuilder(
      builder: (_, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.commandCentreText),
      );
    }
    if (_error != null && _data == null) {
      return _scrollable(
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.red.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.redDark, fontSize: 13),
              ),
              TextButton(onPressed: reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final data = _data as T;
    if (widget.isEmpty?.call(data) ?? false) {
      return _scrollable(
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.emptyIcon, size: 44, color: AppColors.steelLight),
              const SizedBox(height: 10),
              Text(
                widget.emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.steel, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: reload,
      child: widget.builder(context, data),
    );
  }
}
