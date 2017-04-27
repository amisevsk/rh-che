#!/bin/bash

set -e

DEFAULT_CHE_IMAGE_REPO=rhche/che-server
DEFAULT_CHE_IMAGE_TAG=nightly
DEFAULT_REDHAT_CHE_VERSION=5.6.0-openshift-connector-SNAPSHOT

if [ -z ${GITHUB_REPO+x} ]; then
  echo >&2 "Variable GITHUB_REPO not found. Aborting"
  exit 1
fi

echo "using additional parameters: $@"

CHE_IMAGE_REPO=${CHE_IMAGE_REPO:-${DEFAULT_CHE_IMAGE_REPO}}
CHE_IMAGE_TAG=${CHE_IMAGE_TAG:-${DEFAULT_CHE_IMAGE_TAG}}
REDHAT_CHE_VERSION=${REDHAT_CHE_VERSION:-${DEFAULT_REDHAT_CHE_VERSION}}

# Build openshift-connector branch of che-dependencies
git clone -b openshift-connector --single-branch https://github.com/eclipse/che-dependencies.git che-deps
cd che-deps
mvn clean install
cd ..
rm -rf ./che-deps

CURRENT_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd ${GITHUB_REPO}

GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

mvnrh() {
  mvn -Pfast \
      -PmultiThread \
      -DlocalCheRepository=${GITHUB_REPO} \
      -DwithoutKeycloak \
      -Dche-branch=${GIT_BRANCH} \
      -Dpl="assembly/assembly-wsmaster-war" \
      -Damd \
      $@
}

mvnche() {
  mvn -Dskip-enforce -Dskip-validate-sources -DskipTests -Dfindbugs.skip -Dgwt.compiler.localWorkers=2 -T 1C -Dskip-validate-sources $@
}

cd plugins/plugin-docker
mvnche "$@" clean install

cd ${SCRIPT_DIR}/../
mvnrh "$@" install

cd ${GITHUB_REPO}/dockerfiles/che/
mv Dockerfile Dockerfile.alpine
cp Dockerfile.centos Dockerfile

# Link custom assembly and build docker image
source ${GITHUB_REPO}/dockerfiles/build.include
BUILD_ASSEMBLY_ZIP=$(echo "${SCRIPT_DIR}"/../target/builds/fabric8/fabric8-che/assembly/assembly-main/target/eclipse-che-*fabric8*.tar.gz)
LOCAL_ASSEMBLY_ZIP="$(pwd)"/eclipse-che.tar.gz

if [ -f "${LOCAL_ASSEMBLY_ZIP}" ]; then
  rm "${LOCAL_ASSEMBLY_ZIP}"
fi
ln "${BUILD_ASSEMBLY_ZIP}" "${LOCAL_ASSEMBLY_ZIP}"
init --name:server --tag:${CHE_IMAGE_TAG}
build

mv Dockerfile.alpine Dockerfile
docker tag eclipse/che-server:${CHE_IMAGE_TAG} ${CHE_IMAGE_REPO}:${CHE_IMAGE_TAG}

cd ${CURRENT_DIR}
