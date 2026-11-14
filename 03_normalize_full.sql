-- 03_normalize_full.sql
-- Project 2, Step 3: finish the 1NF/BCNF transformation.
-- Prerequisite: run 02_normalize_names.sql in the same database.
--
-- The final application table contains no numbered race/denial columns and only
-- location_id for location information. This script does not read Preliminary.

\set ON_ERROR_STOP on

BEGIN;

DROP TABLE IF EXISTS application_denial_reason CASCADE;
DROP TABLE IF EXISTS co_applicant_race CASCADE;
DROP TABLE IF EXISTS applicant_race CASCADE;
DROP TABLE IF EXISTS application CASCADE;
DROP TABLE IF EXISTS location CASCADE;

-- Preserve the source-row-to-location relationship while assigning one integer to
-- each NULL-safe ten-column location combination. Window grouping treats equal
-- NULL-bearing combinations as the same ordered peer group.
CREATE TEMP TABLE application_location_map ON COMMIT DROP AS
SELECT
    application_id,
    DENSE_RANK() OVER (
        ORDER BY
            county_code NULLS FIRST,
            msamd NULLS FIRST,
            state_code NULLS FIRST,
            census_tract_number NULLS FIRST,
            population NULLS FIRST,
            minority_population NULLS FIRST,
            hud_median_family_income NULLS FIRST,
            tract_to_msamd_income NULLS FIRST,
            number_of_owner_occupied_units NULLS FIRST,
            number_of_1_to_4_family_units NULLS FIRST
    )::integer AS location_id
FROM application_location_step2;

ALTER TABLE application_location_map ADD PRIMARY KEY (application_id);
CREATE INDEX application_location_map_location_idx
    ON application_location_map(location_id);

CREATE TABLE location (
    location_id integer PRIMARY KEY,
    county_code integer CHECK (county_code IS NULL OR county_code >= 0),
    msamd integer REFERENCES msamd(msamd)
        CHECK (msamd IS NULL OR msamd >= 0),
    state_code integer NOT NULL REFERENCES state(state_code)
        CHECK (state_code >= 0),
    census_tract_number text
        CHECK (census_tract_number IS NULL OR census_tract_number <> '<NULL>'),
    population integer CHECK (population IS NULL OR population >= 0),
    minority_population numeric
        CHECK (minority_population IS NULL OR minority_population >= 0),
    hud_median_family_income integer
        CHECK (hud_median_family_income IS NULL OR hud_median_family_income >= 0),
    tract_to_msamd_income numeric
        CHECK (tract_to_msamd_income IS NULL OR tract_to_msamd_income >= 0),
    number_of_owner_occupied_units integer
        CHECK (number_of_owner_occupied_units IS NULL
               OR number_of_owner_occupied_units >= 0),
    number_of_1_to_4_family_units integer
        CHECK (number_of_1_to_4_family_units IS NULL
               OR number_of_1_to_4_family_units >= 0),
    FOREIGN KEY (state_code, county_code)
        REFERENCES county(state_code, county_code)
);

-- Version-independent NULLS-NOT-DISTINCT enforcement for the handout's ten-column
-- alternate key. Sentinels are outside the legal domains enforced above and are
-- index expressions, not additional logical columns.
CREATE UNIQUE INDEX location_ten_column_key
ON location (
    COALESCE(county_code, -1),
    COALESCE(msamd, -1),
    state_code,
    COALESCE(census_tract_number, '<NULL>'),
    COALESCE(population, -1),
    COALESCE(minority_population, -1::numeric),
    COALESCE(hud_median_family_income, -1),
    COALESCE(tract_to_msamd_income, -1::numeric),
    COALESCE(number_of_owner_occupied_units, -1),
    COALESCE(number_of_1_to_4_family_units, -1)
);

INSERT INTO location (
    location_id, county_code, msamd, state_code, census_tract_number,
    population, minority_population, hud_median_family_income,
    tract_to_msamd_income, number_of_owner_occupied_units,
    number_of_1_to_4_family_units
)
SELECT DISTINCT
    map.location_id, source.county_code, source.msamd, source.state_code,
    source.census_tract_number, source.population, source.minority_population,
    source.hud_median_family_income, source.tract_to_msamd_income,
    source.number_of_owner_occupied_units,
    source.number_of_1_to_4_family_units
FROM application_location_map AS map
JOIN application_location_step2 AS source USING (application_id);

CREATE TABLE application (
    application_id integer PRIMARY KEY,
    as_of_year integer NOT NULL,
    agency_code integer NOT NULL,
    respondent_id text NOT NULL,
    loan_type integer NOT NULL REFERENCES loan_type(loan_type),
    property_type integer NOT NULL REFERENCES property_type(property_type),
    loan_purpose integer NOT NULL REFERENCES loan_purpose(loan_purpose),
    owner_occupancy integer NOT NULL REFERENCES owner_occupancy(owner_occupancy),
    loan_amount_000s integer
        CHECK (loan_amount_000s IS NULL OR loan_amount_000s >= 0),
    preapproval integer NOT NULL REFERENCES preapproval(preapproval),
    action_taken integer NOT NULL REFERENCES action_taken(action_taken),
    location_id integer NOT NULL REFERENCES location(location_id),
    applicant_ethnicity integer NOT NULL REFERENCES ethnicity(ethnicity_code),
    co_applicant_ethnicity integer NOT NULL REFERENCES ethnicity(ethnicity_code),
    applicant_sex integer NOT NULL REFERENCES sex(sex_code),
    co_applicant_sex integer NOT NULL REFERENCES sex(sex_code),
    applicant_income_000s integer,
    purchaser_type integer NOT NULL REFERENCES purchaser_type(purchaser_type),
    rate_spread numeric,
    hoepa_status integer NOT NULL REFERENCES hoepa_status(hoepa_status),
    lien_status integer NOT NULL REFERENCES lien_status(lien_status),
    edit_status integer REFERENCES edit_status(edit_status),
    application_date_indicator integer,
    FOREIGN KEY (agency_code, respondent_id)
        REFERENCES respondent(agency_code, respondent_id)
);

INSERT INTO application (
    application_id, as_of_year, agency_code, respondent_id, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status, edit_status, application_date_indicator
)
SELECT
    source.application_id, source.as_of_year, source.agency_code,
    source.respondent_id, source.loan_type, source.property_type,
    source.loan_purpose, source.owner_occupancy, source.loan_amount_000s,
    source.preapproval, source.action_taken, map.location_id,
    source.applicant_ethnicity, source.co_applicant_ethnicity,
    source.applicant_sex, source.co_applicant_sex,
    source.applicant_income_000s, source.purchaser_type,
    source.rate_spread, source.hoepa_status, source.lien_status,
    source.edit_status, source.application_date_indicator
FROM application_step2 AS source
JOIN application_location_map AS map USING (application_id);

CREATE INDEX application_location_idx ON application(location_id);
CREATE INDEX application_respondent_idx
    ON application(agency_code, respondent_id);

CREATE TABLE applicant_race (
    application_id integer NOT NULL
        REFERENCES application(application_id) ON DELETE CASCADE,
    race_number smallint NOT NULL CHECK (race_number BETWEEN 1 AND 5),
    race_code integer NOT NULL REFERENCES race(race_code),
    PRIMARY KEY (application_id, race_number)
);

INSERT INTO applicant_race (application_id, race_number, race_code)
SELECT source.application_id, value.race_number, value.race_code
FROM application_step2 AS source
CROSS JOIN LATERAL (
    VALUES
        (1::smallint, source.applicant_race_1),
        (2::smallint, source.applicant_race_2),
        (3::smallint, source.applicant_race_3),
        (4::smallint, source.applicant_race_4),
        (5::smallint, source.applicant_race_5)
) AS value(race_number, race_code)
WHERE value.race_code IS NOT NULL;

CREATE TABLE co_applicant_race (
    application_id integer NOT NULL
        REFERENCES application(application_id) ON DELETE CASCADE,
    race_number smallint NOT NULL CHECK (race_number BETWEEN 1 AND 5),
    race_code integer NOT NULL REFERENCES race(race_code),
    PRIMARY KEY (application_id, race_number)
);

INSERT INTO co_applicant_race (application_id, race_number, race_code)
SELECT source.application_id, value.race_number, value.race_code
FROM application_step2 AS source
CROSS JOIN LATERAL (
    VALUES
        (1::smallint, source.co_applicant_race_1),
        (2::smallint, source.co_applicant_race_2),
        (3::smallint, source.co_applicant_race_3),
        (4::smallint, source.co_applicant_race_4),
        (5::smallint, source.co_applicant_race_5)
) AS value(race_number, race_code)
WHERE value.race_code IS NOT NULL;

CREATE TABLE application_denial_reason (
    application_id integer NOT NULL
        REFERENCES application(application_id) ON DELETE CASCADE,
    reason_number smallint NOT NULL CHECK (reason_number BETWEEN 1 AND 3),
    denial_reason_code integer NOT NULL
        REFERENCES denial_reason(denial_reason_code),
    PRIMARY KEY (application_id, reason_number)
);

INSERT INTO application_denial_reason (
    application_id, reason_number, denial_reason_code
)
SELECT source.application_id, value.reason_number, value.denial_reason_code
FROM application_step2 AS source
CROSS JOIN LATERAL (
    VALUES
        (1::smallint, source.denial_reason_1),
        (2::smallint, source.denial_reason_2),
        (3::smallint, source.denial_reason_3)
) AS value(reason_number, denial_reason_code)
WHERE value.denial_reason_code IS NOT NULL;

DO $$
DECLARE
    expected_applicant_races bigint;
    expected_co_applicant_races bigint;
    expected_denial_reasons bigint;
BEGIN
    IF (SELECT count(*) FROM application) <> 349563 THEN
        RAISE EXCEPTION 'Expected 349563 applications, found %',
            (SELECT count(*) FROM application);
    END IF;

    IF (SELECT count(*) FROM location) <> 2135 THEN
        RAISE EXCEPTION 'Expected 2135 locations, found %',
            (SELECT count(*) FROM location);
    END IF;

    SELECT
        count(applicant_race_1) + count(applicant_race_2)
        + count(applicant_race_3) + count(applicant_race_4)
        + count(applicant_race_5)
    INTO expected_applicant_races
    FROM application_step2;

    SELECT
        count(co_applicant_race_1) + count(co_applicant_race_2)
        + count(co_applicant_race_3) + count(co_applicant_race_4)
        + count(co_applicant_race_5)
    INTO expected_co_applicant_races
    FROM application_step2;

    SELECT
        count(denial_reason_1) + count(denial_reason_2)
        + count(denial_reason_3)
    INTO expected_denial_reasons
    FROM application_step2;

    IF (SELECT count(*) FROM applicant_race) <> expected_applicant_races THEN
        RAISE EXCEPTION 'Applicant-race transfer count mismatch';
    END IF;
    IF (SELECT count(*) FROM co_applicant_race) <> expected_co_applicant_races THEN
        RAISE EXCEPTION 'Co-applicant-race transfer count mismatch';
    END IF;
    IF (SELECT count(*) FROM application_denial_reason)
       <> expected_denial_reasons THEN
        RAISE EXCEPTION 'Denial-reason transfer count mismatch';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'application'
          AND (column_name LIKE '%name%'
               OR column_name ~ '_(race|reason)_[1-5]$')
    ) THEN
        RAISE EXCEPTION 'A forbidden name or numbered repeating column remains';
    END IF;
END
$$;

DROP TABLE application_location_step2;
DROP TABLE application_step2;

COMMIT;

SELECT 'application' AS table_name, count(*) AS row_count FROM application
UNION ALL SELECT 'location', count(*) FROM location
UNION ALL SELECT 'applicant_race', count(*) FROM applicant_race
UNION ALL SELECT 'co_applicant_race', count(*) FROM co_applicant_race
UNION ALL SELECT 'application_denial_reason', count(*) FROM application_denial_reason
ORDER BY table_name;
