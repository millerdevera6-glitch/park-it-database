# Access Control Plan
## PUP-SPOT: Campus Lost and Found System

### 1. Project Information

| Information | Details |
|---|---|
| Project Name | PUP-SPOT: Campus Lost and Found |
| Repository | https://github.com/grp05-dba/grp05_lostandfound |
| Database Platform | PostgreSQL |
| Database Name | grp05_lostandfounddb |
| Programming Language | PHP 8 |

### 2. Purpose

The purpose of this access control plan is to define the database accounts, group roles, and privileges required by the PUP-SPOT Lost and Found System. It ensures that each database account only receives the permissions necessary for its assigned responsibilities.

The system follows the Principle of Least Privilege to prevent unauthorized access, modification, and deletion of database records.

### 3. Database Accounts and Roles

| Login Account | Group Role | Application Role Served | Responsibility | Required Privileges |
|---|---|---|---|---|
| PostgreSQL Administrator | Database Administrator | System Administrator | Manages the database structure, accounts, and permissions. | Database and role administration as required |
| lostandfound_app | Application Runtime | Application System | Allows the PHP application to communicate with the PostgreSQL database. | SELECT, INSERT, UPDATE, DELETE on authorized tables |
| lostandfound_public | Public Access Role | Public User | Supports public-facing operations of the Lost and Found System. | SELECT and other specifically authorized operations |

**Note:** The login accounts above are based on the repository's existing role-creation SQL script. The application roles and responsibilities are descriptions for this access-control plan. Actual privileges must be verified against the SQL script.

### 4. Database Objects

The PUP-SPOT database contains the following tables:

1. categories
2. items
3. lost_reports
4. claims
5. potential_matches
6. item_images
7. lost_report_images
8. claim_images

These database objects contain information related to lost items, found items, claims, categories, and uploaded images.

### 5. Access Control Strategy

The following security measures will be applied:

- Use separate database accounts for application access and public-facing operations.
- Avoid using the PostgreSQL superuser for ordinary application connections.
- Grant only the privileges required by each account.
- Restrict unauthorized INSERT, UPDATE, and DELETE operations.
- Review database, schema, table, and sequence permissions.
- Verify permissions using actual database login accounts.

### 6. Privilege Verification

The following tests will be performed to verify the assigned permissions.

| Test | Expected Result |
|---|---|
| Application account connects to the database | Allowed |
| Application account reads authorized records | Allowed |
| Application account inserts an authorized record | Allowed, if required |
| Public account reads approved records | Allowed |
| Public account updates restricted records | Denied |
| Public account deletes restricted records | Denied |
| Unauthorized account accesses the database | Denied |

Actual results and screenshots will be added after testing.

### 7. Security Justification

The access-control structure separates application access from public-facing database access. This reduces the risk of unauthorized database operations.

The application runtime account receives the privileges needed to perform system operations, while the public-facing account is restricted to its specifically authorized activities.

The PostgreSQL administrator is reserved for database maintenance and configuration. These restrictions help protect the confidentiality and integrity of the system's records.

### 8. Conclusion

The access-control plan establishes a structured approach to managing database accounts and privileges for the PUP-SPOT Lost and Found System. Through appropriate role assignments and privilege verification, the database can be maintained in a more secure and controlled environment.