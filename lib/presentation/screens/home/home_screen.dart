import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/gem.dart';
import '../../providers/gem_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../widgets/gem_card.dart';
import '../../widgets/conversation_tile.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_screen.dart';
import '../gems/gem_editor_screen.dart';
import '../gems/gem_list_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeActiveAcorn();
  }

  Future<void> _initializeActiveAcorn() async {
    final acornRepo = ref.read(acornRepositoryProvider);
    final defaultAcorn = await acornRepo.getDefaultAcorn();
    ref.read(activeAcornProvider.notifier).state = defaultAcorn;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _MobileHome(
        bottomNavIndex: _bottomNavIndex,
        onNavChanged: (i) => setState(() => _bottomNavIndex = i),
      ),
      desktopLayout: const _DesktopHome(),
    );
  }
}

class _MobileHome extends ConsumerWidget {
  final int bottomNavIndex;
  final ValueChanged<int> onNavChanged;

  const _MobileHome({
    required this.bottomNavIndex,
    required this.onNavChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: IndexedStack(
        index: bottomNavIndex,
        children: [
          _ChatListView(onConversationTap: (conv) {
            ref.read(activeConversationProvider.notifier).state = conv;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          }),
          const AcornListScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomNavIndex,
        onDestinationSelected: onNavChanged,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.surfaceHighlight,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined, size: 20),
            selectedIcon: Icon(Icons.chat_rounded, size: 20),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, size: 20),
            selectedIcon: Icon(Icons.auto_awesome_rounded, size: 20),
            label: 'Acorns',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 20),
            selectedIcon: Icon(Icons.settings_rounded, size: 20),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: bottomNavIndex == 0
          ? FloatingActionButton.small(
              onPressed: () => _createNewConversation(context, ref),
              backgroundColor: AppColors.surfaceHighlight,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              child: const Icon(Icons.add_rounded, size: 20),
            )
          : null,
    );
  }

  Future<void> _createNewConversation(
      BuildContext context, WidgetRef ref) async {
    final activeAcorn = ref.read(activeAcornProvider);
    if (activeAcorn == null) return;

    final convRepo = ref.read(conversationRepositoryProvider);
    final conv = await convRepo.createConversation(acornId: activeAcorn.uuid);

    ref.read(activeConversationProvider.notifier).state = conv;
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }
}

class _DesktopHome extends ConsumerWidget {
  const _DesktopHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAcorn = ref.watch(activeAcornProvider);
    final acornsAsync = ref.watch(allAcornsProvider);

    return Scaffold(
      body: Row(
        children: [
          // Acorn sidebar
          Container(
            width: 64,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // App logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.divider,
                ),
                const SizedBox(height: 8),
                // Acorn icons — monochrome first-letter style
                Expanded(
                  child: acornsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (acorns) => ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: acorns.map((acorn) {
                        final isActive = activeAcorn?.uuid == acorn.uuid;
                        final letter = acorn.name.isNotEmpty
                            ? acorn.name[0].toUpperCase()
                            : '?';
                        return Tooltip(
                          message: acorn.name,
                          child: InkWell(
                            onTap: () {
                              ref.read(activeAcornProvider.notifier).state = acorn;
                              ref.read(activeConversationProvider.notifier)
                                  .state = null;
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 10),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.surfaceHighlight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isActive
                                    ? Border.all(
                                        color: AppColors.textTertiary
                                            .withAlpha(60),
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Create new acorn
                IconButton(
                  icon: Icon(Icons.add_rounded,
                      size: 20, color: AppColors.textTertiary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AcornEditorScreen(
                        onSaved: () {
                          ref.invalidate(allAcornsProvider);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  tooltip: 'Create Acorn',
                ),
                // Settings
                IconButton(
                  icon: Icon(Icons.settings_outlined,
                      size: 20, color: AppColors.textTertiary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  tooltip: 'Settings',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Conversation list
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                right: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                // Header with acorn name and new chat button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeAcorn?.name ?? 'Chats',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_square,
                            size: 18, color: AppColors.textTertiary),
                        onPressed: () =>
                            _createNewConversation(context, ref),
                        tooltip: 'New chat',
                      ),
                    ],
                  ),
                ),
                // Search bar
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _ConversationSearchBar(),
                ),
                // Conversation list
                Expanded(
                  child: _ChatListView(
                    onConversationTap: (conv) {
                      ref.read(activeConversationProvider.notifier).state =
                          conv;
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chat area
          const Expanded(child: ChatScreen()),
        ],
      ),
    );
  }

  Future<void> _createNewConversation(
      BuildContext context, WidgetRef ref) async {
    final activeAcorn = ref.read(activeAcornProvider);
    if (activeAcorn == null) return;

    final convRepo = ref.read(conversationRepositoryProvider);
    final conv = await convRepo.createConversation(acornId: activeAcorn.uuid);
    ref.read(activeConversationProvider.notifier).state = conv;
  }
}

// Search query state
final _searchQueryProvider = StateProvider<String>((ref) => '');

class _ConversationSearchBar extends ConsumerStatefulWidget {
  const _ConversationSearchBar();

  @override
  ConsumerState<_ConversationSearchBar> createState() =>
      _ConversationSearchBarState();
}

class _ConversationSearchBarState
    extends ConsumerState<_ConversationSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync text field with provider (e.g. if cleared externally)
    final query = ref.watch(_searchQueryProvider);
    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection =
          TextSelection.collapsed(offset: query.length);
    }

    return SizedBox(
      height: 34,
      child: TextField(
        controller: _controller,
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 16, color: AppColors.textTertiary),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.textTertiary),
                  onPressed: () {
                    _controller.clear();
                    ref.read(_searchQueryProvider.notifier).state = '';
                  },
                  padding: EdgeInsets.zero,
                )
              : null,
        ),
        onChanged: (value) {
          ref.read(_searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }
}

class _ChatListView extends ConsumerWidget {
  final void Function(dynamic conversation) onConversationTap;

  const _ChatListView({required this.onConversationTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAcorn = ref.watch(activeAcornProvider);
    final activeConv = ref.watch(activeConversationProvider);
    final searchQuery = ref.watch(_searchQueryProvider);

    if (activeAcorn == null) {
      return const Center(
        child: Text('Select an Acorn to start', style: AppTextStyles.body),
      );
    }

    // If searching, use search results; otherwise use acorn conversations
    if (searchQuery.isNotEmpty) {
      final searchAsync = ref.watch(searchResultsProvider(searchQuery));
      return searchAsync.when(
        loading: () => const Center(
            child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Text('No results for "$searchQuery"',
                  style: AppTextStyles.bodySmall),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            itemCount: results.length,
            itemBuilder: (_, index) {
              final conv = results[index];
              return ConversationTile(
                conversation: conv,
                isSelected: activeConv?.uuid == conv.uuid,
                onTap: () => onConversationTap(conv),
                onLongPress: () =>
                    _showConversationOptions(context, ref, conv),
              );
            },
          );
        },
      );
    }

    final conversationsAsync =
        ref.watch(conversationsForAcornProvider(activeAcorn.uuid));

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: AppTextStyles.body),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined,
                      size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'No conversations yet',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start a new chat',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        // Pinned first, then by updated time
        final pinned =
            conversations.where((c) => c.isPinned).toList();
        final unpinned =
            conversations.where((c) => !c.isPinned).toList();
        final sorted = [...pinned, ...unpinned];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          itemCount: sorted.length,
          itemBuilder: (_, index) {
            final conv = sorted[index];
            return ConversationTile(
              conversation: conv,
              isSelected: activeConv?.uuid == conv.uuid,
              onTap: () => onConversationTap(conv),
              onLongPress: () =>
                  _showConversationOptions(context, ref, conv),
            );
          },
        );
      },
    );
  }

  void _showConversationOptions(
      BuildContext context, WidgetRef ref, dynamic conv) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conv.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                size: 20,
              ),
              title: Text(conv.isPinned ? 'Unpin' : 'Pin'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(conversationRepositoryProvider)
                    .togglePin(conv.uuid);
                ref.invalidate(
                    conversationsForAcornProvider(conv.acornId));
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, size: 20),
              title: const Text('Archive'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(conversationRepositoryProvider)
                    .archiveConversation(conv.uuid);
                if (ref.read(activeConversationProvider)?.uuid == conv.uuid) {
                  ref.read(activeConversationProvider.notifier).state = null;
                }
                ref.invalidate(
                    conversationsForAcornProvider(conv.acornId));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.error),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dlgCtx) => AlertDialog(
                    title: const Text('Delete Conversation?'),
                    content: const Text(
                        'This will permanently delete this conversation and all its messages.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dlgCtx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dlgCtx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(conversationRepositoryProvider)
                      .deleteConversation(conv.uuid);
                  if (ref.read(activeConversationProvider)?.uuid == conv.uuid) {
                    ref.read(activeConversationProvider.notifier).state = null;
                  }
                  ref.invalidate(
                      conversationsForAcornProvider(conv.acornId));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
