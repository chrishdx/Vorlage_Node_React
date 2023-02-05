#!/bin/sh

rm -rf .git
npx create-react-app frontend --template cra-template-pwa
copy ./Templates/frontend/* ./frontend/
npm install --prefix ./frontend
mkdir backend
npm init -y --prefix ./backend
npm i  --prefix ./backend express body-parser bcrypt better-sqlite3 dotenv express-session moment-timezone uuidv4
copy ./Templates/backend/* ./backend/


