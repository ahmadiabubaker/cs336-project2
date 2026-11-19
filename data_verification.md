# Project 2 CSV Verification Results

## Source identity

- File: `../hmda_2017_nj_all-records_labels.csv`
- SHA-256: `8FAE1EA53BC4AF1BC1DB107584CAB3AE77E80B24DB347F3E6BD549E265CF01B5`
- Size: 278,834,016 bytes
- Data rows: 349,563
- Columns: 78
- Malformed rows: 0
- Duplicate headers: 0

The file was read without modification by a local-only helper,
`scripts/profile_project2.py`, which is excluded from the submission repository.
The profiler streams the CSV and treats source blanks as values during dependency
testing, so a mixture of a blank and a nonblank right-hand side for one determinant
would be reported as a violation.

Run it with:

```powershell
python "second project/scripts/profile_project2.py" `
  "hmda_2017_nj_all-records_labels.csv"
```

## Completely blank source columns

Exactly four columns are blank in every source row:

- `edit_status_name`
- `edit_status`
- `sequence_number`
- `application_date_indicator`

`sequence_number` is populated only inside PostgreSQL as the application primary
key. It must return to a quoted blank in the reconstructed source-format CSV.

## Code-to-description dependency checks

Every dependency below had zero violating determinant values:

| Dependency domain | Distinct determinant values, including blank | Violations |
|---|---:|---:|
| agency | 6 | 0 |
| loan type | 4 | 0 |
| property type | 3 | 0 |
| loan purpose | 3 | 0 |
| owner occupancy | 3 | 0 |
| preapproval | 3 | 0 |
| action taken | 8 | 0 |
| MSA/MD | 12 | 0 |
| state | 1 | 0 |
| state and county | 22 | 0 |
| applicant ethnicity | 4 | 0 |
| co-applicant ethnicity | 5 | 0 |
| applicant sex | 4 | 0 |
| co-applicant sex | 5 | 0 |
| purchaser type | 10 | 0 |
| HOEPA status | 2 | 0 |
| lien status | 4 | 0 |
| edit status | 1 blank determinant | 0 |
| 1NF race domain | 9 | 0 |
| 1NF denial-reason domain | 10 | 0 |

These results show that the CSV does not violate the proposed mappings. The final FD
submission must additionally provide semantic justification and canonical-cover
calculations; an instance check alone is not proof of a real-world dependency.

## Shared applicant/co-applicant domains

The combined-role tests produced zero code-to-name conflicts:

| Shared domain | Distinct codes | Conflicts |
|---|---:|---:|
| ethnicity | 5 | 0 |
| sex | 5 | 0 |
| race across all ten numbered source positions | 9 | 0 |

Design consequence: use one ethnicity lookup table, one sex lookup table, and one
race lookup table. Applicant and co-applicant foreign-key columns reference the same
domain tables.

## Respondent and agency

The proposed dependency

```text
{respondent_id} -> {agency_code}
```

is false. Two respondent identifiers each occur under agency codes 1 and 3:

```text
0000025093 -> 1 and 3
0000013879 -> 1 and 3
```

Design consequence: the respondent key is `(agency_code, respondent_id)`.
`application` must retain both columns and reference that composite key. The false
dependency must not appear in `functional_dependencies.txt`.

## Location profile

- Distinct combinations of the handout's ten location columns: 2,135
- Source rows with at least one blank location component: 725
- Distinct location combinations with at least one blank component: 43
- Rows with nonblank `state_code`: 349,563

Nonblank counts for the other location fields:

| Column | Nonblank rows |
|---|---:|
| `county_code` | 348,887 |
| `msamd` | 348,838 |
| `census_tract_number` | 348,866 |
| `population` | 348,866 |
| `minority_population` | 348,866 |
| `hud_median_family_income` | 348,866 |
| `tract_to_msamd_income` | 348,866 |
| `number_of_owner_occupied_units` | 348,866 |
| `number_of_1_to_4_family_units` | 348,866 |

Design consequence: location is mandatory for every application because state is
always present, but several components are nullable. The ten-column alternate key
must therefore enforce NULLs-not-distinct semantics; an ordinary pre-PostgreSQL-15
`UNIQUE` constraint is not sufficient.

## Remaining verification

Before freezing DDL:

1. Repeat the decisive checks against the typed PostgreSQL `Preliminary` table.
2. Record the server version to choose the supported NULL-safe location constraint.
3. Compute the formal canonical cover, closures, BCNF decompositions, losslessness,
   and dependency preservation.

## Local PostgreSQL execution results

The SQL pipeline was executed twice from a clean Step 2 state against PostgreSQL
16 using the complete CSV. Both runs completed without an assertion failure.

Final row counts:

| Table | Rows |
|---|---:|
| `application` | 349,563 |
| `location` | 2,135 |
| `applicant_race` | 351,510 |
| `co_applicant_race` | 350,201 |
| `application_denial_reason` | 45,088 |

The normalized-only export produced 349,563 rows and 278,834,016 bytes. Binary
comparison reported no differences, and both files had this SHA-256 value:

```text
8FAE1EA53BC4AF1BC1DB107584CAB3AE77E80B24DB347F3E6BD549E265CF01B5
```

The three invalid-insert demonstrations were also executed successfully. PostgreSQL
rejected them independently through a foreign key, an ordinal `CHECK`, and a
`NOT NULL` constraint, and no invalid test row remained afterward.

## Independent normalization-tool result

The complete FD input was processed by the Carleton University Functional
Dependency Normalizer. The tool:

- Parsed all 26 merged dependencies.
- Found no redundant left-hand-side attributes.
- Found no redundant dependencies.
- Returned the same minimal cover after applying the union rule.
- Reported: `Minimal Cover and Original Set F are EQUIVALENT -- Good`.

The tool models all attributes as one universal relation, so its reported universal
candidate key contains the independent applicant-race, co-applicant-race, and
denial-reason ordinals. That is not the key of the final `application` relation.
Likewise, it removes one of its two identical location schemas as subsumed; the
remaining schema still contains `location_id` and all ten location attributes.
The handout requires `location_id` to be the simple primary key, while the ten
original attributes remain an enforced alternate candidate key.
