@echo off
cd /d "C:\users\matheus\desktop\Projetos\finfamily\finfamily\build\web"
start "" http://localhost:8085
python -m http.server 8085