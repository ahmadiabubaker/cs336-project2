-- 04_export_original_csv.sql
-- Project 2, Step 4: reconstruct the original 78-column CSV using only the final
-- normalized relations. Run after 03_normalize_full.sql.

\set ON_ERROR_STOP on

CREATE OR REPLACE TEMP VIEW normalized_export AS
WITH applicant_race_pivot AS (
    SELECT
        value.application_id,
        MAX(value.race_name) FILTER (WHERE value.race_number = 1) AS race_name_1,
        MAX(value.race_code) FILTER (WHERE value.race_number = 1) AS race_1,
        MAX(value.race_name) FILTER (WHERE value.race_number = 2) AS race_name_2,
        MAX(value.race_code) FILTER (WHERE value.race_number = 2) AS race_2,
        MAX(value.race_name) FILTER (WHERE value.race_number = 3) AS race_name_3,
        MAX(value.race_code) FILTER (WHERE value.race_number = 3) AS race_3,
        MAX(value.race_name) FILTER (WHERE value.race_number = 4) AS race_name_4,
        MAX(value.race_code) FILTER (WHERE value.race_number = 4) AS race_4,
        MAX(value.race_name) FILTER (WHERE value.race_number = 5) AS race_name_5,
        MAX(value.race_code) FILTER (WHERE value.race_number = 5) AS race_5
    FROM (
        SELECT ar.application_id, ar.race_number, ar.race_code, r.race_name
        FROM applicant_race AS ar
        JOIN race AS r USING (race_code)
    ) AS value
    GROUP BY value.application_id
),
co_applicant_race_pivot AS (
    SELECT
        value.application_id,
        MAX(value.race_name) FILTER (WHERE value.race_number = 1) AS race_name_1,
        MAX(value.race_code) FILTER (WHERE value.race_number = 1) AS race_1,
        MAX(value.race_name) FILTER (WHERE value.race_number = 2) AS race_name_2,
        MAX(value.race_code) FILTER (WHERE value.race_number = 2) AS race_2,
        MAX(value.race_name) FILTER (WHERE value.race_number = 3) AS race_name_3,
        MAX(value.race_code) FILTER (WHERE value.race_number = 3) AS race_3,
        MAX(value.race_name) FILTER (WHERE value.race_number = 4) AS race_name_4,
        MAX(value.race_code) FILTER (WHERE value.race_number = 4) AS race_4,
        MAX(value.race_name) FILTER (WHERE value.race_number = 5) AS race_name_5,
        MAX(value.race_code) FILTER (WHERE value.race_number = 5) AS race_5
    FROM (
        SELECT cr.application_id, cr.race_number, cr.race_code, r.race_name
        FROM co_applicant_race AS cr
        JOIN race AS r USING (race_code)
    ) AS value
    GROUP BY value.application_id
),
denial_reason_pivot AS (
    SELECT
        value.application_id,
        MAX(value.denial_reason_name)
            FILTER (WHERE value.reason_number = 1) AS denial_reason_name_1,
        MAX(value.denial_reason_code)
            FILTER (WHERE value.reason_number = 1) AS denial_reason_1,
        MAX(value.denial_reason_name)
            FILTER (WHERE value.reason_number = 2) AS denial_reason_name_2,
        MAX(value.denial_reason_code)
            FILTER (WHERE value.reason_number = 2) AS denial_reason_2,
        MAX(value.denial_reason_name)
            FILTER (WHERE value.reason_number = 3) AS denial_reason_name_3,
        MAX(value.denial_reason_code)
            FILTER (WHERE value.reason_number = 3) AS denial_reason_3
    FROM (
        SELECT adr.application_id, adr.reason_number, adr.denial_reason_code,
               dr.denial_reason_name
        FROM application_denial_reason AS adr
        JOIN denial_reason AS dr USING (denial_reason_code)
    ) AS value
    GROUP BY value.application_id
)
SELECT
    COALESCE(a.as_of_year::text, '') AS as_of_year,
    COALESCE(a.respondent_id, '') AS respondent_id,
    COALESCE(ag.agency_name, '') AS agency_name,
    COALESCE(ag.agency_abbr, '') AS agency_abbr,
    COALESCE(a.agency_code::text, '') AS agency_code,
    COALESCE(lt.loan_type_name, '') AS loan_type_name,
    COALESCE(a.loan_type::text, '') AS loan_type,
    COALESCE(pt.property_type_name, '') AS property_type_name,
    COALESCE(a.property_type::text, '') AS property_type,
    COALESCE(lp.loan_purpose_name, '') AS loan_purpose_name,
    COALESCE(a.loan_purpose::text, '') AS loan_purpose,
    COALESCE(oo.owner_occupancy_name, '') AS owner_occupancy_name,
    COALESCE(a.owner_occupancy::text, '') AS owner_occupancy,
    COALESCE(a.loan_amount_000s::text, '') AS loan_amount_000s,
    COALESCE(pa.preapproval_name, '') AS preapproval_name,
    COALESCE(a.preapproval::text, '') AS preapproval,
    COALESCE(atc.action_taken_name, '') AS action_taken_name,
    COALESCE(a.action_taken::text, '') AS action_taken,
    COALESCE(m.msamd_name, '') AS msamd_name,
    COALESCE(l.msamd::text, '') AS msamd,
    COALESCE(st.state_name, '') AS state_name,
    COALESCE(st.state_abbr, '') AS state_abbr,
    COALESCE(l.state_code::text, '') AS state_code,
    COALESCE(c.county_name, '') AS county_name,
    COALESCE(l.county_code::text, '') AS county_code,
    COALESCE(l.census_tract_number, '') AS census_tract_number,
    COALESCE(ae.ethnicity_name, '') AS applicant_ethnicity_name,
    COALESCE(a.applicant_ethnicity::text, '') AS applicant_ethnicity,
    COALESCE(ce.ethnicity_name, '') AS co_applicant_ethnicity_name,
    COALESCE(a.co_applicant_ethnicity::text, '') AS co_applicant_ethnicity,
    COALESCE(arp.race_name_1, '') AS applicant_race_name_1,
    COALESCE(arp.race_1::text, '') AS applicant_race_1,
    COALESCE(arp.race_name_2, '') AS applicant_race_name_2,
    COALESCE(arp.race_2::text, '') AS applicant_race_2,
    COALESCE(arp.race_name_3, '') AS applicant_race_name_3,
    COALESCE(arp.race_3::text, '') AS applicant_race_3,
    COALESCE(arp.race_name_4, '') AS applicant_race_name_4,
    COALESCE(arp.race_4::text, '') AS applicant_race_4,
    COALESCE(arp.race_name_5, '') AS applicant_race_name_5,
    COALESCE(arp.race_5::text, '') AS applicant_race_5,
    COALESCE(crp.race_name_1, '') AS co_applicant_race_name_1,
    COALESCE(crp.race_1::text, '') AS co_applicant_race_1,
    COALESCE(crp.race_name_2, '') AS co_applicant_race_name_2,
    COALESCE(crp.race_2::text, '') AS co_applicant_race_2,
    COALESCE(crp.race_name_3, '') AS co_applicant_race_name_3,
    COALESCE(crp.race_3::text, '') AS co_applicant_race_3,
    COALESCE(crp.race_name_4, '') AS co_applicant_race_name_4,
    COALESCE(crp.race_4::text, '') AS co_applicant_race_4,
    COALESCE(crp.race_name_5, '') AS co_applicant_race_name_5,
    COALESCE(crp.race_5::text, '') AS co_applicant_race_5,
    COALESCE(ase.sex_name, '') AS applicant_sex_name,
    COALESCE(a.applicant_sex::text, '') AS applicant_sex,
    COALESCE(cse.sex_name, '') AS co_applicant_sex_name,
    COALESCE(a.co_applicant_sex::text, '') AS co_applicant_sex,
    COALESCE(a.applicant_income_000s::text, '') AS applicant_income_000s,
    COALESCE(pu.purchaser_type_name, '') AS purchaser_type_name,
    COALESCE(a.purchaser_type::text, '') AS purchaser_type,
    COALESCE(drp.denial_reason_name_1, '') AS denial_reason_name_1,
    COALESCE(drp.denial_reason_1::text, '') AS denial_reason_1,
    COALESCE(drp.denial_reason_name_2, '') AS denial_reason_name_2,
    COALESCE(drp.denial_reason_2::text, '') AS denial_reason_2,
    COALESCE(drp.denial_reason_name_3, '') AS denial_reason_name_3,
    COALESCE(drp.denial_reason_3::text, '') AS denial_reason_3,
    COALESCE(to_char(a.rate_spread, 'FM00.00'), '') AS rate_spread,
    COALESCE(hs.hoepa_status_name, '') AS hoepa_status_name,
    COALESCE(a.hoepa_status::text, '') AS hoepa_status,
    COALESCE(ls.lien_status_name, '') AS lien_status_name,
    COALESCE(a.lien_status::text, '') AS lien_status,
    COALESCE(es.edit_status_name, '') AS edit_status_name,
    COALESCE(a.edit_status::text, '') AS edit_status,
    ''::text AS sequence_number,
    a.application_id AS sort_key,
    COALESCE(l.population::text, '') AS population,
    COALESCE(l.minority_population::text, '') AS minority_population,
    COALESCE(l.hud_median_family_income::text, '') AS hud_median_family_income,
    COALESCE(l.tract_to_msamd_income::text, '') AS tract_to_msamd_income,
    COALESCE(l.number_of_owner_occupied_units::text, '')
        AS number_of_owner_occupied_units,
    COALESCE(l.number_of_1_to_4_family_units::text, '')
        AS number_of_1_to_4_family_units,
    COALESCE(a.application_date_indicator::text, '')
        AS application_date_indicator
FROM application AS a
JOIN agency AS ag USING (agency_code)
JOIN loan_type AS lt USING (loan_type)
JOIN property_type AS pt USING (property_type)
JOIN loan_purpose AS lp USING (loan_purpose)
JOIN owner_occupancy AS oo USING (owner_occupancy)
JOIN preapproval AS pa USING (preapproval)
JOIN action_taken AS atc USING (action_taken)
JOIN location AS l USING (location_id)
LEFT JOIN msamd AS m USING (msamd)
JOIN state AS st USING (state_code)
LEFT JOIN county AS c
    ON c.state_code = l.state_code AND c.county_code = l.county_code
JOIN ethnicity AS ae ON ae.ethnicity_code = a.applicant_ethnicity
JOIN ethnicity AS ce ON ce.ethnicity_code = a.co_applicant_ethnicity
JOIN sex AS ase ON ase.sex_code = a.applicant_sex
JOIN sex AS cse ON cse.sex_code = a.co_applicant_sex
JOIN purchaser_type AS pu USING (purchaser_type)
JOIN hoepa_status AS hs USING (hoepa_status)
JOIN lien_status AS ls USING (lien_status)
LEFT JOIN edit_status AS es USING (edit_status)
LEFT JOIN applicant_race_pivot AS arp USING (application_id)
LEFT JOIN co_applicant_race_pivot AS crp USING (application_id)
LEFT JOIN denial_reason_pivot AS drp USING (application_id);

\copy (SELECT as_of_year, respondent_id, agency_name, agency_abbr, agency_code, loan_type_name, loan_type, property_type_name, property_type, loan_purpose_name, loan_purpose, owner_occupancy_name, owner_occupancy, loan_amount_000s, preapproval_name, preapproval, action_taken_name, action_taken, msamd_name, msamd, state_name, state_abbr, state_code, county_name, county_code, census_tract_number, applicant_ethnicity_name, applicant_ethnicity, co_applicant_ethnicity_name, co_applicant_ethnicity, applicant_race_name_1, applicant_race_1, applicant_race_name_2, applicant_race_2, applicant_race_name_3, applicant_race_3, applicant_race_name_4, applicant_race_4, applicant_race_name_5, applicant_race_5, co_applicant_race_name_1, co_applicant_race_1, co_applicant_race_name_2, co_applicant_race_2, co_applicant_race_name_3, co_applicant_race_3, co_applicant_race_name_4, co_applicant_race_4, co_applicant_race_name_5, co_applicant_race_5, applicant_sex_name, applicant_sex, co_applicant_sex_name, co_applicant_sex, applicant_income_000s, purchaser_type_name, purchaser_type, denial_reason_name_1, denial_reason_1, denial_reason_name_2, denial_reason_2, denial_reason_name_3, denial_reason_3, rate_spread, hoepa_status_name, hoepa_status, lien_status_name, lien_status, edit_status_name, edit_status, sequence_number, population, minority_population, hud_median_family_income, tract_to_msamd_income, number_of_owner_occupied_units, number_of_1_to_4_family_units, application_date_indicator FROM normalized_export ORDER BY sort_key) TO 'hmda_2017_nj_reconstructed_project2.csv' WITH (FORMAT csv, HEADER true, FORCE_QUOTE *)
