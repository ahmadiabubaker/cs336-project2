-- 05_invalid_insert_tests.sql
-- Project 2, Step 4 video: three INSERT statements rejected for three different
-- constraint mechanisms. Run after 03_normalize_full.sql.

\set ON_ERROR_STOP off

\echo 'TEST 1: invalid property_type must fail its foreign key'
INSERT INTO application (
    application_id, as_of_year, agency_code, respondent_id, loan_type,
    property_type, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
)
SELECT
    -1, as_of_year, agency_code, respondent_id, loan_type,
    4, loan_purpose, owner_occupancy, loan_amount_000s,
    preapproval, action_taken, location_id, applicant_ethnicity,
    co_applicant_ethnicity, applicant_sex, co_applicant_sex,
    applicant_income_000s, purchaser_type, rate_spread, hoepa_status,
    lien_status
FROM application
WHERE application_id = 1;

\echo 'TEST 2: race_number 6 must fail the range CHECK'
INSERT INTO applicant_race (application_id, race_number, race_code)
VALUES (1, 6, 1);

\echo 'TEST 3: NULL agency_name must fail NOT NULL'
INSERT INTO agency (agency_code, agency_name, agency_abbr)
VALUES (99, NULL, 'BAD');

\set ON_ERROR_STOP on

-- None of the rejected rows may remain.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM application WHERE application_id = -1)
       OR EXISTS (
           SELECT 1 FROM applicant_race
           WHERE application_id = 1 AND race_number = 6
       )
       OR EXISTS (SELECT 1 FROM agency WHERE agency_code = 99) THEN
        RAISE EXCEPTION 'An invalid test row was accepted';
    END IF;
END
$$;

\echo 'PASS: all three invalid INSERT statements were rejected.'
