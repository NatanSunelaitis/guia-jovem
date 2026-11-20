@echo off
rem Para a API e o app iniciados pelo iniciar-demo.cmd. Ver README.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\parar-demo.ps1" %*
