# MoviesApp

## Overview
MoviesApp is an iOS application built using SwiftUI that allows users to explore movies, view detailed information, and interact with movie-related content such as reviews and user profiles.  
The application integrates with the Airtable REST API and follows a clean and structured architecture.

## CRUD Operations & API Integration
The application implements full CRUD operations using the provided Airtable API.  
All network requests and data handling are centralized in the `APIServices` class to ensure consistency and maintainability.

### Create
Users can create new movie reviews.  
This functionality is implemented using a POST request to the `reviews` endpoint.

### Read
The application retrieves data from multiple endpoints:
- Movies are fetched from the `movies` table.
- Reviews are fetched dynamically based on the selected movie.
- Actors and directors are retrieved using link tables.
- User profiles are fetched from the `users` table.

Fetched data is displayed dynamically in the user interface based on the selected content.

### Update
Users can update their profile information, such as their name and profile image.  
This is implemented using a PATCH request to the `users/{id}` endpoint.

### Delete
Users can delete their own reviews.  
This is implemented using a DELETE request to the `reviews/{reviewID}` endpoint.

## Architecture & Design
The application follows the MVVM (Model–View–ViewModel) architecture:
- Views handle the presentation layer and user interaction.
- ViewModels manage application logic and state.
- APIServices is responsible for API communication and data processing.

SwiftUI is used to build the user interface, and asynchronous tasks are used to handle network requests efficiently.

## Conclusion
MoviesApp demonstrates the integration of SwiftUI with a RESTful API while supporting full CRUD functionality.  
The application provides a structured and maintainable codebase suitable for future enhancements and scalability.
