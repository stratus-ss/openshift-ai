# OpenShift AI Documentation README

This repo contains mainly documentation on how to accomplish various tasks within OpenShift AI. This documentation was produced working off of mainly OpenShift v4.14 and OpenShift AI 2.7. The [artifacts directory](./artifacts) directory contains sample configuration files which are used throughout this repo to demonstrate various concepts. While an effort will be made to ensure that these artifacts stay up to date, there is a possibility that they will not always work as intended.

The [docs](./docs/) directory contains the [src](./docs/src/) which has the individual subjects broken out into their own markdown files for easier maintanence. In addition, there are the [make_cli_docs.sh](./docs/src/make_cli_docs.sh) and [make_ui_docs.sh](./docs/src/make_ui_docs.sh) which will generate a temp directory, link the appropriate markdown files in and then launch [stitchmd](https://github.com/abhinav/stitchmd) to compile the markdown into one large document. A copy of stitchmd is included with this repo and this version was used to build the documentation. The output is placed in the [rendered](./docs/rendered) directory for easier consumption.

Suggestions and pull requests are welcome. 
