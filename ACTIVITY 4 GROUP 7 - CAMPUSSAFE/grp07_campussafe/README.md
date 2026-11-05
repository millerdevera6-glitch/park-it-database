# Activity 4: Database Access Control & Privilege Management

**Course:** COMP 018 – Database Administration

## Overview

This folder contains the documentation, SQL scripts, access-control plans, and verification evidence prepared for Activity 4.

The activity focuses on evaluating peer database projects and applying the **Principle of Least Privilege (PoLP)** through PostgreSQL roles, memberships, and permissions.

## Evaluated Projects

### Group 7 – CampusSafe

**System:** CampusSafe: Campus Hazard & Safety Reporting System

The evaluation includes:

- Database structure and object inspection
- Access-control plan and privilege specifications
- PostgreSQL role and login account configuration
- Table, sequence, and schema permission checks
- Allowed and denied operation tests
- Supporting screenshots and verification results

**Project documentation:** [View CampusSafe Evaluation](grp07_campussafe/README.md)

## Folder Structure

```text
db-access-control/
├── README.md
└── grp07_campussafe/
    ├── README.md
    ├── access-control-plan.md
    ├── verification-results.md
    ├── scripts/
    └── evidence/
```

## Access-Control Approach

The evaluations follow these principles:

1. Apply the Principle of Least Privilege.
2. Separate group roles (`NOLOGIN`) from individual login roles (`LOGIN`).
3. Grant only the permissions required by each account.
4. Verify both permitted and denied database operations.
5. Keep credentials private and out of committed scripts.

