#!/bin/sh

rm -rf .git
npx create-react-app frontend --template cra-template-pwa
copy ./Templates/frontend/* ./frontend/
cd frontend
npm install
cd ..
mkdir backend
cd backend
npm init -y
npm i express body-parser bcrypt better-sqlite3 dotenv express-session moment-timezone uuidv4
copy ./Templates/backend/* ./backend/
cd ..

