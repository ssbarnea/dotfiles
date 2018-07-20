#!/bin/bash
set -ex
plutil -convert xml1 -r -o com.googlecode.iterm2.xml  com.googlecode.iterm2.plist
plutil -convert json -r -o com.googlecode.iterm2.json  com.googlecode.iterm2.plist
