@echo off
rem Sobe a API (banco guiajovem_demo) e o app web em segundo plano. Ver README.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\iniciar-demo.ps1" %*
