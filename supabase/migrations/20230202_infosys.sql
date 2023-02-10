-- da creare dopo perche' altrimenti impedisce il popolamento tramite seed file

-- CREATE TRIGGER trig_infosys_new
--     AFTER INSERT
--     ON public.info_system
--     FOR EACH ROW
--     EXECUTE FUNCTION public.on_infosys_new();
-- 
-- COMMENT ON TRIGGER trig_infosys_new ON public.info_system
--     IS 'inserisce l''autore e gli owner tra i soggetti abilitati alla modifica';

    
---- rename copy observers to authorizations

ALTER TABLE IF EXISTS public.observers
    RENAME TO authorizations;
    
ALTER TABLE public.authorizations
    RENAME CONSTRAINT observers_pkey TO authorizations_pkey;
    
----

----

CREATE TABLE IF NOT EXISTS public.observers
(
    id bigint primary key generated always as identity,
    created_at date NOT NULL DEFAULT now(),
    modified_at date NOT NULL DEFAULT now(),
    infosys_id bigint NOT NULL,
    email text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT email_observer_infosys_u UNIQUE (email, infosys_id),
    CONSTRAINT infosys_fk FOREIGN KEY (infosys_id)
        REFERENCES public.info_system (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.observers
    OWNER to postgres;

GRANT ALL ON TABLE public.observers TO anon;

GRANT ALL ON TABLE public.observers TO authenticated;

GRANT ALL ON TABLE public.observers TO postgres;

GRANT ALL ON TABLE public.observers TO service_role;

COMMENT ON CONSTRAINT email_observer_infosys_u ON public.observers
    IS 'The infosystem must be observed only once by each user';

-----

