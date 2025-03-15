
# Deepseek on-prem setup

## How to start this sheet the first time

docker compose up -d

## How to pause it

docker compose stop

## How to resume it

docker compose start

## How to wipe this whole sheet out

docker compose down -v

## Forced clean all of your containers (all of them, not just this sheet)

docker rm -f $(docker ps -aq)

## How to add a new model on the fly for testing

To add a new model for testing, use the following command:

```bash
docker compose exec ollama-models-setup ollama pull <model-name>
```

Replace `<model-name>` with the name of the model you want to add.