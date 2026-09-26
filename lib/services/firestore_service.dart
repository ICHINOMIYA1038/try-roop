import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/moderation/moderation_models.dart';
import '../features/try_loop/try_record.dart';
import '../models/app_user.dart';
import '../models/video.dart';
import '../models/chapter.dart';
import '../models/video_progress.dart';
import '../models/category.dart';
import '../models/course.dart';
import '../models/course_progress.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/like.dart';
import '../models/bookmark.dart';
import '../models/app_notification.dart';
import '../models/announcement.dart';
import '../models/badge.dart';
import '../models/live_schedule.dart';
import '../models/user_stats.dart';
import '../models/event.dart';
import '../models/event_participation.dart';
import '../models/text_lesson.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== Users ====================

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }

  Future<void> updateUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!, uid);
    });
  }

  // ==================== User Stats ====================

  Future<UserStats?> getUserStats(String uid) async {
    final doc = await _db.collection('userStats').doc(uid).get();
    if (!doc.exists) return null;
    return UserStats.fromMap(doc.data()!, uid);
  }

  Future<void> saveUserStats(UserStats stats) async {
    await _db.collection('userStats').doc(stats.id).set(stats.toMap());
  }

  Stream<UserStats?> userStatsStream(String uid) {
    return _db.collection('userStats').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserStats.fromMap(doc.data()!, uid);
    });
  }

  Future<List<AppUser>> getMembers({int limit = 50}) async {
    final snapshot = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Videos ====================

  Future<List<Video>> getVideos({AccessLevel? accessLevel}) async {
    Query<Map<String, dynamic>> query =
        _db.collection('videos').orderBy('order');

    if (accessLevel != null) {
      query = query.where('accessLevel', isEqualTo: accessLevel.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Video.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Video>> getVideosByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('videos')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) => Video.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Video?> getVideo(String videoId) async {
    final doc = await _db.collection('videos').doc(videoId).get();
    if (!doc.exists) return null;
    return Video.fromMap(doc.data()!, videoId);
  }

  Stream<List<Video>> videosStream() {
    return _db
        .collection('videos')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Video.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<Video>> getRecentVideos({int limit = 10}) async {
    final snapshot = await _db
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Video.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Video>> searchVideos(String query) async {
    final snapshot = await _db
        .collection('videos')
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => Video.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Chapters ====================

  Future<List<Chapter>> getChapters(String videoId) async {
    final snapshot = await _db
        .collection('chapters')
        .where('videoId', isEqualTo: videoId)
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => Chapter.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Chapter>> chaptersStream(String videoId) {
    return _db
        .collection('chapters')
        .where('videoId', isEqualTo: videoId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chapter.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==================== Subscription mirror ====================

  /// RevenueCat の課金状態を、集計用に users に写す。
  ///
  /// **権限の判定にはこの値を使わない。** 使うと、解約した人が
  /// 次に開くまで（あるいは永久に）プレミアムのままになる。
  /// 権限は必ず RevenueCat を見る。ここは運営が人数を数えるためだけ。
  Future<void> mirrorSubscription(String uid, {required bool active}) async {
    final ref = _db.collection('users').doc(uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    // 変わっていなければ書かない。起動のたびに書き込まないため。
    if (snapshot.data()?['hasActiveSubscription'] == active) return;

    await ref.update({
      'hasActiveSubscription': active,
      'subscriptionCheckedAt': DateTime.now().toIso8601String(),
    });
  }

  // ==================== Moderation ====================

  /// 不適切な内容を通報する。
  ///
  /// 同じ人が同じ対象を何度送っても1件にまとまる。
  Future<void> report({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    String? targetAuthorId,
    required ReportReason reason,
    String? note,
  }) async {
    final id = Report.buildId(
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
    );

    await _db.collection('reports').doc(id).set(
          Report(
            id: id,
            reporterId: reporterId,
            targetType: targetType,
            targetId: targetId,
            targetAuthorId: targetAuthorId,
            reason: reason,
            note: note,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  Future<void> blockUser(String userId, String blockedUserId) async {
    final id = BlockedUser.buildId(userId, blockedUserId);
    await _db.collection('blocks').doc(id).set(
          BlockedUser(
            userId: userId,
            blockedUserId: blockedUserId,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _db
        .collection('blocks')
        .doc(BlockedUser.buildId(userId, blockedUserId))
        .delete();
  }

  /// ブロックした相手の一覧。投稿やコメントを隠すために使う。
  Stream<Set<String>> blockedUserIdsStream(String userId) {
    return _db
        .collection('blocks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data()['blockedUserId'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }

  // ==================== TRY ====================

  /// 挑戦を1回ぶん記録する。
  ///
  /// 同じ日に同じものを何度開いても1回。日をまたげばまた1回になる。
  Future<void> recordTry({
    required String userId,
    required TryKind kind,
    required String targetId,
    String? categoryId,
  }) async {
    final now = DateTime.now();
    final id = TryRecord.buildId(
      userId: userId,
      kind: kind,
      targetId: targetId,
      on: now,
    );

    await _db.collection('tryRecords').doc(id).set(
          TryRecord(
            id: id,
            userId: userId,
            kind: kind,
            targetId: targetId,
            categoryId: categoryId,
            completedAt: now,
          ).toMap(),
        );
  }

  /// その人の TRY の履歴。集計に使うので、直近ぶんをまとめて読む。
  Stream<List<TryRecord>> tryRecordsStream(String userId, {int limit = 400}) {
    return _db
        .collection('tryRecords')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TryRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==================== Account deletion ====================

  /// 退会時にその人のデータを消す。
  ///
  /// App Store のガイドライン 5.1.1(v) はアカウント削除を求めており、
  /// Firebase Authentication の利用者を消すだけでは Firestore 側に
  /// 表示名・自己紹介・投稿が残ってしまう。
  Future<void> deleteUserData(String uid) async {
    // 本人しか触れないコレクション。ドキュメント ID が uid のもの。
    for (final collection in ['users', 'userStats']) {
      await _db.collection(collection).doc(uid).delete();
    }

    // uid を持つ行をまとめて消す。件数は多くないので一度に読んで構わない。
    await _deleteWhere('progress', 'uid', uid);
    await _deleteWhere('courseProgress', 'userId', uid);
    await _deleteWhere('bookmarks', 'userId', uid);
    await _deleteWhere('likes', 'userId', uid);
    await _deleteWhere('eventParticipations', 'userId', uid);
    await _deleteWhere('notifications', 'userId', uid);
    await _deleteWhere('tryRecords', 'userId', uid);
    await _deleteWhere('blocks', 'userId', uid);
    await _deleteWhere('comments', 'authorId', uid);
    await _deleteWhere('posts', 'authorId', uid);
  }

  Future<void> _deleteWhere(
    String collection,
    String field,
    String value,
  ) async {
    const pageSize = 300;

    while (true) {
      final snapshot = await _db
          .collection(collection)
          .where(field, isEqualTo: value)
          .limit(pageSize)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) return;
    }
  }

  // ==================== Progress ====================

  /// 視聴位置のドキュメント ID。uid と videoId から決まるので、
  /// 複合インデックスも要らないし、保存が重なっても行が増えない。
  static String progressId(String uid, String videoId) => '${uid}_$videoId';

  Future<VideoProgress?> getProgress(String uid, String videoId) async {
    final doc =
        await _db.collection('progress').doc(progressId(uid, videoId)).get();
    if (!doc.exists) return null;
    return VideoProgress.fromMap(doc.data()!, doc.id);
  }

  Stream<VideoProgress?> progressStream(String uid, String videoId) {
    return _db
        .collection('progress')
        .doc(progressId(uid, videoId))
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return VideoProgress.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> saveProgress(VideoProgress progress) async {
    final id = progressId(progress.uid, progress.videoId);
    await _db.collection('progress').doc(id).set(progress.toMap());
  }

  Future<List<VideoProgress>> getUserProgress(String uid) async {
    final snapshot = await _db
        .collection('progress')
        .where('uid', isEqualTo: uid)
        .get();

    return snapshot.docs
        .map((doc) => VideoProgress.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Learning records ====================

  /// 視聴位置を保存し、見終わっていれば実績にも反映する。
  ///
  /// 視聴中は数十秒おきに呼ばれるため、完了したときだけ集計を触る。
  Future<void> recordVideoProgress({
    required String uid,
    required Video video,
    required int positionSeconds,
    String? courseId,
  }) async {
    final id = progressId(uid, video.id);
    final ref = _db.collection('progress').doc(id);

    // 残り 1 割まで見たら完了とみなす。長さ不明の動画は完了にしない。
    final completed =
        video.duration > 0 && positionSeconds >= (video.duration * 0.9);

    final before = await ref.get();
    final wasCompleted = before.exists && (before.data()?['completed'] == true);

    await ref.set(
      VideoProgress(
        id: id,
        uid: uid,
        videoId: video.id,
        currentTime: positionSeconds,
        completed: completed || wasCompleted,
        updatedAt: DateTime.now(),
      ).toMap(),
    );

    if (!completed || wasCompleted) return;

    // 見終えた = 1回挑戦した。
    await recordTry(
      userId: uid,
      kind: TryKind.video,
      targetId: video.id,
      categoryId: video.categoryId,
    );

    await _incrementUserStats(uid, {
      'completedVideos': FieldValue.increment(1),
      'totalWatchTime': FieldValue.increment((video.duration / 60).round()),
    });

    if (courseId != null) {
      await _markCourseVideoCompleted(uid, courseId, video.id);
    }
  }

  /// テキストレッスンの読了状態を保存する。
  Future<void> setLessonCompleted({
    required String uid,
    required String lessonId,
    required bool completed,
  }) async {
    await _incrementUserStats(uid, {
      'completedLessonIds': completed
          ? FieldValue.arrayUnion([lessonId])
          : FieldValue.arrayRemove([lessonId]),
    });
  }

  /// userStats を部分更新する。ドキュメントがまだ無い場合も作れるよう、
  /// 既定値をまとめて merge しておく。
  Future<void> _incrementUserStats(
    String uid,
    Map<String, dynamic> changes,
  ) async {
    final ref = _db.collection('userStats').doc(uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set(UserStats.empty(uid).toMap());
    }

    await ref.update({
      ...changes,
      'lastActiveAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _markCourseVideoCompleted(
    String uid,
    String courseId,
    String videoId,
  ) async {
    final course = await getCourse(courseId);
    final totalVideos = course?.videoIds.length ?? 0;
    if (totalVideos == 0) return;

    final docId = '${uid}_$courseId';
    final ref = _db.collection('courseProgress').doc(docId);
    final snapshot = await ref.get();

    final completedIds = <String>{
      ...?(snapshot.data()?['completedVideoIds'] as List?)?.cast<String>(),
      videoId,
    };
    final wasCompleted = snapshot.data()?['isCompleted'] == true;
    final percent = completedIds.length / totalVideos;
    final isCompleted = completedIds.length >= totalVideos;
    final now = DateTime.now();

    await ref.set(
      CourseProgress(
        id: docId,
        userId: uid,
        courseId: courseId,
        completedVideoIds: completedIds.toList(),
        progressPercent: percent,
        isCompleted: isCompleted,
        completedAt: isCompleted ? now : null,
        updatedAt: now,
      ).toMap(),
    );

    if (isCompleted && !wasCompleted) {
      await _incrementUserStats(uid, {
        'completedCourses': FieldValue.increment(1),
      });
    }
  }

  // ==================== Categories ====================

  Future<List<Category>> getCategories() async {
    final snapshot =
        await _db.collection('categories').orderBy('order').get();

    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Category>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==================== Courses ====================

  Future<List<Course>> getCourses({bool? isPublished}) async {
    Query<Map<String, dynamic>> query = _db.collection('courses');

    if (isPublished != null) {
      query = query.where('isPublished', isEqualTo: isPublished);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Course?> getCourse(String courseId) async {
    final doc = await _db.collection('courses').doc(courseId).get();
    if (!doc.exists) return null;
    return Course.fromMap(doc.data()!, courseId);
  }

  Stream<List<Course>> coursesStream() {
    return _db
        .collection('courses')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Course.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('courses')
        .where('categoryId', isEqualTo: categoryId)
        .where('isPublished', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Course Progress ====================

  Future<CourseProgress?> getCourseProgress(String userId, String courseId) async {
    final docId = '${userId}_$courseId';
    final doc = await _db.collection('courseProgress').doc(docId).get();
    if (!doc.exists) return null;
    return CourseProgress.fromMap(doc.data()!, docId);
  }

  Future<void> saveCourseProgress(CourseProgress progress) async {
    final docId = '${progress.userId}_${progress.courseId}';
    await _db.collection('courseProgress').doc(docId).set(progress.toMap());
  }

  Stream<CourseProgress?> courseProgressStream(String userId, String courseId) {
    final docId = '${userId}_$courseId';
    return _db.collection('courseProgress').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CourseProgress.fromMap(doc.data()!, docId);
    });
  }

  Future<List<CourseProgress>> getUserCourseProgress(String userId) async {
    final snapshot = await _db
        .collection('courseProgress')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => CourseProgress.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Posts ====================

  Future<List<Post>> getPosts({int limit = 20, DocumentSnapshot? lastDoc}) async {
    Query<Map<String, dynamic>> query = _db
        .collection('posts')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Post?> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromMap(doc.data()!, postId);
  }

  Stream<List<Post>> postsStream({int limit = 20}) {
    return _db
        .collection('posts')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> createPost(Post post) async {
    final docRef = await _db.collection('posts').add(post.toMap());
    return docRef.id;
  }

  Future<void> updatePost(Post post) async {
    await _db.collection('posts').doc(post.id).update(post.toMap());
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<List<Post>> getUserPosts(String userId) async {
    final snapshot = await _db
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Post.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Comments ====================

  Future<List<Comment>> getComments(CommentTargetType targetType, String targetId) async {
    final snapshot = await _db
        .collection('comments')
        .where('targetType', isEqualTo: targetType.name)
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => Comment.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Comment>> commentsStream(CommentTargetType targetType, String targetId) {
    return _db
        .collection('comments')
        .where('targetType', isEqualTo: targetType.name)
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> createComment(Comment comment) async {
    final docRef = await _db.collection('comments').add(comment.toMap());

    // Update comment count on target
    if (comment.targetType == CommentTargetType.post) {
      await _db.collection('posts').doc(comment.targetId).update({
        'commentCount': FieldValue.increment(1),
      });
    }

    return docRef.id;
  }

  Future<void> deleteComment(Comment comment) async {
    await _db.collection('comments').doc(comment.id).delete();

    // Update comment count on target
    if (comment.targetType == CommentTargetType.post) {
      await _db.collection('posts').doc(comment.targetId).update({
        'commentCount': FieldValue.increment(-1),
      });
    }
  }

  // ==================== Likes ====================

  Future<bool> hasLiked(String userId, LikeTargetType targetType, String targetId) async {
    final docId = Like.generateId(userId, targetType, targetId);
    final doc = await _db.collection('likes').doc(docId).get();
    return doc.exists;
  }

  Future<void> toggleLike(String userId, LikeTargetType targetType, String targetId) async {
    final docId = Like.generateId(userId, targetType, targetId);
    final docRef = _db.collection('likes').doc(docId);
    final doc = await docRef.get();

    final targetCollection = targetType == LikeTargetType.post ? 'posts' : 'comments';
    final targetRef = _db.collection(targetCollection).doc(targetId);

    if (doc.exists) {
      // Unlike
      await docRef.delete();
      await targetRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      // Like
      final like = Like(
        id: docId,
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        createdAt: DateTime.now(),
      );
      await docRef.set(like.toMap());
      await targetRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  Stream<bool> likeStream(String userId, LikeTargetType targetType, String targetId) {
    final docId = Like.generateId(userId, targetType, targetId);
    return _db.collection('likes').doc(docId).snapshots().map((doc) => doc.exists);
  }

  // ==================== Bookmarks ====================

  Future<bool> hasBookmarked(String userId, BookmarkTargetType targetType, String targetId) async {
    final docId = Bookmark.generateId(userId, targetType, targetId);
    final doc = await _db.collection('bookmarks').doc(docId).get();
    return doc.exists;
  }

  Future<void> toggleBookmark(String userId, BookmarkTargetType targetType, String targetId) async {
    final docId = Bookmark.generateId(userId, targetType, targetId);
    final docRef = _db.collection('bookmarks').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      final bookmark = Bookmark(
        id: docId,
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        createdAt: DateTime.now(),
      );
      await docRef.set(bookmark.toMap());
    }
  }

  Stream<bool> bookmarkStream(String userId, BookmarkTargetType targetType, String targetId) {
    final docId = Bookmark.generateId(userId, targetType, targetId);
    return _db.collection('bookmarks').doc(docId).snapshots().map((doc) => doc.exists);
  }

  Future<List<Bookmark>> getUserBookmarks(String userId, {BookmarkTargetType? targetType}) async {
    Query<Map<String, dynamic>> query = _db
        .collection('bookmarks')
        .where('userId', isEqualTo: userId);

    if (targetType != null) {
      query = query.where('targetType', isEqualTo: targetType.name);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Bookmark.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Notifications ====================

  Future<List<AppNotification>> getNotifications(String userId, {int limit = 50}) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<AppNotification>> notificationsStream(String userId, {int limit = 50}) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Stream<int> unreadNotificationCountStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        // バッジに出す数字なので、それ以上は数えても意味がない。
        // 未読が溜まった人の読み取り回数が青天井にならないようにする。
        .limit(99)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> createNotification(AppNotification notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  // ==================== Announcements ====================

  Future<List<Announcement>> getAnnouncements({int limit = 20}) async {
    final snapshot = await _db
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Announcement.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Announcement?> getAnnouncement(String announcementId) async {
    final doc = await _db.collection('announcements').doc(announcementId).get();
    if (!doc.exists) return null;
    return Announcement.fromMap(doc.data()!, announcementId);
  }

  Stream<List<Announcement>> announcementsStream({int limit = 20}) {
    return _db
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Announcement?> getLatestAnnouncement() async {
    final snapshot = await _db
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Announcement.fromMap(doc.data(), doc.id);
  }

  // ==================== Badges ====================

  Future<List<Badge>> getBadges() async {
    final snapshot = await _db.collection('badges').get();
    return snapshot.docs
        .map((doc) => Badge.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Badge?> getBadge(String badgeId) async {
    final doc = await _db.collection('badges').doc(badgeId).get();
    if (!doc.exists) return null;
    return Badge.fromMap(doc.data()!, badgeId);
  }

  Stream<List<Badge>> badgesStream() {
    return _db.collection('badges').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Badge.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<Badge>> getUserBadges(List<String> badgeIds) async {
    if (badgeIds.isEmpty) return [];

    final snapshot = await _db
        .collection('badges')
        .where(FieldPath.documentId, whereIn: badgeIds)
        .get();

    return snapshot.docs
        .map((doc) => Badge.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Live Schedules ====================

  Future<List<LiveSchedule>> getLiveSchedules({LiveStatus? status}) async {
    Query<Map<String, dynamic>> query = _db.collection('liveSchedules');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.orderBy('scheduledAt', descending: false).get();
    return snapshot.docs
        .map((doc) => LiveSchedule.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// これから始まる配信。
  ///
  /// 日時は Timestamp と ISO 文字列が混在しているため、Firestore 側で
  /// 範囲比較すると必ず空になる（型をまたいだ比較は成立しない）。
  /// 件数が少ないコレクションなので、取得してから絞る。
  Future<List<LiveSchedule>> getUpcomingLiveSchedules({int limit = 5}) async {
    final snapshot = await _db
        .collection('liveSchedules')
        .where('status', isEqualTo: LiveStatus.scheduled.name)
        .get();

    final now = DateTime.now();
    final upcoming = snapshot.docs
        .map((doc) => LiveSchedule.fromMap(doc.data(), doc.id))
        .where((l) => l.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return upcoming.take(limit).toList();
  }

  /// 見逃し配信。終わった配信のうち、アーカイブが紐づいているもの。
  Future<List<LiveSchedule>> getArchivedLives({int limit = 20}) async {
    final snapshot = await _db
        .collection('liveSchedules')
        .where('status', isEqualTo: LiveStatus.ended.name)
        .get();

    final archived = snapshot.docs
        .map((doc) => LiveSchedule.fromMap(doc.data(), doc.id))
        .where((l) => l.hasArchive)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return archived.take(limit).toList();
  }

  /// 今日ぶんの配信。開始前・配信中の両方を含む。
  Future<List<LiveSchedule>> getTodayLiveSchedules() async {
    final snapshot = await _db.collection('liveSchedules').get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return snapshot.docs
        .map((doc) => LiveSchedule.fromMap(doc.data(), doc.id))
        .where((l) =>
            l.status != LiveStatus.ended &&
            l.scheduledAt.isAfter(today) &&
            l.scheduledAt.isBefore(tomorrow))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Stream<List<LiveSchedule>> liveSchedulesStream() {
    return _db
        .collection('liveSchedules')
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LiveSchedule.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<LiveSchedule?> getCurrentLive() async {
    final snapshot = await _db
        .collection('liveSchedules')
        .where('status', isEqualTo: LiveStatus.live.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return LiveSchedule.fromMap(doc.data(), doc.id);
  }

  // ==================== Search ====================

  Future<Map<String, dynamic>> search(String query) async {
    final results = await Future.wait([
      searchVideos(query),
      _searchCourses(query),
      _searchPosts(query),
    ]);

    return {
      'videos': results[0],
      'courses': results[1],
      'posts': results[2],
    };
  }

  Future<List<Course>> _searchCourses(String query) async {
    final snapshot = await _db
        .collection('courses')
        .where('isPublished', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Post>> _searchPosts(String query) async {
    final snapshot = await _db
        .collection('posts')
        .orderBy('content')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => Post.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== Events ====================

  Stream<List<Event>> eventsStream() {
    return _db
        .collection('events')
        .where('status', whereIn: [EventStatus.scheduled.name, EventStatus.ongoing.name])
        .orderBy('startAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Event?> getEvent(String eventId) async {
    final doc = await _db.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromMap(doc.data()!, eventId);
  }

  /// これから開催されるイベント。日時の型が混在しているため、
  /// liveSchedules と同じく取得してから絞る。
  Future<List<Event>> getUpcomingEvents({int limit = 10}) async {
    final snapshot = await _db
        .collection('events')
        .where('status', isEqualTo: EventStatus.scheduled.name)
        .get();

    final now = DateTime.now();
    final upcoming = snapshot.docs
        .map((doc) => Event.fromMap(doc.data(), doc.id))
        .where((e) => e.startAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return upcoming.take(limit).toList();
  }

  Future<List<Event>> getEventsByMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // 日時の型が混在しているため Firestore 側で範囲を絞れない。
    final snapshot = await _db.collection('events').get();

    return snapshot.docs
        .map((doc) => Event.fromMap(doc.data(), doc.id))
        .where((e) =>
            !e.startAt.isBefore(startOfMonth) && !e.startAt.isAfter(endOfMonth))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  // ==================== Event Participations ====================

  Stream<EventParticipation?> eventParticipationStream(String userId, String eventId) {
    final docId = EventParticipation.generateId(userId, eventId);
    return _db.collection('eventParticipations').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return EventParticipation.fromMap(doc.data()!, docId);
    });
  }

  Future<EventParticipation?> getEventParticipation(String userId, String eventId) async {
    final docId = EventParticipation.generateId(userId, eventId);
    final doc = await _db.collection('eventParticipations').doc(docId).get();
    if (!doc.exists) return null;
    return EventParticipation.fromMap(doc.data()!, docId);
  }

  Future<List<EventParticipation>> getUserEventParticipations(String userId) async {
    final snapshot = await _db
        .collection('eventParticipations')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          ParticipationStatus.confirmed.name,
          ParticipationStatus.waitlisted.name,
        ])
        .orderBy('registeredAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => EventParticipation.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<EventParticipation>> getEventParticipants(String eventId) async {
    final snapshot = await _db
        .collection('eventParticipations')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: ParticipationStatus.confirmed.name)
        .orderBy('registeredAt')
        .get();

    return snapshot.docs
        .map((doc) => EventParticipation.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<int> eventParticipantsCountStream(String eventId) {
    return _db
        .collection('eventParticipations')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: ParticipationStatus.confirmed.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> registerForEvent(String userId, String eventId) async {
    final event = await getEvent(eventId);
    if (event == null) throw Exception('Event not found');

    final docId = EventParticipation.generateId(userId, eventId);
    final existingDoc = await _db.collection('eventParticipations').doc(docId).get();

    if (existingDoc.exists) {
      final existing = EventParticipation.fromMap(existingDoc.data()!, docId);
      if (existing.status != ParticipationStatus.cancelled) {
        throw Exception('Already registered');
      }
    }

    // Check capacity and determine status
    final currentCount = await _db
        .collection('eventParticipations')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: ParticipationStatus.confirmed.name)
        .count()
        .get();

    final isFull = (currentCount.count ?? 0) >= event.capacity;

    // Calculate waitlist position if needed
    int waitlistPosition = 0;
    if (isFull) {
      final waitlistCount = await _db
          .collection('eventParticipations')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: ParticipationStatus.waitlisted.name)
          .count()
          .get();
      waitlistPosition = (waitlistCount.count ?? 0) + 1;
    }

    final participation = EventParticipation(
      id: docId,
      userId: userId,
      eventId: eventId,
      status: isFull ? ParticipationStatus.waitlisted : ParticipationStatus.confirmed,
      waitlistPosition: waitlistPosition,
      registeredAt: DateTime.now(),
    );

    await _db.collection('eventParticipations').doc(docId).set(participation.toMap());

    // Update event participant count
    if (!isFull) {
      await _db.collection('events').doc(eventId).update({
        'currentParticipants': FieldValue.increment(1),
      });
    }
  }

  Future<void> cancelEventRegistration(String userId, String eventId) async {
    final docId = EventParticipation.generateId(userId, eventId);
    final doc = await _db.collection('eventParticipations').doc(docId).get();

    if (!doc.exists) return;

    final participation = EventParticipation.fromMap(doc.data()!, docId);
    final wasConfirmed = participation.status == ParticipationStatus.confirmed;

    // Update participation status
    await _db.collection('eventParticipations').doc(docId).update({
      'status': ParticipationStatus.cancelled.name,
      'cancelledAt': DateTime.now().toIso8601String(),
    });

    // If was confirmed, decrement count and promote from waitlist
    if (wasConfirmed) {
      await _db.collection('events').doc(eventId).update({
        'currentParticipants': FieldValue.increment(-1),
      });

      // Promote first waitlisted user
      await _promoteFromWaitlist(eventId);
    }
  }

  Future<void> _promoteFromWaitlist(String eventId) async {
    final waitlist = await _db
        .collection('eventParticipations')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: ParticipationStatus.waitlisted.name)
        .orderBy('waitlistPosition')
        .limit(1)
        .get();

    if (waitlist.docs.isEmpty) return;

    final firstWaitlisted = waitlist.docs.first;
    await firstWaitlisted.reference.update({
      'status': ParticipationStatus.confirmed.name,
      'waitlistPosition': 0,
    });

    await _db.collection('events').doc(eventId).update({
      'currentParticipants': FieldValue.increment(1),
    });

    // Update remaining waitlist positions
    final remaining = await _db
        .collection('eventParticipations')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: ParticipationStatus.waitlisted.name)
        .orderBy('waitlistPosition')
        .get();

    final batch = _db.batch();
    int position = 1;
    for (final doc in remaining.docs) {
      batch.update(doc.reference, {'waitlistPosition': position});
      position++;
    }
    await batch.commit();
  }

  // ==================== Text Lessons ====================

  Stream<List<TextLesson>> textLessonsStream() {
    return _db
        .collection('textLessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TextLesson.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<TextLesson?> getTextLesson(String lessonId) async {
    final doc = await _db.collection('textLessons').doc(lessonId).get();
    if (!doc.exists) return null;
    return TextLesson.fromMap(doc.data()!, lessonId);
  }

  Future<List<TextLesson>> getTextLessonsByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('textLessons')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => TextLesson.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<String> createTextLesson(TextLesson lesson) async {
    final docRef = await _db.collection('textLessons').add(lesson.toMap());
    return docRef.id;
  }

  Future<void> updateTextLesson(TextLesson lesson) async {
    await _db.collection('textLessons').doc(lesson.id).update(lesson.toMap());
  }

  Future<void> deleteTextLesson(String lessonId) async {
    await _db.collection('textLessons').doc(lessonId).delete();
  }
}
