# vim: set filetype=dockerfile
ARG LIGHTSPEED_RAG_CONTENT_IMAGE=quay.io/openshift-lightspeed/lightspeed-rag-content@sha256:cbc9b0ea7c96fe400f2f8a8470976dd2c953c8e6239dc61b6aba2fad267363cd
ARG RAG_CONTENTS_SUB_FOLDER=vector_db/ocp_product_docs

FROM ${LIGHTSPEED_RAG_CONTENT_IMAGE} as lightspeed-rag-content

FROM registry.access.redhat.com/ubi9/ubi-minimal

ARG APP_ROOT=/app-root

RUN microdnf install -y --nodocs --setopt=keepcache=0 --setopt=tsflags=nodocs \
    python3.11 python3.11-devel python3.11-pip

# PYTHONDONTWRITEBYTECODE 1 : disable the generation of .pyc
# PYTHONUNBUFFERED 1 : force the stdout and stderr streams to be unbuffered
# PYTHONCOERCECLOCALE 0, PYTHONUTF8 1 : skip legacy locales and use UTF-8 mode
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONCOERCECLOCALE=0 \
    PYTHONUTF8=1 \
    PYTHONIOENCODING=UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off

WORKDIR /app-root

COPY --from=lightspeed-rag-content /rag/${RAG_CONTENTS_SUB_FOLDER} ${APP_ROOT}/${RAG_CONTENTS_SUB_FOLDER}
COPY --from=lightspeed-rag-content /rag/embeddings_model ./embeddings_model

# Add explicit files and directories
# (avoid accidental inclusion of local directories or env files or credentials)
COPY runner.py requirements.txt ./

RUN pip3.11 install --no-cache-dir -r requirements.txt

COPY ols ./ols

# this directory is checked by ecosystem-cert-preflight-checks task in Konflux
COPY LICENSE /licenses/

# Run the application
EXPOSE 8080
EXPOSE 8443
CMD ["python3.11", "runner.py"]

LABEL vendor="Red Hat, Inc."


# no-root user is checked in Konflux
USER 1001
