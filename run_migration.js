const { Client } = require('pg');
const fs = require('fs');

const password = process.env.DB_PASSWORD;
if (!password) {
  console.error('❌ 请设置环境变量: DB_PASSWORD=你的数据库密码');
  process.exit(1);
}

const client = new Client({
  host: 'db.lwoqjahqneosnummjlbo.supabase.co',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: password,
  ssl: { rejectUnauthorized: false }
});

async function run() {
  try {
    await client.connect();
    console.log('✅ 已连接到 Supabase 数据库');
    
    const sql = fs.readFileSync('/Users/openclawfeifei/.openclaw/workspace/sai-site/supabase_migration_v3.sql', 'utf8');
    await client.query(sql);
    console.log('✅ SQL 迁移执行成功！');
    
    // Verify tables created
    const tables = await client.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('flashcards', 'flashcard_reviews', 'study_sessions', 'bookmarks')
      ORDER BY table_name
    `);
    console.log('📋 新建表:', tables.rows.map(r => r.table_name).join(', '));
    console.log('🎉 全部完成！');
  } catch (e) {
    console.error('❌ 错误:', e.message);
  } finally {
    await client.end();
  }
}

run();
