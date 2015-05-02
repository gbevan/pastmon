#!/bin/bash -e

RT="--request-timeout=30"

fleetctl $RT submit pastmon-*.service
fleetctl $RT start pastmon-web@1.service pastmon-web-discovery@1.service

fleetctl $RT start pastmon-sensor@{1..5}.service
