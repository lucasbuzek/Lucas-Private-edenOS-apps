# Existing BIFROSTbridge MCP adapter from this repository; no duplicate core.
# Build context: BIFROST/. Official MCP SDK v2, not the nonexistent npm SSE package.
FROM python:3.12-slim AS base
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
RUN python -m pip install --no-cache-dir "mcp==2.3.0"
COPY headless/mcp_remote.py headless/mcp_remote_auth.py headless/shortcalls.py /app/headless/
COPY core/shortcalls.v1.json /app/core/shortcalls.v1.json
ENV PYTHONPATH=/app/headless
# Explicit test build: docker build --target test -f deploy/oci/Dockerfile .
FROM base AS test
COPY tests/test_mcp_remote_auth.py tests/test_mcp_remote_http.py /app/tests/
ENV BIFROST_REQUIRE_MCP_SDK=1
RUN python -m unittest discover -s /app/tests -p 'test_mcp_remote_auth.py' -v && \
    python -m unittest discover -s /app/tests -p 'test_mcp_remote_http.py' -v
# Production image does not include tests; never starts without verified OAuth env.
FROM base AS runtime
EXPOSE 8799
CMD ["python","-B","/app/headless/mcp_remote.py"]
