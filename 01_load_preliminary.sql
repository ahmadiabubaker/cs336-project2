-- load_preliminary.sql
-- Written with the help of Claude (Anthropic), an AI assistant (AI use is
-- permitted for this assignment); reviewed, run, and verified by our team on iLab.
-- Creates the table Preliminary and loads the 2017 New Jersey HMDA CSV into it.
-- Run from psql in the folder that contains the CSV:   \i load_preliminary.sql
--
-- Approach: every column is first created as TEXT so the CSV loads with no
-- parsing errors; then each column is cast to its correct type.
-- An extra SERIAL column (load_order) numbers the rows in the order they appear
-- in the file; its values are moved into sequence_number, which becomes the
-- primary key (column name unchanged), and load_order is dropped.
--
-- References (PostgreSQL official documentation):
--   COPY:        https://www.postgresql.org/docs/current/sql-copy.html
--   psql \copy:  https://www.postgresql.org/docs/current/app-psql.html
--   ALTER TABLE: https://www.postgresql.org/docs/current/sql-altertable.html
--   Sequences:   https://www.postgresql.org/docs/current/sql-createsequence.html

\set ON_ERROR_STOP on

DROP TABLE IF EXISTS Preliminary CASCADE;

-- Step 1: staging layout, everything as text, plus a row counter.
CREATE TABLE Preliminary (
    as_of_year text,
    respondent_id text,
    agency_name text,
    agency_abbr text,
    agency_code text,
    loan_type_name text,
    loan_type text,
    property_type_name text,
    property_type text,
    loan_purpose_name text,
    loan_purpose text,
    owner_occupancy_name text,
    owner_occupancy text,
    loan_amount_000s text,
    preapproval_name text,
    preapproval text,
    action_taken_name text,
    action_taken text,
    msamd_name text,
    msamd text,
    state_name text,
    state_abbr text,
    state_code text,
    county_name text,
    county_code text,
    census_tract_number text,
    applicant_ethnicity_name text,
    applicant_ethnicity text,
    co_applicant_ethnicity_name text,
    co_applicant_ethnicity text,
    applicant_race_name_1 text,
    applicant_race_1 text,
    applicant_race_name_2 text,
    applicant_race_2 text,
    applicant_race_name_3 text,
    applicant_race_3 text,
    applicant_race_name_4 text,
    applicant_race_4 text,
    applicant_race_name_5 text,
    applicant_race_5 text,
    co_applicant_race_name_1 text,
    co_applicant_race_1 text,
    co_applicant_race_name_2 text,
    co_applicant_race_2 text,
    co_applicant_race_name_3 text,
    co_applicant_race_3 text,
    co_applicant_race_name_4 text,
    co_applicant_race_4 text,
    co_applicant_race_name_5 text,
    co_applicant_race_5 text,
    applicant_sex_name text,
    applicant_sex text,
    co_applicant_sex_name text,
    co_applicant_sex text,
    applicant_income_000s text,
    purchaser_type_name text,
    purchaser_type text,
    denial_reason_name_1 text,
    denial_reason_1 text,
    denial_reason_name_2 text,
    denial_reason_2 text,
    denial_reason_name_3 text,
    denial_reason_3 text,
    rate_spread text,
    hoepa_status_name text,
    hoepa_status text,
    lien_status_name text,
    lien_status text,
    edit_status_name text,
    edit_status text,
    sequence_number text,
    population text,
    minority_population text,
    hud_median_family_income text,
    tract_to_msamd_income text,
    number_of_owner_occupied_units text,
    number_of_1_to_4_family_units text,
    application_date_indicator text,
    load_order serial
);

-- Step 2: load the CSV (\copy reads the file from the client side, so no superuser needed).
-- load_order is not listed, so it is filled from its sequence, row by row in file order.
\copy Preliminary (as_of_year, respondent_id, agency_name, agency_abbr, agency_code, loan_type_name, loan_type, property_type_name, property_type, loan_purpose_name, loan_purpose, owner_occupancy_name, owner_occupancy, loan_amount_000s, preapproval_name, preapproval, action_taken_name, action_taken, msamd_name, msamd, state_name, state_abbr, state_code, county_name, county_code, census_tract_number, applicant_ethnicity_name, applicant_ethnicity, co_applicant_ethnicity_name, co_applicant_ethnicity, applicant_race_name_1, applicant_race_1, applicant_race_name_2, applicant_race_2, applicant_race_name_3, applicant_race_3, applicant_race_name_4, applicant_race_4, applicant_race_name_5, applicant_race_5, co_applicant_race_name_1, co_applicant_race_1, co_applicant_race_name_2, co_applicant_race_2, co_applicant_race_name_3, co_applicant_race_3, co_applicant_race_name_4, co_applicant_race_4, co_applicant_race_name_5, co_applicant_race_5, applicant_sex_name, applicant_sex, co_applicant_sex_name, co_applicant_sex, applicant_income_000s, purchaser_type_name, purchaser_type, denial_reason_name_1, denial_reason_1, denial_reason_name_2, denial_reason_2, denial_reason_name_3, denial_reason_3, rate_spread, hoepa_status_name, hoepa_status, lien_status_name, lien_status, edit_status_name, edit_status, sequence_number, population, minority_population, hud_median_family_income, tract_to_msamd_income, number_of_owner_occupied_units, number_of_1_to_4_family_units, application_date_indicator) FROM 'hmda_2017_nj_all-records_labels.csv' WITH (FORMAT csv, HEADER true)

-- Step 3: cast every column to its correct type.
--   * empty strings become NULL (missing value)
--   * integer: codes, counts, amounts in thousands, year
--   * numeric: decimal values; numeric (not float) keeps every digit exactly,
--              e.g. 27.829999923706055 and 100.0, so no precision is lost
--   * text: English labels, plus identifiers with leading zeros / dashes
--           (respondent_id like '0000177957' or '62-1532940',
--            census_tract_number like '0218.04')
--   * sequence_number takes the file row number from load_order
ALTER TABLE Preliminary
    ALTER COLUMN as_of_year TYPE integer USING NULLIF(as_of_year, '')::integer,
    ALTER COLUMN respondent_id TYPE text USING NULLIF(respondent_id, '')::text,
    ALTER COLUMN agency_name TYPE text USING NULLIF(agency_name, '')::text,
    ALTER COLUMN agency_abbr TYPE text USING NULLIF(agency_abbr, '')::text,
    ALTER COLUMN agency_code TYPE integer USING NULLIF(agency_code, '')::integer,
    ALTER COLUMN loan_type_name TYPE text USING NULLIF(loan_type_name, '')::text,
    ALTER COLUMN loan_type TYPE integer USING NULLIF(loan_type, '')::integer,
    ALTER COLUMN property_type_name TYPE text USING NULLIF(property_type_name, '')::text,
    ALTER COLUMN property_type TYPE integer USING NULLIF(property_type, '')::integer,
    ALTER COLUMN loan_purpose_name TYPE text USING NULLIF(loan_purpose_name, '')::text,
    ALTER COLUMN loan_purpose TYPE integer USING NULLIF(loan_purpose, '')::integer,
    ALTER COLUMN owner_occupancy_name TYPE text USING NULLIF(owner_occupancy_name, '')::text,
    ALTER COLUMN owner_occupancy TYPE integer USING NULLIF(owner_occupancy, '')::integer,
    ALTER COLUMN loan_amount_000s TYPE integer USING NULLIF(loan_amount_000s, '')::integer,
    ALTER COLUMN preapproval_name TYPE text USING NULLIF(preapproval_name, '')::text,
    ALTER COLUMN preapproval TYPE integer USING NULLIF(preapproval, '')::integer,
    ALTER COLUMN action_taken_name TYPE text USING NULLIF(action_taken_name, '')::text,
    ALTER COLUMN action_taken TYPE integer USING NULLIF(action_taken, '')::integer,
    ALTER COLUMN msamd_name TYPE text USING NULLIF(msamd_name, '')::text,
    ALTER COLUMN msamd TYPE integer USING NULLIF(msamd, '')::integer,
    ALTER COLUMN state_name TYPE text USING NULLIF(state_name, '')::text,
    ALTER COLUMN state_abbr TYPE text USING NULLIF(state_abbr, '')::text,
    ALTER COLUMN state_code TYPE integer USING NULLIF(state_code, '')::integer,
    ALTER COLUMN county_name TYPE text USING NULLIF(county_name, '')::text,
    ALTER COLUMN county_code TYPE integer USING NULLIF(county_code, '')::integer,
    ALTER COLUMN census_tract_number TYPE text USING NULLIF(census_tract_number, '')::text,
    ALTER COLUMN applicant_ethnicity_name TYPE text USING NULLIF(applicant_ethnicity_name, '')::text,
    ALTER COLUMN applicant_ethnicity TYPE integer USING NULLIF(applicant_ethnicity, '')::integer,
    ALTER COLUMN co_applicant_ethnicity_name TYPE text USING NULLIF(co_applicant_ethnicity_name, '')::text,
    ALTER COLUMN co_applicant_ethnicity TYPE integer USING NULLIF(co_applicant_ethnicity, '')::integer,
    ALTER COLUMN applicant_race_name_1 TYPE text USING NULLIF(applicant_race_name_1, '')::text,
    ALTER COLUMN applicant_race_1 TYPE integer USING NULLIF(applicant_race_1, '')::integer,
    ALTER COLUMN applicant_race_name_2 TYPE text USING NULLIF(applicant_race_name_2, '')::text,
    ALTER COLUMN applicant_race_2 TYPE integer USING NULLIF(applicant_race_2, '')::integer,
    ALTER COLUMN applicant_race_name_3 TYPE text USING NULLIF(applicant_race_name_3, '')::text,
    ALTER COLUMN applicant_race_3 TYPE integer USING NULLIF(applicant_race_3, '')::integer,
    ALTER COLUMN applicant_race_name_4 TYPE text USING NULLIF(applicant_race_name_4, '')::text,
    ALTER COLUMN applicant_race_4 TYPE integer USING NULLIF(applicant_race_4, '')::integer,
    ALTER COLUMN applicant_race_name_5 TYPE text USING NULLIF(applicant_race_name_5, '')::text,
    ALTER COLUMN applicant_race_5 TYPE integer USING NULLIF(applicant_race_5, '')::integer,
    ALTER COLUMN co_applicant_race_name_1 TYPE text USING NULLIF(co_applicant_race_name_1, '')::text,
    ALTER COLUMN co_applicant_race_1 TYPE integer USING NULLIF(co_applicant_race_1, '')::integer,
    ALTER COLUMN co_applicant_race_name_2 TYPE text USING NULLIF(co_applicant_race_name_2, '')::text,
    ALTER COLUMN co_applicant_race_2 TYPE integer USING NULLIF(co_applicant_race_2, '')::integer,
    ALTER COLUMN co_applicant_race_name_3 TYPE text USING NULLIF(co_applicant_race_name_3, '')::text,
    ALTER COLUMN co_applicant_race_3 TYPE integer USING NULLIF(co_applicant_race_3, '')::integer,
    ALTER COLUMN co_applicant_race_name_4 TYPE text USING NULLIF(co_applicant_race_name_4, '')::text,
    ALTER COLUMN co_applicant_race_4 TYPE integer USING NULLIF(co_applicant_race_4, '')::integer,
    ALTER COLUMN co_applicant_race_name_5 TYPE text USING NULLIF(co_applicant_race_name_5, '')::text,
    ALTER COLUMN co_applicant_race_5 TYPE integer USING NULLIF(co_applicant_race_5, '')::integer,
    ALTER COLUMN applicant_sex_name TYPE text USING NULLIF(applicant_sex_name, '')::text,
    ALTER COLUMN applicant_sex TYPE integer USING NULLIF(applicant_sex, '')::integer,
    ALTER COLUMN co_applicant_sex_name TYPE text USING NULLIF(co_applicant_sex_name, '')::text,
    ALTER COLUMN co_applicant_sex TYPE integer USING NULLIF(co_applicant_sex, '')::integer,
    ALTER COLUMN applicant_income_000s TYPE integer USING NULLIF(applicant_income_000s, '')::integer,
    ALTER COLUMN purchaser_type_name TYPE text USING NULLIF(purchaser_type_name, '')::text,
    ALTER COLUMN purchaser_type TYPE integer USING NULLIF(purchaser_type, '')::integer,
    ALTER COLUMN denial_reason_name_1 TYPE text USING NULLIF(denial_reason_name_1, '')::text,
    ALTER COLUMN denial_reason_1 TYPE integer USING NULLIF(denial_reason_1, '')::integer,
    ALTER COLUMN denial_reason_name_2 TYPE text USING NULLIF(denial_reason_name_2, '')::text,
    ALTER COLUMN denial_reason_2 TYPE integer USING NULLIF(denial_reason_2, '')::integer,
    ALTER COLUMN denial_reason_name_3 TYPE text USING NULLIF(denial_reason_name_3, '')::text,
    ALTER COLUMN denial_reason_3 TYPE integer USING NULLIF(denial_reason_3, '')::integer,
    ALTER COLUMN rate_spread TYPE numeric USING NULLIF(rate_spread, '')::numeric,
    ALTER COLUMN hoepa_status_name TYPE text USING NULLIF(hoepa_status_name, '')::text,
    ALTER COLUMN hoepa_status TYPE integer USING NULLIF(hoepa_status, '')::integer,
    ALTER COLUMN lien_status_name TYPE text USING NULLIF(lien_status_name, '')::text,
    ALTER COLUMN lien_status TYPE integer USING NULLIF(lien_status, '')::integer,
    ALTER COLUMN edit_status_name TYPE text USING NULLIF(edit_status_name, '')::text,
    ALTER COLUMN edit_status TYPE integer USING NULLIF(edit_status, '')::integer,
    ALTER COLUMN sequence_number TYPE integer USING load_order,
    ALTER COLUMN population TYPE integer USING NULLIF(population, '')::integer,
    ALTER COLUMN minority_population TYPE numeric USING NULLIF(minority_population, '')::numeric,
    ALTER COLUMN hud_median_family_income TYPE integer USING NULLIF(hud_median_family_income, '')::integer,
    ALTER COLUMN tract_to_msamd_income TYPE numeric USING NULLIF(tract_to_msamd_income, '')::numeric,
    ALTER COLUMN number_of_owner_occupied_units TYPE integer USING NULLIF(number_of_owner_occupied_units, '')::integer,
    ALTER COLUMN number_of_1_to_4_family_units TYPE integer USING NULLIF(number_of_1_to_4_family_units, '')::integer,
    ALTER COLUMN application_date_indicator TYPE integer USING NULLIF(application_date_indicator, '')::integer;

ALTER TABLE Preliminary DROP COLUMN load_order;

-- Step 4: make sequence_number a real sequential primary key.
ALTER TABLE Preliminary ALTER COLUMN sequence_number SET NOT NULL;
ALTER TABLE Preliminary ADD PRIMARY KEY (sequence_number);
DROP SEQUENCE IF EXISTS preliminary_sequence_number_seq;
CREATE SEQUENCE preliminary_sequence_number_seq OWNED BY Preliminary.sequence_number;
SELECT setval('preliminary_sequence_number_seq', (SELECT max(sequence_number) FROM Preliminary));
ALTER TABLE Preliminary ALTER COLUMN sequence_number SET DEFAULT nextval('preliminary_sequence_number_seq');

-- Quick check
SELECT count(*) AS rows_loaded, min(sequence_number), max(sequence_number) FROM Preliminary;

DO $$
BEGIN
    IF (SELECT count(*) FROM Preliminary) <> 349563 THEN
        RAISE EXCEPTION 'Expected 349563 rows in Preliminary, found %',
            (SELECT count(*) FROM Preliminary);
    END IF;
END
$$;
