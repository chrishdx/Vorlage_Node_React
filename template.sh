#!/bin/bash

projekt_folder="/workspace/Projekte/Node+React"
# Prüfe, ob ein Argument übergeben wurde.
if [ -z "$1" ]; then
    echo -n "Bitte geben Sie den Namen des zu erstellenden Ordners ein: "
    read project_name
else
    project_name="$1"
fi

# Überprüfen, ob der Ordner bereits existiert.
if [ -d "$project_name" ]; then
    echo "Ein Ordner mit dem Namen '$project_name' existiert bereits."
    exit 1
fi

# Überprüfen, ob der Ordnername mit Docker-Tags kompatibel ist.
if [[ ! "$project_name" =~ ^[a-z0-9]([a-z0-9._-]{0,126}[a-z0-9])?$ ]]; then
    echo "Der Ordnername '$project_name' ist nicht mit Docker-Tags kompatibel."
    exit 1
fi

# Überprüfen, ob der Ordnername einen gültigen Domainnamen darstellt.
if [[ "$project_name" =~ _ ]]; then
    echo "Der Ordnername '$project_name' enthält einen Unterstrich, der in Domainnamen nicht zulässig ist."
    exit 1
fi

# Frage nach der Version (1 für light oder 2 für full)
if [ -z "$2" ]; then
    echo "Wählen Sie eine Version:"
    echo "1. Light"
    echo "2. Full"
    read -p "Geben Sie die Nummer der gewünschten Version ein (1 oder 2): " version_choice
else
    version_choice="$2"
fi

# Überprüfe die Auswahl und setze die Version entsprechend.
if [ "$version_choice" == "1" ]; then
    version="light"
elif [ "$version_choice" == "2" ]; then
    version="full"
else
    echo "Ungültige Auswahl. Bitte wählen Sie 1 für Light oder 2 für Full."
    exit 1
fi

cd "$projekt_folder"

# Erstellung des Projekthauptordners und der Unterordner "frontend" und "backend".
mkdir "$project_name"
cd "$project_name"
mkdir frontend backend

# Einrichtung einer React-App im "frontend"-Ordner.
cd frontend
npx create-react-app my_app --template cra-template-pwa
cd my_app

# Einrichtung von Axios und React-Tabs.
npm install axios react-tabs

# Anpassung des "package.json"-Files.
sed -i 's/"start": "react-scripts start"/"start": "PORT=3033 react-scripts start"/' package.json
sed -i '$!b;n;s/}/,\n  "proxy": "http:\/\/127.0.0.1:507"\n}/' package.json

cd ../../backend

# Einrichtung einer Node.js-App mit Express.
npm init -y
npm install express

# Rückkehr zum Hauptverzeichnis.
cd ..

# Erstellung der ".dockerignore"-Datei und einer Dummy-Datei.
echo "backend/node_modules" > .dockerignore
echo "console.log('fertig');" > dummy.js

if [ "$version" == "full" ]; then
    # Erstellung der index.js-Datei für den Express-Server (Full Version).
    cat <<EOT >> backend/index.js
const express = require('express');
const app = express();
const PORT = 507;

app.listen(PORT, () => {
    console.log('Server is running on port ' + PORT);
});
EOT

    # Dockerfile für die Full-Version.
    cat <<EOT >> Dockerfile
# Bauphase für React-App
FROM node:latest AS build
ARG NODE_VERSION
WORKDIR /app
COPY ./frontend ./frontend
WORKDIR /app/frontend/my_app
RUN npm install -g n && \
    n \$NODE_VERSION
RUN npm install
RUN npm run build

# Produktionsphase
FROM nginx:latest
ARG NODE_VERSION

# Kopieren des React-Builds
COPY --from=build /app/frontend/my_app/build  /var/www/html

# Backend kopieren
WORKDIR /usr/src/app
COPY ./backend ./backend

# Node.js und npm manuell installieren
RUN apt-get update && \
    apt-get install -y curl xz-utils nodejs npm && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g n && \
    n \$NODE_VERSION

COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/src/app/backend
# npm-Abhängigkeiten für das Backend installieren
RUN npm install

# Startkommando
CMD sh -c "nginx -g 'daemon off;' & node index.js"
EOT

    # Erstellung der default.conf für den Reverse-Proxy.
    cat <<EOT >> default.conf
server { 
 listen 80;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;

        location / {
    if ( \$uri = '/index.html' ) {
      add_header Cache-Control no-store always;
    }
    try_files \$uri \$uri/ /index.html;
  }

# Do not cache sw.js, required for offline-first updates.
  location /sw.js {
      add_header Cache-Control "no-cache";
      proxy_cache_bypass \$http_pragma;
      proxy_cache_revalidate on;
      expires off;
      access_log off;
  }
 
 location /api {
   proxy_set_header X-Real-IP \$remote_addr;
   proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
   proxy_set_header X-NginX-Proxy true;
   proxy_pass http://127.0.0.1:507;
   proxy_set_header Host \$http_host;
   proxy_cache_bypass \$http_upgrade;
   proxy_redirect off;
 }
}
EOT

else
    # Erstellung der index.js-Datei für den Express-Server (Light Version).
    cat <<EOT >> backend/index.js
const express = require('express');
const app = express();
const PORT = 507;
const fs = require('fs');
const path = require('path');

// Prüfe ob es den Ordner "React" gibt
if (fs.existsSync(path.join(__dirname, 'React'))) {
    app.use(express.static(path.join(__dirname, 'React')));
}

app.listen(PORT, () => {
    console.log('Server is running on port ' + PORT);
});
EOT

    # Dockerfile für die Light-Version.
    cat <<EOT >> Dockerfile
# Bauphase für React-App
FROM node:latest AS build
ARG NODE_VERSION
WORKDIR /app
COPY ./frontend ./frontend
WORKDIR /app/frontend/my_app
RUN npm install -g n && \
    n \$NODE_VERSION
RUN npm install
RUN npm run build

# Produktionsphase
FROM node:latest
ARG NODE_VERSION
# Backend kopieren
WORKDIR /usr/src/app
COPY ./backend ./backend

# Kopieren des React-Builds
COPY --from=build /app/frontend/my_app/build  /usr/src/app/backend/React

WORKDIR /usr/src/app/backend
# npm-Abhängigkeiten für das Backend installieren
RUN npm install -g n && \
    n \$NODE_VERSION
RUN npm install

# Startkommando
CMD ["sh", "-c", "node index.js"]
EOT



fi

# Einrichtung des ".vscode"-Ordners.
mkdir .vscode

# Anpassung der tasks.json für die Aufgaben.
cat <<EOT >> .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Terminate All Tasks",
            "command": "echo \${input:terminate}",
            "type": "shell",
            "problemMatcher": []
        },
        {
            "label": "Frontend",
            "type": "npm",
            "presentation": {
                "group": "React"
            },
            "script": "start",
            "group": "build",
            "isBackground": true,
            "path": "./frontend/my_app",
            "problemMatcher": [
                {
                    "pattern": [
                        {
                            "regexp": ".",
                            "file": 1,
                            "location": 2,
                            "message": 3
                        }
                    ],
                    "background": {
                        "activeOnStart": true,
                        "beginsPattern": ".",
                        "endsPattern": "webpack compiled successfully"
                    }
                }
            ]
        },
        {
            "label": "Backend",
            "type": "shell",
            "isBackground": true,
            "command": "node index.js",
            "options": {
                "cwd": "\${workspaceFolder}/backend"
            },
            "presentation": {
                "group": "React"
            },
            "problemMatcher": [
                {
                    "pattern": [
                        {
                            "regexp": ".",
                            "file": 1,
                            "location": 2,
                            "message": 3
                        }
                    ],
                    "background": {
                        "activeOnStart": true,
                        "beginsPattern": ".",
                        "endsPattern": "."
                    }
                }
            ]
        },
        {
            "label": "Server",
            "dependsOn": [
                "Backend",
                "Frontend"
            ]
        },
        {
            "type": "shell",
            "label": "Docker Build",
            "command": "docker build --build-arg NODE_VERSION=\$(node -v) -t \${workspaceFolderBasename} .",
            "group": "build"
        }
    ],
    "inputs": [
        {
            "id": "terminate",
            "type": "command",
            "command": "workbench.action.tasks.terminate",
            "args": "terminateAll"
        }
    ]
}
EOT

# Anpassung der launch.json für Debugging.
cat <<EOT >> .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "launch",
            "cwd": "\${workspaceFolder}/backend",
            "name": "Backend starten",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "program": "index.js"
        },
        {
            "name": "React + Backend starten",
            "type": "chrome",
            "request": "launch",
            "url": "http://localhost:3033",
            "webRoot": "\${workspaceFolder}/frontend/my_app/src",
            "preLaunchTask": "Server",
            "postDebugTask": "Terminate All Tasks"
        },
        {
            "name": "build Dockercontainer",
            "type": "node",
            "request": "launch",
            "program": "\${workspaceFolder}/dummy.js",
            "preLaunchTask": "Docker Build"
        }
    ]
}
EOT




# Erstellung der docker-compose.yml Datei
cat <<EOT >> docker-compose.yml
version: '3'

services:
  $project_name:
    image: $project_name:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.$project_name.rule=Host(\`${project_name}.csnetworkx.dev\`)"
      - "traefik.http.routers.$project_name.entrypoints=publicwebsecure"
      - "traefik.http.routers.$project_name.tls.certresolver=myresolver"
      - "traefik.http.routers.$project_name.service=$project_name"
EOT

if [ "$version" == "light" ]; then
    echo "      - \"traefik.http.services.$project_name.loadbalancer.server.port=507\"" >> docker-compose.yml
else
    echo "      - \"traefik.http.services.$project_name.loadbalancer.server.port=80\"" >> docker-compose.yml
fi

cat <<EOT >> docker-compose.yml
networks:
  Backend:
    external: true
EOT
