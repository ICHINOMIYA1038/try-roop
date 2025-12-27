import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../providers/providers.dart';
import '../../models/chapter.dart';
import '../../widgets/chapter_list.dart';

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

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
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
    final videoAsync = ref.watch(videoProvider(widget.videoId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.videoId));

    return videoAsync.when(
      data: (video) {
        if (video == null) {
          return const Scaffold(
            body: Center(child: Text('動画が見つかりません')),
          );
        }

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
