@echo off
Powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass', '-File .\FocusHide.ps1' -NoNewWindow"