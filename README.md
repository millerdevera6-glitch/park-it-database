<<<<<<< HEAD
# BrewPOS — Café Point-of-Sale System

## 1. Overview

**BrewPOS** is a web-based Café Point-of-Sale (POS) application built with **Java Spring Boot** and **PostgreSQL**. It is designed to demonstrate relational database design, data integrity, and everyday café register operations.

### Main Features
- **Register:** Tap active menu items to build an order, adjust quantities, choose **Cash** or **Online**, and charge the order.
- **Menu:** Create and edit categories, add or update menu items, and activate or deactivate items on the register.
- **Orders:** Browse completed orders, filter by date, and open itemized receipts.
- **Daily Sales:** View daily net sales, total completed orders, and a **Cash vs. Online** breakdown.

### Tech Stack
- **Database:** PostgreSQL (`grp_brewposdb`, schema `public`)
- **Back End:** Java 17, Spring Boot 4.1.1, Spring Data JPA, Bean Validation
- **Front End:** HTML5, Bootstrap 5, CSS, and Vanilla JavaScript
- **Build Tool:** Included Maven Wrapper (`mvnw.cmd` / `./mvnw` — no separate Maven install required)

---

## 2. Project Documentation & Key Files

| Requirement | File Path | Purpose |
|---|---|---|
| **Setup & Run Guide** | [README.md](README.md) | Overview, prerequisites, installation, configuration, and how to run the app. |
| **Environment Template** | [.env.example](.env.example) | Sample configuration file (no real passwords included). |
| **Database Schema Script** | [database/schema.sql](database/schema.sql) | Creates the 5 database tables, keys, constraints, and indexes. |
| **Sample Data Seeder** | [database/seed.sql](database/seed.sql) | Inserts demo staff, categories, menu items, and sample orders for instant testing. |
| **Database Documentation** | [database/DATABASE_DOCUMENTATION.md](database/DATABASE_DOCUMENTATION.md) | Full guide to `grp_brewposdb`, tables, ERD, keys, constraints, and objects. |
| **User Roles & Security** | [docs/user-roles.md](docs/user-roles.md) | Detailed mapping of application roles to PostgreSQL database roles and privileges. |
| **SQL Scripts & DBA Guide** | [database/README.md](database/README.md) | Overview of all SQL scripts, database role setup, and backup/restore steps. |
| **Testing Walkthrough** | [TESTING_GUIDE.md](TESTING_GUIDE.md) | Easy checklist for testing all features in the browser and running automated tests. |

---

## 3. Prerequisites

Before setting up the project on your computer, make sure you have:

1. **Git** — to clone the repository.
2. **Java JDK 17 or newer** — verify by running `java -version` in your terminal.
3. **PostgreSQL (v16 or v18 recommended)** — running locally (default port `5432`), with **pgAdmin 4** or **`psql`** installed.
4. **Web Browser** — Chrome, Edge, Firefox, or Safari.
5. **Internet Connection (first run only)** — needed once so the project can download its Java libraries automatically.

---

## 4. Installation Steps (After Cloning from GitHub)

### Step 1: Clone the Repository
Open **PowerShell** (Windows) or **Terminal** (macOS/Linux) and run:

```bash
git clone <repository-url>
cd BrewPOS
```

---

### Step 2: Set Up the Database (`grp_brewposdb`)

Choose **either** **pgAdmin 4** (graphical interface) **or** **`psql`** (command line) below.

#### Option A: Using pgAdmin 4 (Recommended if you prefer a GUI)
1. Open **pgAdmin 4** and connect to your local PostgreSQL server.
2. Right-click **Databases** -> **Create** -> **Database...**, type **`grp_brewposdb`**, and click **Save**.
3. Right-click **`grp_brewposdb`** -> **Query Tool**:
   - Click the **Open File** icon, select **`database/schema.sql`**, and click **Execute (F5)** to create the tables.
   - Click **Open File** again, select **`database/seed.sql`**, and click **Execute (F5)** to load the starter menu, staff, and sample orders.
4. *(Optional DBA Role)* If you also want to test with the restricted `brewpos_app` database user instead of `postgres`, open and execute **`database/05_create_app_role.sql`**, then run:
   ```sql
   ALTER ROLE brewpos_app WITH PASSWORD 'your_chosen_password';
   ```

#### Option B: Using `psql` in Terminal

> **Windows Tip:** If PowerShell says `'psql' is not recognized`, run this first to add PostgreSQL to your current window (change `18` if you use another version):
> ```powershell
> $env:Path += ";C:\Program Files\PostgreSQL\18\bin"
> ```

Run these commands from inside the `BrewPOS` folder (enter your local `postgres` password when prompted):

```bash
# 1. Create the database
psql -U postgres -d postgres -c "CREATE DATABASE grp_brewposdb;"

# 2. Create the 5 tables, constraints, and indexes
psql -U postgres -d grp_brewposdb -f database/schema.sql

# 3. Load starter staff, categories, menu items, and sample orders
psql -U postgres -d grp_brewposdb -f database/seed.sql
```

*(Optional: To create and use the dedicated least-privilege `brewpos_app` role, also run:)*
```bash
psql -U postgres -d grp_brewposdb -f database/05_create_app_role.sql
psql -U postgres -d grp_brewposdb -c "\password brewpos_app"
```

---

## 5. Configuration (`.env` Setup)

BrewPOS reads your local database connection settings from a `.env` file in the project root.

### Step 3: Create Your `.env` File

1. Copy `.env.example` to a new file named `.env`:
   - **Windows (PowerShell):**
     ```powershell
     Copy-Item .env.example .env
     ```
   - **macOS / Linux:**
     ```bash
     cp .env.example .env
     ```

2. Open `.env` in any text editor and fill in your local PostgreSQL username and password:

   - **If using your local `postgres` user (simplest for quick testing):**
     ```dotenv
     DB_URL=jdbc:postgresql://localhost:5432/grp_brewposdb
     DB_USERNAME=postgres
     DB_PASSWORD=your_postgres_password
     SERVER_PORT=8081
     ```
   - **If using `brewpos_app` (after running `05_create_app_role.sql`):**
     ```dotenv
     DB_URL=jdbc:postgresql://localhost:5432/grp_brewposdb
     DB_USERNAME=brewpos_app
     DB_PASSWORD=your_brewpos_app_password
     SERVER_PORT=8081
     ```

| Variable | What It Does | Default |
|---|---|---|
| `DB_URL` | Connection URL to `grp_brewposdb` (change `5432` only if your PostgreSQL uses a different port). | `jdbc:postgresql://localhost:5432/grp_brewposdb` |
| `DB_USERNAME` | Your PostgreSQL username (`postgres` or `brewpos_app`). | `postgres` |
| `DB_PASSWORD` | Password for `DB_USERNAME`. | *(Required)* |
| `SERVER_PORT` | Port where the web app runs (`8081`). | `8081` |

*(Note: `.env` is listed in `.gitignore`, so your local password is never uploaded to GitHub.)*

---

## 6. How to Run the Application

### Step 4: Start the Server
Make sure your terminal is inside the `BrewPOS` folder, then run:

- **Windows (PowerShell):**
  ```powershell
  .\mvnw.cmd spring-boot:run
  ```
- **macOS / Linux:**
  ```bash
  chmod +x mvnw
  ./mvnw spring-boot:run
  ```

Wait until you see **`Started BrewPosApplication`** in the terminal (the very first run takes about 30–60 seconds while Maven downloads libraries).

### Step 5: Open BrewPOS in Your Browser
Go to:
- **http://localhost:8081**

What you can try right away:
- **Place an order:** On **Register**, click a few drinks or pastries, pick **Cash** or **Online**, and click **Charge**.
- **Manage the menu:** Use the **top-right dropdown** to switch from `Demo Cashier` to **`Demo Manager`**, then click **Menu** to add or edit categories and items.
- **Check receipts & reports:** Click **Orders** to open receipts, or **Daily Sales** to view sales totals.

To stop the server, press **`Ctrl+C`** in your terminal.

---

## 7. Common Troubleshooting

| Problem | How to Fix It |
|---|---|
| **`.\mvnw.cmd` is not recognized** | Make sure your terminal is inside the `BrewPOS` project folder (`cd path\to\BrewPOS`). |
| **`JAVA_HOME is not defined correctly`** | Install JDK 17+ and set `JAVA_HOME` in PowerShell before running:<br>`$env:JAVA_HOME = (Split-Path (Split-Path (Get-Command javac).Source))` |
| **`password authentication failed`** | Double-check `DB_USERNAME` and `DB_PASSWORD` inside your `.env` file. |
| **`Connection to localhost:5432 refused`** | Make sure PostgreSQL is running, and check if your PostgreSQL uses another port (like `5433`) in `DB_URL`. |
| **Port `8081` is already in use** | Change `SERVER_PORT=8082` in `.env`, restart the app, and open `http://localhost:8082`. |

---

## 8. Design Notes & Scope

- **Role Dropdown (No Login Screen):** Employee login/authentication is outside the project scope. Selecting `Demo Cashier` or `Demo Manager` in the top-right dropdown switches the UI view for classroom demonstration.
- **Accurate Historical Prices:** Order totals are never stored as a fixed column. Instead, each item's price at the moment of sale is saved in `order_line_item.sold_price`, and totals are calculated dynamically (`SUM(quantity * sold_price)`). Changing a menu price later will never change past receipts.
- **Academic Scope:** Features like taxes, discounts, inventory tracking, customer accounts, and order refunds are intentionally excluded to preserve the required 5-table database design.
=======
# Park-It Database Management System

## Project Overview

Park-It is a parking management system designed to help manage parking zones and monitor parking capacity using a PostgreSQL database.

The application uses Node.js, Express.js, and PostgreSQL to handle communication between the user interface and the database.

The current application includes the following implemented functions:

- Create new parking zones.
- View existing parking zones.
- Update parking zone names and maximum capacities.
- Delete parking zones.
- Monitor the number of occupied spaces.
- Record vehicle parking by increasing the occupied count.
- Prevent parking when a zone has reached its maximum capacity.

## Technologies Used

- **Frontend:** HTML, CSS, JavaScript
- **Backend:** Node.js and Express.js
- **Database:** PostgreSQL
- **Database Library:** node-postgres (`pg`)
- **Development Tools:** Visual Studio Code and pgAdmin 4

## Prerequisites

Before running the project, make sure the following are installed:

- Node.js and npm
- PostgreSQL
- pgAdmin 4 (optional, for managing the database)
- Git (for cloning the repository)

## Installation and Database Setup

Follow these steps to set up the project on your local machine.

### 1. Clone the Repository

Open your terminal and run:

```bash
git clone https://github.com/millerdereva6-glitch/park-it-database.git
```

Navigate to the project folder:

```bash
cd park-it-database
```

### 2. Create the Database

1. Open pgAdmin 4.
2. Connect to your PostgreSQL server.
3. Right-click **Databases** and select **Create > Database**.
4. Enter the database name:

```text
grp_parkitdb
```

5. Save the database.

### 3. Create the Database Tables

1. Select the `grp_parkitdb` database.
2. Open the Query Tool.
3. Open the `schema.sql` file from the project folder.
4. Execute the SQL commands.

This creates the database tables and relationships defined in the schema.

### 4. Insert Sample Data

1. Open the Query Tool again.
2. Open the `seed.sql` file.
3. Execute the SQL commands to insert the provided sample records.

Run `schema.sql` before `seed.sql`.

## Configuration

The application uses environment variables to connect to PostgreSQL.

1. Locate the `.env.example` file in the project folder.
2. Create a copy named `.env`.
3. Update the values using your local PostgreSQL credentials.

Example configuration:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=grp_parkitdb
DB_USER=your_database_username
DB_PASSWORD=your_database_password
PORT=3000
```

**Important:** Never upload your actual `.env` file to GitHub because it contains private database credentials.

The `.env.example` file should contain placeholder values only.

## Installing Dependencies

Open a terminal inside the project folder and execute:

```bash
npm install
```

>>>>>>> 51826a2bfd3cc618d5279dcd19c49cd906d92ae0
