-- FUNCTION: public.on_infosys_new()

-- DROP FUNCTION IF EXISTS public.on_infosys_new();

CREATE OR REPLACE FUNCTION public.on_infosys_new()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN	
	------------------------------
	-- authorizations
	------------------------------
	-- - author
	-- - owner
	-- - resp inf
	INSERT INTO public.authorizations(infosys_id, email)
	VALUES (new.id, auth.jwt() ->> 'email')
	ON CONFLICT ON CONSTRAINT email_infosys_u
	DO NOTHING;
	
	INSERT INTO public.authorizations(infosys_id, email)
	VALUES (new.id, new.resp_email)
	ON CONFLICT ON CONSTRAINT email_infosys_u
	DO NOTHING;
	
	if new.resp_inf_email is not null then
	
		INSERT INTO public.authorizations(infosys_id, email)
		VALUES (new.id, new.resp_inf_email)
		ON CONFLICT ON CONSTRAINT email_infosys_u
		DO NOTHING;
	end if;
	
	
	------------------------------
	-- observers
	------------------------------
	-- - author
	-- - owner
	-- - resp inf
	
	INSERT INTO public.observers(infosys_id, email)
	VALUES (new.id, auth.jwt() ->> 'email')
	ON CONFLICT ON CONSTRAINT email_observer_infosys_u
	DO NOTHING;
	
	INSERT INTO public.observers(infosys_id, email)
	VALUES (new.id, new.resp_email)
	ON CONFLICT ON CONSTRAINT email_observer_infosys_u
	DO NOTHING;
	
	if new.resp_inf_email is not null then
	
		INSERT INTO public.observers(infosys_id, email)
		VALUES (new.id, new.resp_inf_email)
		ON CONFLICT ON CONSTRAINT email_observer_infosys_u
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


