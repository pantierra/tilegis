# Tile-based-GIS

This is a simple showcase of a tile-based GIS for the talk on FOSS4G Europe 2024 in Tartu, Estonia. See this [blog post](https://felix.delattre.de/weblog/2023/12/19/tile-based-data-storage-and-visualization/) for more explanation.

## Install dependencies

* PostgreSQL and PostGIS
* Python 3 and PIP.
* pg_tileserv
* pip install dummy_data/requirements.txt

## Setup database

* Create database `tiles`.
* Run `database_functions.sql`on it.

## Generate dummy data

This may take a while.

* `python generate_dummy_data.py`

## Setup website

* Place files in `website` into some reachable webserver.
* Run `pg_tileserv`
