-- ============================================
-- SAIClaws 3.0 升级 - 数据库迁移脚本
-- 在 Supabase Dashboard → SQL Editor 中运行
-- 如果报 policy 已存在，跳过图片相关部分即可
-- ============================================

-- 如果之前图片策略已创建，跳过这段
-- 取消下面注释来创建图片策略：
-- INSERT INTO storage.buckets ... (skip if exists)

-- 1. 闪卡表 (Flashcards)
CREATE TABLE IF NOT EXISTS flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  knowledge_id BIGINT REFERENCES knowledge_base(id) ON DELETE SET NULL,
  subject TEXT,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  source_type TEXT DEFAULT 'manual', -- 'manual' | 'ai_generated' | 'oral_eval'
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 闪卡复习记录表 (SM-2 算法)  
CREATE TABLE IF NOT EXISTS flashcard_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flashcard_id UUID REFERENCES flashcards(id) ON DELETE CASCADE,
  quality INTEGER NOT NULL CHECK (quality >= 0 AND quality <= 5),
  reviewed_at TIMESTAMPTZ DEFAULT NOW(),
  next_review_at TIMESTAMPTZ DEFAULT NOW(),
  interval_days INTEGER DEFAULT 1,
  ease_factor REAL DEFAULT 2.5,
  repetitions INTEGER DEFAULT 0
);

-- 3. 专注学习记录表 (Pomodoro)
CREATE TABLE IF NOT EXISTS study_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_date DATE DEFAULT CURRENT_DATE,
  subject TEXT,
  duration_minutes INTEGER DEFAULT 25,
  pomodoro_count INTEGER DEFAULT 1,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 学习资料收藏表 (Bookmarks)
CREATE TABLE IF NOT EXISTS bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url TEXT NOT NULL,
  title TEXT,
  summary TEXT,
  tags TEXT[],
  subject TEXT,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 为 knowledge_base 添加掌握度字段
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS mastery_level INTEGER DEFAULT 0 CHECK (mastery_level >= 0 AND mastery_level <= 5);

-- 6. 为 study_diary 添加学习时长字段
ALTER TABLE study_diary ADD COLUMN IF NOT EXISTS study_minutes INTEGER DEFAULT 0;

-- 7. 创建今日复习视图
CREATE OR REPLACE VIEW today_flashcard_review AS
SELECT 
  f.id AS flashcard_id,
  f.question,
  f.answer,
  f.subject,
  f.source_type,
  fr.next_review_at,
  fr.interval_days,
  fr.ease_factor,
  fr.repetitions,
  COALESCE(fr.repetitions, 0) AS review_count
FROM flashcards f
LEFT JOIN LATERAL (
  SELECT * FROM flashcard_reviews 
  WHERE flashcard_id = f.id 
  ORDER BY reviewed_at DESC 
  LIMIT 1
) fr ON true
WHERE f.is_deleted = false
  AND (fr.next_review_at IS NULL OR fr.next_review_at <= CURRENT_DATE + INTERVAL '1 day');

-- 8. 索引
CREATE INDEX IF NOT EXISTS idx_flashcards_subject ON flashcards(subject);
CREATE INDEX IF NOT EXISTS idx_flashcard_reviews_flashcard ON flashcard_reviews(flashcard_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_reviews_next ON flashcard_reviews(next_review_at);
CREATE INDEX IF NOT EXISTS idx_study_sessions_date ON study_sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_bookmarks_subject ON bookmarks(subject);

-- 完成！
