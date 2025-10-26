FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y bash fastqc wget awscli unzip default-jre && \
    ln -sf /bin/bash /usr/bin/bash && \
    rm -rf /var/lib/apt/lists/*

# Default shell but not forced ENTRYPOINT
CMD ["/bin/bash"]
