FROM docker.io/metabase/metabase:v0.32.5

RUN apk update \
 && apk add curl jq \
 && rm -rf /var/cache/apk/*

RUN adduser --disabled-password --shell /bin/bash metabase
RUN chown metabase:metabase /app

USER metabase
# RUN mkdir -p /app/metabase.db
# ENV MB_DB_FILE=/app/metabase.db
WORKDIR /app
COPY run_metabase.sh run_metabase.sh

ENTRYPOINT []
CMD ["/app/run_metabase.sh"]

HEALTHCHECK  --interval=5m --timeout=3s \
  CMD curl -s http://localhost:3000/api/health | jq -e '.status | index("ok")' >/dev/null
