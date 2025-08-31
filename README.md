# About
The purpose of the script is to provide an easy way to install the most necessary programs/tools for development

# Usage
Download the script at [latest](https://github.com/maddingo-org/developer-setup/releases/latest) and unzip it. \
To run the script navigate to where you downloaded the script and run ```./dev-setup.sh```

# Hash mismatch, updated versions
Checksum Status: [![Checksums](https://github.com/maddingo-org/developer-setup/actions/workflows/test-checksum.yml/badge.svg?event=schedule)](https://github.com/maddingo-org/developer-setup/actions/workflows/test-checksum.yml)

If the status above is not success, then some tools have an updated version and a new release should be created. 

In this case, follow this routine:
1. create a feature branch
2. run the `update_checksums.sh` tool
3. validate the content of the `*-install.sh` and archive files (`tar.gz`, `*.tgz`). \
   The ones that were changed have an updated hash. \
   These files are ignored by git and should not be checked in.
4. `git add hash`
5. commit and push the files
6. Create a pull request, have someone review it and merge into develop
7. Create a new release on GitHub.
