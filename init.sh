#!/bin/sh

rm -rf .git
npx create-react-app frontend --template cra-template-pwa
copy ./Template/React/* ./frontend/
mkdir backend
cd backend
npm init -y
npm i express body-parser bcrypt better-sqlite3 dotenv express-session moment-timezone uuidv4
cat ./Templates/backend/index.js >> ./backend/index.js
cd ..

