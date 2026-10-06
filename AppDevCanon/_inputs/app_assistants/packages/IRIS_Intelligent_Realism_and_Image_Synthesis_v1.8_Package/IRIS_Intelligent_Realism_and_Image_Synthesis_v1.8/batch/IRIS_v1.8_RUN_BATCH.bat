@echo off
set "HERE=%~dp0"
where py >nul 2>nul && (py -3 "%HERE%IRIS_v1.8_BATCH_RUNNER.py" %* & exit /b %errorlevel%)
python "%HERE%IRIS_v1.8_BATCH_RUNNER.py" %*
