-- This script was generated by the Schema Diff utility in pgAdmin 4
-- For the circular dependencies, the order in which Schema Diff writes the objects is not very sophisticated
-- and may require manual changes to the script to ensure changes are applied in the correct order.
-- Please report an issue for any failure with the reproduction steps.

CREATE OR REPLACE FUNCTION public.on_infosys_update()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    NEW.modification_date := NOW();
    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.on_infosys_update()
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.on_infosys_update() TO authenticated;

GRANT EXECUTE ON FUNCTION public.on_infosys_update() TO postgres;

GRANT EXECUTE ON FUNCTION public.on_infosys_update() TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.on_infosys_update() TO anon;

GRANT EXECUTE ON FUNCTION public.on_infosys_update() TO service_role;


CREATE TABLE IF NOT EXISTS public.uo
(
    id integer NOT NULL,
    cod text COLLATE pg_catalog."default" NOT NULL,
    description text COLLATE pg_catalog."default",
    parent integer NULL,
    CONSTRAINT uo_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.uo
    OWNER to postgres;

GRANT ALL ON TABLE public.uo TO anon;

GRANT ALL ON TABLE public.uo TO authenticated;

GRANT ALL ON TABLE public.uo TO postgres;

GRANT ALL ON TABLE public.uo TO service_role;



CREATE TABLE IF NOT EXISTS public.info_system
(
    id bigint primary key generated always as identity,
    description text COLLATE pg_catalog."default",
    finality text COLLATE pg_catalog."default" NOT NULL,
    uo_id integer NOT NULL,
    pass_url text COLLATE pg_catalog."default",
    name text COLLATE pg_catalog."default" NOT NULL,
    resp_email text COLLATE pg_catalog."default" NOT NULL,
    resp_inf_email text COLLATE pg_catalog."default",
    creation_date date NOT NULL DEFAULT now(),
    modification_date date NOT NULL,
    CONSTRAINT name_uk UNIQUE (name),
    CONSTRAINT uo_fk FOREIGN KEY (uo_id)
        REFERENCES public.uo (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT pass_url_valid CHECK (pass_url ~* 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,255}\.[a-z]{2,9}\y([-a-zA-Z0-9@:%_\+.~#?&//=]*)$'::text),
    CONSTRAINT name_leght CHECK (length(name) < 100),
    CONSTRAINT resp_neq_respinf CHECK (resp_email <> resp_inf_email) NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.info_system
    OWNER to postgres;

GRANT ALL ON TABLE public.info_system TO authenticated;

GRANT ALL ON TABLE public.info_system TO anon;

GRANT ALL ON TABLE public.info_system TO service_role;

GRANT ALL ON TABLE public.info_system TO postgres;

COMMENT ON COLUMN public.info_system.description
    IS 'the short description of the infosystem';

COMMENT ON COLUMN public.info_system.finality
    IS 'the detailed description';

COMMENT ON COLUMN public.info_system.uo_id
    IS 'id of the Organizion Unit  responsibile for the system';

COMMENT ON COLUMN public.info_system.name
    IS 'name of the infosystem';

COMMENT ON COLUMN public.info_system.resp_email
    IS 'email of the responsible for the infosystem';

COMMENT ON CONSTRAINT name_uk ON public.info_system
    IS 'the name of the information system must be unique inside the organization';

COMMENT ON CONSTRAINT pass_url_valid ON public.info_system
    IS 'check if is a valid url';
COMMENT ON CONSTRAINT name_leght ON public.info_system
    IS 'the name lenght must be 100 char max';
COMMENT ON CONSTRAINT resp_neq_respinf ON public.info_system
    IS 'if the system manager for the IT unit is the same as the system manager, then it should not be specified';

CREATE TRIGGER trig_infosys_update
    BEFORE UPDATE 
    ON public.info_system
    FOR EACH ROW
    EXECUTE FUNCTION public.on_infosys_update();

