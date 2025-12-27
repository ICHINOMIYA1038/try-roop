import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/text_lesson.dart';
import '../../models/video.dart' show AccessLevel;
import '../../providers/providers.dart';
import '../../widgets/app_markdown.dart';

class AdminTextLessonEditorScreen extends ConsumerStatefulWidget {
  final String? lessonId;

  const AdminTextLessonEditorScreen({super.key, this.lessonId});

  @override
  ConsumerState<AdminTextLessonEditorScreen> createState() =>
      _AdminTextLessonEditorScreenState();
}

class _AdminTextLessonEditorScreenState
    extends ConsumerState<AdminTextLessonEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _orderController = TextEditingController(text: '1');
  final _readingTimeController = TextEditingController(text: '5');

  String _selectedCategoryId = 'karate';
  AccessLevel _accessLevel = AccessLevel.free;
  bool _isLoading = false;
  bool _showPreview = false;

  bool get isEditing => widget.lessonId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadLesson();
    }
  }

  Future<void> _loadLesson() async {
    setState(() => _isLoading = true);
    final lesson =
        await ref.read(textLessonProvider(widget.lessonId!).future);
    if (lesson != null && mounted) {
      _titleController.text = lesson.title;
      _descriptionController.text = lesson.description;

      // Firestoreのcontentがあればそれを使用、なければローカルアセットを読み込む
      String content = lesson.content ?? '';
      if (content.isEmpty && lesson.usesLocalAsset) {
        try {
          content = await rootBundle.loadString(lesson.assetPath!);
        } catch (e) {
          debugPrint('Failed to load asset: $e');
        }
      }
      _contentController.text = content;

      _orderController.text = lesson.order.toString();
      _readingTimeController.text = lesson.estimatedReadingMinutes.toString();
      _selectedCategoryId = lesson.categoryId;
      _accessLevel = lesson.accessLevel;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _orderController.dispose();
    _readingTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final lesson = TextLesson(
        id: widget.lessonId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text,
        categoryId: _selectedCategoryId,
        order: int.tryParse(_orderController.text) ?? 1,
        estimatedReadingMinutes:
            int.tryParse(_readingTimeController.text) ?? 5,
        accessLevel: _accessLevel,
        createdAt: now,
        updatedAt: now,
      );

      final firestoreService = ref.read(firestoreServiceProvider);

      if (isEditing) {
        await firestoreService.updateTextLesson(lesson);
      } else {
        await firestoreService.createTextLesson(lesson);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? '更新しました' : '作成しました')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('アクセス拒否')),
        body: const Center(child: Text('管理者権限がありません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '教材を編集' : '新規教材作成'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            tooltip: _showPreview ? '編集に戻る' : 'プレビュー',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _isLoading && isEditing && _titleController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _showPreview
              ? _buildPreview()
              : _buildEditor(categoriesAsync),
    );
  }

  Widget _buildEditor(AsyncValue categoriesAsync) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タイトル *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty == true ? 'タイトルを入力してください' : null,
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '説明 *',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) =>
                value?.isEmpty == true ? '説明を入力してください' : null,
          ),
          const SizedBox(height: 16),

          // Category & Access Level
          Row(
            children: [
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリ',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategoryId = value);
                      }
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('カテゴリ読み込みエラー'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<AccessLevel>(
                  value: _accessLevel,
                  decoration: const InputDecoration(
                    labelText: 'アクセスレベル',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AccessLevel.free,
                      child: Text('無料'),
                    ),
                    DropdownMenuItem(
                      value: AccessLevel.premium,
                      child: Text('プレミアム'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _accessLevel = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Order & Reading Time
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    labelText: '表示順',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _readingTimeController,
                  decoration: const InputDecoration(
                    labelText: '読了時間（分）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content (Markdown)
          Row(
            children: [
              const Text(
                'コンテンツ（Markdown）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _showPreview = true),
                icon: const Icon(Icons.preview, size: 18),
                label: const Text('プレビュー'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '# 見出し\n\n本文を入力...\n\n![画像の説明](https://example.com/image.jpg)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 20,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Markdown Tips
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Markdown記法',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '# 見出し1\n'
                    '## 見出し2\n'
                    '**太字** / *斜体*\n'
                    '- リスト項目\n'
                    '![画像](URL)',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.preview, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'プレビュー',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showPreview = false),
                child: const Text('編集に戻る'),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.isEmpty
                      ? 'タイトル未入力'
                      : _titleController.text,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (_contentController.text.isEmpty)
                  Text(
                    'コンテンツ未入力',
                    style: TextStyle(color: Colors.grey[500]),
                  )
                else
                  AppMarkdown(data: _contentController.text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
