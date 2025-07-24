FROM ghcr.io/celestiaorg/celestia-app-standalone:v4.0.10-mocha

USER root

RUN apk add lz4

USER celestia