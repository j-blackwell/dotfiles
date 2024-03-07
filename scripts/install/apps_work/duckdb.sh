#!/usr/bin/bash


wget https://github.com/duckdb/duckdb/releases/download/v0.9.2/duckdb_cli-linux-amd64.zip
unzip duckdb_cli-linux-amd64.zip
sudo mv duckdb /opt/duckdb

rm duckdb_cli-linux-amd64.zip

echo "alias duckdb=/opt/duckdb" >> ~/.bashrc
