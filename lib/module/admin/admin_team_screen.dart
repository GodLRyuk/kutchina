import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/module/admin/reports/salesPersonDetailsScreen.dart';

class AdminTeamScreen extends StatefulWidget {
  const AdminTeamScreen({super.key});

  @override
  State<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends State<AdminTeamScreen> {
  static const int _pageSize = 10;
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _loadError;
  final TextEditingController _searchController = TextEditingController();
  int _page = 1;
  bool _isLoadingMore = false;
  int _count = 0;
  bool _hasMore = false;
  String _query = '';

  static const List<Color> _avatarColors = [
    AppColors.avatarBg1,
    AppColors.avatarBg2,
    AppColors.avatarBg3,
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      // final data = await AdminUsersApi.fetchUsers(
      // );
      // if (!mounted) return;
      // setState(() => _users = data);

      final data = await AdminUsersApi.fetchUsers(
        page: 1, pageSize: _pageSize, search: _query
        );
      if (!mounted) return;
      setState(() {
        _users = data.users;
        _count = data.count;
        _hasMore = _query.isEmpty && data.hasMore;
        _page = 1;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Unable to load team');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUser() async {
    _query = _searchController.text.trim();
    _loadUsers();
   
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final data = await AdminUsersApi.fetchUsers(
        page: next,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(data.users);
        _count = data.count;
        _hasMore = data.hasMore;
        _page = next;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _snack(error.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Unable to load more sales');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openUser(AdminUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSalespersonDetailScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar.simple(title: 'Sales Team'),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales Team',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.commandCentreText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading || _loadError != null
                      ? 'Team members'
                      : '${_count} team members',
                  style: const TextStyle(fontSize: 12, color: AppColors.steel),
                ),
                const SizedBox(height: 16),
                _search(_searchController),
                const SizedBox(height: 16),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.steel),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
           _query.isEmpty ? 'No team members found' : 'No results found',
          style: TextStyle(color: AppColors.steel),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        // itemCount: _users.length,
        itemCount: _users.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        //itemBuilder: (context, i) => _teamCard(_users[i], i),
        itemBuilder: (context, i) {
          if (i == _users.length) return _loadMoreButton();
          return _teamCard(_users[i], i);
        },
      ),
    );
  }

  Widget _teamCard(AdminUser u, int index) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openUser(u),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _avatarColors[index % _avatarColors.length],
                child: Text(
                  u.initials,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.fullName.isEmpty ? u.userId : u.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (u.email.isNotEmpty)
                      Text(
                        u.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.steel,
                        ),
                      ),
                    if (u.phone.isNotEmpty)
                      Text(
                        u.phone,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.steel,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    u.userId,
                    style: const TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    u.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: u.isActive
                          ? AppColors.steel
                          : AppColors.steelLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.steelLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _search(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.ink,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchUser(),
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: "Search by name",
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.steelLight),
          border: InputBorder.none,
          prefixIcon: IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.steel),
            onPressed: _searchUser,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.steel),
            onPressed: () {
              _searchController.clear();
              _searchUser();
              
            },
          ),
        ),
      ),
    );
  }

  Widget _loadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isLoadingMore ? null : _loadMore,
          icon: _isLoadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more, size: 18),
          label: Text(
            _isLoadingMore
                ? 'Loading...'
                : 'Load more (${_users.length} of $_count)',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.line, width: 1.3),
            foregroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
