-- This script was generated by the Schema Diff utility in pgAdmin 4
-- For the circular dependencies, the order in which Schema Diff writes the objects is not very sophisticated
-- and may require manual changes to the script to ensure changes are applied in the correct order.
-- Please report an issue for any failure with the reproduction steps.

CREATE TABLE IF NOT EXISTS public.observers
(
    id bigint primary key generated always as identity,
    created_at date NOT NULL DEFAULT now(),
    modified_at date NOT NULL DEFAULT now(),
    infosys_id bigint NOT NULL,
    email text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT email_infosys_u UNIQUE (email, infosys_id),
    CONSTRAINT infosys_fk FOREIGN KEY (infosys_id)
        REFERENCES public.info_system (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        
        -- dopo l'aggiornamento di supabase risulta che 
        -- il campo email non e' piu' univoco e non puo' 
        -- essere utilizzato per impostare una fk
        -- TODO : impostare univico il campo email come requisito applicativo
    -- CONSTRAINT user_email_fk FOREIGN KEY (email)
    --     REFERENCES auth.users (email) MATCH SIMPLE
    --     ON UPDATE NO ACTION
    --     ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.observers
    OWNER to postgres;

GRANT ALL ON TABLE public.observers TO anon;

GRANT ALL ON TABLE public.observers TO authenticated;

GRANT ALL ON TABLE public.observers TO postgres;

GRANT ALL ON TABLE public.observers TO service_role;

COMMENT ON CONSTRAINT email_infosys_u ON public.observers
    IS 'The infosystem must be observed only once by each user';

ALTER TABLE public.info_system
    ALTER COLUMN description TYPE text COLLATE pg_catalog."default";
ALTER TABLE IF EXISTS public.info_system
    ALTER COLUMN description DROP DEFAULT;

ALTER TABLE IF EXISTS public.info_system
    ALTER COLUMN description SET STORAGE EXTENDED;


ALTER TABLE public.info_system
    ALTER COLUMN finality TYPE text COLLATE pg_catalog."default";
ALTER TABLE IF EXISTS public.info_system
    ALTER COLUMN finality DROP DEFAULT;

ALTER TABLE IF EXISTS public.info_system
    ALTER COLUMN finality DROP NOT NULL;

ALTER TABLE IF EXISTS public.info_system
    ALTER COLUMN finality SET STORAGE EXTENDED;

