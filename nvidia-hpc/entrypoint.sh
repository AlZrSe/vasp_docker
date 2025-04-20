#!/bin/bash

# Fix ownership of /task directory if it's mounted as a volume
if [ -d "/task" ]; then
    sudo chmod 666 /task/*
fi

# Execute the command passed to docker run
exec "$@"