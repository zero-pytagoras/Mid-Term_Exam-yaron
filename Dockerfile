FROM python:3.12-slim

RUN useradd -m dashboard # why no use this as app home ?

WORKDIR /app

COPY pyproject.toml poetry.lock* /app/

RUN pip install --no-cache-dir poetry \
    && poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

COPY app.py /app/

EXPOSE 5000

USER dashboard

CMD ["python", "app.py"]
