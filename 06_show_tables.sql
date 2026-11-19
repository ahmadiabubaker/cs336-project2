-- Project 2, Step 3 video helper. Run after run_normalization.sql.
-- Shows SELECT * FROM each of the 24 final normalized tables, as requested.
-- Press q in the pager after showing the first screen of each result.
-- No LIMIT is used: each command is the exact full-table SELECT.

\set ON_ERROR_STOP on
\pset pager always

\echo '01/24 APPLICATION'
SELECT * FROM application;

\echo '02/24 LOCATION'
SELECT * FROM location;

\echo '03/24 RESPONDENT'
SELECT * FROM respondent;

\echo '04/24 AGENCY'
SELECT * FROM agency;

\echo '05/24 LOAN_TYPE'
SELECT * FROM loan_type;

\echo '06/24 PROPERTY_TYPE'
SELECT * FROM property_type;

\echo '07/24 LOAN_PURPOSE'
SELECT * FROM loan_purpose;

\echo '08/24 OWNER_OCCUPANCY'
SELECT * FROM owner_occupancy;

\echo '09/24 PREAPPROVAL'
SELECT * FROM preapproval;

\echo '10/24 ACTION_TAKEN'
SELECT * FROM action_taken;

\echo '11/24 PURCHASER_TYPE'
SELECT * FROM purchaser_type;

\echo '12/24 HOEPA_STATUS'
SELECT * FROM hoepa_status;

\echo '13/24 LIEN_STATUS'
SELECT * FROM lien_status;

\echo '14/24 EDIT_STATUS'
SELECT * FROM edit_status;

\echo '15/24 ETHNICITY'
SELECT * FROM ethnicity;

\echo '16/24 SEX'
SELECT * FROM sex;

\echo '17/24 RACE'
SELECT * FROM race;

\echo '18/24 DENIAL_REASON'
SELECT * FROM denial_reason;

\echo '19/24 MSAMD'
SELECT * FROM msamd;

\echo '20/24 STATE'
SELECT * FROM state;

\echo '21/24 COUNTY'
SELECT * FROM county;

\echo '22/24 APPLICANT_RACE'
SELECT * FROM applicant_race;

\echo '23/24 CO_APPLICANT_RACE'
SELECT * FROM co_applicant_race;

\echo '24/24 APPLICATION_DENIAL_REASON'
SELECT * FROM application_denial_reason;

\pset pager on
\echo 'Finished showing all 24 final tables.'
