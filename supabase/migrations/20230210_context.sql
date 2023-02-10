-- disable insert/update for the context/external tables

ALTER TABLE "public"."uo" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON "public"."uo"
AS PERMISSIVE FOR SELECT
TO public
USING (true) ;



ALTER TABLE "public"."address_book" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON "public"."address_book"
AS PERMISSIVE FOR SELECT
TO public
USING (true) ;

----------------

----------------


