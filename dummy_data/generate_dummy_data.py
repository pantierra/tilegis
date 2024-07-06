import mercantile
import numpy as np
import psycopg2
from noise import pnoise2
from shapely.geometry import shape

# Define the zoom level of the tiles to be generated
zoom_level = 16

# Define the geographical boundaries of Estonia (roughly)
aoi = shape(
    {
        "type": "Polygon",
        "coordinates": [
            [
                [21.8323, 57.5167],
                [28.2096, 57.5167],
                [28.2096, 59.8694],
                [21.8323, 59.8694],
                [21.8323, 57.5167],
            ]
        ],
    }
)


# Function to get the tiles covering the area at a specific zoom level
def get_tiles(aoi, zoom):
    bounds = aoi.bounds
    tiles = mercantile.tiles(bounds[0], bounds[1], bounds[2], bounds[3], zoom)
    return list(tiles)


# Function to convert tile to quadkey
def tile_to_quadkey(tile):
    return mercantile.quadkey(tile)


# Function to normalize noise values to [0, 1] range
def normalize(value, min_value, max_value):
    return (value - min_value) / (max_value - min_value)


# Get tiles covering the area
tiles = get_tiles(aoi, zoom_level)

# Generate Perlin noise values for each tile
scale = 100.0
octaves = 6
persistence = 0.5
lacunarity = 2.0

# Collect noise values
noise_values = {}
min_noise = float("inf")
max_noise = float("-inf")

for tile in tiles:
    x, y = tile.x, tile.y
    noise_value = pnoise2(
        x / scale,
        y / scale,
        octaves=octaves,
        persistence=persistence,
        lacunarity=lacunarity,
    )
    noise_values[(x, y)] = noise_value
    min_noise = min(min_noise, noise_value)
    max_noise = max(max_noise, noise_value)

# Normalize the noise values to [0, 1] range
normalized_noise_values = {
    k: normalize(v, min_noise, max_noise) for k, v in noise_values.items()
}

# Map tiles to quadkeys with normalized noise values
quadkeys_with_noise = {
    tile_to_quadkey(tile): normalized_noise_values[(tile.x, tile.y)] for tile in tiles
}

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    dbname="tiles", user="user", password="password", host="localhost"
)
cur = conn.cursor()
conn.autocommit = True

# Execute the CREATE DATABASE command
try:
    cur.execute("CREATE DATABASE tiles")
    print("Database created successfully.")
except psycopg2.errors.DuplicateDatabase:
    print("Database already exists.")
except Exception as e:
    print(f"An error occurred: {e}")

cur.execute(
    """CREATE TABLE IF NOT EXISTS tiles (
        quadkey VARCHAR(255) PRIMARY KEY,
        value FLOAT NOT NULL
    );"""
)

# Insert data into the database
for quadkey, noise_value in quadkeys_with_noise.items():
    cur.execute(
        "INSERT INTO tiles (quadkey, value) VALUES (%s, %s) ON CONFLICT (quadkey) DO NOTHING",
        (quadkey, noise_value),
    )

cur.close()
conn.close()

print("Data inserted into the database successfully.")
