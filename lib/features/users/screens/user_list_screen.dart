import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'user_form_screen.dart';

/// User management screen displaying users in a paginated, searchable grid/table.
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 8; // Default rows per page

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _currentPage = 1; // Reset to page 1 on new search
    });
  }

  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('delete_user'),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${context.tr('delete_user_confirm')} (${user.fullName})',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<UserProvider>().deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.tr('delete'),
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({User? user}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(user: user),
      ),
    );
    if (result == true && mounted) {
      context.read<UserProvider>().loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // 1. Filter users based on query
    final filteredUsers = userProvider.users.where((user) {
      if (_searchQuery.isEmpty) return true;
      return user.id.toString() == _searchQuery ||
          user.firstName.toLowerCase().contains(_searchQuery) ||
          user.lastName.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
    }).toList();

    // 2. Paginate filtered users
    final totalUsers = filteredUsers.length;
    final totalPages = (totalUsers / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    
    // Adjust current page if out of bounds after filtering
    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > totalUsers ? totalUsers : endIndex,
    );

    return DashboardShell(
      title: context.tr('users_directory'),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Add Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: context.tr('search_hint'),
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.35),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.5), size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: () => _navigateToForm(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    context.tr('new_button'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Data Table Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                clipBehavior: Clip.antiAlias,
                child: userProvider.isLoading && userProvider.users.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : userProvider.errorMessage != null && userProvider.users.isEmpty
                        ? _buildErrorWidget(userProvider)
                        : filteredUsers.isEmpty
                            ? _buildEmptyWidget()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Grid/Table header and body
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
                                              ),
                                              child: Theme(
                                                data: Theme.of(context).copyWith(
                                                  dividerColor: Colors.white.withOpacity(0.05),
                                                ),
                                                child: DataTable(
                                                  headingRowColor: MaterialStateProperty.all(
                                                    Colors.white.withOpacity(0.03),
                                                  ),
                                                  headingTextStyle: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  dataTextStyle: GoogleFonts.inter(
                                                    color: Colors.white.withOpacity(0.85),
                                                    fontSize: 13,
                                                  ),
                                                  horizontalMargin: 20,
                                                  columnSpacing: 35,
                                                  columns: [
                                                    const DataColumn(label: Text('ID')),
                                                    DataColumn(label: Text(context.tr('full_name'))),
                                                    DataColumn(label: Text(context.tr('email'))),
                                                    DataColumn(label: Text(context.tr('status'))),
                                                    DataColumn(label: Text(context.tr('created_at'))),
                                                    DataColumn(label: Text(context.tr('actions'))),
                                                  ],
                                                  rows: paginatedUsers.map((user) {
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(Text(user.id.toString())),
                                                        DataCell(Row(
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 13,
                                                              backgroundColor: user.isActive
                                                                  ? const Color(0xFF6C63FF).withOpacity(0.2)
                                                                  : Colors.white.withOpacity(0.1),
                                                              child: Text(
                                                                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '',
                                                                style: GoogleFonts.outfit(
                                                                  color: user.isActive
                                                                      ? const Color(0xFF4ECDC4)
                                                                      : Colors.white60,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Text(user.fullName),
                                                          ],
                                                        )),
                                                        DataCell(Text(user.email)),
                                                        DataCell(_buildStatusBadge(user.isActive)),
                                                        DataCell(Text(_formatDate(user.createAt))),
                                                        DataCell(_buildActionsCell(user)),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  // Pagination Footer
                                  _buildPaginationFooter(
                                    totalItems: totalUsers,
                                    totalPages: safeTotalPages,
                                  ),
                                ],
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B))
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B))
              .withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? context.tr('active') : context.tr('inactive'),
        style: GoogleFonts.inter(
          color: isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionsCell(User user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF), size: 18),
          tooltip: context.tr('edit'),
          onPressed: () => _navigateToForm(user: user),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 18),
          tooltip: context.tr('delete'),
          onPressed: () => _showDeleteDialog(user),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter({
    required int totalItems,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total items count
          Text(
            '${context.tr('total_users')}: $totalItems',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          
          // Page navigator controls
          Row(
            children: [
              // Page size chooser hint
              Text(
                '${context.tr('rows_per_page')} ',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              DropdownButton<int>(
                value: _rowsPerPage,
                dropdownColor: const Color(0xFF1E1E2E),
                underline: const SizedBox.shrink(),
                iconEnabledColor: Colors.white38,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                items: [5, 8, 10, 15].map((size) {
                  return DropdownMenuItem<int>(
                    value: size,
                    child: Text('  $size  '),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _rowsPerPage = val;
                      _currentPage = 1;
                    });
                  }
                },
              ),
              const SizedBox(width: 14),
              
              // Navigation Buttons
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: Colors.white70,
                disabledColor: Colors.white.withOpacity(0.15),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                '${context.tr('page')} $_currentPage ${context.tr('of')} $totalPages',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: Colors.white70,
                disabledColor: Colors.white.withOpacity(0.15),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('no_results'),
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                context.tr('search_other_keywords'),
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(UserProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: const Color(0xFFFF6B6B).withOpacity(0.7),
          ),
          const SizedBox(height: 14),
          Text(
            provider.errorMessage!,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => provider.loadUsers(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr('retry'), style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (_) {
      return dateStr.split('T')[0]; // Fallback to basic date
    }
  }
}
