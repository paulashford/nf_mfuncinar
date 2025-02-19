#!/bin/bash

# venv
# python3 -m venv venv 
source ./venv/bin/activate

# upgrade pip etc
pip install --upgrade pip wheel pytest

# https://setuptools.pypa.io/en/latest/userguide/quickstart.html
pip install --upgrade build

# export instantclient for Oracle export
# LD_LIBRARY_PATH=~/instantclient_21_7
