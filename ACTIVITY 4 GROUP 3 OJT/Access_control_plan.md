# Access Control Plan – OJT Record Management System

## 1. Project Overview

The OJT Record Management System is designed to manage and monitor students' On-the-Job Training activities. It stores student records, training information, supervisor details, and OJT-related transactions.

## 2. Access Control Method

The system will use Role-Based Access Control (RBAC). Each database role will receive permissions based on its responsibilities.

## 3. User Roles and Permissions

| User Role | Access Permissions |
|---|---|
| Administrator | Full database access, including viewing, inserting, updating, and deleting records. |
| OJT Coordinator | View and manage OJT records and student information. |
| Academic Supervisor | View assigned student records and monitor OJT progress. |
| Company Supervisor | View assigned trainees and their OJT progress. |
| Student | View personal OJT records and submit required information. |

## 4. Security Policies

- Apply the principle of least privilege.
- Prevent unauthorized users from accessing restricted records.
- Separate permissions according to user responsibilities.
- Restrict database administration to authorized administrators.
- Regularly review assigned database privileges.

## 5. Expected Result

The access control implementation will provide organized database permissions and help protect confidential OJT records from unauthorized access.