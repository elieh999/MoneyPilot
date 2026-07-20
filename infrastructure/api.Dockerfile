FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONPATH=/workspace/services/api/src

RUN groupadd --system app && useradd --system --gid app --create-home app

WORKDIR /workspace

# The service requirements currently reference the shared financial-core package.
# Copy both before installing so editable/local project dependencies resolve.
COPY packages/financial_core_python/ packages/financial_core_python/
COPY services/api/ services/api/

WORKDIR /workspace/services/api
RUN python -m pip install --no-cache-dir --upgrade pip \
    && if [ -f requirements.txt ]; then \
         python -m pip install --no-cache-dir -r requirements.txt; \
       elif [ -f pyproject.toml ]; then \
         python -m pip install --no-cache-dir .; \
       else \
         echo "services/api requires requirements.txt or pyproject.toml" >&2; exit 1; \
       fi \
    && chown -R app:app /workspace

USER app
EXPOSE 8000

CMD ["uvicorn", "money_pilot_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
