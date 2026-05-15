-- =============================================================
-- PIPELINE COMPLETO v4 — pgvector edition (BDsFinales)
-- Schemas: datalake | staging | warehouse
-- Requiere: pgvector/pgvector:pg16
-- Cambios vs v3:
--   · datalake.capturas_crudas: agrega confianza_yolo NUMERIC(4,3)
--   · staging.fn_auto_llenado_central: propaga confianza_yolo en vector_bruto
--   · warehouse.hechos_actividades_escenaurbana: elimina baja_calidad_llava y alertas_coherencia
--   · warehouse.hechos_vectores_descripcion_habitos: elimina cluster_id y etiqueta_habito_ia
--   · warehouse.dim_calendario_escolar reemplazada por dim_tiempo_calendario_escolar (1 fila/fecha)
-- =============================================================

-- ── Extensión vectorial ───────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;

-- ── SCHEMA 1: DATALAKE ───────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS datalake;

CREATE TABLE IF NOT EXISTS datalake.capturas_crudas (
    id_captura      SERIAL PRIMARY KEY,
    imagen_serial   TEXT NOT NULL,
    estampa_tiempo  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    estado_llava    VARCHAR(20) DEFAULT 'pendiente',
    confianza_yolo  NUMERIC(4,3) DEFAULT NULL
);

-- Migracion idempotente para instalaciones existentes
ALTER TABLE datalake.capturas_crudas
    ADD COLUMN IF NOT EXISTS confianza_yolo NUMERIC(4,3) DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_capturas_estado
    ON datalake.capturas_crudas(estado_llava);

CREATE INDEX IF NOT EXISTS idx_capturas_tiempo
    ON datalake.capturas_crudas(estampa_tiempo DESC);

-- ── SCHEMA 2: STAGING ────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.tabla_davis (
    id_davis        SERIAL PRIMARY KEY,
    aqi             NUMERIC(8,2),
    pm1             NUMERIC(8,2),
    pm2_5           NUMERIC(8,2),
    pm10            NUMERIC(8,2),
    temperatura     NUMERIC(8,2),
    humedad         NUMERIC(8,2),
    punto_rocio     NUMERIC(8,2),
    indice_calor    NUMERIC(8,2),
    estampa_tiempo  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_davis_tiempo
    ON staging.tabla_davis(estampa_tiempo DESC);

CREATE TABLE IF NOT EXISTS staging.tabla_llava (
    id_llava        SERIAL PRIMARY KEY,
    id_captura      INT REFERENCES datalake.capturas_crudas(id_captura),
    metadatos_json  TEXT,
    -- Datos YOLO smoking + termica enviados desde la isla.
    -- El qwen_worker los lee desde vector_bruto para cross-validar con LLaVA.
    smoking_json    JSONB DEFAULT NULL,
    estampa_tiempo  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- Migracion para instalaciones existentes (idempotente)
ALTER TABLE staging.tabla_llava
    ADD COLUMN IF NOT EXISTS smoking_json JSONB DEFAULT NULL;

CREATE TABLE IF NOT EXISTS staging.tabla_central (
    id_central      SERIAL PRIMARY KEY,
    estampa_tiempo  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    vector_bruto    JSONB,
    estado_envio    VARCHAR(50) DEFAULT 'pendiente'
);

CREATE INDEX IF NOT EXISTS idx_central_estado
    ON staging.tabla_central(estado_envio);

CREATE INDEX IF NOT EXISTS idx_central_tiempo
    ON staging.tabla_central(estampa_tiempo DESC);

-- Trigger: une tabla_llava + tabla_davis del mismo minuto → tabla_central
CREATE OR REPLACE FUNCTION staging.fn_auto_llenado_central()
RETURNS TRIGGER AS $$
DECLARE
    v_pm10           NUMERIC(8,2);
    v_temp           NUMERIC(8,2);
    v_hum            NUMERIC(8,2);
    v_confianza_yolo NUMERIC(4,3);
    v_vector_armado  JSONB;
BEGIN
    -- Lectura Davis más reciente dentro de los últimos 10 minutos
    SELECT pm10, temperatura, humedad
    INTO   v_pm10, v_temp, v_hum
    FROM   staging.tabla_davis
    WHERE  estampa_tiempo <= NEW.estampa_tiempo
      AND  estampa_tiempo >= NEW.estampa_tiempo - INTERVAL '10 minutes'
    ORDER BY estampa_tiempo DESC
    LIMIT 1;

    -- Confianza YOLO cruda desde datalake
    SELECT confianza_yolo
    INTO   v_confianza_yolo
    FROM   datalake.capturas_crudas
    WHERE  id_captura = NEW.id_captura;

    -- smoking_detection mantiene estructura plana (que lee qwen_worker)
    -- + confianza_yolo agregada via merge JSONB.
    v_vector_armado := jsonb_build_object(
        'vision_llava', NEW.metadatos_json::jsonb,
        'clima_davis', CASE
            WHEN v_pm10 IS NOT NULL THEN jsonb_build_object(
                'pm10', v_pm10,
                'temp', v_temp,
                'hum',  v_hum
            )
            ELSE NULL
        END,
        'smoking_detection',
            COALESCE(NEW.smoking_json, '{}'::jsonb)
            || jsonb_build_object('confianza_yolo', v_confianza_yolo)
    );

    INSERT INTO staging.tabla_central (estampa_tiempo, vector_bruto, estado_envio)
    VALUES (NEW.estampa_tiempo, v_vector_armado, 'pendiente');

    UPDATE datalake.capturas_crudas
    SET    estado_llava = 'procesado'
    WHERE  id_captura   = NEW.id_captura;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_llenado_central ON staging.tabla_llava;
CREATE TRIGGER trg_auto_llenado_central
AFTER INSERT ON staging.tabla_llava
FOR EACH ROW EXECUTE FUNCTION staging.fn_auto_llenado_central();

-- ── SCHEMA 3: WAREHOUSE ───────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS warehouse;

-- 1. DIMENSIONES CATALOGO

CREATE TABLE IF NOT EXISTS warehouse.dim_tiempo (
    id_tiempo       SERIAL PRIMARY KEY,
    estampa_tiempo  TIMESTAMP NOT NULL,
    fecha_completa  DATE NOT NULL,
    anio            INT NOT NULL,
    mes             INT NOT NULL,
    dia             INT NOT NULL,
    dia_semana      VARCHAR(15) NOT NULL,
    hora            INT NOT NULL,
    minuto          INT NOT NULL,
    UNIQUE(fecha_completa, hora, minuto)
);

CREATE TABLE IF NOT EXISTS warehouse.dim_geoespacial (
    id_geoespacial  SERIAL PRIMARY KEY,
    campus          VARCHAR(100) NOT NULL,
    zona            VARCHAR(100),
    camara          VARCHAR(100) UNIQUE,
    coordenadas     VARCHAR(255)
);

-- 2. TABLA CENTRAL DE HECHOS
--    Integra: contexto cognitivo (Qwen) + datos ambientales (Davis)

CREATE TABLE IF NOT EXISTS warehouse.hechos_actividades_escenaurbana (
    id_hecho            SERIAL PRIMARY KEY,
    id_tiempo           INT NOT NULL REFERENCES warehouse.dim_tiempo(id_tiempo),
    id_geoespacial      INT NOT NULL REFERENCES warehouse.dim_geoespacial(id_geoespacial),

    -- Contexto cognitivo (llenado por qwen_worker)
    esta_fumando        BOOLEAN NOT NULL DEFAULT FALSE,
    actividad           VARCHAR(255),
    postura_dominante   VARCHAR(100),
    interaccion_social  VARCHAR(100),
    objetos_detectados  JSONB,
    resumen_semantico   TEXT,

    -- Presencia fisica
    presencia_humana    BOOLEAN DEFAULT FALSE,
    conteo_personas     INT DEFAULT 0,
    nivel_riesgo_salud  VARCHAR(50),

    -- Datos ambientales (llenado por qwen_worker desde Davis)
    nivel_pm10          NUMERIC(8,2),
    temperatura         NUMERIC(5,2),
    humedad             NUMERIC(5,2),
    calidad_aire_label  VARCHAR(50),

    id_central_origen   INT REFERENCES staging.tabla_central(id_central),

    -- Cross-validacion YOLO smoking vs LLaVA
    -- smoking_source: resultado de la logica de cruce:
    --   'confirmado_ambos'         — YOLO=True  + LLaVA=True  → fumado confirmado
    --   'alucinacion_llava'        — YOLO=True  + LLaVA=False → LLaVA descartado
    --   'solo_llava_sin_cigarro'   — YOLO=False + LLaVA=True  → bajo confianza
    --   'negativo_confirmado'      — YOLO=False + LLaVA=False → no fuma
    --   'sin_datos_yolo'           — modelo YOLO no disponible en isla
    smoking_source      VARCHAR(50) DEFAULT 'sin_datos_yolo',
    yolo_cigarette_conf NUMERIC(4,3) DEFAULT NULL
);

-- Migracion idempotente para instalaciones existentes
ALTER TABLE warehouse.hechos_actividades_escenaurbana
    ADD COLUMN IF NOT EXISTS smoking_source      VARCHAR(50) DEFAULT 'sin_datos_yolo';
ALTER TABLE warehouse.hechos_actividades_escenaurbana
    ADD COLUMN IF NOT EXISTS yolo_cigarette_conf NUMERIC(4,3) DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_hechos_tiempo
    ON warehouse.hechos_actividades_escenaurbana(id_tiempo);

CREATE INDEX IF NOT EXISTS idx_hechos_geo
    ON warehouse.hechos_actividades_escenaurbana(id_geoespacial);

CREATE INDEX IF NOT EXISTS idx_hechos_fumando
    ON warehouse.hechos_actividades_escenaurbana(esta_fumando)
    WHERE esta_fumando = TRUE;

-- Indice parcial para alertas rapidas por fuente de deteccion de fumado
CREATE INDEX IF NOT EXISTS idx_hechos_smoking_source
    ON warehouse.hechos_actividades_escenaurbana(smoking_source)
    WHERE esta_fumando = TRUE;

-- 3. EXTENSIÓN MATEMÁTICA: Vectores y UMAP (llenado por habits_worker)

CREATE TABLE IF NOT EXISTS warehouse.hechos_vectores_descripcion_habitos (
    id_vector     SERIAL PRIMARY KEY,
    id_hecho      INT NOT NULL REFERENCES warehouse.hechos_actividades_escenaurbana(id_hecho)
                  ON DELETE CASCADE,
    vector_habito vector(384),
    umap_x        FLOAT,
    umap_y        FLOAT,
    umap_z        FLOAT
    -- cluster_id y etiqueta_habito_ia eliminados:
    -- calculados en tiempo real por HDBSCAN en el dashboard de Streamlit
);

-- 4. ÍNDICES

CREATE INDEX IF NOT EXISTS idx_hechos_tiempo_main
    ON warehouse.hechos_actividades_escenaurbana(id_tiempo);

CREATE INDEX IF NOT EXISTS idx_hechos_geo_main
    ON warehouse.hechos_actividades_escenaurbana(id_geoespacial);

CREATE INDEX IF NOT EXISTS idx_vector_habito
    ON warehouse.hechos_vectores_descripcion_habitos
    USING hnsw (vector_habito vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_vector_null
    ON warehouse.hechos_vectores_descripcion_habitos(id_hecho)
    WHERE vector_habito IS NULL;

CREATE INDEX IF NOT EXISTS idx_vector_hecho
    ON warehouse.hechos_vectores_descripcion_habitos(id_hecho);

-- 5. CÁMARA BASE

INSERT INTO warehouse.dim_geoespacial (campus, zona, camara, coordenadas)
VALUES ('Campus Principal', 'Acceso Norte', 'rtsp_cam_01', '19.4326,-99.1332')
ON CONFLICT (camara) DO NOTHING;

-- 6. CALENDARIO ACADÉMICO (subcatálogo de dim_tiempo, 1 fila por fecha)

CREATE TABLE IF NOT EXISTS warehouse.dim_tiempo_calendario_escolar (
    id_calendario  SERIAL PRIMARY KEY,
    fecha          DATE NOT NULL UNIQUE,
    id_tiempo      INT REFERENCES warehouse.dim_tiempo(id_tiempo),
    tipo_periodo   VARCHAR(60),
    nombre_periodo VARCHAR(120),
    semestre       VARCHAR(40),
    descripcion    TEXT
);

COMMENT ON TABLE warehouse.dim_tiempo_calendario_escolar IS
    'Subcatalogo de dim_tiempo. Una fila por fecha con contexto del calendario academico IPN 2025-2026.';
