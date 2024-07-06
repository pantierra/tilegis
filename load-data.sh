# Shortcuts to load all data in PostGIS DB in Docker Container
# NB the docker-compose stack must be running !
#

# Load example tile information
docker-compose exec database sh -c "apt update && apt install python3 python3-pip"
docker-compose exec database sh -c "pip install -r /work/requirements.txt"
docker-compose exec database sh -c "cp /work/generate_dummy_data.py ."
docker-compose exec database sh -c "python3 generate_dummy_data.py"


# Load SQL functions
cp database_functions.sql ./data/
docker-compose exec database sh -c "cat database_functions.sql | psql -U user -d tiles"
rm ./data/database_functions.sql
