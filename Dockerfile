# The lab image for steps 0 to 3: Python and the libraries. The code is mounted at run time, so you can edit a file and run it again.
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
COPY requirements-lab.txt .
RUN pip install -r requirements-lab.txt

