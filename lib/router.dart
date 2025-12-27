import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main.dart' show isDemoMode;
import 'providers/providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/video/video_player_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/subscription_screen.dart';
import 'screens/profile/bookmarks_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/profile/learning_dashboard_screen.dart';
import 'screens/course/course_list_screen.dart';
import 'screens/course/course_detail_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/community/post_detail_screen.dart';
import 'screens/community/create_post_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/announcement/announcement_list_screen.dart';
import 'screens/announcement/announcement_detail_screen.dart';
import 'screens/members/members_screen.dart';
import 'screens/members/member_profile_screen.dart';
import 'screens/text_lesson/text_lesson_list_screen.dart';
import 'screens/text_lesson/text_lesson_detail_screen.dart';
import 'screens/event/event_calendar_screen.dart';
import 'screens/event/event_detail_screen.dart';
import 'screens/admin/admin_text_lesson_list_screen.dart';
import 'screens/admin/admin_text_lesson_editor_screen.dart';

// Routes that require authentication
const _authRequiredRoutes = [
  '/community',
  '/notifications',
  '/profile',
  '/post/create',
  '/bookmarks',
  '/badges',
  '/dashboard',
  '/members',
  '/events',
];

bool _requiresAuth(String location) {
  return _authRequiredRoutes.any((route) => location.startsWith(route));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Skip authentication in demo mode
      if (isDemoMode) {
        // If on login page in demo mode, redirect to home
        if (state.matchedLocation == '/login') {
          return '/';
        }
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final currentLocation = state.matchedLocation;

      // If logged in and on login page, redirect to home
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      // If not logged in and trying to access auth-required route, redirect to login
      if (!isLoggedIn && _requiresAuth(currentLocation)) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child, location: state.matchedLocation);
        },
        routes: [
          // Home
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),

          // Courses
          GoRoute(
            path: '/courses',
            builder: (context, state) => const CourseListScreen(),
          ),

          // Text Lessons
          GoRoute(
            path: '/text-lessons',
            builder: (context, state) => const TextLessonListScreen(),
          ),

          // Community
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
          ),

          // Notifications
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),

          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Video Player (full screen, no bottom nav)
      GoRoute(
        path: '/video/:id',
        builder: (context, state) {
          final videoId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          final courseId = extra?['courseId'] as String?;
          return VideoPlayerScreen(videoId: videoId, courseId: courseId);
        },
      ),

      // Course Detail
      GoRoute(
        path: '/course/:id',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: courseId);
        },
      ),

      // Text Lesson Detail
      GoRoute(
        path: '/text-lesson/:id',
        builder: (context, state) {
          final lessonId = state.pathParameters['id']!;
          return TextLessonDetailScreen(lessonId: lessonId);
        },
      ),

      // Post Detail
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),

      // Create Post
      GoRoute(
        path: '/post/create',
        builder: (context, state) => const CreatePostScreen(),
      ),

      // Subscription (modal)
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // Search
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Announcements
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementListScreen(),
      ),

      // Announcement Detail
      GoRoute(
        path: '/announcement/:id',
        builder: (context, state) {
          final announcementId = state.pathParameters['id']!;
          return AnnouncementDetailScreen(announcementId: announcementId);
        },
      ),

      // Members
      GoRoute(
        path: '/members',
        builder: (context, state) => const MembersScreen(),
      ),

      // Member Profile
      GoRoute(
        path: '/member/:id',
        builder: (context, state) {
          final memberId = state.pathParameters['id']!;
          return MemberProfileScreen(memberId: memberId);
        },
      ),

      // Bookmarks
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),

      // Badges
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgesScreen(),
      ),

      // Learning Dashboard
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const LearningDashboardScreen(),
      ),

      // Events Calendar
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventCalendarScreen(),
      ),

      // Event Detail
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),

      // Admin - Text Lessons
      GoRoute(
        path: '/admin/text-lessons',
        builder: (context, state) => const AdminTextLessonListScreen(),
      ),
      GoRoute(
        path: '/admin/text-lessons/create',
        builder: (context, state) => const AdminTextLessonEditorScreen(),
      ),
      GoRoute(
        path: '/admin/text-lessons/:id/edit',
        builder: (context, state) {
          final lessonId = state.pathParameters['id']!;
          return AdminTextLessonEditorScreen(lessonId: lessonId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

class MainShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  int _getSelectedIndexLoggedIn(String location) {
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/text-lessons')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  int _getSelectedIndexLoggedOut(String location) {
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/text-lessons')) return 2;
    if (location.startsWith('/login')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).value != null || isDemoMode;
    // We don't need unreadCount here anymore as notification tab is gone
    
    if (isLoggedIn) {
      return _buildLoggedInShell(context, ref);
    } else {
      return _buildLoggedOutShell(context, ref);
    }
  }

  Widget _buildLoggedInShell(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndexLoggedIn(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF433D39).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF8A3D),
          unselectedItemColor: const Color(0xFF8C8681),
          selectedLabelStyle: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/courses');
                break;
              case 2:
                context.go('/text-lessons');
                break;
              case 3:
                context.go('/community');
                break;
              case 4:
                context.go('/profile');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle),
              label: '動画',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'テキスト',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'コミュニティ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'マイページ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutShell(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndexLoggedOut(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF433D39).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF8A3D),
          unselectedItemColor: const Color(0xFF8C8681),
          selectedLabelStyle: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w500,
          ),
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/courses');
                break;
              case 2:
                context.go('/text-lessons');
                break;
              case 3:
                context.go('/login');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle),
              label: '動画',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'テキスト',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.login),
              activeIcon: Icon(Icons.login),
              label: 'ログイン',
            ),
          ],
        ),
      ),
    );
  }
}
