ARG ELASTIC_VERSION=8.14.1

# Base image
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}



# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu

# Copy setup scripts and roles into the container

COPY elasticsearch/setup /usr/local/user_setup

USER root
RUN chmod +x /usr/local/user_setup/update_config.sh

# Run as elasticsearch
USER elasticsearch

