#! /bin/bash -e
#
#	(c) 2019 Vlad Estivill-Castro
#	Probably the stages of the Docker file could be set up better
#	We want the result of Dockerfile as the base of the Jenkins container
echo "Building Dockerfile.jenkins"
echo "Pasting the base image defined in Dockerfile"
cat  Dockerfile > Dockerfile.jenkins
echo "Adding the tail from JenkinsPart.jenkins"
cat  JenkinsPart.jenkins >> Dockerfile.jenkins
echo "To build the container: docker build . -f Dockerfile.jenkins -t mipal-swift-jenkins:latest"
echo "To start (run the container) the image: docker run -it --rm -p 6080:80 -p 8082:8080 -v <absolute-path-to-host-directory>:/var/jenkins_home mipal-swift-jenkins"
echo "To get a shell in the container as the jenkins user:  docker exec -it --user jenkins \`docker ps -l -q\`   bash"
echo "To access the WEB interface for jenkins go to http://localhost:8082"
