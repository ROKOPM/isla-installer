-- webservice/init.sql  (01_webservice.sql)
-- =============================================================================
-- Ejecutado antes que init_pipeline.sql (02_pipeline.sql).
-- El webservice usa datalake.capturas_crudas y staging.tabla_llava,
-- definidas en init_pipeline.sql. Este archivo precrea la extensión vectorial
-- para que esté disponible cuando se ejecute el segundo script.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

DO $$ BEGIN
    RAISE NOTICE '✅ Extensión vector habilitada.';
END $$;
