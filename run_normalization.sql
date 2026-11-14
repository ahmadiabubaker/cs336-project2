-- run_normalization.sql
-- Run from psql while the current working directory contains these SQL files.
-- Preliminary must already exist; otherwise run 01_load_preliminary.sql first.

\set ON_ERROR_STOP on
\i 02_normalize_names.sql
\i 03_normalize_full.sql
