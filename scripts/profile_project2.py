#!/usr/bin/env python3
"""Read-only Project 2 profiling for the original HMDA CSV.

The script streams the file once. It does not rewrite the CSV and deliberately
tests dependencies using the source strings, including blank fields.
"""

from __future__ import annotations

import csv
import json
import sys
from collections import defaultdict
from pathlib import Path


EXPECTED_ROWS = 349_563
EXPECTED_COLUMNS = 78

FD_SPECS: dict[str, tuple[tuple[str, ...], tuple[str, ...]]] = {
    "agency": (("agency_code",), ("agency_name", "agency_abbr")),
    "loan_type": (("loan_type",), ("loan_type_name",)),
    "property_type": (("property_type",), ("property_type_name",)),
    "loan_purpose": (("loan_purpose",), ("loan_purpose_name",)),
    "owner_occupancy": (("owner_occupancy",), ("owner_occupancy_name",)),
    "preapproval": (("preapproval",), ("preapproval_name",)),
    "action_taken": (("action_taken",), ("action_taken_name",)),
    "msamd": (("msamd",), ("msamd_name",)),
    "state": (("state_code",), ("state_name", "state_abbr")),
    "county": (("state_code", "county_code"), ("county_name",)),
    "applicant_ethnicity": (
        ("applicant_ethnicity",),
        ("applicant_ethnicity_name",),
    ),
    "co_applicant_ethnicity": (
        ("co_applicant_ethnicity",),
        ("co_applicant_ethnicity_name",),
    ),
    "applicant_sex": (("applicant_sex",), ("applicant_sex_name",)),
    "co_applicant_sex": (
        ("co_applicant_sex",),
        ("co_applicant_sex_name",),
    ),
    "purchaser_type": (("purchaser_type",), ("purchaser_type_name",)),
    "hoepa_status": (("hoepa_status",), ("hoepa_status_name",)),
    "lien_status": (("lien_status",), ("lien_status_name",)),
    "edit_status": (("edit_status",), ("edit_status_name",)),
}

LOCATION_COLUMNS = (
    "county_code",
    "msamd",
    "state_code",
    "census_tract_number",
    "population",
    "minority_population",
    "hud_median_family_income",
    "tract_to_msamd_income",
    "number_of_owner_occupied_units",
    "number_of_1_to_4_family_units",
)


def add_mapping(
    mappings: dict[tuple[str, ...], set[tuple[str, ...]]],
    left: tuple[str, ...],
    right: tuple[str, ...],
) -> None:
    mappings[left].add(right)


def violation_summary(
    mappings: dict[tuple[str, ...], set[tuple[str, ...]]]
) -> dict[str, object]:
    violations = {left: rights for left, rights in mappings.items() if len(rights) > 1}
    examples = [
        {"lhs": list(left), "rhs_values": [list(value) for value in sorted(rights)]}
        for left, rights in list(violations.items())[:5]
    ]
    return {
        "determinant_values": len(mappings),
        "violating_determinants": len(violations),
        "examples": examples,
    }


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} CSV_PATH", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    fd_maps = {name: defaultdict(set) for name in FD_SPECS}
    race_map: dict[tuple[str, ...], set[tuple[str, ...]]] = defaultdict(set)
    denial_map: dict[tuple[str, ...], set[tuple[str, ...]]] = defaultdict(set)
    shared_ethnicity: dict[tuple[str, ...], set[tuple[str, ...]]] = defaultdict(set)
    shared_sex: dict[tuple[str, ...], set[tuple[str, ...]]] = defaultdict(set)
    respondent_agencies: dict[tuple[str, ...], set[tuple[str, ...]]] = defaultdict(set)
    locations: set[tuple[str, ...]] = set()
    nonblank_counts: dict[str, int] = {}
    malformed_rows = 0
    row_count = 0
    rows_with_any_blank_location_component = 0

    with source.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        headers = reader.fieldnames or []
        nonblank_counts = {column: 0 for column in headers}

        for row in reader:
            row_count += 1
            if None in row or len(row) != len(headers):
                malformed_rows += 1
                continue

            for column, value in row.items():
                if value != "":
                    nonblank_counts[column] += 1

            for name, (lhs_columns, rhs_columns) in FD_SPECS.items():
                add_mapping(
                    fd_maps[name],
                    tuple(row[column] for column in lhs_columns),
                    tuple(row[column] for column in rhs_columns),
                )

            for prefix in ("applicant", "co_applicant"):
                for position in range(1, 6):
                    code = row[f"{prefix}_race_{position}"]
                    name = row[f"{prefix}_race_name_{position}"]
                    add_mapping(race_map, (code,), (name,))

            for position in range(1, 4):
                code = row[f"denial_reason_{position}"]
                name = row[f"denial_reason_name_{position}"]
                add_mapping(denial_map, (code,), (name,))

            for prefix in ("applicant", "co_applicant"):
                add_mapping(
                    shared_ethnicity,
                    (row[f"{prefix}_ethnicity"],),
                    (row[f"{prefix}_ethnicity_name"],),
                )
                add_mapping(
                    shared_sex,
                    (row[f"{prefix}_sex"],),
                    (row[f"{prefix}_sex_name"],),
                )

            add_mapping(
                respondent_agencies,
                (row["respondent_id"],),
                (row["agency_code"],),
            )
            location = tuple(row[column] for column in LOCATION_COLUMNS)
            locations.add(location)
            if "" in location:
                rows_with_any_blank_location_component += 1

    results = {
        "file": str(source.resolve()),
        "bytes": source.stat().st_size,
        "rows": row_count,
        "expected_rows": EXPECTED_ROWS,
        "row_count_matches": row_count == EXPECTED_ROWS,
        "columns": len(headers),
        "expected_columns": EXPECTED_COLUMNS,
        "column_count_matches": len(headers) == EXPECTED_COLUMNS,
        "duplicate_headers": sorted(
            {column for column in headers if headers.count(column) > 1}
        ),
        "malformed_rows": malformed_rows,
        "all_blank_columns": [
            column for column, count in nonblank_counts.items() if count == 0
        ],
        "null_counts": {
            column: row_count - count for column, count in nonblank_counts.items()
        },
        "fd_checks": {
            name: violation_summary(mapping) for name, mapping in fd_maps.items()
        },
        "first_normal_form_domain_checks": {
            "race": violation_summary(race_map),
            "denial_reason": violation_summary(denial_map),
        },
        "shared_domain_checks": {
            "ethnicity": violation_summary(shared_ethnicity),
            "sex": violation_summary(shared_sex),
            "race": violation_summary(race_map),
        },
        "respondent_to_agency": violation_summary(respondent_agencies),
        "distinct_locations": len(locations),
        "distinct_locations_with_any_blank_component": sum(
            1 for location in locations if "" in location
        ),
        "source_rows_with_any_blank_location_component": (
            rows_with_any_blank_location_component
        ),
        "location_column_nonblank_counts": {
            column: nonblank_counts[column] for column in LOCATION_COLUMNS
        },
    }
    print(json.dumps(results, indent=2, sort_keys=True))

    checks_pass = (
        results["row_count_matches"]
        and results["column_count_matches"]
        and not results["duplicate_headers"]
        and malformed_rows == 0
    )
    return 0 if checks_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
