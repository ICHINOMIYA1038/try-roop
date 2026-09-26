import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bookmark.dart';
import '../../models/text_lesson.dart';
import '../../models/user_stats.dart';
import '../../providers/providers.dart';
import '../../widgets/app_markdown.dart';
import '../../services/analytics_service.dart';
import '../../services/review_prompt_service.dart';
import '../../services/share_service.dart';
import '../../widgets/premium_lock.dart';
import '../../widgets/error_view.dart';

class TextLessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const TextLessonDetailScreen({super.key, required this.lessonId});

  @override
  ConsumerState<TextLessonDetailScreen> createState() =>
      _TextLessonDetailScreenState();
}

class _TextLessonDetailScreenState
    extends ConsumerState<TextLessonDetailScreen> {
  String? _markdownContent;
  bool _isLoading = true;
  String? _error;
  // 保存中だけ先に見せる状態。確定した値は userStats から読む。
  bool? _pendingCompleted;
  bool _savingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final lessonAsync = await ref.read(textLessonProvider(widget.lessonId).future);

    if (lessonAsync == null) {
      setState(() {
        _error = 'レッスンが見つかりません';
        _isLoading = false;
      });
      return;
    }

    try {
      String content;

      // Firestoreにコンテンツがあればそれを使用、なければローカルアセットを読み込む
      if (lessonAsync.hasFirestoreContent) {
        content = lessonAsync.content!;
      } else if (lessonAsync.usesLocalAsset) {
        content = await rootBundle.loadString(lessonAsync.assetPath!);
      } else {
        throw Exception('コンテンツが設定されていません');
      }

      setState(() {
        _markdownContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'コンテンツの読み込みに失敗しました';
        _isLoading = false;
      });
    }
  }

  bool _isCompletedFrom(UserStats? stats) {
    return _pendingCompleted ??
        (stats?.completedLessonIds.contains(widget.lessonId) ?? false);
  }

  /// 読了状態を保存する。以前は画面を離れると消えるローカル変数だった。
  Future<void> _setCompleted(bool completed) async {
    if (_savingStatus) return;

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学習状況の記録にはログインが必要です')),
      );
      return;
    }

    setState(() {
      _savingStatus = true;
      _pendingCompleted = completed;
    });

    try {
      await ref.read(firestoreServiceProvider).setLessonCompleted(
            uid: uid,
            lessonId: widget.lessonId,
            completed: completed,
          );
      if (completed) {
        AnalyticsService.lessonCompleted(widget.lessonId);
        // 学び終えた直後は、評価をお願いするのに一番よいタイミング。
        ReviewPromptService.recordCompletion();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed ? '学習を完了しました！お疲れ様です🎉' : 'ステータスを「未完了」に戻しました',
          ),
          backgroundColor: completed ? Colors.green : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学習状況を保存できませんでした')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingStatus = false;
          _pendingCompleted = null;
        });
      }
    }
  }

  void _showStatusMenu(bool isCompleted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '学習ステータスの変更',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF433D39),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  ),
                  title: const Text('未完了に戻す'),
                  trailing: !isCompleted ? const Icon(Icons.check, color: Colors.orange) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _setCompleted(false);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  title: const Text('完了にする'),
                  trailing: isCompleted ? const Icon(Icons.check, color: Colors.orange) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _setCompleted(true);
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(textLessonProvider(widget.lessonId));
    final isCompleted = _isCompletedFrom(ref.watch(userStatsProvider).value);

    return lessonAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF9F7F4),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F7F4),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error),
      ),
      data: (lesson) {
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('レッスンが見つかりません')),
          );
        }

        // 有料レッスンは課金状態を確かめてから本文を出す。一覧の鍵表示だけでは
        // 検索結果やブックマークから直接開かれたときに素通りしてしまう。
        if (!ref.watch(canAccessLessonProvider(lesson))) {
          AnalyticsService.paywallBlocked('lesson', lesson.id);
          return PremiumLock(
            title: lesson.title,
            message: 'このレッスンはプレミアムプランでお読みいただけます。',
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9F7F4),
          body: _buildBody(lesson),
          floatingActionButton: _isLoading || _error != null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showStatusMenu(isCompleted),
                  backgroundColor:
                      isCompleted ? Colors.green : const Color(0xFFFF8A3D),
                  elevation: 4,
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.check,
                    color: Colors.white,
                  ),
                  label: Text(
                    isCompleted ? '完了済み' : '学習完了にする',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBody(TextLesson lesson) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadContent();
              },
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: const Color(0xFFF9F7F4),
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: '共有',
              onPressed: () => ShareService.shareLesson(lesson.title),
            ),
            _BookmarkButton(lessonId: lesson.id),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A3D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TEXT LESSON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8A3D),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.estimatedReadingMinutes} min read',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF433D39),
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                AppMarkdown(data: _markdownContent ?? ''),
                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }
}


/// レッスンのブックマーク切り替え。押しても何も起きないボタンが残っていたので、
/// 動画やコースと同じ仕組みにつないでいる。
class _BookmarkButton extends ConsumerWidget {
  final String lessonId;

  const _BookmarkButton({required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      type: BookmarkTargetType.textLesson,
      targetId: lessonId,
    );
    final isBookmarked = ref.watch(hasBookmarkedProvider(params)).value ?? false;

    return IconButton(
      icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
      tooltip: isBookmarked ? 'ブックマークを外す' : 'ブックマークに追加',
      onPressed: () async {
        final uid = ref.read(currentUserProvider)?.uid;
        if (uid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ブックマークにはログインが必要です')),
          );
          return;
        }
        try {
          await ref.read(firestoreServiceProvider).toggleBookmark(
                uid,
                BookmarkTargetType.textLesson,
                lessonId,
              );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ブックマークを更新できませんでした')),
          );
        }
      },
    );
  }
}
