#!/bin/bash

git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
echo "::add-path::$GITHUB_WORKSPACE/_flutter/bin"
