#!/bin/bash

fleetctl submit pastmon-*.service
fleetctl start pastmon-web@1.service pastmon-web-discovery@1.service

fleetctl start pastmon-sensor@{1..5}.service
