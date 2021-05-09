FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
RUN dd if=/dev/zero of=1M.dummy bs=1M count=1
