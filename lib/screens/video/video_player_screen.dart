import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../config/feature_flags.dart';
import '../../providers/providers.dart';
import '../../models/chapter.dart';
import '../../models/video.dart';
import '../../services/analytics_service.dart';
import '../../services/firestore_service.dart';
import '../../services/share_service.dart';
import '../../widgets/chapter_list.dart';
import '../../widgets/premium_lock.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  final String? courseId;

  const VideoPlayerScreen({super.key, required this.videoId, this.courseId});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  int _currentChapterIndex = 0;

  // 視聴位置の保存まわり
  Timer? _progressTimer;
  Video? _video;
  bool _restoredPosition = false;
  // dispose() のなかで ref を触るのは避けたいので、build のたびに控えておく。
  String? _uid;
  FirestoreService? _firestore;

  @override
  void dispose() {
    _progressTimer?.cancel();
    // 画面を閉じた瞬間の位置を最後に書き込む。await できないので投げっぱなしにする。
    _saveProgress();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  /// いまの再生位置を保存する。無料・有料は問わず、ログイン中だけ記録する。
  void _saveProgress() {
    final video = _video;
    final controller = _controller;
    final uid = _uid;
    final firestore = _firestore;
    if (video == null || controller == null || uid == null) return;
    if (firestore == null || !_isPlayerReady) return;

    final position = controller.value.position.inSeconds;
    if (position <= 0) return;

    firestore
        .recordVideoProgress(
          uid: uid,
          video: video,
          positionSeconds: position,
          courseId: widget.courseId,
        )
        .catchError((Object e) {
      debugPrint('failed to save video progress: $e');
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _saveProgress(),
    );
  }

  /// 前回の続きから再生できるよう、保存済みの位置まで飛ばす。
  Future<void> _restorePosition(Video video) async {
    if (_restoredPosition) return;
    _restoredPosition = true;

    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) return;

    try {
      final saved = await firestore.getProgress(uid, video.id);
      if (saved == null || saved.completed || saved.currentTime < 10) return;
      // 見終わる直前だった場合は最初から流す。
      if (video.duration > 0 && saved.currentTime >= video.duration * 0.9) {
        return;
      }
      if (!mounted) return;
      _controller?.seekTo(Duration(seconds: saved.currentTime));
    } catch (e) {
      debugPrint('failed to restore video progress: $e');
    }
  }

  void _initController(String youtubeVideoId) {
    _controller = YoutubePlayerController(
      initialVideoId: youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    )..addListener(() {
        if (_isPlayerReady && mounted) {
          _updateCurrentChapter();
        }
      });
  }

  void _updateCurrentChapter() {
    final chapters = ref.read(chaptersProvider(widget.videoId)).value ?? [];
    if (chapters.isEmpty || _controller == null) return;

    final currentPosition = _controller!.value.position.inSeconds;

    for (int i = chapters.length - 1; i >= 0; i--) {
      if (currentPosition >= chapters[i].startTime) {
        if (_currentChapterIndex != i) {
          setState(() {
            _currentChapterIndex = i;
          });
        }
        break;
      }
    }
  }

  void _seekToChapter(Chapter chapter) {
    _controller?.seekTo(Duration(seconds: chapter.startTime));
    _controller?.play();
  }

  void _seekToPreviousChapter(List<Chapter> chapters) {
    if (_currentChapterIndex > 0) {
      _seekToChapter(chapters[_currentChapterIndex - 1]);
    }
  }

  void _seekToNextChapter(List<Chapter> chapters) {
    if (_currentChapterIndex < chapters.length - 1) {
      _seekToChapter(chapters[_currentChapterIndex + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show coming soon when video content is disabled
    if (!FeatureFlags.isVideoContentEnabled) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A3D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Color(0xFFFF8A3D),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '動画コンテンツ準備中',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF433D39),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'オリジナル動画コンテンツを\n鋭意制作中です。\nもうしばらくお待ちください！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A3D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ホームに戻る',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final videoAsync = ref.watch(videoProvider(widget.videoId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.videoId));

    return videoAsync.when(
      data: (video) {
        if (video == null) {
          return const Scaffold(
            body: Center(child: Text('動画が見つかりません')),
          );
        }

        // 有料動画は課金状態を確かめてから再生する。検索結果やブックマーク、
        // コース詳細から直接この画面に来られるため、一覧側の鍵表示だけでは
        // 素通りしてしまう。
        if (!ref.watch(canAccessVideoProvider(video))) {
          AnalyticsService.paywallBlocked('video', video.id);
          return PremiumLock(
            title: video.title,
            message: 'この動画はプレミアムプランでご覧いただけます。',
          );
        }

        _video = video;
        _uid = ref.watch(currentUserProvider)?.uid;
        _firestore = ref.watch(firestoreServiceProvider);

        // Initialize controller if not already
        if (_controller == null) {
          _initController(video.youtubeVideoId);
        }

        return YoutubePlayerBuilder(
          onExitFullScreen: () {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
          },
          player: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFFFF8A3D),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFFFF8A3D),
              handleColor: Color(0xFFFF8A3D),
            ),
            onReady: () {
              setState(() {
                _isPlayerReady = true;
              });
              AnalyticsService.videoOpened(video.id, premium: video.isPremium);
              _restorePosition(video);
              _startProgressTimer();
            },
          ),
          builder: (context, player) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.black),
                    tooltip: '共有',
                    onPressed: () => ShareService.shareVideo(video.title),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // YouTube Player
                  player,

                  // Chapter Navigation
                  chaptersAsync.when(
                    data: (chapters) {
                      if (chapters.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _currentChapterIndex > 0
                                  ? () => _seekToPreviousChapter(chapters)
                                  : null,
                              icon: const Icon(Icons.skip_previous),
                              color: _currentChapterIndex > 0
                                  ? const Color(0xFFFF8A3D)
                                  : Colors.grey,
                            ),
                            Expanded(
                              child: Text(
                                chapters[_currentChapterIndex].title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _currentChapterIndex < chapters.length - 1
                                      ? () => _seekToNextChapter(chapters)
                                      : null,
                              icon: const Icon(Icons.skip_next),
                              color:
                                  _currentChapterIndex < chapters.length - 1
                                      ? const Color(0xFFFF8A3D)
                                      : Colors.grey,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Video Info & Chapters List
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Video Info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      video.durationFormatted,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (video.isPremium) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8A3D),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Premium',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (video.description.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    video.description,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Chapters
                          chaptersAsync.when(
                            data: (chapters) {
                              if (chapters.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return ChapterList(
                                chapters: chapters,
                                currentChapterIndex: _currentChapterIndex,
                                onChapterTap: _seekToChapter,
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Center(
                              child: Text('Error: $e'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
