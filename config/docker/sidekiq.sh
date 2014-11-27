#!/bin/sh
cd /home/app/webapp
exec 2>&1
exec chpst -u app bundle exec sidekiq -e production
