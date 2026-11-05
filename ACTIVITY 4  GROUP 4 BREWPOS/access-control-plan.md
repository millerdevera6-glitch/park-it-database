# BrewPOS – Database Access Control Plan

## 1. Project Overview

BrewPOS is a web-based Café Point-of-Sale (POS) system developed using Java Spring Boot and PostgreSQL. It allows café staff to manage menu items, process customer orders, and monitor daily sales.

This access control plan defines the database permissions assigned to each user role to protect business information and prevent unauthorized database operations.

**Database Name:** `grp_brewposdb`  
**Database Schema:** `public`  
**Database Management System:** PostgreSQL  
**Access Control Model:** Role-Based Access Control (RBAC)

## 2. Objectives

The objectives of this access control plan are:

- Restrict database access based on assigned responsibilities.
- Prevent unauthorized modification or deletion of records.
- Protect customer transaction and sales information.
- Apply the Principle of Least Privilege.
- Maintain the integrity and accuracy of historical sales records.

## 3. User Roles and Responsibilities

### 3.1 Store Manager (Administrator)

The Store Manager is responsible for managing the café's product catalog and monitoring business operations.

**Responsibilities:**
- Create, view, update, and delete menu categories.
- Create, view, update, and delete menu items.
- Modify product prices and availability.
- View completed orders and sales reports.
- Maintain menu information.

**Database Role:** `app_admin_grp`

### 3.2 Cashier

The Cashier handles customer transactions and daily order processing.

**Responsibilities:**
- View staff information.
- View available menu categories and products.
- Create customer orders.
- Add items to customer orders.
- View completed receipts.
- Record payment methods.

**Restrictions:**
- Cannot modify menu prices.
- Cannot delete menu categories or products.
- Cannot modify or delete completed transactions.

**Database Role:** `app_runtime_grp`

### 3.3 Viewer / Auditor

The Viewer or Auditor is responsible for inspecting business records and verifying transaction information.

**Responsibilities:**
- View staff records.
- View menu categories and products.
- View customer orders and order details.
- Review historical transaction records.
- Verify sales information.

**Restrictions:**
- Cannot insert new records.
- Cannot update existing records.
- Cannot delete database records.

**Database Role:** `app_readonly_grp`

## 4. Database Access Permissions

The following table presents the intended database permissions for each role.

| Database Table | Manager | Cashier | Auditor |
|---|---|---|---|
| staff | SELECT | SELECT | SELECT |
| menu_category | CRUD | SELECT | SELECT |
| menu_item | CRUD | SELECT | SELECT |
| order_ticket | SELECT | SELECT, INSERT | SELECT |
| order_line_item | SELECT | SELECT, INSERT | SELECT |

CRUD stands for Create, Read, Update, and Delete.

## 5. Database Role Configuration

The system uses PostgreSQL group roles to organize database permissions.

| Role Name | Role Type | Purpose |
|---|---|---|
| `app_admin_grp` | NOLOGIN | Manager access |
| `app_runtime_grp` | NOLOGIN | Cashier/application operations |
| `app_readonly_grp` | NOLOGIN | Auditor access |

Individual PostgreSQL login accounts can be assigned to the appropriate group roles.

The application uses a dedicated database service account named `brewpos_app`, which is assigned to `app_runtime_grp`.

## 6. Security Policies

The following security policies will be applied:

1. **Least Privilege:** Each database role receives only the permissions necessary to perform its responsibilities.
2. **Restricted Transaction Modification:** Completed orders and order details cannot be updated or deleted through the assigned application roles.
3. **Read-Only Access:** Auditors are only permitted to view database records.
4. **Credential Protection:** Database passwords must not be committed to public GitHub repositories.
5. **Role Separation:** Application responsibilities and PostgreSQL database permissions are managed separately.
6. **Database Integrity:** Existing transaction records must remain accurate and protected from unauthorized changes.

## 7. Access Control Testing

The following tests will be conducted to verify that database permissions work correctly.

| Test Case | Expected Result |
|---|---|
| Manager updates a menu item | Allowed |
| Manager views completed orders | Allowed |
| Cashier inserts a new order | Allowed |
| Cashier updates a menu item | Denied |
| Cashier deletes a completed order | Denied |
| Auditor views sales records | Allowed |
| Auditor inserts a new order | Denied |
| Auditor updates a menu item | Denied |

## 8. Conclusion

The BrewPOS access control plan establishes a role-based permission structure that protects the database and its records. By assigning specific privileges to the Store Manager, Cashier, and Viewer/Auditor, the system reduces unauthorized database operations and maintains the integrity of café transactions.

Implementing PostgreSQL Role-Based Access Control ensures that each user or application account can only perform operations permitted by its assigned database role.