# Mafia Platform

## General Overview

The platform is an online multiplayer game system similar to a Mafia party game, where players interact within a virtual town, manage characters, and participate in strategic gameplay.
The architecture of the platform is service-oriented, with multiple specialized services working together. In the subchapters below, each service is described, its responsibilities, and how they communicate to create a consistent, interactive game experience.

## Service Boundaries

Out platform consists of the following microservices, each with their primary role and main functionalities:

### User Management Service

Primary role: Central user identity and account management system

Functionalities:

- User registration and authentication (account creation with email, username, password validation and secure authentication flows)
- Single profile constraint (tracks device and location data)
- In-game and global economy (manages user currency balance, transaction history, etc.)

### Game Service

Primary role: Core game and lobby management system

Functionalities:

- Lobby management (creates and manages game sessions with up to 30 players, tracks player enrollment and capacity limits)
- Game state coordination (the Day/Night cycle, game timing and phase transitions)
- Player status tracking (monitors alive/dead status, assigned roles, career assignments, etc.)
- Event broadcasting (generates and distributes game notifications, like deaths, healings, rumors, phase changes, exiles, to relevant players)
- Voting management (initiates voting phases, coordinates with Voting Service, and announces exile results)

### Shop Service

Primary role: In-game marketplace for item purchases during daytime

Functionalities:

- Item purchasing (allows players to spend in-game currency on items that support daily tasks or provide night protection, e.g., garlic for vampire defense, water for arsonist countermeasures)
- Resource balancing (applies an algorithm to regulate daily item availability, preventing imbalance or overuse of certain items)

### Roleplay Service

Primary role: Manages role-specific abilities and interactions

Functionalities:

- Role abilities (enables players to perform actions unique to their roles, such as Mafia killings or Sheriff investigations)
- Attempt recording (logs every role-based action, successful or not, for traceability and safekeeping)
- Announcement filtering (creates and distribute to certain players outcome messages, e.g. deaths, investigations, failed actions, that are then forwarded to the Game Service for distribution)

### Town Service

Primary role: Central user identity and account management system

Functionalities:

- Location management - stores and provides all places in town (including special ones like Shop and Informator Bureau), and reports these movements to the Task Service.
- Movement tracking - records user movements between locations with timestamps
- Location history - retrieves movement history by user or location
- Reporting - forwards movement events to the Task Service

### Character Service

Primary role: Allows customization and management of player characters, including appereance and assets.

Functionalities:

- Character Customization – create, view, and update a user’s avatar (appearance + slots).
- Asset Catalog – list and provide details of available customization assets.
- Slot Management – define slots, enforce required/optional rules for equipping.
- Profile State – store and persist the current equipped appearance.
- Inventory Linkage – ensure only owned assets from the inventory/shop can be equipped.

### Rumours Service

Primary role: Management of the distribution of strategic intelligence within the Mafia game, allowing players to spend in-game currency to purchase randomized information about other players' roles, activities, or characteristics.

Functionalities:

- Random Information Generation: Creates diverse intelligence types based on available data
- Role-Based Access Control: Filters rumors based on purchaser's role and permissions
- Currency Integration: Validates and processes in-game currency transactions
- Information Scarcity: Manages availability and rarity of different rumor types

### Communication Service

Primary role: Manages all chat interactions in the game, including global chat during voting hours, private Mafia member chats, and private chats between players in the same area of the town.

Functionalities:

- Global Chat: Available only during voting hours for all players to discuss local happenings.
- Private Mafia Chat: Restricted to Mafia members for strategic communication.
- Location-Based Private Chat: Enables private messages between players in the same part of the town.
- Message Persistence: Stores chat history for reference during voting or game events.
- Role-Based Access Control: Ensures only authorized players access restricted chats.

### Task Service

Primary role: Provide players with tasks to perform during the day phase.

Functionalities:

- Task distribution - assign tasks at the start of the day to players based on their role and career.
- Task status - verify whether players completed their assigned tasks.
- Rumor updater - create rumors based on ongoing or completed tasks.
- Currency rewards - grant in-game currency to players who successfully complete tasks.

### Voting Service

Primary role: Voting system for guessing mafia members in the evening.

Functionalities:

- Voting tally - count and track votes cast by each player.
- Voting influence - determine the number of allowed votes per player based on role (from the Roleplay Service).
- Player removal - send a request to the Game Service to mark the player with the most votes as dead at the end of the voting phase.
- Voting log - maintain a record of every vote.

---

The diagram below represents the architecture diagram and how the microservices communicate between each other.
<img width="3764" height="2524" alt="image" src="https://github.com/user-attachments/assets/7051bffc-9c76-4620-9105-7941ed68c39e" />

This microservices architecture is organized into three service clusters behind a load balancer and API gateway. The User and Identity cluster handles authentication and character management. The Game Core cluster contains the Game Service as the central hub coordinating with voting, roleplay, communication, and town services for real-time gameplay. The Economy and Commerce cluster manages the shop, tasks, and rumors system. Each cluster has its own database for data independence, while the Game Service acts as the main orchestrator communicating across all services to coordinate game flow and player interactions.

## Technology Stack and Communication Patterns

### Technology Stack

#### User Management Service

The User Management Service will be written in TypeScript with Node.js, which can handle concurrent authentication requests from up to 30 players per lobby joining simultaneously. JWT authentication provides secure token-based access control, while PostgreSQL ensures data integrity for user data and in-game currency with complex queries for device tracking and fraud prevention. For the communication pattern - Synchronous REST API with asynchronous event publishing enables fast authentication validation that improves user experience when joining a game, while effective fraud detection through device tracking protects app integrity. The service architecture provides reliable user authentication and authorization while maintaining the flexibility to publish events for other services to consume, though it requires additional complexity in managing token refresh cycles to maintain security standards.

#### Game Service

The Game Service will be written in TypeScript with Socket.io, providing real-time bidirectional communication for day/night cycle transitions, instant death notifications, and live voting updates essential for interactive gameplay. PostgreSQL with JSONB columns can store complex game objects while maintaining relational integrity for player relationships and game history queries, complemented by Redis caching for frequently accessed game state to achieve super fast response times during active gameplay. For the communication pattern - Event-driven architecture with WebSocket connections and Redis pub/sub enables lightweight event broadcasting for cross-service notifications without external message queue overhead. The simple architecture reduces deployment complexity and infrastructure costs while maintaining performance, with Redis pub/sub providing reliable event delivery and single database technology across services simplifying development and infrastructure management, though it results in higher memory usage due to Redis caching requirements.

#### Shop Service

The Shop Service will be written in Java Spring Boot, which has a lightweight nature and fast startup times, suitable for managing a microservice. It will be used for writing the algortihms necessary for checking which items should be sold during the game. For database manipulation Hibernate will be used with PostgreSQL for character customization storage. For storing temporary data like player currency during the game, Redis wil be used for fast communication and data retrieval between the shop service and the game service. The communication that the service will have are synchronous(REST API) between itself and Game Service for daytime shop item retrieval and purchasing, and another synchronous(REST API) communication between itself and Character Service for character customization items retrieval.

#### Roleplay Service

The Roleplay Service will be written in Java Spring Boot, which has a lightweight nature and fast startup times, suitable for managing a microservice. It will be used for writing the functionalities necessary for role abilities usage, their validation and announcement creation and recording. For temporary information that is present during gameplay Redis will be used for storing the announcements and later be sent to game service when needed. The service will communicate with Game Service through REST API for announcement sending and role ability validation.

#### Town Service

The Town Service will be written in Python with FastAPI, that provides rapid API development with automatic OpenAPI documentation generation, making it ideal for quick prototyping and iteration. FastAPI's native async support ensures the service can handle concurrent requests efficiently and maintain responsive performance when communicating with other services. For the communication pattern - REST API (JSON) for user location requests - straightforward implementation for location queries, movement commands, and area information retrieval. Town Service have to report to the Task Service, which enables event-based subscriptions, including location availability and accessibility that may change based on task completions, story progression, or time-based events. Event-driven architecture allows the Town Service to automatically update location states, unlock new areas, or modify existing locations without tight coupling to the Task Service.

#### Character Service

The Character Service will be written in Python FastAPI, which enables rapid development of character customization endpoints with automatic validation of asset combinations and slot constraints. FastAPI's built-in async support ensures smooth performance when handling multiple simultaneous character updates and inventory modifications. REST API (JSON) is going to be used for character customization and inventory queries - provides intuitive endpoints for asset selection, slot management, and inventory operations. Event-based communication with Shop Service - when users purchase items, the Character Service automatically updates inventory without tight coupling. The Shop Service emits purchase events that the Character Service subscribes to, ensuring real-time inventory synchronization. Event-based communication with User Service - character creation and updates may need to validate user permissions and currency deductions

#### Communication Service

NestJS is the chosen framework, whichprovides modular architecture (controllers, services, modules) with built-in dependency injection, ideal for microservice development. TypeScript on top of that adds static typing to reduce runtime errors and improve maintainability. The chosen database is Postgresql, which handles structured data, such as chat messages, player roles, and chat room membership. Via Prisma ORM it enables type-safe database access in TypeScript, minimizing errors and boilerplate code. The main communication patterns are Socket.IO Websockets for fast real-time updates to chat participants and REST API for fetching chat history, listing chat rooms, and sending messages when real-time delivery is not required (e.g., loading old messages).

#### Rumour Service

NestJS as the chosen framework provides a modular structure (controllers, services, modules) that fits perfectly with microservice architecture. It also has built-in support for dependency injection, making testing and scaling easier. TypeScript adds static typing, which reduces runtime errors and makes the codebase more maintainable, especially when the service grows. As a database, PostgreSQL is a reliable, SQL-compliant relational database. It handles structured data (rumors, player purchases) with relationships very well, being not case sensitive like MySQL. With Prisma ORM makes database access type-safe and developer-friendly. It generates TypeScript types directly from the schema, which reduces mistakes when querying or updating data, this means less boilerplate and safer operations when storing rumors and linking them to players. REST API (JSON) is used for player interactions - easy to set up, human-readable, lightweight, and widely supported.

Event-based subscriptions from Task/Character Services - Not all rumors are static. They may depend on what’s happening in other services (tasks being completed, character appearance changing). Event-based subscriptions let the Rumors Service automatically update its rumor pool without tightly coupling it to other services. This ensures fresh, relevant rumors and keeps each service independent (Task Service doesn’t need to know Rumors Service exists — it just emits events). Task Service and Character Service send events (or expose APIs) that the Rumors Service uses to populate and update the rumor pool.
Purchased rumors are saved under the player’s ID for retrieval.

#### Task Service

The Task Service will be written in Go with PostgreSQL, designed to assign daily tasks to players based on their roles and careers. Tasks may involve using specific items, visiting locations, or interacting with other players, and completing them rewards in-game currency. PostgreSQL stores task definitions, player progress, and reward history with relational integrity, ensuring accurate tracking of completed and pending tasks. For the communication pattern, the service will expose REST APIs for Game Service queries about available tasks and player progress. Additionally, it will publish events to notify other services, such as Rumors Service or Character Service, about task completions or state changes, enabling real-time updates without tight coupling. This design allows Task Service to reliably manage task assignments while keeping interactions lightweight and scalable.

#### Voting Service

The Voting Service will be written in Go with PostgreSQL and is responsible for collecting and counting votes each evening to determine which players are eliminated under the Mafia mechanics. It records who voted for whom on each day, as well as the final outcome of each vote. PostgreSQL ensures accurate, auditable storage of all voting data. For the communication pattern, the service provides REST APIs for the Game Service to retrieve voting results and current tallies, while also exposing event notifications to update related services in real time. This architecture maintains consistency and responsiveness, allowing the Game Service to reflect voting outcomes immediately while keeping Voting Service decoupled from other gameplay systems.

### Communication Patterns

#### Synchronous (REST APIs)

Services communicate directly using request/response interactions when immediate feedback is required. This pattern is suitable for user-facing operations such as login, booking queries, or data retrieval. The technology stack includes Go with PostgreSQL, Python (FastAPI) with PostgreSQL, Java (Spring Boot) with Redis for caching or session management, TypeScript (NestJS) with Prisma ORM and PostgreSQL, and TypeScript (NodeJS) with PostgreSQL and Redis. REST APIs provide simplicity and are easy to debug, but they create temporary coupling between services, meaning that slow or unavailable downstream services can block requests.

#### Real-Time (WebSockets)

For low-latency, bidirectional communication, services use WebSockets. This approach supports live chat, notifications, and other real-time user interactions. Technologies include SignalR or native WebSocket implementations in NodeJS or Go. WebSockets provide instant updates and a responsive user experience, but maintaining open connections requires careful resource management and scaling considerations.

### Communication Contract

Services communicate using REST APIs for immediate queries and WebSockets for real-time updates. The User Management and Game Services (NodeJS + PostgreSQL + Redis) handle user profiles, authentication, in-game currency, device and location info, day/night cycles, lobby management, event notifications, and voting initiation. The Shop and Roleplay Services (Spring Boot + Redis) manage item purchases, currency, daily preparation, role abilities, announcements, and activity balancing.

The Town and Character Services (FastAPI + PostgreSQL) track locations and movements, manage character customization, inventory, asset slots, and creative features. Rumors and Communication Services (NestJS + Prisma ORM + PostgreSQL) generate purchasable role-based rumors and manage global and private chats, voting-hour communication, and Mafia group chats. Task and Voting Services (Go + PostgreSQL) assign daily tasks by role, reward currency, collect and count votes, and notify the Game Service of results.

WebSockets provide live chat, notifications, and voting updates, ensuring interactive gameplay and responsive, decoupled communication between services.

| Member           | Service(s)                                | Responsibilities                                                                                                                                                 | Technology Stack                              |
| ---------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| Cucos Maria      | **User Management Service, Game Service** | Manage user profiles, authentication, in-game currency, device/location info; handle day/night cycle, lobby management, event notifications, and initiate voting | Typescript (NodeJS) + PostgreSQL + Redis      |
| Mihalachi Mihail | **Shop Service, Roleplay Service**        | Handle in-game item purchases, currency management, daily preparation mechanics; enforce role abilities, generate filtered announcements, balance daily activity | Java (Springboot) + Redis                     |
| Garbuz Nelli     | **Town Service, Character Service**       | Track locations and movements, report to Task Service; manage character customization and inventory, asset slots, and creative features                          | Python (FastAPI) + PostgreSQL                 |
| Frunza Valeria   | **Rumors Service, Communication Service** | Generate role-based rumors purchasable with currency; manage global and private chats, voting-hour communication, and Mafia group chats                          | Typescript (NestJS) + Prisma ORM + PostgreSQL |
| Lupan Lucian     | **Task Service, Voting Service**          | Assign daily tasks per role/career, reward currency for completion; collect and count votes each evening, notify Game Service of results                         | Go + PostgreSQL                               |

## Data Management

### User Management Service

#### Authentication Endpoints

- Endpoint for user registration

```
Endpoint: /auth/register
Method: POST
Payload: {
  "email": "player@example.com",
  "username": "playerName",
  "password": "hashedPassword",
  "identification": "ID_12345",
  "deviceFingerprint": "device_hash_abc123",
  "locationData": {
    "ip": "192.168.1.1",
    "country": "Moldova",
    "city": "Chisinau"
  }
}

// SUCCESS
Response: {
  "status": "success",
  "userId": "user_123",
  "message": "Account created successfully"
}

// EMAIL ALREADY EXISTS
Response: {
  "status": "error",
  "code": "EMAIL_EXISTS",
  "message": "An account with this email already exists"
}

// USERNAME TAKEN
Response: {
  "status": "error",
  "code": "USERNAME_TAKEN", 
  "message": "This username is already taken"
}

// DEVICE ALREADY REGISTERED
Response: {
  "status": "error",
  "code": "DEVICE_CONFLICT",
  "message": "This device is already registered to another account",
  "conflictingUser": "existingPlayer"
}

// INVALID INPUT
Response: {
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Invalid input data",
  "errors": {
    "email": "Invalid email format",
    "password": "Password must be at least 8 characters",
    "username": "Username must be 3-20 characters"
  }
}

// SERVER ERROR
Response: {
  "status": "error",
  "code": "INTERNAL_ERROR",
  "message": "Registration failed due to server error"
}
```

- Endpoint for user login

```
Endpoint: /auth/login
Method: POST
Payload: {
  "email": "player@example.com",
  "password": "hashedPassword",
  "deviceFingerprint": "device_hash_abc123"
}

// SUCCESS
Response: {
  "status": "success",
  "accessToken": "jwt_token_here",
  "refreshToken": "refresh_token_here",
  "user": {
    "userId": "user_123",
    "username": "playerName"
  }
}

// INVALID CREDENTIALS
Response: {
  "status": "error",
  "code": "INVALID_CREDENTIALS",
  "message": "Invalid email or password"
}

// MISSING FIELDS
Response: {
  "status": "error",
  "code": "MISSING_FIELDS",
  "message": "Email and password are required"
}
```

- Endpoint for token validation

```
Endpoint: /auth/validate
Method: POST
Payload: {
  "token": "jwt_token_here"
}

// VALID TOKEN
Response: {
  "status": "valid",
  "userId": "user_123",
  "username": "playerName"
}

// INVALID/EXPIRED TOKEN
Response: {
  "status": "invalid",
  "code": "TOKEN_INVALID",
  "message": "Token is invalid or expired"
}

// MISSING TOKEN
Response: {
  "status": "invalid",
  "code": "TOKEN_MISSING",
  "message": "Token is required"
}
```

#### User Profile Endpoints

- Get user profile

```
Endpoint: /users/{userId}
Method: GET

// SUCCESS
Response: {
  "userId": "user_123",
  "username": "playerName",
  "email": "player@example.com",
  "accountCreated": "2025-01-15T10:30:00Z",
  "currentGameId": "game_456",
  "isInGame": true,
  "globalCurrency": 250,
  "inGameCurrency": 75
}

// USER NOT FOUND
Response: {
  "status": "error",
  "code": "USER_NOT_FOUND",
  "message": "User not found"
}
```

#### Currency Management Endpoints

- Update global currency

```
Endpoint: /users/{userId}/currency/global
Method: PATCH
Payload: {
  "amount": 50,
  "operation": "add",
  "reason": "game_victory"
}

// SUCCESS
Response: {
  "status": "success",
  "globalCurrency": 300,
  "previousCurrency": 250,
  "operation": "add",
  "amount": 50
}

// INSUFFICIENT FUNDS (for subtract operation)
Response: {
  "status": "error",
  "code": "INSUFFICIENT_FUNDS",
  "globalCurrency": 100,
  "attemptedAmount": 150,
  "operation": "subtract"
}
```

- Update in-game currency

```
Endpoint: /users/{userId}/currency/ingame
Method: PATCH
Payload: {
  "amount": 25,
  "operation": "subtract",
  "reason": "item_purchase"
}

// SUCCESS
Response: {
  "status": "success",
  "inGameCurrency": 50,
  "previousCurrency": 75,
  "operation": "subtract",
  "amount": 25
}

// INSUFFICIENT FUNDS (for subtract operation)
Response: {
  "status": "error",
  "code": "INSUFFICIENT_FUNDS",
  "inGameCurrency": 20,
  "attemptedAmount": 25,
  "operation": "subtract"
}

// USER NOT IN GAME
Response: {
  "status": "error",
  "code": "USER_NOT_IN_GAME",
  "message": "User is not currently in a game"
}
```

- Get currency balances

```
Endpoint: /users/{userId}/currency
Method: GET

// SUCCESS (user in game)
Response: {
  "userId": "user_123",
  "globalCurrency": 250,
  "inGameCurrency": 100,
  "gameId": "game_456"
}

// SUCCESS (user not in game)
Response: {
  "userId": "user_123",
  "globalCurrency": 250,
  "inGameCurrency": 0,
  "gameId": null
}

// USER NOT FOUND
Response: {
  "status": "error",
  "code": "USER_NOT_FOUND",
  "message": "User not found"
}
```

### Game Service

#### Lobby Management Endpoints

- Create game lobby

```
Endpoint: /games/create
Method: POST
Payload: {
  "hostUserId": "user_123",
  "maxPlayers": 15
}

// SUCCESS
Response: {
  "status": "success",
  "gameId": "game_789",
  "gameCode": "MAFIA123",
  "hostUserId": "user_123",
  "maxPlayers": 15,
  "currentPlayers": 1,
  "status": "waiting"
}

// INVALID SETTINGS
Response: {
  "status": "error",
  "code": "INVALID_SETTINGS",
  "message": "Max players must be between 6 and 30"
}
```

- Join game

```
Endpoint: /games/{gameId}/join
Method: POST
Payload: {
  "userId": "user_456",
  "gameCode": "MAFIA123"
}

// SUCCESS
Response: {
  "status": "success",
  "gameId": "game_789",
  "playerCount": 2,
  "gameStatus": "waiting"
}

// GAME FULL
Response: {
  "status": "error",
  "code": "GAME_FULL",
  "message": "Game has reached maximum capacity",
  "maxPlayers": 15,
  "currentPlayers": 15
}

// INVALID GAME CODE
Response: {
  "status": "error",
  "code": "INVALID_GAME_CODE",
  "message": "Incorrect game code"
}
```

- Leave game

```
Endpoint: /games/{gameId}/leave
Method: POST
Payload: {
  "userId": "user_456"
}

// SUCCESS
Response: {
  "status": "success",
  "message": "Successfully left game",
  "playerCount": 1
}

// PLAYER NOT IN GAME
Response: {
  "status": "error",
  "code": "PLAYER_NOT_IN_GAME",
  "message": "Player is not in this game"
}
```

- Get game status

```
Endpoint: /games/{gameId}
Method: GET

// SUCCESS (waiting)
Response: {
  "gameId": "game_789",
  "status": "waiting",
  "hostUserId": "user_123",
  "gameCode": "MAFIA123",
  "maxPlayers": 15,
  "currentPlayers": 2,
  "players": [
    {
      "userId": "user_123",
      "username": "playerName",
      "isHost": true
    },
    {
      "userId": "user_456",
      "username": "player2",
      "isHost": false
    }
  ]
}

// SUCCESS (in progress)
Response: {
  "gameId": "game_789",
  "status": "in_progress",
  "currentPhase": "day",
  "dayCount": 3,
  "players": [
    {
      "userId": "user_123",
      "username": "playerName",
      "isAlive": true,
      "role": "mafia",
      "career": "godfather"
    },
    {
      "userId": "user_456",
      "username": "player2",
      "isAlive": false,
      "role": "citizen",
      "career": "baker"
    }
  ],
  "aliveCount": 8,
  "totalPlayers": 12
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "code": "GAME_NOT_FOUND",
  "message": "Game does not exist"
}
```

#### Game State Endpoints

- Start game

```
Endpoint: /games/{gameId}/start
Method: POST
Payload: {
  "hostUserId": "user_123"
}

// SUCCESS
Response: {
  "status": "success",
  "gameId": "game_789",
  "currentPhase": "day",
  "dayCount": 1,
  "totalPlayers": 12,
  "message": "Game started! Day 1 begins."
}

// NOT HOST
Response: {
  "status": "error",
  "code": "UNAUTHORIZED",
  "message": "Only the host can start the game"
}

// INSUFFICIENT PLAYERS
Response: {
  "status": "error",
  "code": "INSUFFICIENT_PLAYERS",
  "message": "Need at least 6 players to start",
  "currentPlayers": 2,
  "minimumPlayers": 6
}

// GAME ALREADY STARTED
Response: {
  "status": "error",
  "code": "GAME_ALREADY_STARTED",
  "message": "Game is already in progress"
}
```

- End game

```
Endpoint: /games/{gameId}/end
Method: POST
Payload: {
  "winCondition": "mafia_victory",
  "winners": ["user_123", "user_789"]
}

// SUCCESS
Response: {
  "status": "success",
  "message": "Game ended",
  "winCondition": "mafia_victory",
  "winners": ["user_123", "user_789"]
}
```

#### Player State Management Endpoints

- Get player info

```
Endpoint: /games/{gameId}/players/{userId}
Method: GET

// SUCCESS
Response: {
  "userId": "user_123",
  "gameId": "game_789",
  "role": "mafia",
  "career": "godfather",
  "isAlive": true,
  "currentPhase": "day",
  "dayCount": 3
}

// PLAYER NOT IN GAME
Response: {
  "status": "error",
  "code": "PLAYER_NOT_IN_GAME",
  "message": "Player is not in this game"
}
```

- Update player alive status

```
Endpoint: /games/{gameId}/players/{userId}/status
Method: PATCH
Payload: {
  "isAlive": false,
  "cause": "voted_out"
}

// SUCCESS
Response: {
  "status": "success",
  "userId": "user_123",
  "isAlive": false,
  "cause": "voted_out",
  "aliveCount": 7
}
```

### Phase Management Endpoints (for Town Service)

- Update game phase

```
Endpoint: /games/{gameId}/phase
Method: PATCH
Payload: {
  "newPhase": "night",
  "dayCount": 3
}

// SUCCESS
Response: {
  "status": "success",
  "gameId": "game_789",
  "previousPhase": "day",
  "currentPhase": "night",
  "dayCount": 3
}

// INVALID PHASE
Response: {
  "status": "error",
  "code": "INVALID_PHASE",
  "message": "Phase must be 'day' or 'night'"
}
```

- Get current phase

```
Endpoint: /games/{gameId}/phase
Method: GET

// SUCCESS
Response: {
  "gameId": "game_789",
  "currentPhase": "day",
  "dayCount": 3
}
```

#### Voting Management Endpoints

- Get eligible voters (alive players)

```
Endpoint: /games/{gameId}/voting
Method: GET

// SUCCESS
Response: {
  "gameId": "game_789",
  "eligibleVoters": [
    {
      "userId": "user_123",
      "username": "playerName"
    },
    {
      "userId": "user_456",
      "username": "player2"
    }
  ],
  "eligibleCount": 2
}

// NO ELIGIBLE VOTERS
Response: {
  "status": "error",
  "code": "NO_ELIGIBLE_VOTERS",
  "message": "No alive players available for voting"
}
```

#### Event Broadcasting Endpoints

- Broadcast game event

```
Endpoint: /games/{gameId}/events/broadcast
Method: POST
Payload: {
  "eventType": "player_death",
  "message": "PlayerName was found dead!",
  "targetPlayers": "all",
  "metadata": {
    "eliminatedPlayerId": "user_456",
    "eliminatedUsername": "player2",
    "cause": "mafia_kill"
  }
}

// WHEN PLAYER GETS EXILED
Payload: {
  "eventType": "player_elimination",
  "message": "player2 has been voted out of the town!",
  "targetPlayers": "all",
  "metadata": {
    "eliminatedPlayerId": "user_456",
    "eliminatedUsername": "player2",
    "voteCount": 5,
    "cause": "voted_out"
  }
}

// SUCCESS
Response: {
  "status": "success",
  "eventId": "event_303",
  "broadcastTime": "2025-01-15T22:31:00Z",
  "recipients": 8
}

// INVALID EVENT TYPE
Response: {
  "status": "error",
  "code": "INVALID_EVENT_TYPE",
  "message": "Event type must be one of: player_death, player_elimination, healing, rumor, visit"
}
```

### Shop Service

#### Shop Endpoints

- Endpoint for listing all of the available items

```
Endpoint: /items
Method: GET
Response: [
  {
    "id": "item_1",
    "name": "Fire Extinguisher",
    "description": "Offers protection against the arsonist  during the night (Dissapears in the daytime)",
  },
  {
    "id": "item_2",
    "name": "Garlic String",
    "description": "Offers protection against the vampires suring the night (Dissapears in the daytime)",
  },
]

```

- Endpoint for listing all of the items available in the shop during the game

```
Endpoint: /shop
Method: GET
Response: [
  {
    "id": "item_1",
    "name": "Fire Extinguisher",
    "description": "Offers protection against the arsonist  during the night (Dissapears in the daytime)",
  },
]

```

- Endpoint for purchasing an item

```
Endpoint: /purchase
Method: POST
Payload: {
  "userId": "user",
  "itemId": "item",
}
Response: {
  "status": "success"
}

```

### Roleplay Service

#### Role actions endpoints

- Endpoint for perform an action associated with the player’s role (e.g., Mafia kill, Sheriff investigation)

```
Endpoint: /roles/{playerId}/actions
Method: POST
Payload: {
  "targetId": "user",
  "action": "kill",
}
Response: {
  "success": true,
  "description": "Target protected by garlic",
  "timestamp": "2025-09-07T19:05:00Z"
}
```

- Endpoint for retrieving a log of all role-based actions attempted by a player.

```
Endpoint: /roles/{playerId}/actions/history
Method: GET
Response: [
  { "action": "kill", "targetId": "user_1", "success": false, "timestamp": "2025-09-07T19:00:00Z" },
  { "action": "investigate", "targetId": "user_2", "success": true, "timestamp": "2025-09-07T19:05:00Z" }
]
```

#### Announcement endpoints

- Endpoint for creating a filtered announcement (e.g., “_[Player]_ was killed last night” without exposing the killer). role (e.g., Mafia kill, Sheriff investigation)

```
Endpoint: /announcements
Method: POST
Payload: {
  "type": "death",
  "details": {
    "userId": "user_1"
  }
}
Response: 201 OK
```

- Endpoint for getting the announcements created by the Roleplay Service to be forwarded to the Game Service.

```
Endpoint: /announcements
Method: GET
Response: [
  { "id": "ann_1", "type": "death", "message": "[Player] was killed during the night" },
  { "id": "ann_2", "type": "investigation", "message": "Sheriff investigated [Player 456]" }
]
```

#### Ability validation endpoints

- Endpoint for checking if a player’s role action is allowed based on the role rules and defensive items.

```
Endpoint: /validate
Method: POST
Payload: {
  "userId": "user_1",
  "action": "kill",
  "targetId": "user_456"
}
Response: {
  "valid": false,
  "reason": "The house was protected from your attacks"
}
```

### Town Service

The chosen database is PostgreSQL, which offers robust support for spatial data types and queries, which is essential for tracking user locations and movements across different town areas. Its ACID compliance ensures data consistency when recording location changes and user activities. SQLAlchemy ORM provides type-safe database operations and seamless async support, enabling efficient database interactions without blocking the event loop during location updates and queries. All messages passed will be in JSON format, with the following requests and responses expected for each Service and endpoint:

#### Location Management endpoints

- Endpoint for retrieveing all the available locations

```
Endpoint: /locations
Method: GET
Response: {
    locations:[
  {
    "id": "loc_1",
    "name": "Shop",
    "type": "special",
    "description": "Main town shop",
    "coordinates": { "x": 10, "y": 25 }
  }
  ]
}

```

- Endpoint getting details of a specific location

```
Endpoint: /locations/{location_id}
Method: GET
Response:
  {
    "id": "loc_1",
    "name": "Shop",
    "type": "special",
    "description": "Main town shop",
    "coordinates": { "x": 10, "y": 25 }
  }
```

- Endpoint for adding a new locations

```
Endpoint: /locations
Method: POST
Payload:
  {
    "name": "Informator Bureau",
    "type": "special",
    "description": "Quest information center",
    "coordinates": { "x": 15, "y": 40 }
  }
Response: 201 OK
```

- Endpoint for updating a location

```
Endpoint: /locations/{location_id}
Method: POST
Payload:
  {
    "name": "Grand Shop",
    "description": "Main town shop with upgraded items",
    "coordinates": { "x": 12, "y": 27 }
  }
Response: 200 OK
```

- Endpoint for deleting a location

```
Endpoint: /locations/{location_id}
Method: DELETE
Response: 204 No content
```

#### User Movements endpoints

- Endpoint for recording a movement event

```
Endpoint: /movements
Method: POST
Payload:
  {
    "user_id": "user_123",
    "from_location": "loc_2",
    "to_location": "loc_1",
    "timestamp": "2025-09-07T09:30:00Z"
  }
Response: 201 OK
```

- Endpoint to list all the movements

```
Endpoint: /movements
Method: GET
Response:{
    movements:[
  {
    "movement_id": "mv_1001"
    "user_id": "user_123",
    "from_location": "loc_2",
    "to_location": "loc_1",
    "timestamp": "2025-09-07T09:30:00Z"
  }
    ]
}
```

- Endpoint of the history of a user's movements

```
Endpoint: /users/{user_id}/movements
Method: GET
Response:{
    movements:[
  {
    "movement_id": "mv_1001"
    "from_location": "loc_2",
    "to_location": "loc_1",
    "timestamp": "2025-09-07T09:30:00Z"
  }
    ]
}
```

- Endpoint of all movements involving a specific location

```
Endpoint: /locations/{location_id}/movements
Method: GET
Response:{
    movements:[
  {
    "movement_id": "mv_1001"
    "user_id": "user_123",
    "from_location": "loc_2",
    "to_location": "loc_1",
    "timestamp": "2025-09-07T09:30:00Z"
  }
    ]
}
```

### Character Service

For the data, PostgreSQL with SQLAlchemy ORM will be used. PostgreSQL's JSON and JSONB support is ideal for storing flexible character asset configurations and inventory data structures. Its relational capabilities efficiently handle the many-to-many relationships between users, owned assets, equipped items, and available customization slots. All messages passed will be in JSON format, with the following requests and responses expected for each endpoint:

#### Character Profile and Customization endpoints

- Endpoint for getting user's character

```
Endpoint: /characters/{user_id}
Method: GET
Response: {
  "userId": "user_123",
  "appearance": {
    "hair": "blonde_curly",
    "coat": "red_jacket",
    "accessory": "gold_watch",
    "face": "cheerful_smile",
    "pants": "dark_jeans"
  },
  "slots": {
    "hair_accessory": "baseball_cap",
    "jewelry": "silver_ring",
    "shoes": "leather_boots"
  }
}
```

- Endpoint for updating character appearance

```
Endpoint: /characters/{user_id}
Method: PUT
Payload: {
  "appearance": {
    "hair": "black_straight",
    "coat": "blue_hoodie",
    "accessory": "sunglasses"
  },
  "slots": {
    "hair_accessory": "headband",
    "jewelry": "gold_necklace"
  }
}
Response: 200 OK
```

- Endpoint for creating initial character

```
Endpoint: /characters
Method: POST
Payload: {
  "userId": "user_456",
  "appearance": {
    "hair": "brown_wavy",
    "coat": "green_shirt",
    "accessory": "wristwatch"
  }
}
Response: 201 Created
```

#### Assets and slots endpoints

- Endpoint for getting all available customization assets

```
Endpoint: /assets
Method: GET
Response: {
  "assets": [
    {
      "id": "blonde_curly",
      "category": "hair",
      "name": "Blonde Curly Hair",
      "description": "Curly blonde hairstyle",
      "imageUrl": "/assets/hair/blonde_curly.png"
    },
    {
      "id": "red_jacket",
      "category": "coat",
      "name": "Red Leather Jacket",
      "description": "Stylish red leather jacket",
      "imageUrl": "/assets/coats/red_jacket.png"
    }
  ]
}
```

- Endpoint for getting available cusotmization slots

```
Endpoint: /assets/slots
Method: GET
Response: {
  "slots": [
    {
      "name": "hair",
      "displayName": "Hairstyle",
      "required": true,
      "category": "appearance"
    },
    {
      "name": "hair_accessory",
      "displayName": "Hair Accessory",
      "required": false,
      "category": "slots"
    },
    {
      "name": "coat",
      "displayName": "Outerwear",
      "required": true,
      "category": "appearance"
    }
  ]
}
```

- Endpoint for getting a specific asset details

```
Endpoint: /assets/{asset_id}
Method: GET
Response: {
  "id": "red_jacket",
  "category": "coat",
  "name": "Red Leather Jacket",
  "description": "A stylish red leather jacket perfect for making a statement",
  "imageUrl": "/assets/coats/red_jacket.png",
}
```

#### Inventory Management endpoints

- Endpoint for getting user's inventory

```
Endpoint: /inventory/{user_id}
Method: GET
Response: {
  "userId": "user_123",
  "items": [
    {
      "itemId": "body_armor",
      "name": "Bulletproof Vest",
      "quantity": 1,
      "durability": 3,
      "maxDurability": 3,
      "purchasePrice": 150,
      "type": "protection",
      "description": "Protects against mafia attacks during night phase"
    },
    {
      "itemId": "fake_id",
      "name": "False Identity Papers",
      "quantity": 1,
      "durability": 1,
      "maxDurability": 1,
      "purchasePrice": 200,
      "type": "deception",
      "description": "Hide your true role from investigation"
    }
  ]
}
```

- Endpoint for adding item to inventory

```
Endpoint: /inventory/{user_id}/items
Method: POST
Payload: {
  "itemId": "listening_device",
  "name": "Wire Tap Device",
  "quantity": 1,
  "durability": 4,
  "purchasePrice": 100,
  "type": "surveillance"
}
Response: 201 Created
```

- Endpoint for using an item

```
Endpoint: /inventory/{user_id}/items/{item_id}/use
Method: PUT
Payload: {
  "usageContext": "night_attack_defense",
  "gameId": "game_789",
  "targetLocation": "warehouse_district"
}
Response: {
  "success": true,
  "itemId": "body_armor",
  "remainingDurability": 2,
  "effectApplied": "attack_protection_active"
}
```

- Endpoint for checking if user has specific item type

```
Endpoint: /inventory/{user_id}/items/type/{item_type}
Method: GET
Response: {
  "hasItem": true,
  "items": [
    {
      "itemId": "body_armor",
      "quantity": 1,
      "durability": 2
    }
  ]
}
```

- Endpoint for removing an item

```
Endpoint: /inventory/{user_id}/items/{item_id}
Method: DELETE
Response: 204 No Content
```

### Rumour Service

- Endpoint when player spends currency to get a random rumor.

```
Endpoint:  /rumors/buy
Method: POST
Request:
{
  "playerId": "123e4567-e89b-12d3-a456-426614174000",
  "currencySpent": 50
}
Response:
{
  "rumorId": "987e6543-e21b-12d3-a456-426614174999",
  "content": "Player X was last seen near the warehouse.",
  "category": "task"
}
```

- Fetch all rumors a player has purchased.

```
Endpoint: /rumors/:playerId
Method: GET
Response:
[
  {
    "rumorId": "987e6543-e21b-12d3-a456-426614174999",
    "content": "Player X was last seen near the warehouse.",
    "category": "task"
  },
  {
    "rumorId": "321e6543-e21b-12d3-a456-426614174111",
    "content": "Player Y has been acting suspiciously.",
    "category": "appearance"
  }
]
```

- (Admin/debug use) Preview a random rumor from the pool.

```
Endpoint: /rumors/random
Method: GET
Response:
{
  "rumorId": "111e6543-e21b-12d3-a456-426614174222",
  "content": "One of the players is secretly a doctor.",
  "category": "role"
}
```

#### Inter-Service Communication

**Outbound Events**

- The service publishes events when rumors are purchased:

```json
{
  "event": "rumor_purchased",
  "data": {
    "playerId": "string",
    "gameId": "string",
    "rumorType": "string",
    "currencySpent": "number",
    "targetPlayer": "string"
  }
}
```

**Inbound Events**

- The service listens for events from other services to generate rumors:

```json
{
  "event": "task_completed",
  "data": {
    "playerId": "string",
    "taskType": "string",
    "location": "string",
    "timestamp": "string"
  }
}
```

### Communication Service

- Endpoint to send a message to a chat room.

```Endpoint: /chat/send
Method: POST
Request:
{
  "chatRoomId": "abc123",
  "senderId": "player123",
  "content": "Did anyone see who was near the warehouse?"
}
Response:
{
  "messageId": "msg987",
  "chatRoomId": "abc123",
  "senderId": "player123",
  "content": "Did anyone see who was near the warehouse?",
  "createdAt": "2025-09-07T12:00:00Z"
}
```

- Fetch all messages for a chat room.

```
Endpoint: /chat/:chatRoomId/messages
Method: GET
Respponse:
[
  {
    "messageId": "msg987",
    "senderId": "player123",
    "content": "Did anyone see who was near the warehouse?",
    "createdAt": "2025-09-07T12:00:00Z"
  },
  {
    "messageId": "msg988",
    "senderId": "player456",
    "content": "I saw Player X heading towards the dock.",
    "createdAt": "2025-09-07T12:01:30Z"
  }
]
```

- Fetch all chat rooms a player has access to (Mafia, location-based, or global during voting hours).

```
Endpoint: /chat/rooms/:playerId
Method: GET
Response:
[
  {
    "chatRoomId": "room123",
    "name": "Global Voting Chat",
    "type": "global"
  },
  {
    "chatRoomId": "room456",
    "name": "Mafia Strategy",
    "type": "mafia"
  }
]
```

### Task Service

#### Task management endpoints

- Endpoint for task creation

```
Endpoint: /tasks
Method: POST
Payload: {
  "role": "cop",
  "task_description": "Perform a routine checkup on locations x, y and z."
}
Response: 201 Created
```

- Endpoint for tasks retrieval

```
Endpoint: /tasks
Method: GET
Response: {
  "tasks": [
    {
      "task_id": 1,
      "role": "cop",
      "task_description": "Perform a routine checkup on locations x, y and z."
    },
    {
      "task_id": 2,
      "role": "doctor",
      "task_description": "Perform a physical on player x."
    }
  ]
}
Response: 200 OK
```

- Endpoint for task retrieval

```
Endpoint: /tasks/{task_id}
Method: GET
Response: {
  "task_id": 1,
  "role": "cop",
  "task_description": "Perform a routine checkup on locations x, y and z."
}
Response: 200 OK
```

- Endpoint for updating task

```
Endpoint: /tasks/{task_id}
Method: PUT
Payload: {
  "role": "cop",
  "task_description": "Perform a routine checkup on locations x, y and z AND investigate players x, y and z."
}
Response: 200 OK
```

- Endpoint for task removal

```
Endpoint: /tasks/{task_id}
Method: DELETE
Response: 204 No Content
```

#### Task assignment endpoints

- Endpoint for assigning task

```
Endpoint: /tasks/assign
Method: POST
Payload: {
  "user_id": 1,
  "task_id": 3
}
Response: 201 Created
```

- Endpoint for removing assigned task

```
Endpoint: /tasks/assign
Method: DELETE
Payload: {
  "user_id": 1,
  "task_id": 3
}
Response: 204 No Content
```

#### Task status endpoint

- Endpoint for getting task status at the end of the day

```
Endpoint: /tasks/status
Method: GET
Response: {
  "tasks": [
    {
      "user_id": 1,
      "task_completed": true
    },
    {
      "user_id": 2,
      "task_completed": false
    }
  ]
}
Response: 200 OK
```

### Voting Service

#### Voting control endpoints

- Endpoint for voting a player

```
Endpoint: /votes
Method: POST
Payload: {
  "user_id": 1,
  "voted_user_id": 3
}
Response: 201 Created
```

- Endpoint for getting all votes

```
Endpoint: /votes
Method: GET
Response: {
  "votes": [
    {
      "user_id": 1,
      "voted_user_id": 3
    },
    {
      "user_id": 2,
      "voted_user_id": 1
    }
  ]
}
Response: 200 OK
```

- Endpoint for getting a player's vote

```
Endpoint: /votes/{user_id}
Method: GET
Response: {
  "user_id": 2,
  "voted_user_id": 1
}
Response: 200 OK
```

- Endpoint for removing a vote on a player

```
Endpoint: /votes/{user_id}
Method: DELETE
Response: 204 No Content
```

#### Voting results endpoints

- Endpoint for getting the voting results

```
Endpoint: /votes/results
Method: GET
Response: {
  "results": [
    {
      "user_id": 1,
      "votes": 5
    },
    {
      "user_id": 2,
      "votes": 1
    }
  ]
}
Response: 200 OK
```

#### Voting logs endpoints

- Endpoint for creating voting logs

```
Endpoint: /votes/logs/{day}
Method: PUT
Payload: {
  "voting": [
    {
      "user_id": 1,
      "voted_user_id": 2
    },
    {
      "user_id": 2,
      "voted_user_id": 1
    },
    {
      "user_id": 3,
      "voted_user_id": 1
    }
  ],
  "results": [
    {
      "user_id": 1,
      "votes": 2
    },
    {
      "user_id": 2,
      "votes": 1
    }
  ],
  "voted_out_id": 1
}
Response: 201 Created
```

- Endpoint for getting voting logs

```
Endpoint: /votes/logs
Method: GET
Response: {
  "day1": {
    "voting": [
      {
        "user_id": 1,
        "voted_user_id": 2
      },
      {
        "user_id": 2,
        "voted_user_id": 1
      },
      {
        "user_id": 3,
        "voted_user_id": 1
      }
    ],
    "results": [
      {
        "user_id": 1,
        "votes": 2
      },
      {
        "user_id": 2,
        "votes": 1
      }
    ],
    "voted_out_id": 1
  }
}
Reponse: 200 OK
```

## Github workflow

### Branch structure

- main
- develop

### Protection rules

Main branch:

- Require 2 approvals minimum
- Require branches to be up to date before merging
- Dismiss stale reviews when new commits are pushed
- Require status checks to pass

Develop branch:

- Require 1 approval minimum
- Allow direct commits for faster iteration
- Require status checks to pass
- No need to be up to date before merging

### Branching strategy

#### Naming convention

- Feature branches: feature/{service-description}
- Bugfix branches: bugfix/{service-issue-description}
- Hotfix branches: hotfix/{critical-issue}

## Commit message format

Follow conventional commits specification:

```
<type>(<scope>): <description>

[optional body]
```

Types: `feat `, `fix `, `docs `, `style `, `refactor `, `test `, `chore `

## Pull request requirements

- Clear title that is descriptive
- Detailed description
- Linked issues, if applicable
- Breaking changes - how it impacts other services, if applicable

## Test coverage

- Unit Tests - 80% code coverage minimum
