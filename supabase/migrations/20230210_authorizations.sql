
ALTER TABLE "public"."authorizations" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for authenticated users" ON "public"."authorizations"
AS PERMISSIVE FOR SELECT
TO authenticated
USING (true) ;

CREATE POLICY "Enable insert for users based on email" ON "public"."authorizations"
-- each user can select a system to observe
-- so a user cannot indicate another user as observer
-- with the exception of the user authorized to change a system (owner, etc.)
AS PERMISSIVE FOR INSERT
TO authenticated
with check 
  ( auth.jwt() ->> 'email' = email 
    or exists ( -- is already authorized for insert
      select 1 
      from public.authorizations a 
      where a.infosys_id = infosys_id 
        and a.email = email
      )
  );
  

CREATE POLICY "Enable update for users based on email" ON "public"."authorizations"
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (auth.jwt() ->> 'email' = email)
WITH CHECK (auth.jwt() ->> 'email' = email);


CREATE POLICY "Enable delete for users based on email" ON "public"."authorizations"
AS PERMISSIVE FOR DELETE
TO authenticated
USING (auth.jwt() ->> 'email' = email);
