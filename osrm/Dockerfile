#
# --- Stage 1: Prepare OpenStreetMap data (download regions, merge and extract bounding box) ---
#
FROM debian:bookworm-slim AS data-prepare
ARG OSRM_REGIONS=
ARG OSRM_BOUNDING_BOX=
ARG OSRM_PROFILE=

# hadolint ignore=DL3008
RUN apt-get update && \
	apt-get install -y --no-install-recommends wget osmium-tool && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /data
COPY scripts/download-and-merge.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/download-and-merge.sh && \
    download-and-merge.sh "$OSRM_REGIONS" "$OSRM_BOUNDING_BOX"

#
# --- Stage 2: Build OSRM data files ---
#
FROM osrm/osrm-backend:${OSRM_VERSION} AS build
COPY --from=data-prepare /data/region.osm.pbf /data/region.osm.pbf

WORKDIR /data
RUN osrm-extract --profile /opt/${OSRM_PROFILE}.lua region.osm.pbf && \
    osrm-partition region.osrm && \
    osrm-customize region.osrm

# Cleanup (see https://github.com/Project-OSRM/osrm-backend/wiki/Toolchain-file-overview)
RUN rm -f \
	/data/*.osm.pbf \
	/data/*.cnbg \
	/data/*.cnbg_to_ebg \
	/data/*.ebg \
	/data/*.edge_penalties \
	/data/*.edge_segment_lookup \
	/data/*.enw \
	/data/*.level \
	/data/*.maneuver_overrides \
	/data/*.restrictions \
	/data/*.turn_penalties_index

#
# --- Stage 3: Run OSRM ---
#
ARG OSRM_VERSION="latest"
FROM osrm/osrm-backend:${OSRM_VERSION} AS final
COPY --from=build --chown=nobody /data /data
CMD ["osrm-routed", "--algorithm", "mld", "-p", "8080", "--max-table-size", "10000", "/data/region.osrm"]
EXPOSE 8080
