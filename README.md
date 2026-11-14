# CS336 Project 2

Normalization of the 2017 New Jersey HMDA dataset from the Project 1
`Preliminary` table into a constrained PostgreSQL schema.

## SQL execution order

From `psql`, while the current directory contains these files:

```sql
\i 01_load_preliminary.sql
\i run_normalization.sql
\i 04_export_original_csv.sql
```

`01_load_preliminary.sql` expects the original CSV to be present locally as
`hmda_2017_nj_all-records_labels.csv`. The CSV is intentionally excluded from this
repository because of its size.

To demonstrate constraint enforcement after normalization:

```sql
\i 05_invalid_insert_tests.sql
```

## Project documents

- `Project.md`: assignment handout
- `design.md`: detailed design and verification record
- `data_verification.md`: source profiling and test results
- `functional_dependencies.txt`: submitted canonical cover
- `normalization_tool_input.txt`: copy/paste input for the normalization checker
- `CS336_Project2_Final_ERD.drawio`: editable final ER diagram
- `CS336_Project2_Final_ERD.pdf`: final ER diagram for submission

`scripts/generate_erd.js` records the SQL-checked starting layout. The editable
final diagram was manually refined afterward; the generator writes a separate
draft file and does not overwrite the final diagram.

The normalized-only export was tested against all 349,563 source records and was
byte-identical to the original CSV.
