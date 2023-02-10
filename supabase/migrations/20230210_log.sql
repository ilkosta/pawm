CREATE TABLE IF NOT EXISTS public.fnlog
(
  id bigint primary key generated always as identity
, source text
, description text
, created_at timestamp with time zone DEFAULT now()
);


