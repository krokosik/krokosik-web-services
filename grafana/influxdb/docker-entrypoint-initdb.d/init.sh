#!/bin/sh

# $INFLUX_CMD "CREATE RETENTION POLICY \"example_policy\" ON \"$INFLUXDB_DB\" DURATION 52w REPLICATION 1;"