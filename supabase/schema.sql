-- Skema database Lentera Pustaka
-- Jalankan file ini pada Supabase Dashboard > SQL Editor.
-- Aman dijalankan berulang karena memakai IF NOT EXISTS dan DROP POLICY IF EXISTS.

create extension if not exists pgcrypto;

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  book_key text not null,
  title text not null,
  author text,
  cover_id integer,
  borrower_name text not null check (char_length(trim(borrower_name)) >= 3),
  borrower_email text,
  borrowed_at date not null default current_date,
  due_date date not null,
  returned_at date,
  status text not null default 'borrowed' check (status in ('borrowed', 'returned')),
  notes text check (notes is null or char_length(notes) <= 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.loans is 'Catatan peminjaman buku milik pengguna Lentera Pustaka';
comment on column public.loans.book_key is 'Kunci work Open Library, contoh /works/OL17930368W';

create index if not exists loans_status_idx on public.loans (status);
create index if not exists loans_book_key_idx on public.loans (book_key);
create index if not exists loans_due_date_idx on public.loans (due_date);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists loans_set_updated_at on public.loans;
create trigger loans_set_updated_at
before update on public.loans
for each row execute function public.set_updated_at();

-- Row Level Security.
-- Aplikasi ini berjalan tanpa autentikasi, jadi akses dibuka untuk role anon
-- yang memakai publishable key. Untuk produksi, ganti policy ini dengan aturan
-- berbasis auth.uid() agar setiap pengguna hanya melihat datanya sendiri.
alter table public.loans enable row level security;

drop policy if exists "loans_select_anon" on public.loans;
create policy "loans_select_anon"
on public.loans for select
to anon
using (true);

drop policy if exists "loans_insert_anon" on public.loans;
create policy "loans_insert_anon"
on public.loans for insert
to anon
with check (true);

drop policy if exists "loans_update_anon" on public.loans;
create policy "loans_update_anon"
on public.loans for update
to anon
using (true)
with check (true);

drop policy if exists "loans_delete_anon" on public.loans;
create policy "loans_delete_anon"
on public.loans for delete
to anon
using (true);

grant select, insert, update, delete on public.loans to anon;

-- Data contoh untuk demo (opsional).
-- Hapus blok ini bila tidak ingin data awal.
insert into public.loans (
  book_key, title, author, cover_id, borrower_name, borrower_email,
  borrowed_at, due_date, status, notes
)
select
  '/works/OL17930368W',
  'Atomic Habits',
  'James Clear',
  12539702,
  'Ari Putri Laksmi',
  'putri.ari@student.undiksha.ac.id',
  current_date - 3,
  current_date + 11,
  'borrowed',
  'Buku referensi untuk tugas mata kuliah.'
where not exists (select 1 from public.loans);

insert into public.loans (
  book_key, title, author, cover_id, borrower_name, borrower_email,
  borrowed_at, due_date, status, notes
)
select
  '/works/OL27482W',
  'The Hobbit',
  'J.R.R. Tolkien',
  14627509,
  'Ari Putri Laksmi',
  'putri.ari@student.undiksha.ac.id',
  current_date - 25,
  current_date - 5,
  'borrowed',
  'Sudah lewat tenggat, perlu segera dikembalikan.'
where (select count(*) from public.loans) = 1;

insert into public.loans (
  book_key, title, author, cover_id, borrower_name, borrower_email,
  borrowed_at, due_date, returned_at, status, notes
)
select
  '/works/OL27448W',
  'The Lord of the Rings',
  'J. R. R. Tolkien',
  14625765,
  'Ari Putri Laksmi',
  'putri.ari@student.undiksha.ac.id',
  current_date - 40,
  current_date - 26,
  current_date - 28,
  'returned',
  'Sudah dikembalikan dengan kondisi baik.'
where (select count(*) from public.loans) = 2;
