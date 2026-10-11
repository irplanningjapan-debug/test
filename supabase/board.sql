-- =====================================================
-- ご意見掲示板 テーブル定義（Supabase / PostgreSQL）
-- Supabase ダッシュボードの SQL Editor に貼り付けて実行してください。
-- =====================================================

-- ----- テーブル -----
create table if not exists public.board_posts (
  id         bigint generated always as identity primary key,
  nickname   text        not null check (char_length(btrim(nickname)) between 1 and 30),
  message    text        not null check (char_length(btrim(message))  between 1 and 500),
  created_at timestamptz not null default now()
);

comment on table  public.board_posts            is 'ご意見掲示板の書き込み';
comment on column public.board_posts.nickname   is 'ニックネーム（1〜30文字）';
comment on column public.board_posts.message    is 'ご意見本文（1〜500文字）';

-- 新しい順の一覧表示用
create index if not exists board_posts_created_at_idx
  on public.board_posts (created_at desc);

-- ----- 権限 -----
-- Supabase は public スキーマのテーブルに anon / authenticated へ全権限を付与するため、
-- いったん取り消してから必要なものだけ付与する。
revoke all on public.board_posts from anon, authenticated;

-- 閲覧：全列
grant select on public.board_posts to anon, authenticated;

-- 書き込み：nickname と message のみ（id・created_at はクライアントから指定させない）
grant insert (nickname, message) on public.board_posts to anon, authenticated;

-- 更新・削除の権限は付与しない（書き込みの改ざん・削除を防ぐ）

-- ----- RLS -----
alter table public.board_posts enable row level security;

-- 誰でも閲覧できる
drop policy if exists "board_posts_select_all" on public.board_posts;
create policy "board_posts_select_all"
  on public.board_posts
  for select
  to anon, authenticated
  using (true);

-- 誰でも書き込める（空文字・長すぎる入力は拒否）
drop policy if exists "board_posts_insert_all" on public.board_posts;
create policy "board_posts_insert_all"
  on public.board_posts
  for insert
  to anon, authenticated
  with check (
    char_length(btrim(nickname)) between 1 and 30
    and char_length(btrim(message)) between 1 and 500
  );

-- update / delete のポリシーは作成しない
--   → RLS 有効時はポリシーが無い操作はすべて拒否される

-- ----- ダミーデータ -----
-- SQL Editor（postgres ロール）から実行するため RLS の影響を受けずに投入できる
insert into public.board_posts (nickname, message, created_at) values
  ('みやざきっ子',   '週間予報がひと目で見られて便利です！',           now() - interval '3 days'),
  ('青島サーファー', '波の情報、毎朝チェックしてます。潮見表もあると嬉しいです。', now() - interval '2 days'),
  ('チキン南蛮',     '延岡の天気もタブで切り替えられて助かります。',     now() - interval '1 day'),
  ('高千穂ファン',   '山沿いの気温をもう少し詳しく知りたいです。',       now() - interval '5 hours'),
  ('日南のおばあ',   '文字が大きくて見やすいです。ありがとう。',         now() - interval '30 minutes');
