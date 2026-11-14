# CS336 Project 2 - Normalization Design and Verification Record

## 1. Purpose of this document

This document is the authoritative design record for Project 2. It combines the
Project 2 handout, the course normalization lecture, the normalization recitation,
the Project 1 review, and the verified facts from Project 1.

The project has a strict rubric. Nothing in this file should be treated as final
merely because it is plausible database design. Every functional dependency,
cardinality, NULL constraint, key, table, and reconstruction rule must be supported
by at least one of the following:

1. An explicit rule in the Project 2 handout.
2. An explicit rule or example in the class materials.
3. A real-world rule from the official HMDA documentation that is not contradicted
   by the CSV.
4. A query against the actual Project 1 `Preliminary` table showing that the rule is
   not violated.

This document intentionally distinguishes **confirmed requirements** from
**candidate design decisions that still require verification**. It is a working
design record, not yet the submitted design. The next milestone is a verified FD
table plus frozen DDL; the ERD will then be generated from that frozen schema.


## 2. Materials reviewed

The following files were reviewed completely:

- `Project.md` - the complete Project 2 specification and rubric.
- `class files/06 (Oct 20) Normalization.pdf` - course recitation covering 1NF, functional
  dependencies, closure, keys, BCNF, decomposition, losslessness, dependency
  preservation, and practice problems.
- `class files/Normalization, ch7.pptx.pdf` - the full Chapter 7 normalization lecture,
  including canonical covers and formal decomposition algorithms.
- `class files/08 (Nov 3) Project 1 Review.pdf` - the course-specific review of the HMDA data,
  Crow's Foot notation, data cardinalities, Project 1 loading/export rules, and a
  Project 2 preview.
- Project 1's final loading/export scripts, screenshots, README, and accepted ERD.

The user reported that the group's Project 1 submission received full credit. The
Project 1 review slides independently confirm that restoring the generated
`sequence_number` to a quoted blank field in the reconstructed source CSV was the
intended behavior; the slides do not report the group's individual grade.


## 3. Project 2 objective

Project 2 starts from the Project 1 `Preliminary` table and converts it into a
lossless, fully normalized database.

The final design must:

- Be in first normal form.
- Put every final relation in BCNF.
- Preserve functional dependencies where possible.
- Always prefer losslessness and full normalization if BCNF and dependency
  preservation conflict.
- Preserve every piece of information needed to reconstruct the original CSV.
- Use the correct PostgreSQL types from Project 1.
- Reproduce the source NULL behavior.
- Reject invalid inserts immediately using database constraints.
- Generate the final CSV without referencing `Preliminary` in any way.
- Match the submitted ER diagram exactly.


## 4. Exact deliverables

### Step 1 - 5 points

- A TXT document containing the functional dependencies in canonical-cover form.
- A PDF containing the final BCNF ER diagram.
- Every table in the ERD must have its primary key marked.
- The decomposition must be lossless.
- Every submitted FD should be preserved where possible.
- The design should contain only tables needed for normalization, unless an extra
  table has a documented and strong justification.
- A normalization tool must be used as a separate check.

Rubric hazards:

- Missing any required part can make Step 1 worth zero.
- A missing or false FD loses credit.
- Leaving a listed BCNF violation in the ERD loses major credit.
- Any ER formatting/cardinality mistake or repeated Project 1 mistake loses a point.

### Step 2 - 3 points

- An SQL script that creates the initial normalized tables and moves data out of
  `Preliminary`.
- For this stage, normalize all dependencies involving a column whose name contains
  `name`.
- The main application table must not retain any `*_name` column.
- Except possibly `respondent_id`, text belongs in secondary lookup tables rather
  than the main application table.
- Types and NULL status must remain correct.
- The Project 1 preliminary-loading script must also be submitted if the Project 2
  script assumes that `Preliminary` already exists.

Rubric hazard: any name table/field incorrectly retained in the original/main table
can make Step 2 worth zero.

### Step 3 - 4 points

- Complete the first-normal-form conversion.
- Complete the BCNF decomposition.
- Create and populate the final normalized database.
- Preserve all original data and the ordinal position of repeated values.
- Use one unique integer application key and one unique integer location key.
- Submit a video no longer than one minute showing `SELECT * FROM table` for every
  normalized table. Large tables may be exited using `q` after their first portion
  is visible.

Rubric hazards:

- A location-ID mismatch costs two points.
- Losing the original race/reason position or other data costs points.
- If the ERD and implemented tables differ, or the final database is not in 1NF,
  Step 3 can receive zero.

### Step 4 - 3 points

- Add constraints that immediately reject inconsistent data.
- Submit an SQL script that reconstructs the original CSV using only the normalized
  database.
- Submit a video no longer than one minute showing three invalid inserts rejected
  for three different reasons.
- Submit a screenshot of the reconstructed CSV opened in a spreadsheet program.

Rubric hazards:

- The report must not use `Preliminary`, directly or indirectly.
- Skipping any Step 4 part, using `Preliminary`, or failing the video instructions
  can make Step 4 worth zero.
- The grader may try invalid operations other than the three shown in the video.


## 5. Course-specific normalization rules

### 5.1 First normal form

The class defines 1NF using both atomic domains and row shape:

- Each cell contains one atomic value.
- Each conceptual attribute is represented by one column.
- Every row has the same logical fields.
- NULL means an unknown value, not that a numbered field does not exist for that
  row.

The following repeating source columns therefore cannot remain as numbered columns:

- `applicant_race_1` through `applicant_race_5`
- `applicant_race_name_1` through `applicant_race_name_5`
- `co_applicant_race_1` through `co_applicant_race_5`
- `co_applicant_race_name_1` through `co_applicant_race_name_5`
- `denial_reason_1` through `denial_reason_3`
- `denial_reason_name_1` through `denial_reason_name_3`

These groups must become rows in join tables. Their original position must be stored
so that the 78-column CSV can be reconstructed exactly.

### 5.2 Functional dependencies

`X -> Y` means that all legal rows agreeing on `X` must also agree on `Y`.

An accidental pattern in this one file is not automatically a real FD. Examples of
patterns that must not be accepted without a real rule include:

- `as_of_year` determining unrelated fields merely because every row is from 2017.
- An empty attribute determining another attribute.
- `state_code` determining unrelated application fields merely because the file
  contains only New Jersey.
- A person's name determining an ID merely because names happen to be unique in the
  current data.

The CSV is used to disprove proposed dependencies, not by itself to establish that
an accidental dependency is a real-world rule.

### 5.3 Attribute closure and keys

For an attribute set `X`, `X+` is computed by repeatedly adding the right side of
every FD whose left side is already contained in the closure.

- `X` is a superkey when `X+` reaches every attribute of the relation.
- `X` is a candidate key when it is a minimal superkey.
- Attributes never appearing on any FD's right side must appear in every candidate
  key, unless they are generated surrogate identifiers introduced by this project.

Every proposed key will be verified through closure, not intuition.

### 5.4 Canonical cover

The submitted canonical cover must:

- Have the same closure as the full FD set.
- Contain no extraneous attribute on either side.
- Use the union rule so each distinct left side occurs only once.
- Exclude redundant FDs implied by the remaining dependencies.

Generic example: if

```text
{A} -> {B}
{B} -> {C}
```

then this should not also be submitted:

```text
{A} -> {C}
```

because it follows through transitivity.

### 5.5 BCNF

A relation is in BCNF when, for every nontrivial FD `X -> Y`, `X` is a
superkey of that relation.

For a violating dependency, the class decomposition rule is:

```text
R1 = X union Y
R2 = R minus (Y minus X)
```

Every relation produced by a split must be checked again, including FDs from the
restriction of the original FD closure that apply to the new relation.

### 5.6 Lossless decomposition

For a binary decomposition into `R1` and `R2`, it is lossless when the shared
attributes determine all of `R1` or all of `R2`:

```text
(R1 intersect R2) -> R1
```

or

```text
(R1 intersect R2) -> R2
```

Every decomposition step will have a written lossless-join justification.

### 5.7 Dependency preservation

Dependency preservation means that the original FDs can be checked using the
individual decomposed tables without computing an expensive join.

Dependency preservation is required where possible. The handout explicitly says to
choose lossless/full BCNF normalization over dependency preservation if a conflict
cannot be avoided.


## 6. Confirmed Project 1 data facts

- Source records: 349,563.
- Source columns: 78.
- `sequence_number` is blank in every source row.
- `edit_status` is blank in every source row.
- `edit_status_name` is blank in every source row.
- `application_date_indicator` is blank in every source row.

The re-uploaded source CSV was profiled directly on November 13, 2026:

- SHA-256: `8FAE1EA53BC4AF1BC1DB107584CAB3AE77E80B24DB347F3E6BD549E265CF01B5`
- Size: 278,834,016 bytes.
- Shape: exactly 349,563 data rows and 78 columns.
- Malformed rows: zero.
- Duplicate headers: zero.
- Distinct ten-column location combinations: 2,135.
- Source rows with at least one blank location component: 725.
- Distinct location combinations with at least one blank component: 43.
- Project 1 generated `sequence_number` values from 1 through 349,563 in source-file
  order and made that column the primary key.
- The accepted Project 1 export restored `sequence_number` to `""` in its original
  column position and passed a byte-for-byte `diff` with the source CSV.
- `respondent_id` must remain text because it contains leading zeros and dashes.
- `census_tract_number` must remain text because values such as `0218.04` must retain
  formatting.
- `rate_spread`, `minority_population`, and `tract_to_msamd_income` require exact
  `numeric`, not floating-point types.
- Missing numeric source values became SQL NULL.
- Text/name fields were stored as text.
- The live Project 1 `Preliminary` table used for the group submission is in the
  `er1027` iLab database according to the final README and screenshots.


## 7. Confirmed class cardinality guidance

The Project 1 review establishes these data-specific relationships:

- Each application has exactly one respondent.
- Each application has exactly one agency through its respondent/code information.
- Each application has exactly one value for mandatory code domains.
- Each application has exactly one applicant.
- A co-applicant relationship may be optional, even though the source code domain
  can contain a `No co-applicant` value.
- Every application has exactly one location when state is included, because every
  row has a state.
- A location excluding state would be optional for 676 rows that contain only state.
- Denial information is optional; 312,346 of 349,563 rows have no first denial
  reason.
- Rate spread is optional; only 8,816 rows contain it.
- HOEPA is not optional merely because many loans are not HOEPA loans; `Not a HOEPA
  loan` is an actual coded value.

The class Crow's Foot convention requires two symbols at every relationship end:

- The symbol nearest the entity represents the maximum: bar for one, crow's foot
  for many.
- The outer symbol represents the minimum: bar for one, circle for zero.
- Cardinality must be read across the relationship from one entity to the marks at
  the other entity.

The final diagram will use the same course-approved notation as the full-credit
Project 1 diagram, while ensuring both ends of every relationship are explicitly
marked.


## 8. Initial 1NF transformation design

This section is a design candidate supported directly by the handout. It becomes
final only after names, keys, and constraints are verified against the class rules
and data.

### 8.1 Applicant race rows

```text
applicant_race
--------------
application_id
race_number
race_code
```

Proposed key: `{application_id, race_number}`.

Rules:

- One row for each non-NULL original applicant race position.
- `race_number` must be between 1 and 5.
- The race code must reference the race lookup table.
- No row is inserted for an empty source position.

### 8.2 Co-applicant race rows

```text
co_applicant_race
-----------------
application_id
race_number
race_code
```

Proposed key: `{application_id, race_number}`.

The same position-preservation rules apply. Separate applicant and co-applicant
tables avoid creating an unnecessary `party_type` attribute and follow the source's
two distinct repeating groups.

### 8.3 Denial reason rows

```text
application_denial_reason
-------------------------
application_id
reason_number
denial_reason_code
```

Proposed key: `{application_id, reason_number}`.

Rules:

- `reason_number` must be between 1 and 3.
- An application with no denial reasons has no rows in this table.
- The reason code references the denial-reason lookup table.
- The ordinal is required so the report can restore reasons to positions 1, 2,
  and 3.

The added ordinal attributes are part of the explicitly required initial 1NF
conversion. The handout permits adding fewer attributes than are removed during
this conversion.


## 9. Verified functional-dependency inventory

The following dependencies have zero violations across all 349,563 source rows.
They still require the formal extraneous-attribute, redundancy, closure, and
canonical-cover calculations before submission; zero instance violations alone do
not turn an accidental pattern into a semantic rule.

### 9.1 High-confidence code/name dependencies

```text
{agency_code} -> {agency_name, agency_abbr}
{loan_type} -> {loan_type_name}
{property_type} -> {property_type_name}
{loan_purpose} -> {loan_purpose_name}
{owner_occupancy} -> {owner_occupancy_name}
{preapproval} -> {preapproval_name}
{action_taken} -> {action_taken_name}
{msamd} -> {msamd_name}
{state_code} -> {state_name, state_abbr}
{state_code, county_code} -> {county_name}
{purchaser_type} -> {purchaser_type_name}
{hoepa_status} -> {hoepa_status_name}
{lien_status} -> {lien_status_name}
{applicant_ethnicity} -> {applicant_ethnicity_name}
{co_applicant_ethnicity} -> {co_applicant_ethnicity_name}
{applicant_sex} -> {applicant_sex_name}
{co_applicant_sex} -> {co_applicant_sex_name}
{edit_status} -> {edit_status_name}
```

After the repeating groups enter 1NF, likely domain dependencies are:

```text
{race_code} -> {race_name}
{denial_reason_code} -> {denial_reason_name}
```

This mechanically covers every source-form code/name determinant, including the
five dependencies that are easy to overlook. Race and denial dependencies are
shown after their required 1NF transformation.

Mechanical coverage inventory:

| # | Source or 1NF determinant | Descriptive right side | Intended physical domain |
|---:|---|---|---|
| 1 | `agency_code` | `agency_name`, `agency_abbr` | agency |
| 2 | `loan_type` | `loan_type_name` | loan type |
| 3 | `property_type` | `property_type_name` | property type |
| 4 | `loan_purpose` | `loan_purpose_name` | loan purpose |
| 5 | `owner_occupancy` | `owner_occupancy_name` | owner occupancy |
| 6 | `preapproval` | `preapproval_name` | preapproval |
| 7 | `action_taken` | `action_taken_name` | action taken |
| 8 | `msamd` | `msamd_name` | MSA/MD |
| 9 | `state_code` | `state_name`, `state_abbr` | state |
| 10 | `state_code`, `county_code` | `county_name` | county |
| 11 | `applicant_ethnicity` | `applicant_ethnicity_name` | shared ethnicity |
| 12 | `co_applicant_ethnicity` | `co_applicant_ethnicity_name` | shared ethnicity |
| 13 | 1NF `race_code` | `race_name` | shared race |
| 14 | `applicant_sex` | `applicant_sex_name` | shared sex |
| 15 | `co_applicant_sex` | `co_applicant_sex_name` | shared sex |
| 16 | `purchaser_type` | `purchaser_type_name` | purchaser type |
| 17 | 1NF `denial_reason_code` | `denial_reason_name` | denial reason |
| 18 | `hoepa_status` | `hoepa_status_name` | HOEPA status |
| 19 | `lien_status` | `lien_status_name` | lien status |
| 20 | `edit_status` | `edit_status_name` | all-NULL handling; see Section 11 |

Every original descriptive column is on the right side of exactly one listed
dependency after the race and denial groups are converted to 1NF. This inventory
was checked mechanically against the 78-column source definition. The repeated
race-name and denial-name columns collapse into
their 1NF domain dependencies; they do not require one FD or table per numbered
position.

The FD cover uses the original applicant and co-applicant attribute names, so the
four ethnicity/sex dependencies remain distinct FDs. The union-of-roles conflict
queries returned zero rows, so the physical schema uses one shared ethnicity table,
one shared sex table, and one shared race table. Different application foreign-key
columns can reference one domain table; separate source FDs do not require duplicate
lookup tables.

### 9.2 Respondent and agency result

```text
{respondent_id} -> {agency_code}
```

This proposed dependency is false in the actual CSV and must not appear in the
submitted FD cover. Two respondent identifiers occur under both agency 1 and
agency 3:

```text
0000025093
0000013879
```

Therefore the verified respondent identifier is the pair
`{agency_code, respondent_id}`. Use
`respondent(agency_code, respondent_id)` with a composite primary key, and retain
both columns as a composite foreign key in `application`.

The handout instructs us to treat the stated ten-column location set as the location
candidate key. Therefore, finer geographic dependencies must not be added to the
submitted cover merely because they happen to hold in this NJ/2017 instance.

The following must not be assumed:

- `msamd -> hud_median_family_income`
- `census_tract_number ->` demographic/location measures
- `county_code -> county_name` without `state_code`
- Any dependency whose determinant is a constant in this NJ-only, 2017-only file

### 9.3 Generated-key dependencies

The generated application identifier determines the non-lookup facts stored for
one application. Its canonical-cover RHS must exclude values already reached
transitively through respondent, code, and location dependencies.

The generated location identifier determines the location attributes. The handout
states that the following ten original columns together identify one location:

```text
county_code
msamd
state_code
census_tract_number
population
minority_population
hud_median_family_income
tract_to_msamd_income
number_of_owner_occupied_units
number_of_1_to_4_family_units
```

The location mapping therefore has two candidate-key directions by construction:

```text
{location_id} -> {the ten location columns}
{the ten location columns} -> {location_id}
```

These two directions belong in the final cover. They must be reconciled carefully
with code/name decompositions for state, county, and MSA/MD, but no additional
geographic FD should be invented beyond the handout's assumption and the explicit
code/name mappings.


## 10. Candidate final schema

This is the current implementation blueprint, not yet a frozen schema. Table and
column names may be adjusted only after the canonical cover is finalized.

### 10.1 Central application relation

The final `application` table should contain:

- `application_id`/`sequence_number` as its primary key.
- Both `agency_code` and `respondent_id`, forming the composite foreign key to
  `respondent`.
- `location_id` as the only location information.
- Numeric code values for lookup domains.
- Nonrepeating numeric application facts.
- No `*_name` columns.
- No numbered race or denial-reason columns.
- No location-detail columns other than `location_id`.
- No text column except possibly `respondent_id`.

Possible retained application facts include:

- `as_of_year`
- `loan_type`
- `property_type`
- `loan_purpose`
- `owner_occupancy`
- `loan_amount_000s`
- `preapproval`
- `action_taken`
- applicant/co-applicant ethnicity codes
- applicant/co-applicant sex codes
- `applicant_income_000s`
- `purchaser_type`
- `rate_spread`
- `hoepa_status`
- `lien_status`
- `application_date_indicator`, subject to the all-NULL design decision

Whether applicant and co-applicant scalar fields remain in `application` or require
separate tables must be decided from the canonical cover. A 1:1 conceptual entity
split alone does not automatically require another table under the handout's rule
against unnecessary tables.

### 10.2 Respondent and agency

The data disproves `{respondent_id} -> {agency_code}`, so the respondent design is
frozen as:

```text
agency(
    agency_code primary key,
    agency_name,
    agency_abbr
)

respondent(
    agency_code not null references agency,
    respondent_id not null,
    primary key (agency_code, respondent_id)
)
```

`application` stores both `agency_code` and `respondent_id` and references the
composite respondent key. This is necessary because the same respondent text occurs
under more than one agency.

### 10.3 Code/name lookup relations

Expected lookup relations include domains for:

- agency
- loan type
- property type
- loan purpose
- owner occupancy
- preapproval
- action taken
- state
- county
- MSA/MD
- ethnicity
- race
- sex
- purchaser type
- denial reason
- HOEPA status
- lien status
- edit status, even though the current source has no non-NULL edit-status values

The combined-role tests returned zero conflicts for ethnicity, sex, and race.
Therefore use exactly one shared ethnicity table, one shared sex table, and one
shared race table. Creating separate applicant/co-applicant copies would be an
unnecessary duplicate-table error. The source-form ethnicity and sex FDs remain
separate because their original determinants have different column names.

### 10.4 Location

```text
location(
    location_id primary key,
    county_code,
    msamd,
    state_code,
    census_tract_number,
    population,
    minority_population,
    hud_median_family_income,
    tract_to_msamd_income,
    number_of_owner_occupied_units,
    number_of_1_to_4_family_units,
    NULL-safe unique candidate key over the ten original location columns
)
```

The exact table must also account for state/county/MSA code-name lookup
dependencies. Names belong in their code tables, not in `location`.

Every application must receive exactly one `location_id`, because state is present
for every row. The assignment-specific ten-column grouping controls identity even
when some of its fields are NULL.

Ordinary PostgreSQL `UNIQUE (ten_columns)` is insufficient on versions before 15
because NULL-containing rows are treated as distinct. The implementation must begin
with `SHOW server_version;` and use one of these verified branches:

- PostgreSQL 15 or newer: `UNIQUE NULLS NOT DISTINCT` over the ten columns.
- Older PostgreSQL: a collision-free expression unique index using typed sentinel
  values that are excluded by CHECK constraints, while keeping the invented
  expression out of the logical schema.

For population, create a temporary application-to-location mapping with
`DENSE_RANK()` over the typed ten-column `ORDER BY`. PostgreSQL ordering groups equal
NULLs together, so identical typed combinations receive one ID without an
O(applications x locations) NULL-safe join. The temporary mapping is keyed by the
existing application ID and is not part of the final ERD. A concatenated `loc_key`
may be used only as a temporary performance aid after a collision proof; it must not
become an unapproved permanent attribute or replace the semantic ten-column
candidate key.

### 10.5 Repeating-value join relations

- `applicant_race(application_id, race_number, race_code)`
- `co_applicant_race(application_id, race_number, race_code)`
- `application_denial_reason(application_id, reason_number, denial_reason_code)`

These are required for 1NF and report reconstruction.


## 11. All-NULL column decision

Project 1 already established the appropriate treatment: its accepted application
entity and typed `Preliminary` table retained `edit_status`, `edit_status_name`, and
`application_date_indicator` as application attributes. Project 2 preserves that
decision while removing the name dependency:

- `application.edit_status` remains a nullable integer foreign key.
- `application.application_date_indicator` remains a nullable integer.
- `edit_status(edit_status PK, edit_status_name)` is the code/name relation. It has
  zero rows for this CSV because no edit-status code or name is present.
- The generated application key replaces the blank source `sequence_number`; the
  export restores a quoted blank in that source position.

This design creates no singleton table and no third identifier. It preserves the
original typed columns, keeps the name field out of the main application table, and
remains valid if a future dataset contains a non-NULL edit status. The handout says
the all-NULL columns *can* be placed in one single-row table; it does not require
that optional representation.


## 12. SQL verification plan

### 12.1 Nullability profile

For every source column:

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(column_name) AS non_null_rows,
    COUNT(*) - COUNT(column_name) AS null_rows
FROM preliminary;
```

If a column is never NULL in the actual data, the corresponding final field or
relationship must be mandatory and enforced with `NOT NULL`.

### 12.2 Functional-dependency violation test

For `X -> Y`, first form distinct `(X, Y)` combinations and then look for more than
one combination per `X`. This treats NULL combinations consistently and does not
discard a NULL determinant.

Conceptual pattern:

```sql
SELECT x, COUNT(*) AS distinct_rhs_count
FROM (
    SELECT DISTINCT x, y1, y2
    FROM preliminary
) AS distinct_pairs
GROUP BY x
HAVING COUNT(*) > 1;
```

Zero rows means the current data does not disprove the FD. It does not by itself
prove that the FD is a real-world rule. This exact pattern is the workhorse for all
source-form code/name dependencies.

### 12.3 Lookup conflict checks

For each proposed lookup table, verify:

- One code never has two names.
- The same code/name pair is not duplicated after `SELECT DISTINCT` insertion.
- Role-sharing domains such as applicant/co-applicant race, ethnicity, and sex do
  not assign conflicting meanings to one code.

Use a combined-role query, not two separate per-column queries. Ethnicity example:

```sql
SELECT code, COUNT(*) AS distinct_name_count
FROM (
    SELECT DISTINCT code, name
    FROM (
        SELECT applicant_ethnicity AS code,
               applicant_ethnicity_name AS name
        FROM preliminary
        UNION ALL
        SELECT co_applicant_ethnicity AS code,
               co_applicant_ethnicity_name AS name
        FROM preliminary
    ) AS role_values
) AS distinct_pairs
GROUP BY code
HAVING COUNT(*) > 1;
```

Run the same shape for sex. For race, union all ten applicant/co-applicant numbered
positions before the outer `SELECT DISTINCT`. A zero-row result permits one shared
physical lookup table. A nonzero result requires inspection; it does not permit
silently losing one role's label.

Verify the respondent branch separately:

```sql
SELECT respondent_id, COUNT(*) AS distinct_agency_count
FROM (
    SELECT DISTINCT respondent_id, agency_code
    FROM preliminary
) AS respondent_agencies
GROUP BY respondent_id
HAVING COUNT(*) > 1;
```

The actual query returns two respondent IDs, so the composite respondent key is
required and `{respondent_id} -> {agency_code}` is excluded from the submitted FD
cover.

### 12.4 Location mapping checks

Required checks:

- Count distinct NULL-safe ten-column location combinations.
- Assign exactly one `location_id` per combination.
- Join every preliminary row to exactly one location.
- Confirm no application matches zero locations.
- Confirm no application matches multiple locations.
- Confirm the application row count remains 349,563.
- Join back and compare every one of the ten values using NULL-safe equality.

`SELECT DISTINCT`/`GROUP BY` treat equal NULL-bearing typed combinations as one
group, while ordinary pre-15 UNIQUE constraints do not. A concatenated key is not
the proof. If one is used temporarily for speed, compare the count of ten-column
groups with the count of distinct generated keys and retain the true NULL-safe
candidate-key constraint described in Section 10.4.

### 12.5 Repeating-group preservation checks

For every race/reason group:

- Count the number of non-NULL original positions.
- Verify the join-table row count equals that count.
- Verify every stored ordinal is within its allowed range.
- Pivot/join the normalized rows back into their original positions.
- Compare each recovered code with the original field using NULL-safe equality.
- Recover each name through the lookup table and compare it with the source name.

### 12.6 Table-level row-count checks

- `application` must contain exactly 349,563 rows.
- Each code table must contain exactly the distinct non-NULL code/name mappings from
  the source domain.
- `respondent` must contain exactly the distinct verified respondent mappings.
- `location` must contain exactly the distinct ten-column location combinations.
- Join tables must contain exactly the non-NULL repeated values from the source.


## 13. Constraint design

The database must reject invalid states immediately.

Required constraint categories:

- Primary keys on every table.
- Foreign keys from every code field to its code table.
- Foreign keys from race/reason join tables to `application` and their lookup tables.
- A foreign key from `application.location_id` to `location`.
- A foreign key from `application.respondent_id` to `respondent`, if that
  decomposition is confirmed.
- `NOT NULL` on every attribute that is never NULL in the real data.
- Unique constraints for alternate/candidate keys, including the NULL-safe location
  identity rule.
- CHECK constraints for ordinal domains:
  - applicant/co-applicant `race_number` between 1 and 5
  - `reason_number` between 1 and 3
- Appropriate type constraints inherited from Project 1.

Three video tests should demonstrate different mechanisms, for example:

1. Invalid foreign-key code, such as a nonexistent property type.
2. NULL inserted into a required field.
3. Duplicate primary key or duplicate ordinal for one application.

Additional tests must be run privately because the grader may choose different
invalid values.


## 14. Reconstruction strategy

The final export must be generated only from normalized tables.

The reconstruction query must:

1. Start from the final `application` table, not `Preliminary`.
2. Join respondent and agency data.
3. Join every code table to restore each `*_name` field.
4. Join `location` and geographic lookup tables to restore all ten location fields
   and geographic names.
5. Pivot applicant race rows back into positions 1 through 5.
6. Pivot co-applicant race rows back into positions 1 through 5.
7. Pivot denial reasons back into positions 1 through 3.
8. Emit all-NULL source attributes as blank values according to the final approved
   design.
9. Emit `sequence_number` as `""` in its original source position.
10. Restore exact text formatting, including `rate_spread` leading zeros.
11. Use `FORCE_QUOTE *` and the same CSV header order as Project 1.
12. Prefer `ORDER BY application_id` so the output also matches original row order,
    even though Project 2 permits a different order.

Implementation rules:

- Use `LEFT JOIN` for every optional relationship, especially county, MSA/MD,
  denial reasons, race rows, and nullable code domains. An INNER JOIN can silently
  remove applications.
- Pivot repeating rows with conditional aggregation, for example
  `MAX(CASE WHEN race_number = 1 THEN race_code END)`, grouped by application ID.
  Do not use five independent self-joins when one grouped pass is sufficient.
- Create indexes on each join table's `application_id`, on
  `application(location_id)`, and on the final respondent foreign-key columns before
  running the export.
- Reuse the accepted Project 1 export formatting: `COALESCE(col::text, '')`,
  `to_char(rate_spread, 'FM00.00')`, `''::text AS sequence_number`, a separate real
  sort-key alias, and `FORCE_QUOTE *` with an unquoted header.
- `census_tract_number` remains text in the secondary location table; this does not
  violate the rule against text in the main application table.

The strongest validation is a byte-for-byte comparison with the original CSV after
using the same accepted formatting behavior as Project 1. If order differs, a
separate order-insensitive comparison must compare complete rows without losing
duplicates.


## 15. ER diagram construction rules

- Use the same notation accepted for the group's full-credit Project 1 diagram.
- Mark a primary key in every table.
- Show all final tables implemented by SQL and no nonexistent tables.
- Show all required foreign-key relationships.
- Put explicit minimum and maximum cardinality symbols on both ends of every line.
- Base mandatory/optional marks on NULL counts and coded-value behavior.
- Do not add conceptual tables that are unnecessary for the BCNF decomposition.
- Do not omit all-NULL source information without documenting how it is recovered.
- Ensure application-location is mandatory when state is part of location.
- Ensure optional repeated relations allow zero rows.
- Ensure one application can have multiple ordered race/reason rows.


## 16. Proposed project files

```text
second project/
|-- Project.md
|-- design.md
|-- data_verification.md
|-- class files/
|   |-- 06 (Oct 20) Normalization.pdf
|   |-- 08 (Nov 3) Project 1 Review.pdf
|   `-- Normalization, ch7.pptx.pdf
|-- functional_dependencies.txt
|-- 01_load_preliminary.sql
|-- 02_normalize_names.sql
|-- 03_normalize_full.sql
|-- 04_export_original_csv.sql
|-- 05_invalid_insert_tests.sql
|-- run_normalization.sql
|-- ER_Diagram.drawio
|-- ER_Diagram.pdf
|-- scripts/
|   `-- profile_project2.py
`-- evidence/
    |-- normalization_tool_input.png
    |-- normalization_tool_output.png
    |-- normalized_tables_video.mp4
    |-- rejected_inserts_video.mp4
    `-- reconstructed_csv.png
```

The final Project 1 `load_preliminary.sql`, not an older draft, should be copied into
this folder before implementation begins. Script composition must be explicit:

- `01` creates and loads `Preliminary`.
- `02` creates the final lookup tables plus an intermediate name-normalized
  application relation.
- `03` creates location and repeating-value relations, creates the final application
  table, validates transfer counts, and removes only its own intermediate objects.
- Every script starts with `\set ON_ERROR_STOP on` and drops/recreates its own output
  objects in reverse foreign-key order so repeated test runs are deterministic.


## 17. Zero-mistake quality gates

The project is not ready to submit unless all gates below pass.

### Requirements gate

- [ ] Every Step 1-4 deliverable exists.
- [ ] Both videos are no longer than one minute.
- [ ] Required SQL scripts are included.
- [ ] The database remains populated in the named iLab account.

### FD and normalization gate

- [ ] Every proposed FD has semantic justification.
- [ ] Every proposed FD has zero data violations.
- [ ] The canonical cover has unique left sides.
- [ ] No canonical-cover FD contains an extraneous attribute.
- [ ] No canonical-cover FD is redundant.
- [ ] Candidate keys are verified with closure.
- [ ] Every final table passes the BCNF test.
- [ ] Every decomposition step has a lossless proof.
- [ ] Dependency preservation is checked and any unavoidable loss is documented.
- [x] A normalization tool independently confirms the canonical cover.

### Data-transfer gate

- [ ] Exactly 349,563 application rows are transferred.
- [ ] No source record is skipped or duplicated.
- [ ] Every location maps to exactly one `location_id`.
- [ ] Every application maps to exactly one location.
- [ ] Race and denial join-table counts match original non-NULL counts.
- [ ] Every original ordinal position is preserved.
- [ ] Every code/name mapping matches the source.

### Constraint gate

- [ ] Every table has a primary key.
- [ ] Every required lookup relationship has a foreign key.
- [ ] Every never-NULL source value is enforced as mandatory.
- [ ] Optional values remain optional.
- [ ] Invalid codes are rejected.
- [ ] Invalid ordinals are rejected.
- [ ] Duplicate keys and duplicate positions are rejected.

### ERD/schema gate

- [ ] Every implemented table appears in the ERD.
- [ ] Every ERD table exists in SQL.
- [ ] Every primary key matches.
- [ ] Every relationship/cardinality matches its constraint and real data.
- [ ] Every relationship end has both minimum and maximum notation.
- [ ] No unnecessary table or invented attribute remains.

### Reconstruction gate

- [ ] The export query contains no reference to `Preliminary`.
- [ ] All 78 source columns are reconstructed in the original order.
- [ ] Generated sequence values are replaced with the original blank field.
- [ ] Repeated groups return to their original numbered positions.
- [ ] Exact numeric precision and textual formatting are preserved.
- [ ] The reconstructed file matches the original data.
- [ ] The spreadsheet screenshot clearly shows the reconstructed report.


## 18. Open questions requiring resolution before schema freeze

1. Which normalization tool will be used? This does not require instructor approval;
   choose one that accepts the complete schema/FD set and retain screenshots in
   `evidence/`.
2. Is there a Project 2 recitation or Canvas clarification that changes any of the
   above?

No final ERD or SQL schema should be declared complete until these questions and all
verification queries are resolved.


## 19. Immediate next actions

1. Copy the accepted Project 1 loading script into `second project` and recreate
   `Preliminary` in the developer's own iLab database.
2. Run `SHOW server_version;` to select the correct NULL-safe location constraint.
3. Repeat the source profiler's decisive checks in PostgreSQL and retain the query
   output as evidence.
4. Write the complete `functional_dependencies.txt`, including both location-key
   directions, and compute the canonical cover and closures.
5. Freeze the table/column/type/PK/FK/NULL specification and write DDL from it.
6. Draw the ERD from the frozen DDL, then mechanically compare its table, column,
    and key inventory against the implemented database before submission.
