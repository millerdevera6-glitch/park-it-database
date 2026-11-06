# 🅿️ Park It — Database Management System

**Installation and User Guide**

Park It is a web-based parking management system built with **PHP** and **PostgreSQL 18.6**. This guide walks you through setting up the database, starting the application, and using its main features.

> **Before you begin:** You will need the project folder, the provided `schema.sql` file, PostgreSQL 18.6, and XAMPP installed on your computer.

---

## 📑 Table of Contents

- [1. About Park It](#1-about-park-it)
- [2. Required Software](#2-required-software)
- [3. Database Setup](#3-database-setup)
- [4. Project Setup](#4-project-setup)
- [5. Start Park It](#5-start-park-it)
- [6. Using the System](#6-using-the-system)
- [7. Troubleshooting](#7-troubleshooting)
- [8. Stop the System](#8-stop-the-system)

---

## 1. About Park It

Park It helps staff manage vehicle entry, parking payments, vehicle exits, and parking-space availability.

### Main features

- **Vehicle entry:** Records a vehicle's license plate, vehicle type, and entry time.
- **Parking fees:** Calculates the parking fee based on how long the vehicle has been parked.
- **Lost-ticket fee:** Applies a flat **₱200.00** fee when a parking ticket is lost.
- **Payment records:** Saves payments and marks parking transactions as completed.
- **Live parking monitor:** Tracks **50 parking spaces** and displays warnings when spaces are running low or the parking lot is full.

## 2. Required Software

Install these programs before setting up Park It.

| Software | What it is used for |
|---|---|
| **PostgreSQL 18.6** | Stores vehicle details, parking records, staff accounts, and payments. |
| **pgAdmin 4** | A graphical tool included with PostgreSQL for managing the database. |
| **XAMPP** | Runs Apache and PHP so you can use Park It in a web browser. |
| **Web browser** | Use Google Chrome, Microsoft Edge, or Mozilla Firefox. |
| **Notepad** | Opens the project settings file so you can enter your PostgreSQL password. |

---

## 3. Database Setup

> ⚠️ **Important:** Use the provided database file as it is. Do not add, remove, or change any database tables or columns.

### Step 1 — Open pgAdmin 4

1. Click the Windows **Start** button.
2. Type **pgAdmin 4**, then open it.
3. Wait for pgAdmin 4 to load.
4. In the left panel, click the arrow beside **Servers**.
5. Click **PostgreSQL 18**.
6. Enter your PostgreSQL superuser password (`postgres`) if prompted, then click **OK**.

### Step 2 — Create the Park It database

1. In the left panel, find **PostgreSQL 18**.
2. Right-click **Databases**.
3. Select **Create → Database**.
4. In the **Database** name field, enter this exact name:

   `grp_parkitdb`

5. Leave **Owner** set to `postgres`.
6. Click **Save**.

### Step 3 — Open the provided SQL file

1. Select `grp_parkitdb` in the left panel.
2. From the top menu, click **Tools → Query Tool**.
3. In the Query Tool toolbar, click the **Open File** icon (folder icon).
4. Find and select the provided file named `schema.sql`.
5. Click **Open**.

### Step 4 — Prepare and run the SQL file

1. Check the beginning of the SQL script. If there is a line starting with `\restrict`, delete that line.
2. Check the end of the script. If there is a line starting with `\unrestrict`, delete that line.
3. These lines are intended for command-line tools and can cause an error in the pgAdmin Query Tool.
4. Click **Execute script** (the Play button) or press **F5**.
5. Wait for the message **Query returned successfully** in the bottom panel.

### Step 5 — Confirm that the tables were created

1. In the left panel, expand `grp_parkitdb`.
2. Expand **Schemas**, then **public**.
3. Right-click **Tables** and select **Refresh**.
4. Expand **Tables**.
5. Confirm that these five tables appear:

   - `parking_zone`
   - `payment`
   - `staff_user`
   - `transaction`
   - `vehicle`

---

## 4. Project Setup

### Step 6 — Copy the project into XAMPP

1. Find the project folder named `park-it`.
2. Open **File Explorer**.
3. Go to `C:\xampp\htdocs`.
4. Copy the entire `park-it` folder into `htdocs`.

Your project folder should be here:

`C:\xampp\htdocs\park-it`

> **Check the folder location:** Make sure the project is not accidentally inside another `park-it` folder.

### Step 7 — Enable PostgreSQL support in XAMPP

PHP needs its PostgreSQL extensions enabled to connect to your database. This is usually a one-time setup.

1. Open the **XAMPP Control Panel**.
2. Find the **Apache** row and click its **Config** button.
3. Select **PHP (php.ini)**. The file should open in Notepad.
4. Press **Ctrl + F**, search for `pdo_pgsql`, and press **Enter**.
5. Find these two lines:

   ```ini
   ;extension=pdo_pgsql
   ;extension=pgsql
   ```

6. Remove the semicolon (`;`) at the start of each line. They should look like this:

   ```ini
   extension=pdo_pgsql
   extension=pgsql
   ```

7. In Notepad, click **File → Save**.
8. Close Notepad.

### Step 8 — Set the database connection details

1. Open this folder:

   `C:\xampp\htdocs\park-it\config`

2. Right-click `database.php` and choose **Open with → Notepad**.
3. Find the database settings. They should look like this:

   ```php
   define('DB_HOST', 'localhost');
   define('DB_PORT', '5432');
   define('DB_NAME', 'grp_parkitdb');
   define('DB_USER', 'postgres');
   define('DB_PASS', 'your_postgres_password');
   ```

4. Replace `your_postgres_password` with the password you created for PostgreSQL. Keep the single quotes around the password.
5. Leave the other settings as shown:

   | Setting | Value |
   |---|---|
   | Host | `localhost` |
   | Port | `5432` |
   | Database name | `grp_parkitdb` |
   | Username | `postgres` |
   | Password | Your PostgreSQL password |

6. Click **File → Save**, then close Notepad.

---

## 5. Start Park It

### Step 9 — Start Apache

1. Open the **XAMPP Control Panel**.
2. Find the **Apache** row.
3. Click **Start**.
4. Wait until Apache is highlighted in green.

### Step 10 — Run the first-time setup

> **Do this once before your first login.** This setup creates the Main Parking Lot with 50 spaces and the default staff accounts.

1. Open your web browser.
2. Enter this address in the address bar:

   `http://localhost/park-it/config/seed.php`

3. Press **Enter**.
4. Look for the message:

   **Database initialization completed successfully.**

This step initializes the parking zone and default accounts.

### Step 11 — Open the login page

After the setup is complete, open:

`http://localhost/park-it/`

You should be taken to the Park It login page. The direct login address is:

`http://localhost/park-it/auth/login.php`

---

## 6. Using the System

### Log in

Use one of the default accounts created by the setup script. The default passwords below are the values described in `config/seed.php`.

| Account | Username | Default password |
|---|---|---|
| Administrator | `admin` | `admin123` |
| Staff | `staff` | `staff123` |

Enter the username and password on the login page, then click **Sign In**.

### Module 1 — Register a vehicle

1. Click **Module 1: Vehicles & Entry** in the top navigation bar.
2. Under **Register Incoming Vehicle**, enter the vehicle's license plate number. Example: `ABC-1234`.
3. Select the vehicle type: **Car** or **Motorcycle**.
4. Select **Main Parking Lot** as the parking zone.
5. Click **Record Vehicle Entry**.

The system records the entry time, creates an active transaction, and increases the occupied-space count by one.

**To edit a vehicle:** Find it in the **Registered Vehicles Directory** and click **Edit**.

**To delete a vehicle:** Click **Delete**. Vehicles that already have parking transactions are marked **Protected** and cannot be deleted.

### Module 2 — Process payment and vehicle exit

1. Click **Module 2: Payment & Exit** in the top navigation bar.
2. Enter the vehicle's license plate in **Search Active Vehicle** and click **Search Active Transaction**. You can also click **Select** beside a vehicle in the **Currently Parked Vehicles** table.
3. Review the parking details and the amount due.
4. Select a payment method: **Cash, GCash, Maya, or Credit/Debit Card**.
5. Click **Record Payment & Authorize Vehicle Exit**.
6. Click **OK** on the confirmation message.

The system saves the payment, records the exit time, marks the transaction as completed, and decreases the occupied-space count by one.

#### Parking fee rates

| Vehicle type | First 3 hours | Each succeeding hour |
|---|---:|---:|
| Car | ₱50.00 | +₱10.00 |
| Motorcycle | ₱30.00 | +₱10.00 |

#### Handle a lost ticket

1. Search for and select the vehicle in **Module 2: Payment & Exit**.
2. Click **Mark as Lost Ticket (200.00)** above the fee summary.
3. The system replaces the regular parking fee with a flat **₱200.00** fee.
4. If the driver finds the ticket before paying, click **Revert to Regular Fee**.
5. Select the payment method and click **Record Payment & Authorize Vehicle Exit**.

### Module 3 — Monitor parking availability

1. Click **Module 3: Live Monitoring** in the top navigation bar.
2. View the parking information displayed at the top of the page:
   - Total parking capacity
   - Occupied parking spaces
   - Available parking spaces
   - Number of active vehicles
   - Parking availability status

The monitoring page updates automatically every **3 seconds**. You do not need to refresh the browser.

| Parking condition | What the system does |
|---|---|
| 10 or fewer spaces available | Displays a yellow warning. |
| All 50 spaces occupied | Displays a red full-capacity warning and blocks new vehicle entries. |
| More than 10 spaces available again | Automatically removes the low-space warning. |

### Log out

1. Go to the top-right corner of any page.
2. Click the red **Logout** button.

---

## 7. Troubleshooting

Use the solutions below if you encounter a problem.

### 1. Database connection error: `could not find driver`

**Cause:** The PHP PostgreSQL extensions are still disabled in XAMPP.

**Solution:** Repeat [Step 7](#step-7--enable-postgresql-support-in-xampp). Make sure the semicolons are removed from `extension=pdo_pgsql` and `extension=pgsql`. Save `php.ini`, then restart Apache.

### 2. `password authentication failed for user "postgres"`

**Cause:** The password in `config/database.php` does not match your PostgreSQL password.

**Solution:** Open `C:\xampp\htdocs\park-it\config\database.php` in Notepad. Enter the correct password inside the single quotes for `DB_PASS`, then save the file.

### 3. `database "grp_parkitdb" does not exist`

**Cause:** The database was not created, or its name was entered incorrectly.

**Solution:** Return to pgAdmin 4 and follow [Steps 2–4](#step-2--create-the-park-it-database) to create `grp_parkitdb` and run `schema.sql`.

### 4. `Connection refused (port 5432)`

**Cause:** The PostgreSQL service is not running.

**Solution:**

1. Press **Windows key + R**.
2. Type `services.msc` and press **Enter**.
3. Find `postgresql-x64-18` in the list.
4. Right-click it and select **Start**.

### 5. Apache will not start in XAMPP

**Cause:** Another program may be using port 80 or 443, or Apache may already be running.

**Solution:** Close other web-server programs, such as Skype or IIS. You can also run the XAMPP Control Panel as Administrator and try starting Apache again.

### 6. `Object not found!` or a 404 error in the browser

**Cause:** The project folder may be in the wrong location or may have an incorrect folder structure.

**Solution:** Check that the project files are directly inside:

`C:\xampp\htdocs\park-it`

Make sure the folder is not nested inside a second `park-it` folder.

### 7. `No parking zones are configured yet`

**Cause:** The first-time setup script has not been run.

**Solution:** Open this address in your browser once:

`http://localhost/park-it/config/seed.php`

The script creates the 50-space parking zone and the default staff accounts.

---

## 8. Stop the System

1. Log out of Park It and close the browser tab.
2. Open the **XAMPP Control Panel**.
3. Click **Stop** beside Apache.
4. Wait until the green Apache highlight disappears.
5. Close the XAMPP Control Panel.

> **Note:** You do not need to stop PostgreSQL 18.6. It can continue running in the background so the database is ready the next time you use Park It.

---

**Park It — Installation and User Guide**  
*Database: PostgreSQL 18.6 · Backend: PHP · Local server: Apache (XAMPP)*
