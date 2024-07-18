ARG  ELASTIC_VERSION=8.14.1

# https://www.docker.elastic.co/
FROM docker.elastic.co/logstash/logstash:${ELASTIC_VERSION}

# Add your logstash plugins setup here
# Example: RUN logstash-plugin install logstash-filter-json

COPY logstash/config/logstash.yml /usr/share/logstash/config/logstash.yml
COPY /logstash/pipeline /usr/share/logstash/pipeline
