import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/admin_config.dart';
import '../main.dart' show isDemoMode;
import '../models/app_user.dart';
import '../models/video.dart';
import '../models/chapter.dart';
import '../models/category.dart';
import '../models/course.dart';
import '../models/course_progress.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/bookmark.dart';
import '../models/app_notification.dart';
import '../models/announcement.dart';
import '../models/badge.dart';
import '../models/like.dart';
import '../models/live_schedule.dart';
import '../models/user_stats.dart';
import '../models/text_lesson.dart';
import '../models/event.dart';
import '../models/event_participation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/subscription_service.dart';

// ==================== Demo Data ====================

final _demoVideos = [
  // 空手 カテゴリ
  Video(
    id: 'demo1',
    title: 'フィットネス空手 基本の構え',
    description: '画面の見本に合わせて一緒に動くだけ。構えと突きの基本からスタート。',
    youtubeVideoId: 'zlEzw4zXv44',
    thumbnailUrl: 'https://img.youtube.com/vi/zlEzw4zXv44/0.jpg',
    duration: 1800,
    accessLevel: AccessLevel.free,
    categoryId: 'karate',
    order: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Video(
    id: 'demo2',
    title: '脂肪燃焼空手エクササイズ',
    description: 'ゆるめの強度で脂肪燃焼＆姿勢改善。未経験でも安心。',
    youtubeVideoId: 'Xp2meYR_fIA',
    thumbnailUrl: 'https://img.youtube.com/vi/Xp2meYR_fIA/0.jpg',
    duration: 1200,
    accessLevel: AccessLevel.premium,
    categoryId: 'karate',
    order: 2,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // 筋トレ カテゴリ
  Video(
    id: 'demo3',
    title: '初心者向け自重トレーニング',
    description: '自重メインで関節にやさしいメニュー。ゼロから正しいフォーム。',
    youtubeVideoId: 'xgkKsoNTXt8',
    thumbnailUrl: 'https://img.youtube.com/vi/xgkKsoNTXt8/0.jpg',
    duration: 900,
    accessLevel: AccessLevel.free,
    categoryId: 'workout',
    order: 3,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Video(
    id: 'demo4',
    title: '肩こり・腰痛ケア筋トレ',
    description: '10〜15分の短時間セットで習慣化。肩こり・腰痛ケアにも。',
    youtubeVideoId: 'ALloGpY1hUQ',
    thumbnailUrl: 'https://img.youtube.com/vi/ALloGpY1hUQ/0.jpg',
    duration: 600,
    accessLevel: AccessLevel.premium,
    categoryId: 'workout',
    order: 4,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // 健康 カテゴリ
  Video(
    id: 'demo5',
    title: '最高の睡眠 - 免疫力を高める方法',
    description: '食事・睡眠・運動や心の健康をやさしく解説。',
    youtubeVideoId: 'qsQgqNpuhks',
    thumbnailUrl: 'https://img.youtube.com/vi/qsQgqNpuhks/0.jpg',
    duration: 1500,
    accessLevel: AccessLevel.free,
    categoryId: 'health',
    order: 5,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Video(
    id: 'demo6',
    title: '安眠法 - 睡眠の質を上げる',
    description: '季節のセルフケアを1テーマずつ。家族の体調管理にも役立つ。',
    youtubeVideoId: '8LIWI-oAPkU',
    thumbnailUrl: 'https://img.youtube.com/vi/8LIWI-oAPkU/0.jpg',
    duration: 1200,
    accessLevel: AccessLevel.premium,
    categoryId: 'health',
    order: 6,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // AI カテゴリ
  Video(
    id: 'demo7',
    title: 'AI入門 - ChatGPTの使い方',
    description: '初心者向けAI講座。ChatGPTを日常生活で活用する方法。',
    youtubeVideoId: 'sibJTVzp_44',
    thumbnailUrl: 'https://img.youtube.com/vi/sibJTVzp_44/0.jpg',
    duration: 1800,
    accessLevel: AccessLevel.free,
    categoryId: 'ai',
    order: 7,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Video(
    id: 'demo8',
    title: 'AI活用術 - 仕事効率化編',
    description: 'AIを使って仕事を効率化する実践テクニック。',
    youtubeVideoId: 'QwW7qq4ADfs',
    thumbnailUrl: 'https://img.youtube.com/vi/QwW7qq4ADfs/0.jpg',
    duration: 2400,
    accessLevel: AccessLevel.premium,
    categoryId: 'ai',
    order: 8,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

final _demoChapters = {
  'demo1': [
    Chapter(id: 'ch1', videoId: 'demo1', title: 'イントロダクション', startTime: 0, order: 1),
    Chapter(id: 'ch2', videoId: 'demo1', title: 'Flutterとは', startTime: 60, order: 2),
    Chapter(id: 'ch3', videoId: 'demo1', title: 'セットアップ', startTime: 180, order: 3),
    Chapter(id: 'ch4', videoId: 'demo1', title: 'まとめ', startTime: 500, order: 4),
  ],
  'demo2': [
    Chapter(id: 'ch5', videoId: 'demo2', title: 'Riverpodとは', startTime: 0, order: 1),
    Chapter(id: 'ch6', videoId: 'demo2', title: 'Provider種類', startTime: 300, order: 2),
    Chapter(id: 'ch7', videoId: 'demo2', title: '実践例', startTime: 600, order: 3),
  ],
  'demo3': [
    Chapter(id: 'ch8', videoId: 'demo3', title: 'Firebase設定', startTime: 0, order: 1),
    Chapter(id: 'ch9', videoId: 'demo3', title: '認証実装', startTime: 200, order: 2),
  ],
};

final _demoCourses = [
  Course(
    id: 'course1',
    title: '空手フィットネス入門',
    description: '空手の基本動作を使った全身フィットネス。初心者でも安心して始められるプログラムです。',
    thumbnailUrl: 'https://img.youtube.com/vi/zlEzw4zXv44/0.jpg',
    categoryId: 'karate',
    videoIds: ['demo1', 'demo2'],
    totalDuration: 50,
    difficulty: CourseDifficulty.beginner,
    isPublished: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  ),
  Course(
    id: 'course2',
    title: '自重トレーニング完全ガイド',
    description: '器具を使わない自重トレーニングで、効率よく筋力アップを目指しましょう。',
    thumbnailUrl: 'https://img.youtube.com/vi/xgkKsoNTXt8/0.jpg',
    categoryId: 'workout',
    videoIds: ['demo3', 'demo4'],
    totalDuration: 25,
    difficulty: CourseDifficulty.beginner,
    isPublished: true,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now(),
  ),
  Course(
    id: 'course3',
    title: '睡眠改善マスター講座',
    description: '質の高い睡眠を手に入れるための科学的アプローチを学びます。',
    thumbnailUrl: 'https://img.youtube.com/vi/qsQgqNpuhks/0.jpg',
    categoryId: 'health',
    videoIds: ['demo5', 'demo6'],
    totalDuration: 45,
    difficulty: CourseDifficulty.intermediate,
    isPublished: true,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now(),
  ),
  Course(
    id: 'course4',
    title: 'AI活用入門コース',
    description: 'ChatGPTを始めとするAIツールの基礎から応用まで学べるコースです。',
    thumbnailUrl: 'https://img.youtube.com/vi/sibJTVzp_44/0.jpg',
    categoryId: 'ai',
    videoIds: ['demo7', 'demo8'],
    totalDuration: 70,
    difficulty: CourseDifficulty.beginner,
    isPublished: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now(),
  ),
];

List<Post> demoPosts = [
  Post(
    id: 'post1',
    authorId: 'demo_user',
    authorName: 'サロン運営',
    authorPhotoUrl: null,
    content: '皆さん、tryroop campus liveへようこそ！\n\nこのコミュニティでは、健康・フィットネス・AIについて一緒に学んでいきましょう。質問や感想があればお気軽に投稿してください！',
    imageUrls: [],
    likeCount: 42,
    commentCount: 5,
    isPinned: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  Post(
    id: 'post2',
    authorId: 'user1',
    authorName: '田中太郎',
    authorPhotoUrl: null,
    content: '空手フィットネス入門コースを完走しました！🎉\n\n最初は体が硬くて大変でしたが、毎日少しずつ続けていたら、だいぶ動けるようになりました。次は自重トレーニングに挑戦します！',
    imageUrls: [],
    likeCount: 15,
    commentCount: 3,
    isPinned: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Post(
    id: 'post3',
    authorId: 'user2',
    authorName: '鈴木花子',
    authorPhotoUrl: null,
    content: 'AI活用コース、とても勉強になりました！\n\nChatGPTを使って仕事の効率が上がりました。特にメール作成のテンプレート化が便利です。',
    imageUrls: [],
    likeCount: 23,
    commentCount: 7,
    isPinned: false,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

void addDemoPost(Post post) {
  demoPosts.insert(0, post);
}

final _demoComments = {
  'post1': [
    Comment(
      id: 'comment1',
      targetType: CommentTargetType.post,
      targetId: 'post1',
      authorId: 'user1',
      authorName: '田中太郎',
      content: 'よろしくお願いします！',
      likeCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 29)),
      updatedAt: DateTime.now().subtract(const Duration(days: 29)),
    ),
  ],
};

final _demoAnnouncements = [
  Announcement(
    id: 'ann1',
    title: '年末年始の配信スケジュールについて',
    content: '年末年始も通常通り配信を行います。\n\n12月31日と1月1日は特別ライブ配信を予定しています。お楽しみに！',
    isPublished: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Announcement(
    id: 'ann2',
    title: '新コース「ヨガ入門」がリリースされました',
    content: 'リクエストの多かったヨガ入門コースをリリースしました！\n\n初心者向けの優しいプログラムですので、ぜひチャレンジしてみてください。',
    isPublished: true,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
];

final _demoBadges = [
  Badge(
    id: 'badge1',
    name: 'ファーストステップ',
    description: '初めての動画を視聴しました',
    iconUrl: '🎬',
    condition: BadgeCondition(type: BadgeConditionType.videosWatched, threshold: 1),
    createdAt: DateTime.now(),
  ),
  Badge(
    id: 'badge2',
    name: 'コース完走',
    description: '初めてのコースを完了しました',
    iconUrl: '🏆',
    condition: BadgeCondition(type: BadgeConditionType.coursesCompleted, threshold: 1),
    createdAt: DateTime.now(),
  ),
  Badge(
    id: 'badge3',
    name: '継続は力なり',
    description: '7日間連続でアプリを利用しました',
    iconUrl: '🔥',
    condition: BadgeCondition(type: BadgeConditionType.consecutiveDays, threshold: 7),
    createdAt: DateTime.now(),
  ),
  Badge(
    id: 'badge4',
    name: 'コミュニティ参加',
    description: '初めての投稿を行いました',
    iconUrl: '💬',
    condition: BadgeCondition(type: BadgeConditionType.postsCreated, threshold: 1),
    createdAt: DateTime.now(),
  ),
];

final _demoLiveSchedules = [
  LiveSchedule(
    id: 'live1',
    title: '年末特別ライブ - 2024年の振り返り',
    description: '今年一年の学びを振り返る特別配信です。質問も受け付けます！',
    scheduledAt: DateTime.now().add(const Duration(days: 7)),
    duration: 60,
    status: LiveStatus.scheduled,
    createdAt: DateTime.now(),
  ),
  LiveSchedule(
    id: 'live2',
    title: '新年ライブ - 2025年の目標設定',
    description: '新年を迎えて、一緒に目標を設定しましょう！',
    scheduledAt: DateTime.now().add(const Duration(days: 14)),
    duration: 90,
    status: LiveStatus.scheduled,
    createdAt: DateTime.now(),
  ),
];

final _demoNotifications = [
  AppNotification(
    id: 'notif1',
    userId: 'demo_user',
    type: NotificationType.announcement,
    title: '新しいお知らせ',
    body: '年末年始の配信スケジュールについて',
    data: {'announcementId': 'ann1'},
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'notif2',
    userId: 'demo_user',
    type: NotificationType.newCourse,
    title: '新コース追加',
    body: 'AI活用入門コースが追加されました',
    data: {'courseId': 'course4'},
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

// ==================== Services ====================

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final subscriptionServiceProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());

// ==================== Auth ====================

final authStateProvider = StreamProvider<User?>((ref) {
  if (isDemoMode) {
    return Stream.value(null);
  }
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ==================== App User ====================

final appUserProvider = StreamProvider<AppUser?>((ref) {
  if (isDemoMode) {
    return Stream.value(AppUser(
      uid: 'demo_user',
      email: 'demo@example.com',
      displayName: 'デモユーザー',
      membershipType: MembershipType.premium,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreServiceProvider).userStream(user.uid);
});

// ==================== User Stats ====================

final userStatsProvider = StreamProvider<UserStats?>((ref) {
  if (isDemoMode) {
    return Stream.value(UserStats(
      id: 'demo_user',
      bio: 'デモユーザーです。よろしくお願いします！',
      totalWatchTime: 120,
      completedCourses: 2,
      completedVideos: 5,
      badgeIds: ['badge1', 'badge2'],
      consecutiveDays: 7,
      lastActiveAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreServiceProvider).userStatsStream(user.uid);
});

// ==================== Subscription ====================

final isPremiumProvider = FutureProvider<bool>((ref) async {
  if (isDemoMode) {
    return true;
  }

  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return false;

  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.isPremium();
});

final packagesProvider = FutureProvider<List<Package>>((ref) async {
  if (isDemoMode) {
    return [];
  }
  return await ref.watch(subscriptionServiceProvider).getPackages();
});

// ==================== Videos ====================

final videosProvider = StreamProvider<List<Video>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoVideos);
  }
  return ref.watch(firestoreServiceProvider).videosStream();
});

final freeVideosProvider = Provider<List<Video>>((ref) {
  final videos = ref.watch(videosProvider).value ?? [];
  return videos.where((v) => v.accessLevel == AccessLevel.free).toList();
});

final premiumVideosProvider = Provider<List<Video>>((ref) {
  final videos = ref.watch(videosProvider).value ?? [];
  return videos.where((v) => v.accessLevel == AccessLevel.premium).toList();
});

final accessibleVideosProvider = Provider<List<Video>>((ref) {
  final videos = ref.watch(videosProvider).value ?? [];
  final isPremium = ref.watch(isPremiumProvider).value ?? false;

  if (isPremium) {
    return videos;
  } else {
    return videos.where((v) => v.accessLevel == AccessLevel.free).toList();
  }
});

final videoProvider =
    FutureProvider.family<Video?, String>((ref, videoId) async {
  if (isDemoMode) {
    return _demoVideos.where((v) => v.id == videoId).firstOrNull;
  }
  return await ref.watch(firestoreServiceProvider).getVideo(videoId);
});

final recentVideosProvider = FutureProvider<List<Video>>((ref) async {
  if (isDemoMode) {
    return _demoVideos.take(5).toList();
  }
  return await ref.watch(firestoreServiceProvider).getRecentVideos(limit: 5);
});

// ==================== Chapters ====================

final chaptersProvider =
    StreamProvider.family<List<Chapter>, String>((ref, videoId) {
  if (isDemoMode) {
    return Stream.value(_demoChapters[videoId] ?? []);
  }
  return ref.watch(firestoreServiceProvider).chaptersStream(videoId);
});

// ==================== Categories ====================

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  if (isDemoMode) {
    return Stream.value([
      Category(id: 'karate', name: '空手', order: 1),
      Category(id: 'workout', name: '筋トレ', order: 2),
      Category(id: 'health', name: '健康', order: 3),
      Category(id: 'ai', name: 'AI', order: 4),
    ]);
  }
  return ref.watch(firestoreServiceProvider).categoriesStream();
});

// ==================== Video by Category ====================

final videosByCategoryProvider =
    FutureProvider.family<List<Video>, String>((ref, categoryId) async {
  if (isDemoMode) {
    return _demoVideos.where((v) => v.categoryId == categoryId).toList();
  }
  return await ref
      .watch(firestoreServiceProvider)
      .getVideosByCategory(categoryId);
});

// ==================== Courses ====================

final coursesProvider = StreamProvider<List<Course>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoCourses);
  }
  return ref.watch(firestoreServiceProvider).coursesStream();
});

final courseProvider = FutureProvider.family<Course?, String>((ref, courseId) async {
  if (isDemoMode) {
    return _demoCourses.where((c) => c.id == courseId).firstOrNull;
  }
  return await ref.watch(firestoreServiceProvider).getCourse(courseId);
});

final coursesByCategoryProvider =
    FutureProvider.family<List<Course>, String>((ref, categoryId) async {
  if (isDemoMode) {
    return _demoCourses.where((c) => c.categoryId == categoryId).toList();
  }
  return await ref
      .watch(firestoreServiceProvider)
      .getCoursesByCategory(categoryId);
});

final courseVideosProvider =
    Provider.family<List<Video>, Course>((ref, course) {
  final allVideos = ref.watch(videosProvider).value ?? [];
  return course.videoIds
      .map((id) => allVideos.where((v) => v.id == id).firstOrNull)
      .whereType<Video>()
      .toList();
});

// ==================== Course Progress ====================

final courseProgressProvider =
    StreamProvider.family<CourseProgress?, String>((ref, courseId) {
  if (isDemoMode) {
    return Stream.value(CourseProgress(
      id: 'demo_user_$courseId',
      userId: 'demo_user',
      courseId: courseId,
      completedVideoIds: ['demo1'],
      progressPercent: 0.5,
      isCompleted: false,
      updatedAt: DateTime.now(),
    ));
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreServiceProvider).courseProgressStream(user.uid, courseId);
});

final userCourseProgressListProvider = FutureProvider<List<CourseProgress>>((ref) async {
  if (isDemoMode) {
    return [
      CourseProgress(
        id: 'demo_user_course1',
        userId: 'demo_user',
        courseId: 'course1',
        completedVideoIds: ['demo1'],
        progressPercent: 0.5,
        isCompleted: false,
        updatedAt: DateTime.now(),
      ),
    ];
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return await ref.watch(firestoreServiceProvider).getUserCourseProgress(user.uid);
});

// ==================== Posts ====================

final postsProvider = StreamProvider<List<Post>>((ref) {
  if (isDemoMode) {
    return Stream.value(demoPosts);
  }
  return ref.watch(firestoreServiceProvider).postsStream();
});

final postProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  if (isDemoMode) {
    final posts = ref.watch(postsProvider).value ?? demoPosts;
    return posts.where((p) => p.id == postId).firstOrNull;
  }
  return await ref.watch(firestoreServiceProvider).getPost(postId);
});

// ==================== Comments ====================

final commentsProvider =
    StreamProvider.family<List<Comment>, ({CommentTargetType type, String targetId})>(
        (ref, params) {
  if (isDemoMode) {
    if (params.type == CommentTargetType.post) {
      return Stream.value(_demoComments[params.targetId] ?? []);
    }
    return Stream.value([]);
  }
  return ref
      .watch(firestoreServiceProvider)
      .commentsStream(params.type, params.targetId);
});

// ==================== Likes ====================

final hasLikedProvider =
    StreamProvider.family<bool, ({LikeTargetType type, String targetId})>(
        (ref, params) {
  if (isDemoMode) {
    return Stream.value(false);
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);

  return ref
      .watch(firestoreServiceProvider)
      .likeStream(user.uid, params.type, params.targetId);
});

// ==================== Bookmarks ====================

final hasBookmarkedProvider =
    StreamProvider.family<bool, ({BookmarkTargetType type, String targetId})>(
        (ref, params) {
  if (isDemoMode) {
    return Stream.value(false);
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);

  return ref
      .watch(firestoreServiceProvider)
      .bookmarkStream(user.uid, params.type, params.targetId);
});

final userBookmarksProvider =
    FutureProvider.family<List<Bookmark>, BookmarkTargetType?>((ref, type) async {
  if (isDemoMode) {
    return [];
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return await ref
      .watch(firestoreServiceProvider)
      .getUserBookmarks(user.uid, targetType: type);
});

// ==================== Notifications ====================

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoNotifications);
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return ref.watch(firestoreServiceProvider).notificationsStream(user.uid);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  if (isDemoMode) {
    return Stream.value(1);
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  return ref.watch(firestoreServiceProvider).unreadNotificationCountStream(user.uid);
});

// ==================== Announcements ====================

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoAnnouncements);
  }
  return ref.watch(firestoreServiceProvider).announcementsStream();
});

final latestAnnouncementProvider = FutureProvider<Announcement?>((ref) async {
  if (isDemoMode) {
    return _demoAnnouncements.isNotEmpty ? _demoAnnouncements.first : null;
  }
  return await ref.watch(firestoreServiceProvider).getLatestAnnouncement();
});

// ==================== Badges ====================

final badgesProvider = StreamProvider<List<Badge>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoBadges);
  }
  return ref.watch(firestoreServiceProvider).badgesStream();
});

final userBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  if (isDemoMode) {
    return _demoBadges.take(2).toList();
  }

  final userStats = ref.watch(userStatsProvider).value;
  if (userStats == null || userStats.badgeIds.isEmpty) return [];

  return await ref.watch(firestoreServiceProvider).getUserBadges(userStats.badgeIds);
});

// ==================== Live Schedules ====================

final liveSchedulesProvider = StreamProvider<List<LiveSchedule>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoLiveSchedules);
  }
  return ref.watch(firestoreServiceProvider).liveSchedulesStream();
});

final upcomingLiveSchedulesProvider = FutureProvider<List<LiveSchedule>>((ref) async {
  if (isDemoMode) {
    return _demoLiveSchedules.where((l) => l.isUpcoming).toList();
  }
  return await ref.watch(firestoreServiceProvider).getUpcomingLiveSchedules();
});

final currentLiveProvider = FutureProvider<LiveSchedule?>((ref) async {
  if (isDemoMode) {
    return null;
  }
  return await ref.watch(firestoreServiceProvider).getCurrentLive();
});

// ==================== Search ====================

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return {'videos': <Video>[], 'courses': <Course>[], 'posts': <Post>[]};
  }

  if (isDemoMode) {
    final videos = _demoVideos
        .where((v) => v.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final courses = _demoCourses
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final posts = demoPosts
        .where((p) => p.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return {'videos': videos, 'courses': courses, 'posts': posts};
  }

  return await ref.watch(firestoreServiceProvider).search(query);
});

// ==================== Members ====================

final membersProvider = FutureProvider<List<AppUser>>((ref) async {
  if (isDemoMode) {
    return [
      AppUser(
        uid: 'demo_user',
        email: 'demo@example.com',
        displayName: 'デモユーザー',
        membershipType: MembershipType.premium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: 'user1',
        email: 'tanaka@example.com',
        displayName: '田中太郎',
        membershipType: MembershipType.premium,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: 'user2',
        email: 'suzuki@example.com',
        displayName: '鈴木花子',
        membershipType: MembershipType.premium,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  return await ref.watch(firestoreServiceProvider).getMembers();
});

// ==================== Navigation ====================

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

// ==================== Text Lessons ====================

final _demoTextLessons = [
  // 空手カテゴリ
  TextLesson(
    id: 'lesson_karate_1',
    title: '空手の基本姿勢と構え',
    description: '空手を始める前に知っておきたい基本姿勢と正しい構え方を解説します。',
    assetPath: 'assets/lessons/karate/basics.md',
    categoryId: 'karate',
    order: 1,
    estimatedReadingMinutes: 5,
    accessLevel: AccessLevel.free,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  TextLesson(
    id: 'lesson_karate_2',
    title: '突きの基本技術',
    description: '正拳突き、追い突き、逆突きなど基本的な突き技を学びます。',
    assetPath: 'assets/lessons/karate/punches.md',
    categoryId: 'karate',
    order: 2,
    estimatedReadingMinutes: 8,
    accessLevel: AccessLevel.free,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  TextLesson(
    id: 'lesson_karate_3',
    title: '蹴りの基本技術',
    description: '前蹴り、回し蹴り、横蹴りなど基本的な蹴り技を解説します。',
    assetPath: 'assets/lessons/karate/kicks.md',
    categoryId: 'karate',
    order: 3,
    estimatedReadingMinutes: 10,
    accessLevel: AccessLevel.premium,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // 筋トレカテゴリ
  TextLesson(
    id: 'lesson_workout_1',
    title: '自重トレーニング入門',
    description: '器具を使わず自分の体重だけで行うトレーニングの基礎を学びます。',
    assetPath: 'assets/lessons/workout/bodyweight.md',
    categoryId: 'workout',
    order: 1,
    estimatedReadingMinutes: 6,
    accessLevel: AccessLevel.free,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  TextLesson(
    id: 'lesson_workout_2',
    title: '正しいスクワットのフォーム',
    description: '膝や腰を痛めない正しいスクワットのやり方を詳しく解説。',
    assetPath: 'assets/lessons/workout/squat.md',
    categoryId: 'workout',
    order: 2,
    estimatedReadingMinutes: 7,
    accessLevel: AccessLevel.free,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // 健康カテゴリ
  TextLesson(
    id: 'lesson_health_1',
    title: '質の良い睡眠のコツ',
    description: '睡眠の質を高めるための環境づくりと習慣について解説します。',
    assetPath: 'assets/lessons/health/sleep.md',
    categoryId: 'health',
    order: 1,
    estimatedReadingMinutes: 8,
    accessLevel: AccessLevel.free,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  TextLesson(
    id: 'lesson_health_2',
    title: 'ストレス管理の基本',
    description: '日常生活で実践できるストレス管理のテクニックを紹介します。',
    assetPath: 'assets/lessons/health/stress.md',
    categoryId: 'health',
    order: 2,
    estimatedReadingMinutes: 10,
    accessLevel: AccessLevel.premium,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // AIカテゴリ
  TextLesson(
    id: 'lesson_ai_1',
    title: 'ChatGPT入門ガイド',
    description: 'ChatGPTの基本的な使い方とプロンプトの書き方を学びます。',
    assetPath: 'assets/lessons/ai/chatgpt_intro.md',
    categoryId: 'ai',
    order: 1,
    estimatedReadingMinutes: 10,
    accessLevel: AccessLevel.free,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  TextLesson(
    id: 'lesson_ai_2',
    title: 'プロンプトエンジニアリング基礎',
    description: 'AIから良い回答を引き出すためのプロンプト設計テクニック。',
    assetPath: 'assets/lessons/ai/prompt_engineering.md',
    categoryId: 'ai',
    order: 2,
    estimatedReadingMinutes: 15,
    accessLevel: AccessLevel.premium,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

final textLessonsProvider = StreamProvider<List<TextLesson>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoTextLessons);
  }
  return ref.watch(firestoreServiceProvider).textLessonsStream();
});

final freeTextLessonsProvider = Provider<List<TextLesson>>((ref) {
  final lessons = ref.watch(textLessonsProvider).value ?? [];
  return lessons.where((l) => l.isFree).toList();
});

final textLessonsByCategoryProvider =
    Provider.family<List<TextLesson>, String>((ref, categoryId) {
  final lessons = ref.watch(textLessonsProvider).value ?? [];
  return lessons.where((l) => l.categoryId == categoryId).toList();
});

final textLessonProvider =
    FutureProvider.family<TextLesson?, String>((ref, lessonId) async {
  if (isDemoMode) {
    return _demoTextLessons.where((l) => l.id == lessonId).firstOrNull;
  }
  return await ref.watch(firestoreServiceProvider).getTextLesson(lessonId);
});

// ==================== Admin ====================

final isAdminProvider = Provider<bool>((ref) {
  if (isDemoMode) {
    return true; // デモモードでは管理者権限を有効に
  }
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return isAdminEmail(user.email);
});

// ==================== Events ====================

final _demoEvents = [
  Event(
    id: 'event1',
    title: 'オンライン空手セミナー',
    description: '初心者向けの空手セミナーです。基本の型を一緒に練習しましょう。\n\n持ち物：動きやすい服装、タオル、水分\n\n当日はZoomで参加いただけます。',
    eventType: EventType.online,
    startAt: DateTime.now().add(const Duration(days: 7, hours: 2)),
    endAt: DateTime.now().add(const Duration(days: 7, hours: 4)),
    capacity: 50,
    currentParticipants: 35,
    meetingUrl: 'https://zoom.us/j/example',
    imageUrl: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
    status: EventStatus.scheduled,
    requiresRegistration: true,
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    updatedAt: DateTime.now().subtract(const Duration(days: 14)),
  ),
  Event(
    id: 'event2',
    title: '東京オフラインミートアップ',
    description: 'メンバー同士の交流イベントです。\n\n普段オンラインで学んでいる仲間と実際に会って交流しましょう！\n\n軽食とドリンクをご用意しています。',
    eventType: EventType.offline,
    startAt: DateTime.now().add(const Duration(days: 14, hours: 6)),
    endAt: DateTime.now().add(const Duration(days: 14, hours: 9)),
    capacity: 20,
    currentParticipants: 20,
    location: '東京都渋谷区神南1-2-3 渋谷スタジオ 3F',
    imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
    status: EventStatus.scheduled,
    requiresRegistration: true,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Event(
    id: 'event3',
    title: 'AI活用ワークショップ',
    description: 'ChatGPTを使った実践的なワークショップです。\n\n・プロンプトエンジニアリングの基礎\n・仕事で使える活用術\n・Q&Aセッション\n\n参加者には特別資料をプレゼント！',
    eventType: EventType.online,
    startAt: DateTime.now().add(const Duration(days: 21, hours: -2)),
    endAt: DateTime.now().add(const Duration(days: 21)),
    capacity: 100,
    currentParticipants: 45,
    meetingUrl: 'https://meet.google.com/example',
    imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800',
    status: EventStatus.scheduled,
    requiresRegistration: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Event(
    id: 'event4',
    title: '大阪オフラインセミナー',
    description: '大阪エリア初の対面セミナーを開催します！\n\n空手フィットネスの基礎を直接指導します。初心者大歓迎！',
    eventType: EventType.offline,
    startAt: DateTime.now().add(const Duration(days: 30, hours: 3)),
    endAt: DateTime.now().add(const Duration(days: 30, hours: 6)),
    capacity: 15,
    currentParticipants: 8,
    location: '大阪府大阪市北区梅田1-1-1 大阪スタジオ 2F',
    imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    status: EventStatus.scheduled,
    requiresRegistration: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final _demoEventParticipations = <EventParticipation>[
  EventParticipation(
    id: 'demo_user_event1',
    userId: 'demo_user',
    eventId: 'event1',
    status: ParticipationStatus.confirmed,
    waitlistPosition: 0,
    registeredAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

final eventsProvider = StreamProvider<List<Event>>((ref) {
  if (isDemoMode) {
    return Stream.value(_demoEvents);
  }
  return ref.watch(firestoreServiceProvider).eventsStream();
});

final eventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  if (isDemoMode) {
    return _demoEvents.where((e) => e.id == eventId).firstOrNull;
  }
  return await ref.watch(firestoreServiceProvider).getEvent(eventId);
});

final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  if (isDemoMode) {
    return _demoEvents.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
  return await ref.watch(firestoreServiceProvider).getUpcomingEvents();
});

final eventsByMonthProvider = FutureProvider.family<List<Event>, DateTime>((ref, month) async {
  if (isDemoMode) {
    return _demoEvents.where((e) =>
      e.startAt.year == month.year && e.startAt.month == month.month
    ).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
  return await ref.watch(firestoreServiceProvider).getEventsByMonth(month);
});

// ==================== Event Participations ====================

final eventParticipationProvider = StreamProvider.family<EventParticipation?, String>((ref, eventId) {
  if (isDemoMode) {
    final participation = _demoEventParticipations
        .where((p) => p.eventId == eventId && p.userId == 'demo_user' && !p.isCancelled)
        .firstOrNull;
    return Stream.value(participation);
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreServiceProvider)
      .eventParticipationStream(user.uid, eventId);
});

final userEventParticipationsProvider = FutureProvider<List<EventParticipation>>((ref) async {
  if (isDemoMode) {
    return _demoEventParticipations.where((p) => !p.isCancelled).toList();
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return await ref.watch(firestoreServiceProvider)
      .getUserEventParticipations(user.uid);
});

final eventParticipantsCountProvider = StreamProvider.family<int, String>((ref, eventId) {
  if (isDemoMode) {
    final event = _demoEvents.where((e) => e.id == eventId).firstOrNull;
    return Stream.value(event?.currentParticipants ?? 0);
  }
  return ref.watch(firestoreServiceProvider)
      .eventParticipantsCountStream(eventId);
});

// Selected date for calendar filtering
final selectedEventDateProvider = StateProvider<DateTime?>((ref) => null);

// Event type filter
final eventTypeFilterProvider = StateProvider<EventType?>((ref) => null);

// Focused month for calendar
final focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
