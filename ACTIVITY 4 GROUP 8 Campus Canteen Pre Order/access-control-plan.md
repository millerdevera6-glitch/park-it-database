
# Database Access Control Plan
## Campus Canteen Pre-Order and Queue Management System

### 1. Project Overview
The system is a campus canteen management platform that allows students to pre-order food, vendors to manage their menus and orders, and administrators to oversee canteen operations.

### 2. Database Information
- Database Management System: PostgreSQL
- Database Name: canteen_db
- Schema: public
- Total Tables: 7

### 3. User Roles and Responsibilities

| Role | Description |
|---|---|
| canteen_admin | Database owner responsible for database setup and migrations. |
| canteen_app | Application login used by the backend system. |
| canteen_app_grp | Group role that provides application database permissions. |
| canteen_readonly_grp | Group role that provides read-only access. |

### 4. Access Permissions

| Permission | Application Group | Read-only Group |
|---|---|---|
| SELECT | Allowed | Allowed |
| INSERT | Allowed | Denied |
| UPDATE | Allowed | Denied |
| DELETE | menu_item only | Denied |
| Sequence USAGE | Allowed | Not required |

### 5. Security Measures
- Follow the principle of least privilege.
- Avoid using the database owner account for normal application operations.
- Use strong passwords for database login accounts.
- Keep database credentials outside the public repository.
- Assign permissions through group roles.
- Regularly verify database permissions.

### 6. Implementation
The access-control configuration is implemented through SQL scripts that create database roles, assign privileges, and verify the permissions.

### 7. Expected Outcome
The application receives only the permissions required for its operations, while read-only users can retrieve information without modifying database records.
