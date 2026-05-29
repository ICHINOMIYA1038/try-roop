// Seeds initial content (videos, categories, courses, text lessons, badges)
// into the try-roop Firestore project.
//
// Auth: prefers service account key at tool/serviceAccountKey.json,
// falls back to Application Default Credentials.
//
// Run:
//   cd tool && npm install && node seed.js

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const keyPath = path.join(__dirname, 'serviceAccountKey.json');
if (fs.existsSync(keyPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
  });
  console.log('Authenticated via serviceAccountKey.json');
} else {
  admin.initializeApp({ projectId: 'try-roop' });
  console.log('Authenticated via Application Default Credentials');
}

const db = admin.firestore();
const NOW = new Date().toISOString();

const categories = [
  { id: 'karate', data: { name: '空手', order: 1 } },
  { id: 'workout', data: { name: '筋トレ', order: 2 } },
  { id: 'health', data: { name: '健康', order: 3 } },
  { id: 'ai', data: { name: 'AI', order: 4 } },
];

const videos = [
  {
    id: 'video_TeMPE3PJx2Y',
    data: {
      title: '脂肪燃焼したいならこれ！14分の筋トレ×キック（オンライントレーニング風景）',
      description:
        '14分の筋トレ×キックで効率よく脂肪燃焼。オンライントレーニング風景です。',
      youtubeVideoId: 'TeMPE3PJx2Y',
      thumbnailUrl: 'https://img.youtube.com/vi/TeMPE3PJx2Y/0.jpg',
      duration: 840,
      accessLevel: 'free',
      categoryId: 'workout',
      order: 1,
      createdAt: NOW,
      updatedAt: NOW,
    },
  },
  {
    id: 'video_qhXlYkxXLGE',
    data: {
      title: '自宅でしっかり15分！桃尻トレーニング（オンライントレーニング風景）',
      description:
        '自宅で15分、お尻にしっかり効く下半身トレーニング。オンライントレーニング風景です。',
      youtubeVideoId: 'qhXlYkxXLGE',
      thumbnailUrl: 'https://img.youtube.com/vi/qhXlYkxXLGE/0.jpg',
      duration: 900,
      accessLevel: 'premium',
      categoryId: 'workout',
      order: 2,
      createdAt: NOW,
      updatedAt: NOW,
    },
  },
];

const courses = [
  {
    id: 'course_online_fitness',
    data: {
      title: 'オンラインフィットネス入門',
      description:
        'キックボクシングと自重トレーニングを組み合わせた、自宅でできるフィットネスプログラム。',
      thumbnailUrl: 'https://img.youtube.com/vi/TeMPE3PJx2Y/0.jpg',
      instructorId: null,
      categoryId: 'workout',
      videoIds: ['video_TeMPE3PJx2Y', 'video_qhXlYkxXLGE'],
      totalDuration: 29,
      difficulty: 'beginner',
      isPublished: true,
      createdAt: NOW,
      updatedAt: NOW,
    },
  },
];

const textLessons = [
  {
    id: 'lesson_karate_1',
    data: {
      title: '空手の基本姿勢と構え',
      description: '空手を始める前に知っておきたい基本姿勢と正しい構え方を解説します。',
      content: null,
      assetPath: 'assets/lessons/karate/basics.md',
      thumbnailUrl: null,
      categoryId: 'karate',
      order: 1,
      estimatedReadingMinutes: 5,
      accessLevel: 'free',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_karate_2',
    data: {
      title: '突きの基本技術',
      description: '正拳突き、追い突き、逆突きなど基本的な突き技を学びます。',
      content: null,
      assetPath: 'assets/lessons/karate/punches.md',
      thumbnailUrl: null,
      categoryId: 'karate',
      order: 2,
      estimatedReadingMinutes: 8,
      accessLevel: 'free',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_karate_3',
    data: {
      title: '蹴りの基本技術',
      description: '前蹴り、回し蹴り、横蹴りなど基本的な蹴り技を解説します。',
      content: null,
      assetPath: 'assets/lessons/karate/kicks.md',
      thumbnailUrl: null,
      categoryId: 'karate',
      order: 3,
      estimatedReadingMinutes: 10,
      accessLevel: 'premium',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_workout_1',
    data: {
      title: '自重トレーニング入門',
      description: '器具を使わず自分の体重だけで行うトレーニングの基礎を学びます。',
      content: null,
      assetPath: 'assets/lessons/workout/bodyweight.md',
      thumbnailUrl: null,
      categoryId: 'workout',
      order: 1,
      estimatedReadingMinutes: 6,
      accessLevel: 'free',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_workout_2',
    data: {
      title: '正しいスクワットのフォーム',
      description: '膝や腰を痛めない正しいスクワットのやり方を詳しく解説。',
      content: null,
      assetPath: 'assets/lessons/workout/squat.md',
      thumbnailUrl: null,
      categoryId: 'workout',
      order: 2,
      estimatedReadingMinutes: 7,
      accessLevel: 'free',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_health_1',
    data: {
      title: '質の良い睡眠のコツ',
      description: '睡眠の質を高めるための環境づくりと習慣について解説します。',
      content: null,
      assetPath: 'assets/lessons/health/sleep.md',
      thumbnailUrl: null,
      categoryId: 'health',
      order: 1,
      estimatedReadingMinutes: 8,
      accessLevel: 'free',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_health_2',
    data: {
      title: 'ストレス管理の基本',
      description: '日常生活で実践できるストレス管理のテクニックを紹介します。',
      content: null,
      assetPath: 'assets/lessons/health/stress.md',
      thumbnailUrl: null,
      categoryId: 'health',
      order: 2,
      estimatedReadingMinutes: 10,
      accessLevel: 'premium',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_ai_1',
    data: {
      title: 'ChatGPT入門ガイド',
      description: 'ChatGPTの基本的な使い方とプロンプトの書き方を学びます。',
      content: null,
      assetPath: 'assets/lessons/ai/chatgpt_intro.md',
      thumbnailUrl: null,
      categoryId: 'ai',
      order: 1,
      estimatedReadingMinutes: 10,
      accessLevel: 'free',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
  {
    id: 'lesson_ai_2',
    data: {
      title: 'プロンプトエンジニアリング基礎',
      description: 'AIから良い回答を引き出すためのプロンプト設計テクニック。',
      content: null,
      assetPath: 'assets/lessons/ai/prompt_engineering.md',
      thumbnailUrl: null,
      categoryId: 'ai',
      order: 2,
      estimatedReadingMinutes: 15,
      accessLevel: 'premium',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  },
];

const badges = [
  {
    id: 'badge_first_step',
    data: {
      name: 'ファーストステップ',
      description: '初めての動画を視聴しました',
      iconUrl: '🎬',
      condition: { type: 'videosWatched', threshold: 1, courseId: null },
      createdAt: NOW,
    },
  },
  {
    id: 'badge_course_complete',
    data: {
      name: 'コース完走',
      description: '初めてのコースを完了しました',
      iconUrl: '🏆',
      condition: { type: 'coursesCompleted', threshold: 1, courseId: null },
      createdAt: NOW,
    },
  },
  {
    id: 'badge_streak_7',
    data: {
      name: '継続は力なり',
      description: '7日間連続でアプリを利用しました',
      iconUrl: '🔥',
      condition: { type: 'consecutiveDays', threshold: 7, courseId: null },
      createdAt: NOW,
    },
  },
  {
    id: 'badge_community',
    data: {
      name: 'コミュニティ参加',
      description: '初めての投稿を行いました',
      iconUrl: '💬',
      condition: { type: 'postsCreated', threshold: 1, courseId: null },
      createdAt: NOW,
    },
  },
];

// 運営アカウントの uid。クライアントから消されないよう authorId を固定し、
// Firebase Auth 側でも同じ uid のサービスアカウントを作っておく想定。
const STAFF_UID = 'staff_official';
const STAFF_NAME = 'TryRoop 運営';

const announcements = [
  {
    id: 'announcement_welcome',
    data: {
      title: 'TryRoop Campus Live へようこそ',
      content:
        'TryRoop Campus Live をご利用いただきありがとうございます。\n\n' +
        '本アプリでは、空手・筋トレ・健康・AI など、暮らしに役立つ学習コンテンツをお届けします。' +
        '動画とテキストレッスンを組み合わせて、あなたのペースで学習を進めてください。\n\n' +
        '不具合のご報告やご意見は、プロフィール画面の「ヘルプ・お問い合わせ」からお寄せください。',
      imageUrl: null,
      isPublished: true,
      createdAt: NOW,
    },
  },
];

const posts = [
  {
    id: 'post_welcome',
    data: {
      authorId: STAFF_UID,
      authorName: STAFF_NAME,
      authorPhotoUrl: null,
      content:
        'TryRoop Campus Live のコミュニティへようこそ！\n\n' +
        'ここは、学んだことや気づきを共有したり、仲間と励まし合ったりする場所です。' +
        '気軽に投稿・コメントしてください。',
      imageUrls: [],
      likeCount: 0,
      commentCount: 0,
      isPinned: true,
      createdAt: NOW,
      updatedAt: NOW,
    },
  },
];

async function writeCollection(name, items) {
  console.log(`\n→ ${name} (${items.length} docs)`);
  for (const item of items) {
    await db.collection(name).doc(item.id).set(item.data);
    console.log(`  ✓ ${item.id}`);
  }
}

async function main() {
  await writeCollection('categories', categories);
  await writeCollection('videos', videos);
  await writeCollection('courses', courses);
  await writeCollection('textLessons', textLessons);
  await writeCollection('badges', badges);
  await writeCollection('announcements', announcements);
  await writeCollection('posts', posts);
  // liveSchedules は配信予定が決まり次第ここに追加してください。
  console.log('\n✅ Seed complete');
}

main().catch((e) => {
  console.error('❌ Seed failed:', e);
  process.exit(1);
});
