# Frontend - User Management

A modern React application for managing users through the Go API backend.

## Features

- 🎨 Modern, responsive UI with gradient design
- 📊 Real-time health status monitoring
- 👥 User list display with avatars
- 🔄 Refresh functionality for loading new mock data
- 📱 Mobile-friendly responsive design
- 🐳 Docker support

## Technologies

- React 18
- CSS3 with modern styling
- Nginx (for production)
- Docker

## Development

### Prerequisites

- Node.js 18+ and npm
- Backend API running on `http://localhost:8080`

### Installation

```bash
cd frontend
npm install
```

### Running Locally

```bash
npm start
```

The app will open at `http://localhost:3000`

### Building for Production

```bash
npm run build
```

## Docker Deployment

### Build Docker Image

```bash
docker build -t react-frontend:latest .
```

### Run Container

```bash
docker run -d --name frontend -p 3000:80 react-frontend:latest
```

### Using Docker Compose (Recommended)

From the project root:

```bash
docker compose up -d
```

This will start both frontend and backend services together.

## Environment Variables

- `REACT_APP_API_URL`: Backend API URL (default: `http://localhost:8080`)

## Project Structure

```
frontend/
├── public/
│   └── index.html              # HTML template
├── src/
│   ├── App.js                  # Main application component
│   ├── App.css                 # Application styles
│   ├── index.js                # React entry point
│   └── index.css               # Global styles
├── Dockerfile                  # Docker configuration
├── nginx.conf                  # Nginx configuration for production
├── package.json                # Dependencies
└── README.md                   # This file
```

## API Endpoints Used

- `GET /api/v1/health` - Health check
- `GET /api/v1/users` - Fetch users list

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

