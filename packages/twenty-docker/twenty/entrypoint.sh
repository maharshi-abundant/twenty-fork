#!/bin/sh
set -e

setup_and_migrate_db() {
    if [ "${DISABLE_DB_MIGRATIONS}" = "true" ]; then
        echo "Database setup and migrations are disabled, skipping..."
        return
    fi

    echo "Running database setup and migrations..."
    PGUSER=$(echo $PG_DATABASE_URL | awk -F '//' '{print $2}' | awk -F ':' '{print $1}')
    PGPASS=$(echo $PG_DATABASE_URL | awk -F ':' '{print $3}' | awk -F '@' '{print $1}')
    PGHOST=$(echo $PG_DATABASE_URL | awk -F '@' '{print $2}' | awk -F ':' '{print $1}')
    PGPORT=$(echo $PG_DATABASE_URL | awk -F ':' '{print $4}' | awk -F '/' '{print $1}')
    PGDATABASE=$(echo $PG_DATABASE_URL | awk -F '/' '{print $NF}' | cut -d'?' -f1)

    # Creating the database if it doesn't exist
    db_count=$(PGPASSWORD=${PGPASS} psql -h ${PGHOST} -p ${PGPORT} -U ${PGUSER} -d postgres -tAc "SELECT COUNT(*) FROM pg_database WHERE datname = '${PGDATABASE}'")
    if [ "$db_count" = "0" ]; then
        echo "Database ${PGDATABASE} does not exist, creating..."
        PGPASSWORD=${PGPASS} psql -h ${PGHOST} -p ${PGPORT} -U ${PGUSER} -d postgres -c "CREATE DATABASE \"${PGDATABASE}\""

        # Run setup and migration scripts
        NODE_OPTIONS="--max-old-space-size=1500" tsx ./scripts/setup-db.ts
        yarn database:migrate:prod
    fi
    
    yarn command:prod upgrade
    echo "Successfully migrated DB!"
}

register_background_jobs() {
    if [ "${DISABLE_CRON_JOBS_REGISTRATION}" = "true" ]; then
        echo "Cron job registration is disabled, skipping..."
        return
    fi
  
    echo "Registering background sync jobs..."
    if yarn command:prod cron:register:all; then
        echo "Successfully registered all background sync jobs!"
    else
        echo "Warning: Failed to register background jobs, but continuing startup..."
    fi
}

wait_for_dependencies() {
    echo "Waiting for dependencies to be ready..."
    
    # Wait for database
    if [ -n "$PG_DATABASE_URL" ]; then
        echo "Waiting for database connection..."
        PGUSER=$(echo $PG_DATABASE_URL | awk -F '//' '{print $2}' | awk -F ':' '{print $1}')
        PGPASS=$(echo $PG_DATABASE_URL | awk -F ':' '{print $3}' | awk -F '@' '{print $1}')
        PGHOST=$(echo $PG_DATABASE_URL | awk -F '@' '{print $2}' | awk -F ':' '{print $1}')
        PGPORT=$(echo $PG_DATABASE_URL | awk -F ':' '{print $4}' | awk -F '/' '{print $1}')
        
        until PGPASSWORD=${PGPASS} psql -h ${PGHOST} -p ${PGPORT} -U ${PGUSER} -d postgres -c '\q' 2>/dev/null; do
            echo "Database is unavailable - sleeping"
            sleep 2
        done
        echo "Database is up - continuing"
    fi
    
    # Wait for Redis if configured
    if [ -n "$REDIS_URL" ]; then
        echo "Waiting for Redis connection..."
        until redis-cli -u "$REDIS_URL" ping 2>/dev/null; do
            echo "Redis is unavailable - sleeping"
            sleep 2
        done
        echo "Redis is up - continuing"
    fi
}

setup_and_migrate_db
register_background_jobs
wait_for_dependencies

# Add a small delay to ensure everything is properly initialized
echo "Application startup complete, waiting 5 seconds before starting server..."
sleep 5

# Continue with the original Docker command
exec "$@"
