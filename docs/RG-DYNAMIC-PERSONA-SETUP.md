# RG Dynamic Persona Configuration

## Quick Setup

Your RG Dynamic Persona backend is already configured and ready to use. Here's how to connect the frontend:

### Backend Details
- **URL**: `https://rg-dynamic-persona-1036279278510.europe-west9.run.app`
- **Endpoint**: `/chat`
- **Authentication**: IAM (Bearer token required)
- **Request Format**: Plain text (GraphQL natural language)
- **Response Format**: JSON with `answer` field

### 1. Get Your Bearer Token

```bash
gcloud auth print-identity-token --audiences=https://rg-dynamic-persona-1036279278510.europe-west9.run.app
```

### 2. Start the Frontend

```powershell
# Use the provided test script
.\test-rg-dynamic-persona.ps1

# Or start manually with your token
docker run -d --name rg-persona-frontend -p 8080:8080 `
  -e AUTH_MODE=bearer `
  -e "BACKEND_BASE_URL=https://rg-dynamic-persona-1036279278510.europe-west9.run.app" `
  -e "BEARER_TOKEN=your-token-here" `
  -e IAP_MODE=false `
  rg-dynamic-persona-frontend
```

### 3. Test the Chat

Open http://localhost:8080 and try these example messages:

- "What should I wear today in Ushuaia?"
- "Give me fashion advice for cold weather"
- "What's the weather like?"

## API Integration

The frontend has been configured to work with your specific backend:

### Request Format
- **Content-Type**: `text/plain`
- **Body**: Direct natural language text (not JSON)
- **Headers**: `Authorization: Bearer {token}`

### Response Format
```json
{
  "answer": "Your personalized fashion advice response..."
}
```

### Example Request
```
POST https://rg-dynamic-persona-1036279278510.europe-west9.run.app/chat
Content-Type: text/plain
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...

What should I wear today in Ushuaia, Argentina?
```

### Example Response
```json
{
  "answer": "Given that it is currently overcast in Ushuaia, Argentina with a temperature of 7.1°C (feels like 2.6°C), and it's 2025-09-05 10:07:04 -03, a fashion-conscious individual might consider a stylish, yet warm outfit. This could include a well-tailored coat, perhaps in a wool or cashmere blend, layered over a turtleneck or a sophisticated sweater. Chinos or dark-wash jeans, paired with leather boots or stylish waterproof shoes, would complete the look while ensuring warmth and practicality in the cool, potentially damp weather. A scarf would add an extra layer of warmth and a touch of personal style."
}
```

## Troubleshooting

### Authentication Errors (401)
- Check your bearer token is valid
- Regenerate token: `gcloud auth print-identity-token --audiences=https://rg-dynamic-persona-1036279278510.europe-west9.run.app`
- Tokens expire after ~1 hour

### CORS Errors
- Your backend should already be configured for CORS
- Check browser console for specific error messages

### Connection Issues
- Verify your internet connection
- Check if the Cloud Run service is running
- Test the backend directly: `curl -H "Authorization: Bearer YOUR_TOKEN" -H "Content-Type: text/plain" -d "test message" https://rg-dynamic-persona-1036279278510.europe-west9.run.app/chat`

### Container Issues
- Check logs: `docker logs rg-persona-frontend`
- Restart container: `docker restart rg-persona-frontend`
- Check if port 8080 is available

## Development Notes

The frontend automatically:
- Sends user messages as plain text to `/chat`
- Includes bearer token in Authorization header
- Extracts the `answer` field from JSON responses
- Handles authentication errors with user-friendly messages
- Provides CORS support for browser requests
