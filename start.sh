#!/bin/sh
nginx -g "daemon off;"&
node /app/index.js
