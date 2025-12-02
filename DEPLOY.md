# Deploy to Cloud Run

## Frontend

From the project root:

```bash
gcloud builds submit --config=cloudbuild.yaml
```

Service URL: `https://corpus-explorer-frontend-1036279278510.europe-west4.run.app`

## Auth Proxy

If you modify the auth-proxy, deploy it separately:

```bash
cd auth-proxy
gcloud builds submit --tag europe-west4-docker.pkg.dev/rg-dynamic-persona/dynamic-persona-frontend/auth-proxy:latest .
gcloud run deploy rg-dynamic-persona-auth-proxy --image=europe-west4-docker.pkg.dev/rg-dynamic-persona/dynamic-persona-frontend/auth-proxy:latest --region=europe-west4 --allow-unauthenticated
```

Service URL: `https://rg-dynamic-persona-auth-proxy-1036279278510.europe-west4.run.app`
