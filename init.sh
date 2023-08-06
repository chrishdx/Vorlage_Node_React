#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf .git
npx create-react-app frontend --template cra-template-pwa
cp $DIR/Templates/frontend/* frontend/
npm install --prefix frontend
mkdir backend
npm init -y --prefix backend
npm i  --prefix backend express body-parser bcrypt better-sqlite3 dotenv express-session moment-timezone uuidv4
cp $DIR/Templates/backend/* backend/



