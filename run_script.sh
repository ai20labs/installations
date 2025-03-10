!#/bin/bash
model_name="gemma:2b"
#docker build  --no-cache  -t rapid-demo-ui:1.0.0 . #for building images
if ! command -v docker &> /dev/null
then
  echo "Docker is not installed. Install docker from \n ref: https://docs.docker.com/desktop/setup/install/mac-install/"
  exit 1
  # Add commands to execute if Docker is not installed here, for example:
  # brew install docker
  # if [ $? -eq 0 ]; then
  #   echo "docker imstallation successful, starting docker service"
  #   open -a Docker
    
  # else
  #   echo "docker installation failed, exiting, try installing docker manually and then rerun this script"
  #   exit 1
  # fi
else
  echo "Docker is installed. proceeding.., starting docker service"
fi

# open --background -a Docker
#clean old service is existing
docker stop rapid-demo-ui rapid-demo chromadb ollama
docker rm -f  rapid-demo-ui rapid-demo chromadb ollama
docker pull ratish11/rapid-demo:1.1.2
docker pull ratish11/rapid-demo-ui:1.1.0
docker pull chromadb/chroma:0.6.3
docker pull ollama/ollama
docker network create -d bridge rapid-demo-network
docker volume create ollama 
docker volume create chroma-data
docker run -d -v ollama:/root/.ollama -p 11434:11434 --network rapid-demo-network --name ollama ollama/ollama
docker exec ollama ollama pull ${model_name}
docker run -d -v chroma-data:/data -e ALLOW_RESET=true -p 8000:8000 --name chromadb --network   rapid-demo-network chromadb/chroma:0.6.3
docker run -d -p 8080:8080 --network rapid-demo-network --name rapid-demo ratish11/rapid-demo:1.1.2
docker run -d -p 3000:3000 --network rapid-demo-network --name rapid-demo-ui ratish11/rapid-demo-ui:1.1.0
echo "Installations complete, loading model in memory"
# curl -X POST -H "Content-Type: application/json" -d "{\"model\": \"${model_name}\", \"prompt\": \"What is the capital of France?\", \"keep_alive\": 15}" http://localhost:11434/api/generate > /dev/null
curl http://localhost:11434/api/generate -d "{ \"model\": \"${model_name}\", \"keep_alive\": -1}"
#check ollama model status
docker exec ollama ollama ps
docker image prune -a -f

