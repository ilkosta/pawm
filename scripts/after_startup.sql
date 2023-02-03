-- the trigger must be activated after the db initialization by the loading of seed
-- to prevent the insert errors

CREATE TRIGGER trig_infosys_new
    AFTER INSERT
    ON public.info_system
    FOR EACH ROW
    EXECUTE FUNCTION public.on_infosys_new();

COMMENT ON TRIGGER trig_infosys_new ON public.info_system
    IS 'inserisce l''autore e gli owner tra i soggetti abilitati alla modifica';
