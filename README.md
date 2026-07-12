# Movieisme

**Discover movies. Save favorites. Share your reviews.**

Movieisme is a movie discovery and review iOS app that allows users to browse movies, explore detailed information, save favorites, and share reviews. The application is powered by the **Airtable REST API** and follows a clean **MVVM architecture** with a reusable networking layer.

<br>
<img width="1441" alt="Movieisme" src="https://github.com/user-attachments/assets/4981449d-d17e-4b56-9a28-13b9dcb5c925" />
<br>

## Features

- **Movie catalog** — browse movies with posters, story, runtime, genre, language, and IMDb rating.
- **Search & Genre Filtering** — quickly find movies by title or browse by genre.
- **Movie Details** — dynamically loads actors and directors through Airtable link tables.
- **Reviews** — read reviews, publish your own with a rating, and delete your own reviews.
- **Favorites** — save and remove favorite movies with synchronized user data.
- **User Profiles** — sign in, manage your profile information, and update your profile image.

---

## Technical Overview

Built a native iOS application using **SwiftUI** with an **MVVM architecture**, integrating the Airtable REST API through a reusable networking layer built with **URLSession**, **async/await**, **JSON decoding**, and **generics**.

The networking layer includes:

- Centralized API communication
- Generic request builder
- HTTP response validation
- Full CRUD operations
- Dynamic data loading
- Session-aware state management
- Optimistic UI updates
- Typed DTO decoding

---

## Project Structure

```text
App
├── App
├── Core
├── Models
├── Networking
├── Pages
│   ├── SignIn
│   │   ├── View
│   │   └── ViewModel
│   ├── MoviesCenter
│   │   ├── View
│   │   └── ViewModel
│   ├── MovieDetails
│   │   ├── View
│   │   └── ViewModel
│   └── Profile
│       ├── ProfileView
│       ├── EditProfileView
│       └── ViewModel
└── Assets
```

---

## CRUD Operations

All API communication is centralized inside a reusable `APIServices` layer.

| Operation | Endpoint | Purpose |
|-----------|----------|---------|
| **Create** | `POST /reviews` | Publish movie reviews |
| **Read** | `GET /movies`, `/reviews`, `/actors`, `/directors`, `/users`, `/favorites` | Load movies, reviews, cast, profiles, and favorites |
| **Update** | `PATCH /users/{id}`<br>`PATCH /favorites/{id}` | Update user profiles and favorite movies |
| **Delete** | `DELETE /reviews/{id}` | Delete user reviews |

Movies are loaded once, while reviews, actors, directors, and favorites are fetched dynamically as needed to reduce unnecessary network traffic.

---

## Architecture

MVVM with a centralized networking layer.

- **APIServices** — reusable networking service responsible for all Airtable communication.
- **MovieDetailsViewModel** — handles movie details, reviews, and user interactions.
- **SessionManager** — manages authentication state and user session.
- **DTO Models** — strongly typed models for decoding Airtable responses.

---

## Tech Stack

| Layer | Technology |
|--------|------------|
| **Language / UI** | Swift · SwiftUI |
| **Architecture** | MVVM |
| **Networking** | URLSession · Async/Await |
| **Backend** | Airtable REST API |
| **Data** | JSON Encoding & Decoding |
| **State Management** | ObservableObject · @Published |
| **Version Control** | Git · GitHub |

---

## Setup

The project requires a local `Secrets.plist` file containing your Airtable credentials.

Create:

```text
Movieisme/Core/Secrets.plist
```

with the following keys:

```text
AirtableBaseID
AirtableToken
```

The file is intentionally excluded from Git using `.gitignore` to keep credentials out of source control.
