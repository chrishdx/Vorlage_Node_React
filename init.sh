#!/bin/sh

rm -rf .git
npx create-react-app frontend --template cra-template-pwa
mkdir backend
cd backend
npm init -y
echo "#Standart Einstiegspunkt für die App" >> index.js
cd ..

