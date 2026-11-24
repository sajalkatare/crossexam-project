
@echo off
REM Run a Python file inside the lab Docker image.
REM Usage:
REM   run.bat check.py
REM   run.bat ladder/step1_one_agent.py demo-data/files/0002_bundle_scan.pdf

cd /d "%~dp0"

if not exist .env (
    copy /Y .env.example .env >nul
    echo Created .env: put your Gemini key in it
)

docker build -q -t crossexam-steps:lab . >nul

if errorlevel 1 (
    echo Docker build failed: is Docker Desktop running?
    exit /b 1
)

docker run --rm --env-file .env -v "%CD%:/app" -w /app -e PYTHONPATH=/app crossexam-steps:lab python %*
