---- Generates vector tiles with values from the `tiles` database table.

CREATE OR REPLACE FUNCTION public.generate_obm_vector_tiles(
    z INTEGER, x INTEGER, y INTEGER
)
RETURNS BYTEA AS
$$
    DECLARE
        vector_tile BYTEA DEFAULT '';
        parent_quadkey TEXT;
        inside_tiles INTEGER; -- Number of tiles at zoom level 16 on an axis of a tile with zoom level `z`.
        inside_tile_pixels INTEGER;
    BEGIN
        IF z > 16 THEN
            RAISE NOTICE 'Vector tiles cannot be be created for zoom levels higher than 16.';
        ELSE
            parent_quadkey = convert_xyz_to_quadkey(x, y, z);
            inside_tiles = 2 ^ (16 - z);
            inside_tile_pixels = 4096 / inside_tiles;
            WITH mvtdata AS (
                SELECT ST_MakeEnvelope(
                    inside_tile_pixels * tile_x, inside_tile_pixels * tile_y,
                    inside_tile_pixels * (tile_x + 1), inside_tile_pixels * (tile_y + 1)
                ) AS geom,
                tiles.*
                FROM
                    tiles tiles,
                    generate_series(0, inside_tiles - 1) AS tile_x,
                    generate_series(0, inside_tiles - 1) AS tile_y
                WHERE tiles.quadkey
                    = parent_quadkey || convert_xyz_to_quadkey(tile_x, tile_y, 16 - z)
            )
            SELECT ST_AsMVT(mvtdata.*, 'tiles', 4096, 'geom')
            FROM mvtdata INTO vector_tile;
        END IF;
        RETURN vector_tile;
    END;
$$
LANGUAGE plpgsql STABLE PARALLEL SAFE;

---- Converts a tile identifier from the format x,y,z to a Quadkey.

CREATE OR REPLACE FUNCTION public.convert_xyz_to_quadkey(
    x INTEGER, y INTEGER, z INTEGER
)
RETURNS TEXT AS
$$
    DECLARE
        quadkey TEXT;
        quadkey_digit INTEGER;
        rx INTEGER;
        ry INTEGER;
    BEGIN
        FOR i IN 1..z LOOP
            rx = x % 2;
            x = x / 2;
            ry = y % 2;
            y = y / 2;
            IF rx = 0 AND ry = 0 THEN
                quadkey_digit = 0;
            ELSIF rx = 1 AND ry = 0 THEN
                quadkey_digit = 1;
            ELSIF rx = 0 AND ry = 1 THEN
                quadkey_digit = 2;
            ELSIF rx = 1 AND ry = 1 THEN
                quadkey_digit = 3;
            ELSE
                RAISE EXCEPTION 'Failure converting xyz to Quadkey';
            END IF;
            quadkey = CONCAT(CAST(quadkey_digit AS CHAR), quadkey);
        END LOOP;
        RETURN quadkey;
    END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
