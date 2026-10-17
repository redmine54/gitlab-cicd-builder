# Customer Portal Architecture

- `frontend/`: Vue 3 and Vite user interface; `/api` is proxied to Spring Boot.
- `backend/`: Spring Boot REST API and Spring Data JPA persistence.
- H2: in-memory database for local development and CI tests.
- `playwright/`: browser-level registration flow test.

Run the backend with `mvn spring-boot:run` from `backend/`, and run the frontend with `npm install && npm run dev` from `frontend/`.
