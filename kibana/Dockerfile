ARG ELASTIC_VERSION=8.14.1

# https://www.docker.elastic.co/
FROM docker.elastic.co/kibana/kibana:${ELASTIC_VERSION}

# Add your kibana plugins setup here
# Example: RUN kibana-plugin install <name|url>

COPY kibana/ca.key /usr/share/elasticsearch/ca.key 
COPY kibana/ca.crt /usr/share/elasticsearch/ca.crt 

COPY kibana/config/kibana.yml /usr/share/kibana/config/kibana.yml
COPY /logstash/pipeline /usr/share/logstash/pipeline
