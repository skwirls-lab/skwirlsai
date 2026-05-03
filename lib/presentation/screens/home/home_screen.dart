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
    _initializeActiveGem();
  }

  Future<void> _initializeActiveGem() async {
    final gemRepo = ref.read(gemRepositoryProvider);
    final defaultGem = await gemRepo.getDefaultGem();
    ref.read(activeGemProvider.notifier).state = defaultGem;
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
          const GemListScreen(),
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
            label: 'Gems',
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
    final activeGem = ref.read(activeGemProvider);
    if (activeGem == null) return;

    final convRepo = ref.read(conversationRepositoryProvider);
    final conv = await convRepo.createConversation(gemId: activeGem.uuid);

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
    final activeGem = ref.watch(activeGemProvider);
    final gemsAsync = ref.watch(allGemsProvider);

    return Scaffold(
      body: Row(
        children: [
          // Gem sidebar
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
                // Gem icons — monochrome first-letter style
                Expanded(
                  child: gemsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (gems) => ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: gems.map((gem) {
                        final isActive = activeGem?.uuid == gem.uuid;
                        final letter = gem.name.isNotEmpty
                            ? gem.name[0].toUpperCase()
                            : '?';
                        return Tooltip(
                          message: gem.name,
                          child: InkWell(
                            onTap: () {
                              ref.read(activeGemProvider.notifier).state = gem;
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
            color: AppColors.background,
            child: Column(
              children: [
                // Header with gem name and new chat button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeGem?.name ?? 'Chats',
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
    final activeGem = ref.read(activeGemProvider);
    if (activeGem == null) return;

    final convRepo = ref.read(conversationRepositoryProvider);
    final conv = await convRepo.createConversation(gemId: activeGem.uuid);
    ref.read(activeConversationProvider.notifier).state = conv;
  }
}

class _ChatListView extends ConsumerWidget {
  final void Function(dynamic conversation) onConversationTap;

  const _ChatListView({required this.onConversationTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGem = ref.watch(activeGemProvider);
    final activeConv = ref.watch(activeConversationProvider);

    if (activeGem == null) {
      return const Center(
        child: Text('Select a Gem to start', style: AppTextStyles.body),
      );
    }

    final conversationsAsync =
        ref.watch(conversationsForGemProvider(activeGem.uuid));

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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          itemCount: sorted.length,
          itemBuilder: (_, index) {
            final conv = sorted[index];
            return ConversationTile(
              conversation: conv,
              isSelected: activeConv?.uuid == conv.uuid,
              onTap: () => onConversationTap(conv),
            );
          },
        );
      },
    );
  }
}
