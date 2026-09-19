--Creating table cgmacros
CREATE TABLE cgmacros (
    subject INT,
    source_file VARCHAR(100),
    timestamp TIMESTAMP,
    libre_gl NUMERIC(10,2),
    dexcom_gl NUMERIC(10,2),
    hr INTEGER,
    calories_activity NUMERIC(10,4),
    mets NUMERIC(10,2),
    meal_type VARCHAR(100),
    calories NUMERIC(10,2),
    carbs NUMERIC(10,2),
    protein NUMERIC(10,2),
    fat NUMERIC(10,2),
    fiber NUMERIC(10,2),
    amount_consumed NUMERIC(10,2),
    steps INTEGER,
    intensity INTEGER,
    sugar NUMERIC(10,2),
    amount_consumed_flag BOOLEAN,
    nutrition_outlier_flag BOOLEAN
);
-------------------------
---Creating the table for Bio:
CREATE TABLE bio (
    subject INT PRIMARY KEY,
    age INTEGER, 
	gender VARCHAR(20), 
    bmi NUMERIC(10,2), 
	body_weight NUMERIC(10,2), 
	height NUMERIC(10,2),
	ethnicity VARCHAR(100),
    a1c_pdl_lab  NUMERIC(10,2), 
	fasting_glu_pdl_lab NUMERIC, 
	insulin NUMERIC(10,2),
    triglycerides NUMERIC, 
	cholesterol NUMERIC, 
	hdl NUMERIC,
    non_hdl NUMERIC, 
	ldl_cal NUMERIC, 
	vldl_cal NUMERIC,
	cho_per_hdl_ratio NUMERIC(10,2),
	collection_time_pdl_lab TIME,
	num_1_contour_fingerstick_glu NUMERIC,
	time_t TIME,
	num_2_contour_fingerstick_glu NUMERIC,
	time_t_1 TIME,
	num_3_contour_fingerstick_glu NUMERIC,
	time_t_2 TIME
    -- diabetes_status TEXT  -- derive from a1c thresholds if not already a column
);
------------------------------------------------------------------------------------------------------------------------------
--Creating the table Microbes:
-- PostgreSQL allows at most 1,600 columns per table, and the practical limit can be even lower depending on row size.
-- So you cannot load this Microbes CSV as one normal PostgreSQL table with all 1,980 columns.
CREATE TABLE microbes (
    subject INTEGER NOT NULL,
    microorganism TEXT NOT NULL,
    presence SMALLINT,

    CONSTRAINT pk_microbes
        PRIMARY KEY (subject, microorganism),

    CONSTRAINT chk_microbe_presence
        CHECK (presence IN (0, 1) OR presence IS NULL)
);
TRUNCATE TABLE microbes;
-----------------------------------------------------------------------------------------------------------------------------
--Creating table for Gut Health Test:
CREATE TABLE gut_health_test
(
subject INTEGER PRIMARY KEY,
  gut_lining_health INTEGER,
  lps_biosynthesis_pathways INTEGER,
  biofilm_chemotaxis_virulence_pathways INTEGER,
  tma_production_pathways INTEGER,
  ammonia_production_pathways INTEGER,
  metabolic_fitness INTEGER,
  active_microbial_diversity INTEGER,
  butyrate_production_pathways INTEGER,
  flagellar_assembly_pathways INTEGER,
  putrescine_production_pathways INTEGER,
  uric_acid_production_pathways INTEGER,
  bile_acid_metabolism_pathways INTEGER,
  inflammatory_activity INTEGER,
  gut_microbiome_health INTEGER,
  digestive_efficiency INTEGER,
  protein_fermentation INTEGER,
  gas_production INTEGER,
  methane_gas_production_pathways INTEGER,
  sulfide_gas_production_pathways INTEGER,
  oxalate_metabolism_pathways INTEGER,
  salt_stress_pathways INTEGER,
  microbiome_induced_stress INTEGER
);
-----------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM microbes;
SELECT * FROM gut_health_test;
SELECT * FROM bio;
SELECT * FROM cgmacros;

SELECT COUNT(DISTINCT subject) FROM cgmacros;
SELECT COUNT(DISTINCT subject) FROM bio;
SELECT COUNT(DISTINCT subject) FROM gut_health_test;
SELECT COUNT(DISTINCT subject) FROM microbes;
------------------------------------------------------------------------------------------------------------------------------------

-----------------------Created Diabetes_category Based on -------------------------
 -- pre-existing diabetes (HbA1c<5.7%), 16 had pre-diabetes (5.7% ≤HbA1c≤6.4%), and 14 had type 2 diabetes (T2D) (HbA1c>6.4%).
--Establish the metabolic groups

CREATE OR REPLACE VIEW subject_metabolic_group AS
SELECT
    subject,
    age,
    gender,
    bmi,
    body_weight,
    fasting_glu_pdl_lab,
    insulin,
    triglycerides,
    hdl,
    cholesterol,
    a1c_pdl_lab,

    CASE
        WHEN a1c_pdl_lab < 5.7 THEN 'Normal'
        WHEN a1c_pdl_lab BETWEEN 5.7 AND 6.4 THEN 'Pre-diabetes'
        WHEN a1c_pdl_lab > 6.4 THEN 'Type 2 Diabetes'
        ELSE 'Unknown'
    END AS diabetes_group

FROM bio;

-----------------To check the Diabetes_category count---------------------------------------------------------
SELECT diabetes_group, COUNT(*)
FROM subject_metabolic_group
GROUP BY diabetes_group;

-------------------Verified Diabetes_Group Patient Count--------------------------------------------------------------
WITH patient_groups AS (
    SELECT
        subject,
        a1c_pdl_lab,
        CASE
            WHEN a1c_pdl_lab < 5.7 THEN 'Normal'
            WHEN a1c_pdl_lab BETWEEN 5.7 AND 6.4 THEN 'Pre-diabetes'
            WHEN a1c_pdl_lab > 6.4 THEN 'Type 2 Diabetes'
            ELSE 'Unknown'
        END AS diabetes_group
    FROM bio
)
SELECT
    diabetes_group,
    COUNT(*) AS patient_count
FROM patient_groups
GROUP BY diabetes_group
ORDER BY
    CASE diabetes_group
        WHEN 'Normal' THEN 1
        WHEN 'Pre-diabetes' THEN 2
        WHEN 'Type 2 Diabetes' THEN 3
        ELSE 4
    END;

------------------------------------------Sensor Analysis--------------------------------------------------------------------------------------	
--Question 1: Does the diagnosis appear in everyday glucose behavior?
--Do Normal, Prediabetes and Type 2 Diabetes participants actually behave differently throughout the day,
--beyond their HbA1c classification?

CREATE OR REPLACE VIEW subject_cgm_metrics AS
SELECT
    subject,

    ROUND(AVG(libre_gl), 2) AS avg_glucose,

    ROUND(STDDEV_SAMP(libre_gl), 2) AS glucose_sd,

    ROUND(
        100.0 * STDDEV_SAMP(libre_gl)
        / NULLIF(AVG(libre_gl), 0),
        2
    ) AS glucose_cv_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE libre_gl BETWEEN 70 AND 180
        ) / NULLIF(COUNT(libre_gl), 0),
        2
    ) AS tir_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE libre_gl BETWEEN 70 AND 140
        ) / NULLIF(COUNT(libre_gl), 0),
        2
    ) AS titr_70_140_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE libre_gl > 140
        ) / NULLIF(COUNT(libre_gl), 0),
        2
    ) AS time_above_140_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE libre_gl > 180
        ) / NULLIF(COUNT(libre_gl), 0),
        2
    ) AS tar_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE libre_gl < 70
        ) / NULLIF(COUNT(libre_gl), 0),
        2
    ) AS tbr_pct

FROM cgmacros
WHERE libre_gl IS NOT NULL
GROUP BY subject;


--checking AVG
SELECT
    m.diabetes_group,
    COUNT(*) AS subjects,
    ROUND(AVG(c.avg_glucose),2) AS avg_glucose,
    ROUND(AVG(c.glucose_sd),2) AS glucose_variability,
    ROUND(AVG(c.tir_pct),2) AS avg_tir,
    ROUND(AVG(c.tar_pct),2) AS avg_tar
FROM subject_metabolic_group m
JOIN subject_cgm_metrics c
    USING(subject)
GROUP BY m.diabetes_group;
------------------------------------------------------------------------------------------------------------------------------------
--2.Why does the Normal group have lower standard TIR despite having much lower average glucose and almost no hyperglycemia?

SELECT
    m.diabetes_group,
    COUNT(*) AS subjects,

    ROUND(AVG(c.avg_glucose), 2) AS avg_glucose,
    ROUND(AVG(c.glucose_sd), 2) AS glucose_variability,

    ROUND(AVG(c.tir_pct), 2) AS avg_tir,
    ROUND(AVG(c.tar_pct), 2) AS avg_tar,
    ROUND(AVG(c.tbr_pct), 2) AS avg_tbr

FROM subject_metabolic_group m

JOIN subject_cgm_metrics c
    USING(subject)

GROUP BY m.diabetes_group

ORDER BY
    CASE m.diabetes_group
        WHEN 'Normal' THEN 1
        WHEN 'Pre-diabetes' THEN 2
        WHEN 'Type 2 Diabetes' THEN 3
    END;
------------------------------------------------------------------------------------------------------------------------------
--3.Does a tighter glucose range and relative variability separate the three groups better than standard TIR?

--DROP VIEW IF EXISTS subject_cgm_metrics;

--Check this
SELECT *
FROM subject_cgm_metrics
LIMIT 10;

--Flag extreme CGM profiles
SELECT
    subject,
    avg_glucose,
    glucose_sd,
    glucose_cv_pct,
    tir_pct,
    titr_70_140_pct,
    time_above_140_pct,
    tar_pct,
    tbr_pct
FROM subject_cgm_metrics
WHERE
       tbr_pct > 20
    OR tar_pct > 10
    OR glucose_cv_pct > 36
ORDER BY subject;

--Add diabetes group to these 18 subjects
SELECT
    c.subject,
    m.diabetes_group,
    m.a1c_pdl_lab,
    m.fasting_glu_pdl_lab,
    m.bmi,

    c.avg_glucose,
    c.glucose_sd,
    c.glucose_cv_pct,
    c.tir_pct,
    c.titr_70_140_pct,
    c.time_above_140_pct,
    c.tar_pct,
    c.tbr_pct

FROM subject_cgm_metrics c
JOIN subject_metabolic_group m
    USING (subject)

WHERE
       c.tbr_pct > 20
    OR c.tar_pct > 10
    OR c.glucose_cv_pct > 36

ORDER BY
    m.diabetes_group,
    c.avg_glucose;
---------------------------------------------------------------------------------------------
--Validate the low-glucose subjects against Dexcom
SELECT
    subject,

    COUNT(libre_gl) AS libre_readings,
    COUNT(dexcom_gl) AS dexcom_readings,

    ROUND(AVG(libre_gl), 2) AS avg_libre,
    ROUND(AVG(dexcom_gl), 2) AS avg_dexcom,

    ROUND(AVG(dexcom_gl) - AVG(libre_gl), 2) AS avg_sensor_difference,

    MIN(libre_gl) AS min_libre,
    MIN(dexcom_gl) AS min_dexcom,

    MAX(libre_gl) AS max_libre,
    MAX(dexcom_gl) AS max_dexcom

FROM cgmacros

WHERE subject IN (15, 32, 27, 17, 2, 34, 48, 7)

GROUP BY subject
ORDER BY subject;

--Paired Libre vs Dexcom comparison  
SELECT
    subject,

    COUNT(*) AS paired_readings,

    ROUND(AVG(libre_gl), 2) AS paired_avg_libre,
    ROUND(AVG(dexcom_gl), 2) AS paired_avg_dexcom,

    ROUND(
        AVG(dexcom_gl - libre_gl),
        2
    ) AS mean_dexcom_minus_libre,

    ROUND(
        AVG(ABS(dexcom_gl - libre_gl)),
        2
    ) AS mean_absolute_difference,

    ROUND(
        CORR(libre_gl, dexcom_gl)::numeric,
        3
    ) AS sensor_correlation

FROM cgmacros

WHERE libre_gl IS NOT NULL
  AND dexcom_gl IS NOT NULL
  AND subject IN (2, 7, 15, 17, 27, 32, 34, 48)

GROUP BY subject
ORDER BY mean_absolute_difference DESC;
	
--Calculating for all 45 subjects
SELECT
    subject,

    COUNT(*) AS paired_readings,

    ROUND(AVG(libre_gl), 2) AS paired_avg_libre,
    ROUND(AVG(dexcom_gl), 2) AS paired_avg_dexcom,

    ROUND(
        AVG(dexcom_gl - libre_gl),
        2
    ) AS mean_dexcom_minus_libre,

    ROUND(
        AVG(ABS(dexcom_gl - libre_gl)),
        2
    ) AS mean_absolute_difference,

    ROUND(
        CORR(libre_gl, dexcom_gl)::numeric,
        3
    ) AS sensor_correlation

FROM cgmacros

WHERE libre_gl IS NOT NULL
  AND dexcom_gl IS NOT NULL

GROUP BY subject
ORDER BY mean_absolute_difference DESC;
----------------------------------------------------------------------------------------------------------------------------------------
--Summarize the sensor difference by diabetes group
--3.Does Libre–Dexcom disagreement differ according to metabolic status?

WITH sensor_metrics AS (
    SELECT
        subject,
        COUNT(*) AS paired_readings,

        AVG(libre_gl) AS avg_libre,
        AVG(dexcom_gl) AS avg_dexcom,

        AVG(dexcom_gl - libre_gl) AS mean_difference,

        AVG(ABS(dexcom_gl - libre_gl)) AS mean_absolute_difference,

        CORR(libre_gl, dexcom_gl) AS sensor_correlation

    FROM cgmacros

    WHERE libre_gl IS NOT NULL
      AND dexcom_gl IS NOT NULL

    GROUP BY subject
)

SELECT
    m.diabetes_group,

    COUNT(*) AS subjects,

    ROUND(AVG(s.avg_libre), 2) AS avg_libre,

    ROUND(AVG(s.avg_dexcom), 2) AS avg_dexcom,

    ROUND(AVG(s.mean_difference), 2)
        AS avg_dexcom_minus_libre,

    ROUND(AVG(s.mean_absolute_difference), 2)
        AS avg_absolute_difference,

    ROUND(AVG(s.sensor_correlation)::numeric, 3)
        AS avg_sensor_correlation

FROM sensor_metrics s

JOIN subject_metabolic_group m
    USING(subject)

GROUP BY m.diabetes_group

ORDER BY
    CASE m.diabetes_group
        WHEN 'Normal' THEN 1
        WHEN 'Pre-diabetes' THEN 2
        WHEN 'Type 2 Diabetes' THEN 3
    END;
----------------------------------------------------------------------------------------------------------------------------------
--4.Does Libre or Dexcom align more strongly with HbA1c and fasting glucose?

WITH subject_sensor_avg AS (
    SELECT
        subject,
        AVG(libre_gl) AS avg_libre,
        AVG(dexcom_gl) AS avg_dexcom
    FROM cgmacros
    GROUP BY subject
)

SELECT
    ROUND(
        CORR(s.avg_libre, b.a1c_pdl_lab)::numeric,
        3
    ) AS libre_vs_hba1c,

    ROUND(
        CORR(s.avg_dexcom, b.a1c_pdl_lab)::numeric,
        3
    ) AS dexcom_vs_hba1c,

    ROUND(
        CORR(s.avg_libre, b.fasting_glu_pdl_lab)::numeric,
        3
    ) AS libre_vs_fasting_glucose,

    ROUND(
        CORR(s.avg_dexcom, b.fasting_glu_pdl_lab)::numeric,
        3
    ) AS dexcom_vs_fasting_glucose

FROM subject_sensor_avg s
JOIN bio b
    USING(subject);
--Libre has a noticeably stronger relationship with fasting glucose
--Although Libre and Dexcom showed substantial absolute differences in some participants, both sensors strongly
--tracked HbA1c. Libre showed the stronger association with fasting glucose and was therefore selected as the primary
--CGM signal for subsequent metabolic and predictive analyses, while Dexcom was retained for sensitivity validation.

--------------------------------------Phenotype Discovery----------------------------------------------------------------------------
--5.Among the 16 participants with Prediabetes, are some metabolically closer to Normal while others already resemble Type 2 Diabetes?
--We switch to Python




