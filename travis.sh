#!/bin/bash

# compose Docker image tag ----------------------------------------------------
#   NOTE: This needs to be called before build and deploy
getTag() {
temp=""

# find tag prefix: master -> "", devel -> "devel"
if [[ "$TRAVIS_BRANCH" == "devel" ]]; then
  temp="devel-"
fi

os=""
# determine os debian -> "", alpine -> "alpine"
if [[ "$dockerfile" == "alpine" ]]; then
  temp="${temp}alpine-"
fi

# append tag
temp="${temp}${tag}"

# set tag variable
echo "$temp"
}

# compose full image name (image name + tag) ----------------------------------
getImageName() {
  setTag
  echo "${repo_name}/${image_name}:$(getTag)"
}

# build Docker image ----------------------------------------------------------
build() {
  docker build --build-arg baseimage_tag=${baseimage_tag} \
               --build-arg webmapclient_version=${webmapclient_version} \
               -t "$(getImageName)" \
               ${dockerfile}
}

# run Docker container --------------------------------------------------------
runContainer() {
  setTag  
  docker run --name webcl -d -p 8000:8000 "$(getImageName)"
}

# deploy ----------------------------------------------------------------------
deploy() {
  if [[ "$TRAVIS_BRANCH" == "master" || "$TRAVIS_BRANCH" == "devel" ]]; then
    setTag
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker push "$(getImageName)"
  fi
}

# main ------------------------------------------------------------------------
# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi
