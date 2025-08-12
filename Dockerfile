FROM ubuntu:noble
ARG DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
WORKDIR /app
RUN chown nobody /app && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y bash libstdc++6 openssl libncurses6 locales ca-certificates && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
COPY --chown=nobody:root ./_build/prod/rel/ex_automation/ ./
USER nobody
RUN mkdir data
SHELL ["bash", "-c"]
CMD ["/app/bin/server"]
