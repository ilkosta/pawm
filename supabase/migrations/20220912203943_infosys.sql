-- FUNCTION: public.on_infosys_new()

-- DROP FUNCTION IF EXISTS public.on_infosys_new();

CREATE OR REPLACE FUNCTION public.on_infosys_new()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN	
	-- insert the author
	if auth.jwt() != '{}'::jsonb then
	else
		INSERT INTO public.observers(infosys_id, email)
		VALUES (new.id, auth.jwt() ->> 'email')
		ON CONFLICT ON CONSTRAINT email_infosys_u
		DO NOTHING;
	end if;
	
	-- insert responsible
	INSERT INTO public.observers(infosys_id, email)
	VALUES (new.id, new.resp_email)
	ON CONFLICT ON CONSTRAINT email_infosys_u
	DO NOTHING;
	
	-- insert inf. resp.
	if new.resp_inf_email != '' then
		INSERT INTO public.observers(infosys_id, email)
		VALUES (new.id, new.resp_inf_email)
		ON CONFLICT ON CONSTRAINT email_infosys_u
		DO NOTHING;
	end if;
	
    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.on_infosys_new()
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.on_infosys_new() TO authenticated;

GRANT EXECUTE ON FUNCTION public.on_infosys_new() TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.on_infosys_new() TO anon;

GRANT EXECUTE ON FUNCTION public.on_infosys_new() TO service_role;



ALTER TABLE public.observers
    ALTER COLUMN email TYPE text COLLATE pg_catalog."default";
ALTER TABLE IF EXISTS public.observers
    ALTER COLUMN email DROP DEFAULT;

ALTER TABLE IF EXISTS public.observers
    ALTER COLUMN email SET STORAGE EXTENDED;
ALTER TABLE IF EXISTS public.observers DROP CONSTRAINT IF EXISTS user_email_fk;
