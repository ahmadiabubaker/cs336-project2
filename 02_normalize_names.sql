-- 02_normalize_names.sql
-- Project 2, Step 2: remove every code-to-name dependency from Preliminary.
-- Prerequisite: run 01_load_preliminary.sql in the same database.
--
-- This script is intentionally rerunnable. application_step2 is an intermediate
-- relation consumed and removed by 03_normalize_full.sql. No source *_name column
-- remains in application_step2, and its only text field is respondent_id.

\set ON_ERROR_STOP on

BEGIN;

-- Remove any previous final-stage output before rebuilding the Step 2 state.
DROP TABLE IF EXISTS application_denial_reason CASCADE;
DROP TABLE IF EXISTS co_applicant_race CASCADE;
DROP TABLE IF EXISTS applicant_race CASCADE;
DROP TABLE IF EXISTS application CASCADE;
DROP TABLE IF EXISTS location CASCADE;
DROP TABLE IF EXISTS application_location_step2 CASCADE;
DROP TABLE IF EXISTS application_step2 CASCADE;
DROP TABLE IF EXISTS respondent CASCADE;
DROP TABLE IF EXISTS edit_status CASCADE;
DROP TABLE IF EXISTS denial_reason CASCADE;
DROP TABLE IF EXISTS race CASCADE;
DROP TABLE IF EXISTS sex CASCADE;
DROP TABLE IF EXISTS ethnicity CASCADE;
DROP TABLE IF EXISTS lien_status CASCADE;
DROP TABLE IF EXISTS hoepa_status CASCADE;
DROP TABLE IF EXISTS purchaser_type CASCADE;
DROP TABLE IF EXISTS county CASCADE;
DROP TABLE IF EXISTS state CASCADE;
DROP TABLE IF EXISTS msamd CASCADE;
DROP TABLE IF EXISTS action_taken CASCADE;
DROP TABLE IF EXISTS preapproval CASCADE;
DROP TABLE IF EXISTS owner_occupancy CASCADE;
DROP TABLE IF EXISTS loan_purpose CASCADE;
DROP TABLE IF EXISTS property_type CASCADE;
DROP TABLE IF EXISTS loan_type CASCADE;
DROP TABLE IF EXISTS agency CASCADE;

CREATE TABLE agency (
    agency_code integer PRIMARY KEY,
    agency_name text NOT NULL,
    agency_abbr text NOT NULL
);

CREATE TABLE loan_type (
    loan_type integer PRIMARY KEY,
    loan_type_name text NOT NULL
);

CREATE TABLE property_type (
    property_type integer PRIMARY KEY,
    property_type_name text NOT NULL
);

CREATE TABLE loan_purpose (
    loan_purpose integer PRIMARY KEY,
    loan_purpose_name text NOT NULL
);

CREATE TABLE owner_occupancy (
    owner_occupancy integer PRIMARY KEY,
    owner_occupancy_name text NOT NULL
);

CREATE TABLE preapproval (
    preapproval integer PRIMARY KEY,
    preapproval_name text NOT NULL
);

CREATE TABLE action_taken (
    action_taken integer PRIMARY KEY,
    action_taken_name text NOT NULL
);

CREATE TABLE msamd (
    msamd integer PRIMARY KEY,
    msamd_name text
);

CREATE TABLE state (
    state_code integer PRIMARY KEY,
    state_name text NOT NULL,
    state_abbr text NOT NULL
);

CREATE TABLE county (
    state_code integer NOT NULL REFERENCES state(state_code),
    county_code integer NOT NULL,
    county_name text NOT NULL,
    PRIMARY KEY (state_code, county_code)
);

CREATE TABLE ethnicity (
    ethnicity_code integer PRIMARY KEY,
    ethnicity_name text NOT NULL
);

CREATE TABLE race (
    race_code integer PRIMARY KEY,
    race_name text NOT NULL
);

CREATE TABLE sex (
    sex_code integer PRIMARY KEY,
    sex_name text NOT NULL
);

CREATE TABLE purchaser_type (
    purchaser_type integer PRIMARY KEY,
    purchaser_type_name text NOT NULL
);

CREATE TABLE denial_reason (
    denial_reason_code integer PRIMARY KEY,
    denial_reason_name text NOT NULL
);

CREATE TABLE hoepa_status (
    hoepa_status integer PRIMARY KEY,
    hoepa_status_name text NOT NULL
);

CREATE TABLE lien_status (
    lien_status integer PRIMARY KEY,
    lien_status_name text NOT NULL
);

-- This table is empty for the current CSV because both source columns are NULL in
-- every row. Keeping the typed domain preserves the Project 1 column design without
-- inventing a singleton key. A future non-NULL edit status has one code/name row.
CREATE TABLE edit_status (
    edit_status integer PRIMARY KEY,
    edit_status_name text
);

INSERT INTO agency
SELECT DISTINCT agency_code, agency_name, agency_abbr
FROM Preliminary;

INSERT INTO loan_type
SELECT DISTINCT loan_type, loan_type_name
FROM Preliminary;

INSERT INTO property_type
SELECT DISTINCT property_type, property_type_name
FROM Preliminary;

INSERT INTO loan_purpose
SELECT DISTINCT loan_purpose, loan_purpose_name
FROM Preliminary;

INSERT INTO owner_occupancy
SELECT DISTINCT owner_occupancy, owner_occupancy_name
FROM Preliminary;

INSERT INTO preapproval
SELECT DISTINCT preapproval, preapproval_name
FROM Preliminary;

INSERT INTO action_taken
SELECT DISTINCT action_taken, action_taken_name
FROM Preliminary;

INSERT INTO msamd
SELECT DISTINCT msamd, msamd_name
FROM Preliminary
WHERE msamd IS NOT NULL;

INSERT INTO state
SELECT DISTINCT state_code, state_name, state_abbr
FROM Preliminary;

INSERT INTO county
SELECT DISTINCT state_code, county_code, county_name
FROM Preliminary
WHERE county_code IS NOT NULL;

INSERT INTO ethnicity
SELECT DISTINCT ethnicity_code, ethnicity_name
FROM (
    SELECT applicant_ethnicity AS ethnicity_code,
           applicant_ethnicity_name AS ethnicity_name
    FROM Preliminary
    UNION ALL
    SELECT co_applicant_ethnicity, co_applicant_ethnicity_name
    FROM Preliminary
) AS ethnicity_values;

INSERT INTO race
SELECT DISTINCT race_code, race_name
FROM (
    SELECT applicant_race_1 AS race_code, applicant_race_name_1 AS race_name FROM Preliminary
    UNION ALL SELECT applicant_race_2, applicant_race_name_2 FROM Preliminary
    UNION ALL SELECT applicant_race_3, applicant_race_name_3 FROM Preliminary
    UNION ALL SELECT applicant_race_4, applicant_race_name_4 FROM Preliminary
    UNION ALL SELECT applicant_race_5, applicant_race_name_5 FROM Preliminary
    UNION ALL SELECT co_applicant_race_1, co_applicant_race_name_1 FROM Preliminary
    UNION ALL SELECT co_applicant_race_2, co_applicant_race_name_2 FROM Preliminary
    UNION ALL SELECT co_applicant_race_3, co_applicant_race_name_3 FROM Preliminary
    UNION ALL SELECT co_applicant_race_4, co_applicant_race_name_4 FROM Preliminary
    UNION ALL SELECT co_applicant_race_5, co_applicant_race_name_5 FROM Preliminary
) AS race_values
WHERE race_code IS NOT NULL;

INSERT INTO sex
SELECT DISTINCT sex_code, sex_name
FROM (
    SELECT applicant_sex AS sex_code, applicant_sex_name AS sex_name
    FROM Preliminary
    UNION ALL
    SELECT co_applicant_sex, co_applicant_sex_name
    FROM Preliminary
) AS sex_values;

INSERT INTO purchaser_type
SELECT DISTINCT purchaser_type, purchaser_type_name
FROM Preliminary;

INSERT INTO denial_reason
SELECT DISTINCT denial_reason_code, denial_reason_name
FROM (
    SELECT denial_reason_1 AS denial_reason_code,
           denial_reason_name_1 AS denial_reason_name
    FROM Preliminary
    UNION ALL SELECT denial_reason_2, denial_reason_name_2 FROM Preliminary
    UNION ALL SELECT denial_reason_3, denial_reason_name_3 FROM Preliminary
) AS denial_values
WHERE denial_reason_code IS NOT NULL;

INSERT INTO hoepa_status
SELECT DISTINCT hoepa_status, hoepa_status_name
FROM Preliminary;

INSERT INTO lien_status
SELECT DISTINCT lien_status, lien_status_name
FROM Preliminary;

INSERT INTO edit_status
SELECT DISTINCT edit_status, edit_status_name
FROM Preliminary
WHERE edit_status IS NOT NULL;

-- respondent_id alone is not a key: two IDs occur under both agencies 1 and 3.
CREATE TABLE respondent (
    agency_code integer NOT NULL REFERENCES agency(agency_code),
    respondent_id text NOT NULL,
    PRIMARY KEY (agency_code, respondent_id)
);

INSERT INTO respondent
SELECT DISTINCT agency_code, respondent_id
FROM Preliminary;

CREATE TABLE application_step2 (
    application_id integer PRIMARY KEY,
    as_of_year integer NOT NULL,
    agency_code integer NOT NULL,
    respondent_id text NOT NULL,
    loan_type integer NOT NULL REFERENCES loan_type(loan_type),
    property_type integer NOT NULL REFERENCES property_type(property_type),
    loan_purpose integer NOT NULL REFERENCES loan_purpose(loan_purpose),
    owner_occupancy integer NOT NULL REFERENCES owner_occupancy(owner_occupancy),
    loan_amount_000s integer,
    preapproval integer NOT NULL REFERENCES preapproval(preapproval),
    action_taken integer NOT NULL REFERENCES action_taken(action_taken),
    applicant_ethnicity integer NOT NULL REFERENCES ethnicity(ethnicity_code),
    co_applicant_ethnicity integer NOT NULL REFERENCES ethnicity(ethnicity_code),
    applicant_race_1 integer NOT NULL REFERENCES race(race_code),
    applicant_race_2 integer REFERENCES race(race_code),
    applicant_race_3 integer REFERENCES race(race_code),
    applicant_race_4 integer REFERENCES race(race_code),
    applicant_race_5 integer REFERENCES race(race_code),
    co_applicant_race_1 integer NOT NULL REFERENCES race(race_code),
    co_applicant_race_2 integer REFERENCES race(race_code),
    co_applicant_race_3 integer REFERENCES race(race_code),
    co_applicant_race_4 integer REFERENCES race(race_code),
    co_applicant_race_5 integer REFERENCES race(race_code),
    applicant_sex integer NOT NULL REFERENCES sex(sex_code),
    co_applicant_sex integer NOT NULL REFERENCES sex(sex_code),
    applicant_income_000s integer,
    purchaser_type integer NOT NULL REFERENCES purchaser_type(purchaser_type),
    denial_reason_1 integer REFERENCES denial_reason(denial_reason_code),
    denial_reason_2 integer REFERENCES denial_reason(denial_reason_code),
    denial_reason_3 integer REFERENCES denial_reason(denial_reason_code),
    rate_spread numeric,
    hoepa_status integer NOT NULL REFERENCES hoepa_status(hoepa_status),
    lien_status integer NOT NULL REFERENCES lien_status(lien_status),
    edit_status integer REFERENCES edit_status(edit_status),
    application_date_indicator integer,
    FOREIGN KEY (agency_code, respondent_id)
        REFERENCES respondent(agency_code, respondent_id)
);

INSERT INTO application_step2 (
    application_id, as_of_year, agency_code, respondent_id, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, applicant_ethnicity, co_applicant_ethnicity,
    applicant_race_1, applicant_race_2, applicant_race_3, applicant_race_4,
    applicant_race_5, co_applicant_race_1, co_applicant_race_2,
    co_applicant_race_3, co_applicant_race_4, co_applicant_race_5,
    applicant_sex, co_applicant_sex, applicant_income_000s, purchaser_type,
    denial_reason_1, denial_reason_2, denial_reason_3, rate_spread,
    hoepa_status, lien_status, edit_status, application_date_indicator
)
SELECT
    sequence_number, as_of_year, agency_code, respondent_id, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, applicant_ethnicity, co_applicant_ethnicity,
    applicant_race_1, applicant_race_2, applicant_race_3, applicant_race_4,
    applicant_race_5, co_applicant_race_1, co_applicant_race_2,
    co_applicant_race_3, co_applicant_race_4, co_applicant_race_5,
    applicant_sex, co_applicant_sex, applicant_income_000s, purchaser_type,
    denial_reason_1, denial_reason_2, denial_reason_3, rate_spread,
    hoepa_status, lien_status, edit_status, application_date_indicator
FROM Preliminary;

-- The location attributes are kept outside the main application relation so its
-- only text field is respondent_id. Step 3 replaces this one-to-one intermediate
-- table with a deduplicated location table and location_id.
CREATE TABLE application_location_step2 (
    application_id integer PRIMARY KEY
        REFERENCES application_step2(application_id) ON DELETE CASCADE,
    county_code integer,
    msamd integer REFERENCES msamd(msamd),
    state_code integer NOT NULL REFERENCES state(state_code),
    census_tract_number text,
    population integer,
    minority_population numeric,
    hud_median_family_income integer,
    tract_to_msamd_income numeric,
    number_of_owner_occupied_units integer,
    number_of_1_to_4_family_units integer,
    FOREIGN KEY (state_code, county_code)
        REFERENCES county(state_code, county_code)
);

INSERT INTO application_location_step2
SELECT
    sequence_number, county_code, msamd, state_code, census_tract_number,
    population, minority_population, hud_median_family_income,
    tract_to_msamd_income, number_of_owner_occupied_units,
    number_of_1_to_4_family_units
FROM Preliminary;

DO $$
DECLARE
    preliminary_rows bigint;
    application_rows bigint;
    location_rows bigint;
BEGIN
    SELECT count(*) INTO preliminary_rows FROM Preliminary;
    SELECT count(*) INTO application_rows FROM application_step2;
    SELECT count(*) INTO location_rows FROM application_location_step2;

    IF preliminary_rows <> 349563
       OR application_rows <> preliminary_rows
       OR location_rows <> preliminary_rows THEN
        RAISE EXCEPTION
            'Step 2 transfer mismatch: Preliminary %, application_step2 %, location %',
            preliminary_rows, application_rows, location_rows;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'application_step2'
          AND column_name LIKE '%name%'
    ) THEN
        RAISE EXCEPTION 'A name column remains in application_step2';
    END IF;
END
$$;

COMMIT;

SELECT 'agency' AS table_name, count(*) AS row_count FROM agency
UNION ALL SELECT 'respondent', count(*) FROM respondent
UNION ALL SELECT 'application_step2', count(*) FROM application_step2
UNION ALL SELECT 'application_location_step2', count(*) FROM application_location_step2
ORDER BY table_name;
