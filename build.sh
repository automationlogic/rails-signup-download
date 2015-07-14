#!/bin/bash
# Build and deploy rails-signup-download app on Docker

if [ $# -eq 0 ]
then
    echo "Image version not provided."
    exit 1
fi

if [ $# -eq 1 ]
then
    echo "Git branch not provided."
    exit 1
fi

if [ $2 = "dev" ]
then
    TARGET_IP=$DEV_IP
elif [ $2 = "deploy" ]
then
    TARGET_IP=$DEPLOY_IP
else
    echo "Target IP unknown for git branch $2."
    exit 1
fi

mvn clean package
#docker build -t lwilts/rails_signup_download_demo:$1 .
echo "*** Building dockerfile ***"
tar zcf dockerfile.tar.gz ./
http_response=$(curl -w "\n%{http_code}\n" --verbose --request POST -H "Content-Type:application/tar" --data-binary '@dockerfile.tar.gz' "http://$DEV_IP:2376/build?nocache=true&t=lwilts/rails_signup_download_demo:$2$1" | tail -1)
if [ $http_response != "200" ]
then
    echo "Failed to build dockerfile."
    exit 1
fi
#docker login -u lwilts
#docker push lwilts/rails_signup_download_demo
http_response=$(curl -w "\n%{http_code}\n" --request POST -H "X-Registry-Auth: eyJ1c2VybmFtZSI6Imx3aWx0cyIsInBhc3N3b3JkIjoiRC0jb0M9RlNGTXM5NWZyUnpIaiUiLCAiYXV0aCI6IiIsImVtYWlsIjoibHVrZUBsdWtld2lsdHNoaXJlLmNvLnVrIn0K" http://$DEV_IP:2376/images/lwilts/rails_signup_download_demo/push?tag=$2$1 | tail -1)
if [ $http_response != "200" ]
then
    echo "Failed to push image to docker hub registry."
    exit 1
fi
sleep 10

# REMOTE DEPLOY
#docker kill rails-signup-download && docker rm rails-signup-download
echo "*** Removing old rails-signup-download ***"
curl --verbose --request DELETE http://$TARGET_IP:2376/containers/rails-signup-download?force=true
#docker run --name rails-signup-download -p 80:8080 -d lwilts/rails_signup_download_demo:$1
echo "*** Creating new rails-signup-download ***"
sed -i "s/BUILD_NUMBER/$2$1/g" container.json
http_response=$(curl -w "\n%{http_code}\n" --verbose --request POST "http://$TARGET_IP:2376/images/create?fromImage=lwilts/rails_signup_download_demo&tag=$2$1" | tail -1)
if [ $http_response != "200" ]
then
   echo "Failed to pull image from the docker hub registry."
   exit 1
fi
http_response=$(curl -w "\n%{http_code}\n" --verbose --request POST -H "Content-Type:application/json" --data-binary '@container.json' http://$TARGET_IP:2376/containers/create?name=rails-signup-download | tail -1)
if [ $http_response != "201" ]
then
   echo "Failed to create container on docker host."
   exit 1
fi
http_response=$(curl -w "\n%{http_code}\n" --verbose --request POST http://$TARGET_IP:2376/containers/rails-signup-download/start | tail -1)
if [ $http_response != "204" ]
then
   echo "Failed to start container on docker host."
   exit 1
fi

exit 0
