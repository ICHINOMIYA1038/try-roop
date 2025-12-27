import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/course.dart';
import '../../providers/providers.dart';
import '../../widgets/course_card.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String? _selectedCategoryId;
  CourseDifficulty? _selectedDifficulty;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final userProgressAsync = ref.watch(userCourseProgressListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('コース'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category filter
                  categoriesAsync.when(
                    data: (categories) => Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('すべて'),
                          selected: _selectedCategoryId == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        ...categories.map((category) => FilterChip(
                              label: Text(category.name),
                              selected: _selectedCategoryId == category.id,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategoryId =
                                      selected ? category.id : null;
                                });
                              },
                            )),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 16),
                  // Difficulty filter
                  DropdownButton<CourseDifficulty?>(
                    value: _selectedDifficulty,
                    hint: const Text('難易度'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('すべて'),
                      ),
                      ...CourseDifficulty.values.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(_getDifficultyLabel(d)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Course list
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                // Apply filters
                var filteredCourses = courses;
                if (_selectedCategoryId != null) {
                  filteredCourses = filteredCourses
                      .where((c) => c.categoryId == _selectedCategoryId)
                      .toList();
                }
                if (_selectedDifficulty != null) {
                  filteredCourses = filteredCourses
                      .where((c) => c.difficulty == _selectedDifficulty)
                      .toList();
                }

                if (filteredCourses.isEmpty) {
                  return const Center(
                    child: Text('コースがありません'),
                  );
                }

                final progressList = userProgressAsync.value ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
                    final progress = progressList
                        .where((p) => p.courseId == course.id)
                        .firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CourseCard(
                        course: course,
                        progressPercent: progress?.progressPercent,
                        onTap: () => context.push('/course/${course.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('エラーが発生しました: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyLabel(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return '初級';
      case CourseDifficulty.intermediate:
        return '中級';
      case CourseDifficulty.advanced:
        return '上級';
    }
  }
}
