#!/bin/bash

IMAGE_VERSION=v1.0
TOOL_VERSION=GALN-0.2.7


IMAGE_TAG="${IMAGE_VERSION}_${TOOL_VERSION}"
IMAGE_NAME="ghcr.io/nbisweden/galn"

# Build images

        docker build -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:latest . || {
                echo "Error building image, exited script"
                exit 1
        }

# Push images

        # docker push $IMAGE_NAME:$IMAGE_TAG || {
        #         echo "Error pushing image, exited script"
        #         exit 1
        # }

        # docker push $IMAGE_NAME:latest || {
        #         echo "Error pushing image, exited script"
        #         exit 1
        # }

######################

# Debug build

# Build images

        # docker build -t $IMAGE_NAME:$IMAGE_VERSION -t $IMAGE_NAME:latest . > build.log 2>&1 || {
        #       echo "Error building image, exited script"
        #       exit 1
        # }
