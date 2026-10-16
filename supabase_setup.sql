-- MayankkiShadiOutfits: run this whole file in Supabase Dashboard > SQL Editor.
-- Public visitors can read approved outfits and submit suggestions/comments/votes/ratings/rankings.
-- The admin account is allow-listed in public.admins. Only admins can see pending outfits or moderate.
create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.outfits (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('Haldi','Mehendi','Sangeet','Wedding','Reception')),
  title text not null check (char_length(title) between 1 and 100),
  description text not null default '' check (char_length(description) <= 1000),
  image_url text not null,
  source text not null default 'community' check (source in ('owner','community')),
  submitted_by text not null default '' check (char_length(submitted_by) <= 60),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  outfit_id uuid not null references public.outfits(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  body text not null check (char_length(body) between 1 and 1200),
  created_at timestamptz not null default now()
);
create table if not exists public.reactions (
  id uuid primary key default gen_random_uuid(),
  outfit_id uuid not null references public.outfits(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  reaction text not null check (reaction in ('like','dislike')),
  created_at timestamptz not null default now(),
  unique(outfit_id,name)
);
create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  outfit_id uuid not null references public.outfits(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  rating int not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  unique(outfit_id,name)
);
create table if not exists public.rankings (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('Haldi','Mehendi','Sangeet','Wedding','Reception')),
  outfit_id uuid not null references public.outfits(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  rank int not null check (rank between 1 and 10),
  created_at timestamptz not null default now(),
  unique(category,name,outfit_id)
);
create index if not exists outfits_category_status_idx on public.outfits(category,status);
create index if not exists comments_outfit_idx on public.comments(outfit_id,created_at desc);
create index if not exists reactions_outfit_idx on public.reactions(outfit_id);
create index if not exists ratings_outfit_idx on public.ratings(outfit_id);
create index if not exists rankings_outfit_idx on public.rankings(outfit_id);

alter table public.admins enable row level security;
alter table public.outfits enable row level security;
alter table public.comments enable row level security;
alter table public.reactions enable row level security;
alter table public.ratings enable row level security;
alter table public.rankings enable row level security;

-- Admins can verify their own membership; only project owner/service role should add admins.
drop policy if exists "admins can read own membership" on public.admins;
create policy "admins can read own membership" on public.admins for select to authenticated using (auth.uid() = user_id);

-- Approved outfits are public. Admins can see all rows and moderate.
drop policy if exists "public reads approved outfits" on public.outfits;
create policy "public reads approved outfits" on public.outfits for select to anon, authenticated using (status = 'approved' or exists (select 1 from public.admins a where a.user_id = auth.uid()));
drop policy if exists "anyone can suggest outfit" on public.outfits;
create policy "anyone can suggest outfit" on public.outfits for insert to anon, authenticated with check (status = 'pending' and source = 'community');
drop policy if exists "admins update outfits" on public.outfits;
create policy "admins update outfits" on public.outfits for update to authenticated using (exists (select 1 from public.admins a where a.user_id = auth.uid())) with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));
drop policy if exists "admins delete outfits" on public.outfits;
create policy "admins delete outfits" on public.outfits for delete to authenticated using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- Anyone can read feedback for approved outfits and submit feedback. No public update/delete policies.
drop policy if exists "public reads comments" on public.comments;
create policy "public reads comments" on public.comments for select to anon, authenticated using (exists (select 1 from public.outfits o where o.id = outfit_id and (o.status='approved' or exists (select 1 from public.admins a where a.user_id=auth.uid()))));
drop policy if exists "public adds comments" on public.comments;
create policy "public adds comments" on public.comments for insert to anon, authenticated with check (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved'));
drop policy if exists "public reads reactions" on public.reactions;
create policy "public reads reactions" on public.reactions for select to anon, authenticated using (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved'));
drop policy if exists "public adds reactions" on public.reactions;
create policy "public adds reactions" on public.reactions for insert to anon, authenticated with check (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved'));
drop policy if exists "public reads ratings" on public.ratings;
create policy "public reads ratings" on public.ratings for select to anon, authenticated using (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved'));
drop policy if exists "public adds ratings" on public.ratings;
create policy "public adds ratings" on public.ratings for insert to anon, authenticated with check (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved'));
drop policy if exists "public reads rankings" on public.rankings;
create policy "public reads rankings" on public.rankings for select to anon, authenticated using (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved'));
drop policy if exists "public adds rankings" on public.rankings;
create policy "public adds rankings" on public.rankings for insert to anon, authenticated with check (exists (select 1 from public.outfits o where o.id=outfit_id and o.status='approved' and o.category=rankings.category));

-- Public image bucket. Images are intentionally public as requested; uploads are limited to 8 MB and image types.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('outfit-photos','outfit-photos',true,8388608,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=8388608,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "public views outfit photos" on storage.objects;
create policy "public views outfit photos" on storage.objects for select to anon, authenticated using (bucket_id='outfit-photos');
drop policy if exists "public uploads outfit photos" on storage.objects;
create policy "public uploads outfit photos" on storage.objects for insert to anon, authenticated with check (bucket_id='outfit-photos' and lower(storage.extension(name)) in ('jpg','jpeg','png','webp'));
drop policy if exists "admins delete outfit photos" on storage.objects;
create policy "admins delete outfit photos" on storage.objects for delete to authenticated using (bucket_id='outfit-photos' and exists (select 1 from public.admins a where a.user_id=auth.uid()));

-- Explicit API privileges for the browser roles; RLS policies above still constrain rows.
grant select on public.admins to authenticated;
grant select, insert on public.outfits to anon, authenticated;
grant update, delete on public.outfits to authenticated;
grant select, insert on public.comments to anon, authenticated;
grant select, insert on public.reactions to anon, authenticated;
grant select, insert on public.ratings to anon, authenticated;
grant select, insert on public.rankings to anon, authenticated;
grant select on storage.objects to anon, authenticated;
grant insert on storage.objects to anon, authenticated;
grant delete on storage.objects to authenticated;
