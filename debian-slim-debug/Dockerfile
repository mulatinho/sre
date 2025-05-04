# Debug image used by me to troubleshooting
# Last update: 2025/05/04
FROM debian:bullseye-slim

RUN apt-get update -y \
    && apt-get install -y bash ca-certificates netcat-openbsd curl wget bind9-dnsutils net-tools iproute2 dnsutils iputils-ping tmux git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN addgroup --system mlt && adduser --system --ingroup mlt mlt

USER mlt

ENTRYPOINT [ "/bin/bash" ]

LABEL org.opencontainers.image.title="debian-slim-debug" \
      org.opencontainers.image.description="A lightweight image to doing troubleshooting in Kubernetes." \
      org.opencontainers.image.authors="Alexandre Mulatinho <alex@livredigital.com>" \
      org.opencontainers.image.version="1.0.1" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/mulatinho/sre/debian-slim-debug" \
      org.opencontainers.image.documentation="https://mulatinho.net/posts/debian-slim-debug"
