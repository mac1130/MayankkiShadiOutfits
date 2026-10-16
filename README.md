# MayankkiShadiOutfits — GitHub Pages + Supabase

A mobile-friendly wedding outfit board for Haldi, Mehendi, Sangeet, Wedding and Reception. Includes outfit cards, guest outfit suggestions, comments, like/dislike, 1–5 star ratings, rankings and admin approval/deletion.

## Important privacy note
This is a public website and the outfit photos/data are public by design. Visitors can browse approved outfits and submit feedback/suggestions. New suggestions are hidden until an admin approves them. The GitHub repository will also be public. Do not upload private or sensitive photos.

## Setup (free tiers)

### 1. Create the Supabase project
1. Sign in at https://supabase.com/dashboard and create a new project (choose a strong database password and keep it in your password manager).
2. Open **SQL Editor → New query**, paste the full contents of `supabase_setup.sql`, and run it.
3. Open **Project Settings → API** (or **Connect**) and copy the Project URL and the **publishable key** (or legacy anon key). Never use a `service_role` or secret key in this website.
4. In `index.html`, replace `PASTE_YOUR_SUPABASE_PROJECT_URL_HERE` and `PASTE_YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY_HERE` with those two public values.

### 2. Create your admin account
1. In Supabase, open **Authentication → Users → Add user** and create your admin email/password.
2. Copy that user's UUID from the Users table.
3. In **SQL Editor**, run this, replacing the UUID with your user UUID:

```sql
insert into public.admins (user_id) values ('PASTE-ADMIN-USER-UUID-HERE');
```

4. Use **Admin** on the website and sign in with that account to approve/delete pending suggestions. Do not share this password.

### 3. Publish to GitHub Pages
1. Create a **public** GitHub repository named `MayankkiShadiOutfits` (GitHub Pages is available for public repositories on GitHub Free).
2. Upload `index.html`, `supabase_setup.sql`, and `README.md` to the repository root.
3. In GitHub, open **Settings → Pages**. Under **Build and deployment**, choose **Deploy from a branch**, select `main` and `/ (root)`, then save.
4. Wait for the Pages deployment to finish. The site URL will appear in Settings → Pages, usually `https://YOUR-GITHUB-USERNAME.github.io/MayankkiShadiOutfits/`.

### 4. Test before sharing
- Open the published URL in a private/incognito browser window.
- Submit one test outfit; confirm it is pending and not shown publicly.
- Sign in as admin, approve it, and confirm it appears on the home page.
- Test comments, reactions, ratings and rankings.

## Limits and safety
- The frontend contains only the Supabase Project URL and publishable/anon key. Those are designed for browser use **only when Row Level Security is enabled and policies are correct**. Never add a Supabase secret/service-role key to `index.html` or GitHub.
- Since guest submissions and feedback are public, a person who discovers the URL could submit spam. Admin moderation controls whether outfit suggestions appear, but comments/ratings/votes are public. This starter does not include CAPTCHA or per-IP rate limiting.
- Images are public, intentionally. The storage upload policy limits each image to 8 MB and allows JPG, PNG and WEBP.
- Keep an occasional backup of the SQL/data from Supabase. GitHub stores the website code, not the live database or uploaded photos.
- GitHub Pages serves a static website only. Do not upload the old FastAPI app or its `.env` file to this repository.
