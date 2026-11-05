-- Create application account
CREATE ROLE lostandfound_app
WITH LOGIN PASSWORD 'YOUR_LOCAL_PASSWORD';

-- Create public account
CREATE ROLE lostandfound_public
WITH LOGIN PASSWORD 'YOUR_LOCAL_PASSWORD';