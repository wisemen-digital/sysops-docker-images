#!/bin/sh
set -eux

OSM_BASE="http://download.geofabrik.de"
OSRM_REGIONS="$1"   # space-separated
OSRM_BOUNDING_BOX="$2" # minlon,minlat,maxlon,maxlat

files=""
for region in $OSRM_REGIONS; do
  name="$(basename "$region")"
  file="${name}.pbf"

  wget --quiet -O "$file" \
    "$OSM_BASE/${region}-latest.osm.pbf"

  files="$files $file"
done

osmium merge $files -o merged.osm.pbf
osmium extract -b "$OSRM_BOUNDING_BOX" merged.osm.pbf -o region.osm.pbf
