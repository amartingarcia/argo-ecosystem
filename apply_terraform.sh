#!/bin/bash

terraform -chdir=resources/terraform/argo init && terraform -chdir=resources/terraform/argo apply -auto-approve

terraform -chdir=resources/terraform/event-bus init && terraform -chdir=resources/terraform/event-bus apply -auto-approve
