#!/bin/bash

sudo docker compose down
sudo docker compose up -d
sudo docker exec -it DB_Server /bin/bash
