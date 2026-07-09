# Movieisme

**Explore movies. Share what you think.**

Movieisme is a SwiftUI iOS app for browsing movies, viewing their details, and reading and writing reviews — backed entirely by the **Airtable REST API** with full CRUD support and a clean MVVM structure.

<br>
<img width="1441" height="802" alt="Screenshot 2026-07-09 at 4 45 45 AM" src="https://github.com/user-attachments/assets/4981449d-d17e-4b56-9a28-13b9dcb5c925" />
<br>

## Features

- **Movie catalog** — browse movies with posters, story, runtime, genre, language, and IMDb rating
- **Search & genre filtering** — find movies by name or browse by genre section
- **Movie details** — cast and directors resolved dynamically through Airtable link tables
- **Reviews** — read reviews per movie, write your own with a rating, and delete your own reviews
- **User profiles** — sign in with email/password validation, view and edit your profile (name and photo)

## CRUD Over Airtable

All networking is centralized in a single `APIServices` layer with a generic request builder, response validation, and typed DTOs decoded from Airtable's record format:

| Operation | Endpoint | Used for |
|---|---|---|
| **Create** | `POST /reviews` | Publishing a new movie review |
| **Read** | `GET /movies`, `/reviews`, `/actors`, `/directors`, `/users` | Catalog, per-movie reviews, cast via link tables, profiles |
| **Update** | `PATCH /users/{id}` | Editing profile name and image |
| **Delete** | `DELETE /reviews/{id}` | Removing the user's own review |

Reviews, actors, and directors are fetched on demand for the selected movie rather than up front, and profile edits are applied locally as well so the UI updates instantly.

## Architecture

MVVM with one shared networking service:

```
Movieisme
├── App/             # Entry + RootView
├── Models/          # Generic AirtableRecord/ListResponse wrappers
│                    # + DTOs: Movie, Review, Actor, Director, Profile
├── NetWorking/      # APIServices — request builder, validation,
│                    # and all CRUD calls
└── Pages/           # SignIn, MoviesCenter, MovieDetails,
                     # Profile / EditProfile (View + ViewModel each)
```

A small but useful detail: Airtable responses share one shape, so the app decodes everything through generic `AirtableListResponse<T>` / `AirtableRecord<T>` wrappers — adding a new table means adding one `Fields` struct, not new parsing code.

## Tech Stack

- Swift · SwiftUI
- Airtable REST API (async/await networking with `URLSession`)
- MVVM architecture

> Built as a learning project — it uses a demo Airtable base with an embedded token for easy setup; a production app would keep credentials out of source control.
