# Securitas ISMS/AIMS Portal - 本番環境セットアップ手順

## 前提条件
- Supabaseアカウント（https://supabase.com）
- GitHubアカウント
- Anthropic APIキー

---

## 1. Supabaseプロジェクト作成

1. https://supabase.com にログイン
2. **「New project」** をクリック
3. 以下を設定:
   - **Name**: `securitas`
   - **Database Password**: 強いパスワードを設定（保存しておくこと）
   - **Region**: `Northeast Asia (Tokyo)`
4. 作成完了まで待つ（約1分）

---

## 2. データベーススキーマ適用

1. Supabaseダッシュボード → **SQL Editor**
2. `supabase/migrations/001_schema.sql` の内容を貼り付けて実行

---

## 3. 初回管理者ユーザー作成

1. Supabaseダッシュボード → **Authentication** → **Users** → **Add user**
2. メールアドレスとパスワードを入力して作成
3. **SQL Editor** で管理者権限を付与:
   ```sql
   UPDATE public.profiles
   SET role = 'admin', display_name = 'システム管理者', dept = '情報システム部'
   WHERE id = (SELECT id FROM auth.users WHERE email = 'your-email@example.com');
   ```

---

## 4. Claude API プロキシ（Edge Function）のデプロイ

### Supabase CLIのインストール
```bash
npm install -g supabase
```

### ログインとリンク
```bash
supabase login
supabase link --project-ref <your-project-ref>
# project-refはダッシュボードのURLから確認: https://app.supabase.com/project/[project-ref]
```

### シークレット設定
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
```

### Edge Functionデプロイ
```bash
supabase functions deploy claude-proxy
```

---

## 5. GitHub Secretsの設定

GitHubリポジトリ → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret名 | 値 | 確認場所 |
|---|---|---|
| `SUPABASE_URL` | `https://xxxx.supabase.co` | Supabase → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | `eyJhbGc...` | Supabase → Settings → API → anon public key |

---

## 6. GitHub Pages 有効化

1. GitHubリポジトリ → **Settings** → **Pages**
2. **Source**: `GitHub Actions` を選択
3. 保存

---

## 7. デプロイ実行

```bash
git add .
git commit -m "feat: Supabase + GitHub Pages 本番対応"
git push origin main
```

→ GitHub Actions が自動実行され、GitHub Pages にデプロイされます。
→ デプロイ後のURL: `https://iidayoshihide-sudo.github.io/securitas/`

---

## 8. 追加ユーザーの招待

Supabaseダッシュボード → **Authentication** → **Users** → **Invite user**
- メールアドレスを入力 → 招待メールが送信されます
- ユーザーはメールリンクからパスワードを設定してログインできます

---

## セキュリティチェックリスト

- [x] Claude APIキーはブラウザに露出しない（Edge Function内のシークレット）
- [x] 認証はSupabase Auth（JWT）
- [x] Row Level Security（RLS）でデータを保護
- [x] HTTPSのみ（GitHub Pages + Supabase）
- [ ] Supabaseダッシュボード → Auth → URL Configuration でサイトURLを設定
- [ ] Supabase → Auth → Policies でメール確認を要件化（本番推奨）
