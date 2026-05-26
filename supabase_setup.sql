-- ============================================
-- SAIClaws 图片上传功能 - Supabase 数据库设置
-- 请在 Supabase Dashboard → SQL Editor 中运行此脚本
-- ============================================

-- 1. 创建图片存储桶 (public bucket)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('images', 'images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- 2. 允许所有人读取图片
CREATE POLICY "Public read images" ON storage.objects
  FOR SELECT USING (bucket_id = 'images');

-- 3. 允许匿名用户上传图片
CREATE POLICY "Anyone upload images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'images');

-- 4. daily_memos 添加 image_urls 列
ALTER TABLE daily_memos 
  ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]'::jsonb;

-- 5. study_diary 添加 image_urls 列
ALTER TABLE study_diary 
  ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]'::jsonb;

-- 完成！
-- 刷新 saiclaws.com/app.html 即可使用图片上传和图库功能
