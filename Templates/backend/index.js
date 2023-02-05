//Standart Einstiegspunkt für die App"
echo "const app = require('express')();
require('dotenv').config();
const NODE_ENV = process.env.NODE_ENV || 'dev';
const Port = NODE_ENV === "production" ? parseInt(process.env.Port) || 507 : 2210" 
