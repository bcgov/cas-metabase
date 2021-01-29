FROM metabase/metabase:v0.37.8

RUN mkdir -p /home/metabase
COPY ./run_metabase.sh /app/run_metabase.sh
RUN chmod -R g+rwX /app /home/metabase
RUN chmod o+r /app/metabase.jar
RUN chmod g+w /etc/passwd