import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';

class UserListScreen extends StatefulWidget {
  final bool showBottomNav;

  const UserListScreen({super.key, this.showBottomNav = true});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  static const int _pageSize = 20;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<AdminUser> _users = [];
  int _page = 1;
  int _count = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    if (_scrollController.position.extentAfter < 240) _loadMore();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await AdminUsersApi.fetchUsers(
        page: 1,
        pageSize: _pageSize,
        search: _query,
      );
      if (!mounted) return;
      setState(() {
        _users = page.users;
        _count = page.count;
        _hasMore = _query.isEmpty && page.hasMore;
        _page = 1;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load users');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _query.isNotEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await AdminUsersApi.fetchUsers(
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(result.users);
        _page = nextPage;
        _count = result.count;
        _hasMore = result.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to load more users');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _search() {
    _query = _searchController.text.trim();
    _loadUsers();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Users',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Search users',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.regionBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'User directory',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '$_count users',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(backgroundColor: Colors.white)
          : null,
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadUsers, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _users.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _userCard(_users[index], index);
        },
      ),
    );
  }

  Widget _userCard(AdminUser user, int index) {
    final name = user.fullName.isEmpty
        ? (user.userId.isEmpty ? 'User ${user.id}' : user.userId)
        : user.fullName;
    final role = user.roleName.isNotEmpty
        ? user.roleName
        : user.roleId.isNotEmpty
        ? 'Role ${user.roleId}'
        : 'Role not provided';
    final accent = index.isEven ? AppColors.aiBlue : AppColors.dayEndIconBg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent, width: 1.3),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.avatarBg1,
            foregroundColor: AppColors.regionBlue,
            child: Text(
              user.initials,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.bold,
                    color: AppColors.regionBlue,
                    fontSize: 14,
                  ),
                ),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.steel,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _badge(role, AppColors.aiBlueBg, AppColors.regionBlue),
                    _badge(
                      user.isActive ? 'Active' : 'Inactive',
                      user.isActive ? AppColors.greenLight : AppColors.coldBg,
                      user.isActive ? AppColors.green : AppColors.coldText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
