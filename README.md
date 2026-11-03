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

