@echo off
setlocal

:: Set your Heroku app name
set HEROKU_APP_NAME=nc-election-analysis

:: Build the Docker image
docker build -t my-website .

:: Tag the image for Heroku
docker tag my-website registry.heroku.com/%HEROKU_APP_NAME%/web

:: Push the image to Heroku
docker push registry.heroku.com/%HEROKU_APP_NAME%/web

:: Release the new version
heroku container:release web -a %HEROKU_APP_NAME%

echo Deployment completed successfully!

pause