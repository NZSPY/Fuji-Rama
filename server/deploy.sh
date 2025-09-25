gcloud config set project fuji-llama
gcloud run deploy llama-server --source . --region=asia-southeast1 --min-instances=0 --max-instances=1