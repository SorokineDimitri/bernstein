FROM kicbase/stable:v0.0.50

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/local/bin/minikube \
        https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && chmod +x /usr/local/bin/minikube \
    && curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

WORKDIR /bernstein

RUN mkdir -p \
    db/postgres \
    db/redis \
    services/poll \
    services/result \
    services/worker \
    utils/cadvisor \
    utils/traefik

CMD ["bash"]
