# park-it-database# 

Park It Database Management System

## Project Overview
The "Park It" system is an automated 3-tier database application designed to log vehicle entries and exits, calculate parking fees based on duration, track real-time parking zone capacities, and securely verify payment statuses[cite: 92]. 

## Prerequisites
Before running this project, ensure you have the following installed on your local machine:
* **PostgreSQL 18.6** (or compatible version)
* pgAdmin 4 (for executing database scripts)
* [Insert your programming language here, e.g., Node.js or Python]

## Installation & Database Setup
Follow these steps to replicate the database environment on your local machine:

1. **Create the Database:**
   Open pgAdmin, right-click on your PostgreSQL 18 server, select **Create > Database**, and name it exactly `grp_parkitdb`[cite: 106, 107].
2. **Build the Schema:**
   Right-click `grp_parkitdb` and open the **Query Tool**. Open the `schema.sql` file provided in this repository, paste its contents into the Query Tool, and execute it. This will create the 5 required tables (`parking_zone`, `vehicle`, `staff_user`, `transaction`, `payment`)[cite: 106].
3. **Load Sample Data:**
   Clear the Query Tool, open the `seed.sql` file, paste its contents, and execute it. This populates the database with initial parking zones, dummy vehicle records, and sample staff accounts so you can test the system immediately[cite: 84].

## Configuration
This application requires environment variables to connect to the database securely[cite: 84].
1. Locate the `.env.example` file in the root folder of this repository[cite: 84].
2. Create a new file named `.env` in the exact same location.
3. Copy the contents of `.env.example` into your new `.env` file.
4. Replace the placeholder values with your actual local PostgreSQL credentials (e.g., set your specific database password). **Never commit this `.env` file to version control.**[cite: 84]

## Execution Instructions
1. Open your terminal or command prompt.
2. Navigate to the project folder.
3. Install the required dependencies by running: `[Insert command, e.g., npm install or pip install -r requirements.txt]`
4. Start the application by running: `[Insert command, e.g., npm start or python app.py]`

## Application User Roles
Below is the mapping of the roles used inside the application to their intended PostgreSQL database group roles[cite: 84].

| Application Role | Responsibilities in the application | Functions and data access | Intended database role |
| :--- | :--- | :--- | :--- |
| **Administrator** | Manages system settings, staff accounts, and views revenue reports. | Create, read, update, delete on `staff_user` and `parking_zone`; Read on `transaction` and `payment`. | `parkit_admin_grp` |
| **Parking Teller / Staff** | Processes payments and performs manual overrides for lost tickets. | Read on `parking_zone` and `vehicle`; Update on `transaction` (status) and Create on `payment`. | `parkit_teller_grp` |
| **Application Runtime** | The automated system account used by the backend code to connect to the database. | Executes queries required for logging vehicles in/out and calculating fees. | `parkit_runtime_grp` |

## Troubleshooting Guide
* **Error:** `Database grp_parkitdb does not exist.`
  * **Solution:** Ensure you completed Step 1 of the installation and that you are executing the `schema.sql` script specifically inside `grp_parkitdb`, not the default `postgres` database[cite: 84].
* **Error:** `Relation does not exist` when running `seed.sql`.
  * **Solution:** This means the tables weren't created properly. Re-run `schema.sql` first before attempting to insert the seed data[cite: 84].
* **Error:** `Connection refused` when starting the app.
  * **Solution:** Check your `.env` file to ensure the `DB_PORT` (usually 5432) and `DB_PASSWORD` match your local pgAdmin setup[cite: 84].
