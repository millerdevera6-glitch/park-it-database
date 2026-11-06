# PARK IT — Application User Roles & Database Role Mapping

**Project:** Park It — Database Management System  
**Database:** PostgreSQL 18.6  
**Application:** PHP, HTML, CSS, JavaScript, and AJAX  
**Database:** `grp_parkitdb`

---

## 1. Overview and Core Principle

Park It uses application user roles to control what each person can see and do inside the parking management system. These application roles are separate from PostgreSQL database roles, which control what the PHP application is allowed to do at the database level.

The existing `staff_user` table stores application login accounts and their roles. The application uses the `role` column to identify whether a signed-in user is an **Administrator** or **Staff** member.

End users should not need their own PostgreSQL accounts. The PHP application connects to PostgreSQL through one dedicated database service account. PHP checks the signed-in user's application role before allowing restricted actions, while PostgreSQL permissions limit what the application service account can do.

**Important:** Application role checks must be performed in PHP on every protected page and action. Hiding a button in the browser is not sufficient security. The server must also reject unauthorized requests.

---

## 2. Application and Database Role Mapping Matrix

The following matrix describes the intended access policy for Park It. The exact role values stored in `staff_user.role` must match the values inserted by the project's setup script (`config/seed.php`). The examples below use `admin` and `staff`.

| Application Role | Responsibilities | Application Functions and Data Access | Database Role Mapping |
|---|---|---|---|
| **Administrator** (`admin`) | Oversees parking operations and has permission to register vehicle information. | Register vehicles; create vehicle-entry transactions; view vehicle and transaction records; access payment and exit functions; view parking availability and monitoring information. May edit vehicle information where supported. Deletion must be blocked when a vehicle is referenced by transaction history. | Uses the shared PHP database service account, `parkit_app`, through `parkit_runtime_grp`. Administrator-specific restrictions are enforced by PHP. |
| **Staff** (`staff`) | Handles authorized day-to-day parking operations. | Search and view active parking records; process payment and vehicle exit; view payment and transaction information needed for operations; monitor occupied and available spaces. Vehicle registration and vehicle-record maintenance are restricted to the Administrator under the stated project requirement. | Uses the same PHP database service account, `parkit_app`, through `parkit_runtime_grp`. Staff-specific restrictions are enforced by PHP. |
| **Application Runtime** *(System Account)* | Connects the PHP application to PostgreSQL and performs approved database operations on behalf of signed-in users. | Reads staff accounts for login verification; reads and records vehicle information; creates and updates parking transactions; records payments; reads and updates parking-zone counts. It should not have permission to delete payment or transaction history. | `parkit_app` *(member of `parkit_runtime_grp`)*. |

**Role mapping note:** Administrator and Staff are application roles, not separate PostgreSQL login accounts. If both users connect through the same PHP database service account, PostgreSQL sees the service account—not the human user. Therefore, the application must enforce the difference between Administrator and Staff permissions.

Park It's stated requirements currently define Administrator and Staff accounts. A separate Viewer/Auditor application role is not included in this document because it has not been specified as a system feature.

---

## 3. Detailed Application User Roles

### 3.1 Administrator

- **Role Purpose:** Oversees the parking system and performs administrative vehicle-registration tasks.
- **Application Capabilities:**
  - **Vehicle Registration:** Enter a vehicle's license plate number and select its type (`Car` or `Motorcycle`).
  - **Vehicle Entry:** Create the parking transaction and record the vehicle's entry time when the vehicle is admitted.
  - **Vehicle Records:** View registered vehicles and edit vehicle information when the application provides that function.
  - **Safe Record Handling:** Do not delete a vehicle record if existing parking transactions refer to it. Preserve transaction and payment history.
  - **Payment and Exit:** Access the payment and vehicle-exit workflow, subject to the implemented authorization rules.
  - **Parking Monitoring:** View the total capacity, occupied spaces, available spaces, and parking warnings.

### 3.2 Staff

- **Role Purpose:** Handles authorized daily parking operations.
- **Application Capabilities:**
  - **Active Vehicle Search:** Search for a vehicle by its license plate and view its active parking transaction.
  - **Payment Processing:** Review the entry time and parking duration, select the payment method, and record the amount paid.
  - **Lost Ticket Handling:** Apply the configured flat lost-ticket fee of PHP 200.00 when the ticket is reported lost.
  - **Vehicle Exit:** Complete the authorized exit process after payment is recorded. The transaction's exit time and status must be updated, and the occupied-space count must decrease.
  - **Parking Monitoring:** View occupied and available parking spaces and the current capacity status.
  - **Restricted Administration:** Cannot register vehicles or maintain vehicle master records under the stated Administrator-only registration requirement. Cannot change database credentials or directly alter database permissions.

### 3.3 Application Runtime Account

- **Role Purpose:** Provides the database connection used by the PHP application.
- **Application and Database Responsibilities:**
  - Connect to the `grp_parkitdb` database using PostgreSQL.
  - Read `staff_user` records needed for login verification.
  - Read and insert vehicle records as permitted by the application workflow.
  - Read, insert, and update parking transactions.
  - Read and insert payment records.
  - Read and update parking-zone occupancy information.
  - Avoid deleting payment and transaction history.
- **Security Requirement:** Use a dedicated PostgreSQL account with only the permissions needed by the application. Do not use the PostgreSQL superuser account (`postgres`) as the normal application runtime account in a deployed environment.

---

## 4. Intended PostgreSQL Database RBAC Setup

PostgreSQL Role-Based Access Control (RBAC) limits the operations that a database account can perform. Park It should follow the **Principle of Least Privilege**: give the application database account only the permissions required to run the system.

The SQL below is an example of a database-role setup. It creates PostgreSQL roles and grants permissions; it does **not** add, remove, or change any Park It tables or columns.

**Before running these statements:**

1. Confirm that the database is named `grp_parkitdb`.
2. Review the complete `schema.sql` file and confirm the table names and any ID-generation sequences it defines.
3. Run the role-creation statements only once. If a role already exists, do not create it again.
4. Run these commands using a PostgreSQL account allowed to create roles and grant privileges.
5. Replace the sample password with a strong local password. Never commit the real password to Git.

### 4.1 Database Group Role (`NOLOGIN`)

```sql
-- Group role for the PHP application's database permissions.
CREATE ROLE parkit_runtime_grp WITH NOLOGIN;
```

### 4.2 Database Permissions

Connect to `grp_parkitdb` before running the following grants.

```sql
-- Allow the application group to connect to the database
-- and use the public schema.
GRANT CONNECT ON DATABASE grp_parkitdb TO parkit_runtime_grp;
GRANT USAGE ON SCHEMA public TO parkit_runtime_grp;

-- Read the records needed by the application.
GRANT SELECT ON
    public.staff_user,
    public.vehicle,
    public."transaction",
    public.payment,
    public.parking_zone
TO parkit_runtime_grp;

-- Create vehicle and entry records, and record payments.
GRANT INSERT ON
    public.vehicle,
    public."transaction",
    public.payment
TO parkit_runtime_grp;

-- Update vehicle details, transaction status/exit information,
-- and the parking-zone active vehicle count.
GRANT UPDATE ON
    public.vehicle,
    public."transaction",
    public.parking_zone
TO parkit_runtime_grp;
```

**Why these permissions are used:**

- `staff_user`: The application needs to read account information to verify login credentials. The runtime account is not granted permission to change staff passwords or roles through this example.
- `vehicle`: The application needs to read, register, and, where allowed by the application, update vehicle information.
- `transaction`: The application needs to read active records, create entry records, and update exit time, status, and lost-ticket information.
- `payment`: The application needs to read payment history and insert new payment records. Update and delete permissions are not granted.
- `parking_zone`: The application needs to read capacity information and update the active vehicle count.

**Important limitation:** These grants apply to the shared application database account. They do not distinguish the Administrator from Staff. PHP must enforce application-level restrictions for those two roles. Also, the example deliberately does not grant `DELETE` on transaction or payment records, helping protect parking and payment history.

### 4.3 Database Login Account (`LOGIN`)

```sql
-- Create a dedicated login account for the PHP application.
CREATE ROLE parkit_app WITH LOGIN PASSWORD 'CHANGE_THIS_PASSWORD';

-- Give the application account the permissions of the group role.
GRANT parkit_runtime_grp TO parkit_app;
```

Configure the PHP database connection to use `parkit_app` and the password you set locally. Keep the password outside the public Git repository.

### 4.4 Important Notes About IDs and Sequences

The supplied table definitions show integer ID columns, but the definitions provided for this project do not, by themselves, establish whether those IDs use identity columns, serial defaults, or separate sequences.

Do not assume that sequences exist. Inspect the complete `schema.sql` file first. If it defines sequences or identity-backed IDs, grant only the required sequence permissions to `parkit_runtime_grp`. Do not apply broad sequence grants without checking the actual database setup.

---

## 5. Existing Database Tables Used by Park It

The role permissions above refer only to the five tables already provided for Park It.

| Existing Table | Purpose in Park It | Main Access Needed by the Application |
|---|---|---|
| `staff_user` | Stores usernames, password hashes, and application roles. | `SELECT` for login verification. |
| `vehicle` | Stores license plate numbers and vehicle types. | `SELECT`, `INSERT`, and `UPDATE`. |
| `transaction` | Stores vehicle entry, exit, zone, status, and lost-ticket information. | `SELECT`, `INSERT`, and `UPDATE`. |
| `payment` | Stores transaction payments, amounts, payment methods, and payment times. | `SELECT` and `INSERT`. |
| `parking_zone` | Stores parking-zone capacity and current active vehicle count. | `SELECT` and `UPDATE`. |

The table named `transaction` is a PostgreSQL keyword-sensitive identifier. SQL statements should reference it as `public."transaction"` when quoting is required.

**Database structure rule:** This user-role document does not require any table or column changes. Keep the existing Park It database schema unchanged.

---

## 6. Security and Credential Isolation

1. **Password Hashing:** Store password hashes in `staff_user.password_hash`. Use PHP's `password_hash()` when creating passwords and `password_verify()` when checking login credentials. Never store plain-text passwords in the database.
2. **Application Role Checks:** Read the user's role after successful login. Check that role on the server for every restricted page and action. Do not rely only on hidden buttons or menu items.
3. **Database Account:** Use a dedicated, least-privilege account such as `parkit_app` for the PHP application. Avoid using the PostgreSQL `postgres` superuser account as the normal runtime account.
4. **Prepared Statements:** Use PDO prepared statements for database queries to help prevent SQL injection.
5. **Session Protection:** Require a valid login session before opening protected modules. Destroy the session when the user logs out.
6. **Credential Safety:** Never commit real database passwords, private configuration files, or production credentials to GitHub. Use placeholders in example configuration files.
7. **Record Integrity:** Do not casually delete payment or transaction history. Keep completed parking and payment records for reference and auditing.
8. **Atomic Operations:** Process payment recording, transaction completion, exit-time recording, and parking-count updates in a database transaction so related changes succeed or fail together.

---

## 7. Implementation Status and Verification

This document describes the intended role policy and a suggested PostgreSQL permission setup. It is not proof that every permission is already enforced in the current application or database.

Before treating the role policy as implemented, verify the following:

- The `staff_user.role` values created by `config/seed.php` match the role values checked by the PHP code.
- Administrator-only vehicle registration is enforced on the server, not only hidden in the interface.
- Staff cannot access Administrator-only actions by manually entering a URL or sending a direct request.
- The payment and exit endpoints require an authenticated, authorized user.
- The PHP database configuration uses the intended database account.
- PostgreSQL grants match the operations the actual PHP code performs.
- Payment and transaction history cannot be deleted through normal application functions.

If the application currently connects using `DB_USER = 'postgres'`, it is using the PostgreSQL superuser account shown in the existing setup guide. The dedicated `parkit_app` account described above is a recommended least-privilege configuration and must be created and configured before it can be used. Do not assume it already exists.

