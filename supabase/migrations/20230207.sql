-- imposto la row level security su info_system

-- tutti possono leggere
CREATE POLICY "Enable read access for all users" ON "public"."info_system"
AS PERMISSIVE FOR SELECT
TO public
USING (true)

-- solo gli utenti atutenticati possono inserire dei sistemi

CREATE POLICY "Enable insert for authenticated users only" ON "public"."info_system"
AS PERMISSIVE FOR INSERT
TO authenticated

WITH CHECK (true)


-- solo un abilitato puo' modificare
CREATE POLICY "Enable update only to user which email is listed on authorizations table" ON "public"."info_system"
AS PERMISSIVE FOR UPDATE
TO public
USING (exists ( select 1 from public.authorizations a where a.infosys_id = id and a.email = auth.email() ))
WITH CHECK (exists ( select 1 from public.authorizations a where a.infosys_id = id and a.email = auth.email() ))


CREATE POLICY "Enable delete only to user which email is listed on authorizations table" ON "public"."info_system"
AS PERMISSIVE FOR DELETE
TO public
USING (exists ( select 1 from public.authorizations a where a.infosys_id = id and a.email = auth.email() ))
WITH CHECK (exists ( select 1 from public.authorizations a where a.infosys_id = id and a.email = auth.email() ))
