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
- Currency operations (add, subtract):
  - Global currency: "game_reward", "shop_purchase"
  - In-game currency: "task_reward", "item_purchase", "rumor_purchase"

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
- Redis Caching from pub/sub messaging.
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
<img width="6068" height="4300" alt="image" src="https://github.com/user-attachments/assets/088ba6ab-30bc-4fd8-a9d0-df53835ffb23" />


This microservices architecture is organized into three service clusters behind a load balancer and API gateway. The User and Identity cluster handles authentication and character management. The Game Core cluster contains the Game Service as the central hub coordinating with voting, roleplay, communication, and town services for real-time gameplay. The Economy and Commerce cluster manages the shop, tasks, and rumors system. Each cluster has its own database for data independence, while the Game Service acts as the main orchestrator communicating across all services to coordinate game flow and player interactions.

## Technology Stack and Communication Patterns

### Technology Stack

#### User Management Service

The User Management Service will be written in TypeScript with Node.js, which can handle concurrent authentication requests from up to 30 players per lobby joining simultaneously. JWT authentication provides secure token-based access control, while PostgreSQL ensures data integrity for user data and in-game currency with complex queries for device tracking and fraud prevention. For the communication pattern - Synchronous REST API with asynchronous event publishing enables fast authentication validation that improves user experience when joining a game, while effective fraud detection through device tracking protects app integrity. The service architecture provides reliable user authentication and authorization while maintaining the flexibility to publish events for other services to consume, though it requires additional complexity in managing token refresh cycles to maintain security standards.

#### Game Service

The Game Service will be written in TypeScript with Socket.io, providing real-time bidirectional communication for day/night cycle transitions, instant death notifications, and live voting updates essential for interactive gameplay. PostgreSQL with JSONB columns stores complex game objects while maintaining relational integrity for player relationships and game history queries, complemented by Redis caching for frequently accessed game state to achieve fast response times during active gameplay. For the communication pattern, the service relies on WebSocket connections for live updates. Redis is used only for caching and not for pub/sub, reducing infrastructure complexity while still improving performance for frequently accessed data. This simple architecture minimizes deployment overhead and maintains performance with a single database technology, though Redis caching increases memory usage.

#### Shop Service

The Shop Service will be written in Java Spring Boot, which has a lightweight nature and fast startup times, suitable for managing a microservice. It will be used for writing the algortihms necessary for checking which items should be sold during the game. For database manipulation Hibernate will be used with PostgreSQL for character customization storage. For storing temporary data like player currency during the game, Redis wil be used for fast communication and data retrieval between the shop service and the game service. The communication that the service will have are synchronous(REST API) between itself and Game Service for daytime shop item retrieval and purchasing, and another synchronous(REST API) communication between itself and Character Service for character customization items retrieval.

#### Roleplay Service

The Roleplay Service will be written in Java Spring Boot, which has a lightweight nature and fast startup times, suitable for managing a microservice. It will be used for writing the functionalities necessary for role abilities usage, their validation and announcement creation and recording. For temporary information that is present during gameplay Redis will be used for storing the announcements and later be sent to game service when needed. The service will communicate with Game Service through REST API for announcement sending and role ability validation.

#### Town Service

The Town Service will be written in Python with FastAPI, that provides rapid API development with automatic OpenAPI documentation generation, making it ideal for quick prototyping and iteration. FastAPI's native async support ensures the service can handle concurrent requests efficiently and maintain responsive performance when communicating with other services. For the communication pattern - REST API (JSON) for user location requests - straightforward implementation for location queries, movement commands, and area information retrieval. Town Service have to report to the Task Service, which enables event-based subscriptions, including location availability and accessibility that may change based on task completions, story progression, or time-based events. Event-driven architecture allows the Town Service to automatically update location states, unlock new areas, or modify existing locations without tight coupling to the Task Service.

#### Character Service

The Character Service will be written in Python FastAPI, which enables rapid development of character customization endpoints with automatic validation of asset combinations and slot constraints. FastAPI's built-in async support ensures smooth performance when handling multiple simultaneous character updates and inventory modifications. REST API (JSON) is going to be used for character customization and inventory queries - provides intuitive endpoints for asset selection, slot management, and inventory operations. Event-based communication with Shop Service - when users purchase items, the Character Service automatically updates inventory without tight coupling. The Shop Service emits purchase events that the Character Service subscribes to, ensuring real-time inventory synchronization. Event-based communication with User Service - character creation and updates may need to validate user permissions and currency deductions

#### Communication Service

NestJS is the chosen framework, whichprovides modular architecture (controllers, services, modules) with built-in dependency injection, ideal for microservice development. TypeScript on top of that adds static typing to reduce runtime errors and improve maintainability. The chosen database is Postgresql, which handles structured data, such as chat messages, player roles, and chat room membership. Via Type ORM it enables type-safe database access in TypeScript, minimizing errors and boilerplate code. The main communication patterns are Websockets for fast real-time updates to chat participants and REST API for fetching chat history, listing chat rooms, and sending messages when real-time delivery is not required (e.g., loading old messages). Redis is used for caching and pub/sub messaging.

#### Rumour Service

NestJS as the chosen framework provides a modular structure (controllers, services, modules) that fits perfectly with microservice architecture. It also has built-in support for dependency injection, making testing and scaling easier. TypeScript adds static typing, which reduces runtime errors and makes the codebase more maintainable, especially when the service grows. As a database, PostgreSQL is a reliable, SQL-compliant relational database. It handles structured data (rumors, player purchases) with relationships very well, being not case sensitive like MySQL. With Prisma ORM makes database access type-safe and developer-friendly. It generates TypeScript types directly from the schema, which reduces mistakes when querying or updating data, this means less boilerplate and safer operations when storing rumors and linking them to players. REST API (JSON) is used for player interactions - easy to set up, human-readable, lightweight, and widely supported.

Event-based subscriptions from Task/Character Services - Not all rumors are static. They may depend on what’s happening in other services (tasks being completed, character appearance changing). Event-based subscriptions let the Rumors Service automatically update its rumor pool without tightly coupling it to other services. This ensures fresh, relevant rumors and keeps each service independent (Task Service doesn’t need to know Rumors Service exists — it just emits events). Task Service and Character Service send events (or expose APIs) that the Rumors Service uses to populate and update the rumor pool.
Purchased rumors are saved under the player’s ID for retrieval.

The service implements role-based access control through currency requirements:

| **Role**          | **Category Access** | **Min Currency** | **Example**                |
| ----------------- | ------------------- | ---------------- | -------------------------- |
| **Mafia Roles**   | `task` rumors       | 200-299          | Mafioso, Assassin, Framer  |
| **Town Roles**    | `location` rumors   | 150-199          | Citizen, Doctor, Detective |
| **Special Roles** | `role` rumors       | 300+             | Detective, Scout           |
| **All Roles**     | `appearance` rumors | 100-149          | Any role can access        |

#### Task Service

The Task Service will be written in Python (Django) with PostgreSQL, designed to assign daily tasks to players based on their roles and careers. Tasks may involve using specific items, visiting locations, or interacting with other players, and completing them rewards in-game currency. PostgreSQL stores task definitions, player progress, and reward history with relational integrity, ensuring accurate tracking of completed and pending tasks. For the communication pattern, the service will expose REST APIs for Game Service queries about available tasks and player progress. Additionally, it will publish events to notify other services, such as Rumors Service or Character Service, about task completions or state changes, enabling real-time updates without tight coupling. This design allows Task Service to reliably manage task assignments while keeping interactions lightweight and scalable.

#### Voting Service

The Voting Service will be written in Python (Django) with PostgreSQL and is responsible for collecting and counting votes each evening to determine which players are eliminated under the Mafia mechanics. It records who voted for whom on each day, as well as the final outcome of each vote. PostgreSQL ensures accurate, auditable storage of all voting data. For the communication pattern, the service provides REST APIs for the Game Service to retrieve voting results and current tallies, while also exposing event notifications to update related services in real time. This architecture maintains consistency and responsiveness, allowing the Game Service to reflect voting outcomes immediately while keeping Voting Service decoupled from other gameplay systems.

### Communication Patterns

#### Synchronous (REST APIs)

Services communicate directly using request/response interactions when immediate feedback is required. This pattern is suitable for user-facing operations such as login, booking queries, or data retrieval. The technology stack includes Python (Django) with PostgreSQL, Python (FastAPI) with PostgreSQL, Java (Spring Boot) with Redis for caching or session management, TypeScript (NestJS) with Prisma ORM and PostgreSQL, and TypeScript (NodeJS) with PostgreSQL and Redis. REST APIs provide simplicity and are easy to debug, but they create temporary coupling between services, meaning that slow or unavailable downstream services can block requests.

#### Real-Time (WebSockets)

For low-latency, bidirectional communication, services use WebSockets. This approach supports live chat, notifications, and other real-time user interactions. Technologies include SignalR or native WebSocket implementations in NodeJS. WebSocketsGo provide instant updates and a responsive user experience, but maintaining open connections requires careful resource management and scaling considerations.

### Communication Contract

Services communicate using REST APIs for immediate queries and WebSockets for real-time updates. The User Management and Game Services (NodeJS + PostgreSQL + Redis) handle user profiles, authentication, in-game currency, device and location info, day/night cycles, lobby management, event notifications, and voting initiation. The Shop and Roleplay Services (Spring Boot + Redis) manage item purchases, currency, daily preparation, role abilities, announcements, and activity balancing.

The Town and Character Services (FastAPI + PostgreSQL) track locations and movements, manage character customization, inventory, asset slots, and creative features. Rumors and Communication Services (NestJS + Prisma ORM + PostgreSQL) generate purchasable role-based rumors and manage global and private chats, voting-hour communication, and Mafia group chats. Task and Voting Services (Django + PostgreSQL) assign daily tasks by role, reward currency, collect and count votes, and notify the Game Service of results.

WebSockets provide live chat, notifications, and voting updates, ensuring interactive gameplay and responsive, decoupled communication between services.

| Member           | Service(s)                                | Responsibilities                                                                                                                                                 | Technology Stack                                           |
| ---------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Cucos Maria      | **User Management Service, Game Service** | Manage user profiles, authentication, in-game currency, device/location info; handle day/night cycle, lobby management, event notifications, and initiate voting | Typescript (NodeJS) + PostgreSQL + Redis                   |
| Mihalachi Mihail | **Shop Service, Roleplay Service**        | Handle in-game item purchases, currency management, daily preparation mechanics; enforce role abilities, generate filtered announcements, balance daily activity | Java (Springboot) + Redis                                  |
| Garbuz Nelli     | **Town Service, Character Service**       | Track locations and movements, report to Task Service; manage character customization and inventory, asset slots, and creative features                          | Python (FastAPI) + PostgreSQL                              |
| Frunza Valeria   | **Rumors Service, Communication Service** | Generate role-based rumors purchasable with currency; manage global and private chats, voting-hour communication, and Mafia group chats                          | Typescript (NestJS) + Prisma/Type ORM + PostgreSQL + Redis |
| Lupan Lucian     | **Task Service, Voting Service**          | Assign daily tasks per role/career, reward currency for completion; collect and count votes each evening, notify Game Service of results                         | Django (REST Framework) + PostgreSQL                                            |

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
  "deviceFingerprint": "device_hash_abc123"
}

// SUCCESS
Response: {
  "status": "success",
  "userId": "user_123",
  "createdAt": "2025-01-15T10:30:00Z",
  "message": "Account created successfully"
}

// EMAIL ALREADY EXISTS
Response: {
  "status": "error",
  "message": "An account with this email already exists"
}

// USERNAME TAKEN
Response: {
  "status": "error",
  "message": "This username is already taken"
}

// DEVICE ALREADY REGISTERED
Response: {
  "status": "error",
  "message": "This device is already registered to another account",
  "conflictingUser": "existingPlayer"
}

// INVALID INPUT
Response: {
  "status": "error",
  "message": "Invalid input data",
  "errors": {
    "email": "Invalid email format",
    "password": "Password must be at least 8 characters",
    "username": "Username must be 3-20 characters"
  }
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
  "expiresAt": "2025-09-16T15:30:00Z",
  "refreshExpiresAt": "2025-09-23T15:30:00Z",
  "userId": "user_123",
  "username": "playerName"
}

// INVALID CREDENTIALS
Response: {
  "status": "error",
  "message": "Invalid email or password"
}

// MISSING FIELDS
Response: {
  "status": "error",
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
  "username": "playerName",
  "expiresAt": "2025-01-16T10:30:00Z"
}

// EXPIRED/INVALID/MISSING TOKEN
Response: {
  "status": "error",
  "message": "Invalid token"
}
```

- Delete account

```
Endpoint: /users/{userId}
Method: DELETE
Authorization: Bearer token required

// SUCCESS
Response: {
  "status": "success",
  "message": "Account deleted successfully"
}

// USER NOT FOUND
Response: {
  "status": "error",
  "message": "User not found"
}
```

#### User Profile Endpoints

- Get user profile

```
Endpoint: /users/{userId}
Method: GET
Authorization: Bearer token required

// SUCCESS
Response: {
  "status": "success",
  "userId": "user_123",
  "username": "playerName",
  "email": "player@example.com",
  "createdAt": "2025-01-15T10:30:00Z",
  "gameId": "game_456",
  "globalCurrency": 250,
  "inGameCurrency": 75
}

// USER NOT FOUND
Response: {
  "status": "error",
  "message": "User not found"
}
```

- Bulk user lookup for Game Service

```
Endpoint: /internal/users/bulk
Method: POST
Authorization: Bearer token required
Payload: {
  "userIds": ["user_123", "user_456", "user_789"]
}

// SUCCESS
Response: {
  "status": "success",
  "users": [
    {
      "userId": "user_123",
      "username": "playerName"
    },
    {
      "userId": "user_456",
      "username": "player2"
    },
    {
      "userId": "user_789",
      "username": "player3"
    }
  ],
  "notFound": [],
  "totalRequested": 3,
  "totalFound": 3
}

// PARTIAL SUCCESS
Response: {
  "status": "partial_success",
  "users": [
    {
      "userId": "user_123",
      "username": "playerName"
    }
  ],
  "notFound": ["user_456", "user_789"],
  "totalRequested": 3,
  "totalFound": 1
}

// NO USERS FOUND
Response: {
  "status": "error",
  "users": [],
  "notFound": ["user_123", "user_456"],
  "totalRequested": 2,
  "totalFound": 0
}
```

#### Currency Management Endpoints

- Update global currency

```
Endpoint: /users/{userId}/currency/global
Method: PATCH
Authorization: Bearer token required
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
  "amount": 50,
  "operation": "add",
  "reason": "game_victory"
}

// INSUFFICIENT FUNDS (for subtract operation)
Response: {
  "status": "error",
  "globalCurrency": 100,
  "attemptedAmount": 150,
  "operation": "subtract",
  "reason": "shop_purchase"
}
```

- Update in-game currency

```
Endpoint: /users/{userId}/currency/ingame
Method: PATCH
Authorization: Bearer token required
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
  "amount": 25,
  "operation": "subtract",
  "reason": "item_purchase"
}

// INSUFFICIENT FUNDS (for subtract operation)
Response: {
  "status": "error",
  "inGameCurrency": 20,
  "attemptedAmount": 25,
  "operation": "subtract",
  "reason": "rumor_purchase"
}

// USER NOT IN GAME
Response: {
  "status": "error",
  "message": "User is not currently in a game"
}
```

- Get currency balances

```
Endpoint: /users/{userId}/currency
Method: GET
Authorization: Bearer token required

// SUCCESS (user in game)
Response: {
  "status": "success",
  "userId": "user_123",
  "globalCurrency": 250,
  "inGameCurrency": 100,
  "gameId": "game_456"
}

// SUCCESS (user not in game)
Response: {
  "status": "success",
  "userId": "user_123",
  "globalCurrency": 250,
  "inGameCurrency": 0,
  "gameId": null
}

// USER NOT FOUND
Response: {
  "status": "error",
  "message": "User not found"
}
```

### Game Service

#### Lobby Management Endpoints

- Create game lobby

```
Endpoint: /games/create
Method: POST
Authorization: Bearer token required
Payload: {
  "hostUserId": "user_123",
  "maxPlayers": 15
}

// SUCCESS
Response: {
  "status": "success",
  "game": {
    "gameId": "game_1",
    "gameCode": "AYA4G",
    "hostUserId": "user_123",
    "gameStatus": "waiting",
    "maxPlayers": 15,
    "currentPlayers": 1
  }
}

// INVALID SETTINGS
Response: {
  "status": "error",
  "message": "Max players must be between 6 and 30"
}
```

- Get all active games

```
Endpoint: /games
Method: GET
Authorization: Bearer token required

// SUCCESS
Response: {
  "status": "success",
  "games": [
    {
      "gameId": "game_1",
      "gameCode": "GA9UT",
      "hostUserId": "user_2",
      "currentPlayers": 3,
      "maxPlayers": 6,
      "players": [
        {
          "userId": "user_2",
          "username": "player2"
        },
        {
          "userId": "user_4",
          "username": "player4"
        },
        {
          "userId": "user_5",
          "username": "player5"
        }
      ],
      "spotsAvailable": 3,
      "createdAt": "2025-10-18T13:14:09.390Z"
    },
    {
      "gameId": "game_2",
      "gameCode": "2F9BS",
      "hostUserId": "user_1",
      "currentPlayers": 2,
      "maxPlayers": 8,
      "players": [
        {
          "userId": "user_1",
          "username": "player1"
        },
        {
          "userId": "user_3",
          "username": "player3"
        }
      ],
      "spotsAvailable": 6,
      "createdAt": "2025-10-18T13:11:12.120Z"
    }
  ],
  "totalGames": 2
}
```

- Join game by code

```
Endpoint: /games/join
Method: POST
Authorization: Bearer token required
Payload: {
  "userId": "user_456",
  "gameCode": "MAFIA123"
}

// SUCCESS
Response: {
  "status": "success",
  "gameId": "game_789",
  "gameStatus": "waiting",
  "playerCount": 2
}

// GAME FULL
Response: {
  "status": "error",
  "message": "Game has reached maximum capacity",
  "maxPlayers": 15,
  "currentPlayers": 15
}

// INVALID GAME CODE
Response: {
  "status": "error",
  "message": "Incorrect game code"
}

// USER ALREADY IN GAME
Response: {
  "status": "error",
  "message": "User already in game"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

- Join game by ID

```
Endpoint: /games/{gameId}/join
Method: POST
Authorization: Bearer token required
Payload: {
  "userId": "user_456"
}

// SUCCESS
Response: {
  "status": "success",
  "gameId": "game_789",
  "gameStatus": "waiting",
  "playerCount": 2
}

// GAME FULL
Response: {
  "status": "error",
  "message": "Game has reached maximum capacity",
  "maxPlayers": 15,
  "currentPlayers": 15
}

// USER ALREADY IN GAME
Response: {
  "status": "error",
  "message": "User already in game"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
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
  "message": "Player is not in this game"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

- Get game status

```
Endpoint: /games/{gameId}
Method: GET
Authorization: Bearer token required

// SUCCESS (waiting)
Response: {
  "status": "success",
  "game": {
    "gameId": "game_1",
    "gameCode": "PSY1M",
    "hostUserId": "user_123",
    "gameStatus": "waiting",
    "maxPlayers": 15,
    "currentPlayers": 2,
    "players": [
      {
        "userId": "user_123",
        "username": "player1"
      },
      {
        "userId": "user_456",
        "username": "player2"
      }
    ]
  }
}

// SUCCESS (in progress)
Response: {
  "status": "success",
  "game": {
    "gameId": "game_789",
    "gameStatus": "in_progress",
    "currentPhase": "day",
    "dayCount": 3,
    "players": [
      {
        "userId": "user_123",
        "username": "player1",
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
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

#### Game State Endpoints

- Start game

```
Endpoint: /games/{gameId}/start
Method: POST
Authorization: Bearer token required
Payload: {
  "hostUserId": "user_123"
}

// SUCCESS
Response: {
  "status": "success",
  "game": {
    "gameId": "game_789",
    "gameStatus": "in_progress",
    "currentPhase": "day",
    "dayCount": 1,
    "totalPlayers": 12,
    "message": "Game started! Day 1 begins."
  }
}

// NOT HOST
Response: {
  "status": "error",
  "message": "Only the host can start the game"
}

// INSUFFICIENT PLAYERS
Response: {
  "status": "error",
  "message": "Need at least 6 players to start",
  "currentPlayers": 2,
  "minimumPlayers": 6
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

- End game

```
Endpoint: /games/{gameId}/end
Method: PATCH
Payload: {
  "winCondition": "mafia_victory",
  "winners": [
    {
      "userId": "user_123"
    },
    {
      "userId": "user_789"
    }
  ]
}

// SUCCESS
Response: {
  "status": "success",
  "message": "Game ended",
  "game": {
    "gameId": "game_789",
    "gameStatus": "ended",
    "winCondition": "mafia_victory",
    "winners": [
      {
        "userId": "user_123"
      },
      {
        "userId": "user_789"
      }
    ]
  }
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

- Delete game (after rewards distributed)

```
Endpoint: /games/{gameId}
Method: DELETE
Authorization: Bearer token required

// SUCCESS
Response: {
  "status": "success",
  "message": "Game deleted"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

#### Player State Management Endpoints

- Get player info

```
Endpoint: /games/{gameId}/players/{userId}
Method: GET
Authorization: Bearer token required

// SUCCESS
Response: {
  "status": "success",
  "userId": "user_123",
  "gameId": "game_789",
  "role": "mafia",
  "career": "godfather",
  "isAlive": true
}

// PLAYER NOT IN GAME
Response: {
  "status": "error",
  "message": "Player is not in this game"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

- Update player alive status

```
Endpoint: /games/{gameId}/players/{userId}/status
Method: PATCH
Authorization: Bearer token required
Payload: {
  "isAlive": false,
  "cause": "voted_out"
}

// SUCCESS
Response: {
  "status": "success",
  "userId": "user_123",
  "isAlive": false,
  "cause": "voted_out"
}

// PLAYER NOT IN GAME
Response: {
  "status": "error",
  "message": "Player is not in this game"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

#### Phase Management Endpoints

- Update game phase

```
Endpoint: /games/{gameId}/phase
Method: PATCH
Authorization: Bearer token required
Payload: {
  "newPhase": "night"
}

// SUCCESS
Response: {
  "status": "success",
  "game": {
    "gameId": "game_789",
    "previousPhase": "day",
    "currentPhase": "night",
    "dayCount": 3
  }
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

- Get current phase

```
Endpoint: /games/{gameId}/phase
Method: GET
Authorization: Bearer token required

// SUCCESS
Response: {
  "status": "success",
  "game": {
    "gameId": "game_789",
    "currentPhase": "day",
    "dayCount": 3
  }
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

#### Event Broadcasting Endpoints

- Broadcast game event

```
Endpoint: /games/{gameId}/broadcast
Method: POST
Authorization: Bearer token required
Payload: {
  "eventType": "player_death",
  "message": "PlayerName was found dead!",
  "targetPlayers": ["user_123", "user_789"],
  "metadata": {
    "eliminatedPlayerId": "user_456",
    "cause": "mafia_kill"
  }
}

// WHEN PLAYER GETS EXILED
Payload: {
  "eventType": "player_elimination",
  "message": "player2 has been voted out of the town!",
  "metadata": {
    "eliminatedPlayerId": "user_456",
    "voteCount": 5,
    "cause": "voted_out"
  }
}

// SUCCESS
Response: {
  "status": "success",
  "message": "Event broadcasted successfully"
}

// INVALID EVENT TYPE
Response: {
  "status": "error",
  "message": "Event type must be one of: player_death, player_elimination, healing, rumor, visit"
}

// GAME NOT FOUND
Response: {
  "status": "error",
  "message": "Game not found"
}
```

### Shop Service

#### Customization Shop Endpoints

- Endpoint for listing all of the available items
```
Endpoint: /items
Method: GET
Response: [
  {
    "id": 1,
    "name": "Blonde Hairr",
    "description": "Looking I-legally blonde!",
    "type": "HAIR",
    "price": 200
  },
  {
    "id": 2,
    "name": "Gold Necklace",
    "description": "Because rappers thought it was cool",
    "type": "JEWELRY",
    "price": 350
  },
]
```

- Endpoint for creating a clothing item
```
Endpoint: /items
Method: POST
Payload: {
   "name": "Gold Necklace",
   "description": "Because rappers thought it was cool",
   "type": "JEWELRY",
   "price": 350
 }
Response: {
   "id": 2,
   "name": "Gold Necklace",
   "description": "Because rappers thought it was cool",
   "type": "JEWELRY",
   "price": 350
}
```

- Endpoint for updating a clothing item
```
Endpoint: /items/{id}
Method: PUT
Payload: { 
  "name": "Golden Necklace",
  "description": "Some people say it's fake gold. Doesn't taste like it!",
  "type": "JEWELRY",
  "price": 400
}
Response: {
  "id": 2
  "name": "Golden Necklace",
  "description": "Some people say it's fake gold. Doesn't taste like it!",
  "type": "JEWELRY",
  "price": 400
}
```

- Endpoint for deleting a clothing item
```
Endpoint: /items/{id}
Method: DELETE
Response: {
  "status": "success"
}
```

### Roleplay Service

#### Announcement endpoints
- Endpoint for creating an announcement
```
Endpoint: /lobbies/{lobbyId}/announcements
Method: POST
Payload: {
  "id": "3",
  "content": "Randomizer was killed by MyCallAngel0",
  "timestamp": "2025-09-22T12:30:00",
  "day": 1
}
Response: 201 OK
```

- Endpoint for getting all the lobby announcements
```
Endpoint: /lobbies/{lobbyId}/announcements
Method: GET
Response: [
  { "id": "1", "content": "Randomizer was killed by MyCallAngel0", "day": 1, "timestamp": "2025-09-22T12:30:00" },
  { "id": "2", "content": "yum3lo investigated MyCallAngel0", "day": 1 "timestamp": "2025-09-22T12:35:00" }
]
```

- Endpoint for getting a single lobby announcements
```
Endpoint: /lobbies/{lobbyId}/announcements/{id}
Method: GET
Response: { 
    "id": "1", 
    "content": "Randomizer was killed by MyCallAngel0", 
    "day": 1, 
    "timestamp": "2025-09-22T12:30:00" 
}
```

- Endpoint for updating a lobby announcements
```
Endpoint: /lobbies/{lobbyId}/announcements/{id}
Method: PUT
Payload: {
  "id": "3",
  "content": "yum3lo was killed by MyCallAngel0",
  "timestamp": "2025-09-22T12:30:00",
  "day": 1
}
Response: 200 OK
```

- Endpoint for deleting a lobby announcements
```
Endpoint: /lobbies/{lobbyId}/announcements/{id}
Method: DELETE
Response: 200 OK
```

- Endpoint for deleting all lobby announcements
```
Endpoint: /lobbies/{lobbyId}/announcements
Method: DELETE
Response: 200 OK
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

To avoid sending a huge list of movements and requiring the Rumours Service to filter by timestamp, the Town Service includes the game day number with each movement event.
When a movement is recorded, the Town Service determines the game day by comparing the movement’s timestamp to the day boundaries.

- Endpoint for recording a movement event

```
Endpoint: /movements
Method: POST
Payload:
  {
    "user_id": "user_123",
    "from_location": "loc_2",
    "to_location": "loc_1",
    "timestamp": "2025-09-07T09:30:00Z",
    "gameDay": 1

  }
Response: 201 OK
```

- Endpoint to list all the movements (with optional filtering)

```
Endpoint: /movements
Method: GET
Query params: ?gameDay=3 (optional)
Response: {
  movements: [
    {
      "movement_id": "mv_1001",
      "user_id": "user_123",
      "from_location": "loc_2",
      "to_location": "loc_1",
      "timestamp": "2025-09-07T09:30:00Z",
      "gameDay": 3
    }
  ]
}
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
    gameDay: 1
  }
    ]
}
```

- Endpoint of the history of a user's movements

```
Endpoint: /users/{user_id}/movements
Method: GET
Query params: ?gameDay=3 (optional)
Response: {
  movements: [
    {
      "movement_id": "mv_1001",
      "from_location": "loc_2",
      "to_location": "loc_1",
      "timestamp": "2025-09-07T09:30:00Z",
      "gameDay": 3
    }
  ]
}
```

- Endpoint of all movements involving a specific location

```
Endpoint: /locations/{location_id}/movements
Method: GET
Query params: ?gameDay=3 (optional)
Response: {
  movements: [
    {
      "movement_id": "mv_1001",
      "user_id": "user_123",
      "from_location": "loc_2",
      "to_location": "loc_1",
      "timestamp": "2025-09-07T09:30:00Z",
      "gameDay": 3
    }
  ]
}
```

### Character Service

For the data, PostgreSQL with SQLAlchemy ORM will be used. PostgreSQL's JSON and JSONB support is ideal for storing flexible character asset configurations and inventory data structures. Its relational capabilities efficiently handle the many-to-many relationships between users, owned assets, equipped items, and available customization slots. All messages passed will be in JSON format, with the following requests and responses expected for each endpoint:

All customization actions, including appearance changes and slot updates, require spending global currency and are strictly limited to the lobby phase before the game begins. Once the game starts, the ability to modify character appearance is locked, ensuring that all players enter the game with their chosen look and assets.

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
  },
  "currencyType": "global",
  "globalCurrency": 250,
  "currencySpent": 100
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
  },
  "currencyType": "global",
  "globalCurrency": 250,
  "currencySpent": 100
}
Response: 200 OK
```

- Endpoint for creating initial character (

```
Endpoint: /characters
Method: POST
Payload: {
  "userId": "user_456",
  "appearance": {
    "hair": "brown_wavy",
    "coat": "green_shirt",
    "accessory": "wristwatch"
  },
  "currencyType": "global",
  "globalCurrency": 250,
  "currencySpent": 0
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

All inventory actions, including item purchases from the shop and usage, require spending in-game currency and are strictly limited to the active game phase. Global currency cannot be used for inventory transactions once the game has started.

- Endpoint for getting user's inventory

```
Endpoint: /inventory/{user_id}
Method: GET
Response: {
  "userId": "user_123",
  "inGameCurrency": 75
  "items": [
    {
      "itemId": "body_armor",
      "name": "Bulletproof Vest",
      "quantity": 1,
      "expiresNextDay": true,
      "currencyType": "in-game",
      "purchasePrice": 150,
      "type": "protection",
      "description": "Protects against mafia attacks during night phase"
    },
    {
      "itemId": "fake_id",
      "name": "False Identity Papers",
      "quantity": 1,
      "expiresNextDay": true,
      "currencyType": "in-game",
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
  "expiresNextDay": true,
  "currencyType": "in-game",
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

- Get all available rumors in the system with optional filtering.

```
Endpoint:  /rumors
# Optional query parameters:
# ?category=role|task|appearance|location
# ?active=true|false
Method: GET
Response:
[
  {
    "id": "c5ee1573-8c3c-449c-9900-b81b34c736d7",
    "content": "The mayor was seen talking to suspicious characters",
    "category": "role",
    "isActive": true,
    "createdAt": "2025-09-20T09:15:25.220Z",
    "updatedAt": "2025-09-20T09:15:25.220Z"
  },
  {
    "id": "987e6543-e21b-12d3-a456-426614174999",
    "content": "Someone was spotted near the warehouse at midnight",
    "category": "location",
    "isActive": true,
    "createdAt": "2025-09-20T09:15:25.220Z",
    "updatedAt": "2025-09-20T09:15:25.220Z"
  }
]
```

- Create a new rumor (Admin/System use).

```
Endpoint: /rumors
Method: POST
Request:
{
  "content": "The user has a black hat.",
  "category": "appearance",
  "isActive": true
}
Response:
{
  "id": "new-rumor-id",
  "content": "The user has a black hat.",
  "category": "appearance",
  "isActive": true,
  "createdAt": "2025-09-20T09:15:25.220Z",
  "updatedAt": "2025-09-20T09:15:25.220Z"
}
```

- Get a specific rumor by ID.

```
Endpoint: /rumors/:id
Method: GET
Response:
{
  "id": "c5ee1573-8c3c-449c-9900-b81b34c736d7",
  "content": "The mayor was seen talking to suspicious characters",
  "category": "role",
  "isActive": true,
  "createdAt": "2025-09-20T09:15:25.220Z",
  "updatedAt": "2025-09-20T09:15:25.220Z"
}
```

- Purchase a rumor - Player spends currency to get a random rumor based on their role and currency amount.

```
Endpoint: /player-rumors
Method: POST
Request:
{
  "playerId": "player-doctor-001",
  "playerRole": "doctor",
  "gameId": "game-001",
  "spentCurrency": 120
}
Response:
{
  "id": "d08a88c3-21ee-44f9-9e20-8ae34baa8bc9",
  "playerId": "player-doctor-001",
  "rumorId": "c5ee1573-8c3c-449c-9900-b81b34c736d7",
  "gameId": "game-001",
  "purchasedAt": "2025-09-20T09:15:40.839Z",
  "spentCurrency": 120,
  "rumor": {
    "id": "c5ee1573-8c3c-449c-9900-b81b34c736d7",
    "content": "Someone was spotted near the old church",
    "category": "appearance",
    "isActive": true,
    "createdAt": "2025-09-20T09:15:25.220Z",
    "updatedAt": "2025-09-20T09:15:25.220Z"
  }
}
```

- Get a specific a specific purchase record by purchase ID.

```
Endpoint: /player-rumors/:id
# Optional query parameters:
# ?gameId - specific game
# ?playerId - specific player
Method: GET
Response:
{
  "id": "d08a88c3-21ee-44f9-9e20-8ae34baa8bc9",
  "playerId": "player-doctor-001",
  "rumorId": "c5ee1573-8c3c-449c-9900-b81b34c736d7",
  "gameId": "game-001",
  "purchasedAt": "2025-09-20T09:15:40.839Z",
  "spentCurrency": 120,
  "rumor": {
    "id": "c5ee1573-8c3c-449c-9900-b81b34c736d7",
    "content": "Someone was spotted near the old church",
    "category": "appearance",
    "isActive": true,
    "createdAt": "2025-09-20T09:15:25.220Z",
    "updatedAt": "2025-09-20T09:15:25.220Z"
  }
}
```

#### Event Broadcasting

When a rumor is purchased, the service emits events for chat integration:

```json
{
  "type": "RUMOR_PURCHASED",
  "gameId": "game-123",
  "message": "A detective just purchased a role rumor for 350 coins",
  "timestamp": "2025-09-20T10:30:00Z",
  "metadata": {
    "playerId": "player-456",
    "rumorCategory": "role",
    "spentCurrency": 350,
    "purchaseId": "purchase-789"
  }
}
```

#### Inbound Events

The service listens for events from other services to generate rumors:

**From Town Service**

```json
{
  "event": "player_moved",
  "data": {
    "playerId": "string",
    "fromLocation": "string",
    "toLocation": "string",
    "timestamp": "string"
  }
}
```

- Generates **location rumors** (“Player Y was last seen at the warehouse”).

---

**From Game Service**

```json
{
  "event": "phase_changed",
  "data": {
    "gameId": "string",
    "phase": "day|night|voting",
    "timestamp": "string"
  }
}
```

- Controls rumor availability (e.g., no buying at night).

```json
{
  "event": "player_status_updated",
  "data": {
    "playerId": "string",
    "status": "alive|dead|exiled",
    "timestamp": "string"
  }
}
```

- Filters rumors about dead players.

### Communication Service

- Create a new chat room. (Admin/System)

```Endpoint: /chat/rooms
Method: POST
Request:
{
  "name": "Mafia Strategy Room",
  "type": "mafia",
  "gameId": "game-uuid-123",
  "locationId": "location-uuid-456",
  "maxParticipants": 10
}
Response:
{
  "id": "room-uuid-789",
  "name": "Mafia Strategy Room",
  "type": "mafia",
  "gameId": "game-uuid-123",
  "locationId": "location-uuid-456",
  "active": true,
  "maxParticipants": 10,
  "createdAt": "2025-09-21T12:00:00Z"
}
```

- Send message to chat-room

```
Endpoint: /chat/rooms/:roomId/messages
Method: POST
Request:
{
  "senderId": "player-uuid-123",
  "content": "Did anyone see who was near the warehouse?",
  "type": "text"
}
Response:
{
  "id": "msg-uuid-987",
  "chatRoomId": "room-uuid-789",
  "senderId": "player-uuid-123",
  "content": "Did anyone see who was near the warehouse?",
  "type": "text",
  "createdAt": "2025-09-21T12:00:00Z"
}
```

- Fetch messages for a chat room with pagination.

```
Endpoint: /chat/rooms/:roomId/messages
Method: GET
# Optional query params:
# ?playerId: Filter messages visible to this player
# ?limit: Maximum number of messages, default 50
# ?offset: Number of messages to skip, default 0
Response:
[
  {
    "id": "msg-uuid-987",
    "senderId": "player-uuid-123",
    "content": "Did anyone see who was near the warehouse?",
    "type": "text",
    "createdAt": "2025-09-21T12:00:00Z"
  },
  {
    "id": "msg-uuid-988",
    "senderId": "player-uuid-456",
    "content": "I saw Player X heading towards the dock.",
    "type": "text",
    "createdAt": "2025-09-21T12:01:30Z"
  }
]
```

- Fetch all chat rooms a player has access to.

```
Endpoint: /chat/players/:playerId/rooms
Method: GET
# Mandatory query params:
# ?gameId
Response:
[
  {
    "id": "room-uuid-123",
    "name": "Global Voting Chat",
    "type": "voting",
    "gameId": "game-uuid-123",
    "active": true
  },
  {
    "id": "room-uuid-456",
    "name": "Mafia Strategy",
    "type": "mafia",
    "gameId": "game-uuid-123",
    "active": true
  }
]
```

- Join a chat-room

```
Endpoint:  /chat/rooms/:roomId/join
Method: POST
Request:
{
  "playerId": "player-uuid-123"
}
Response:
{
  "message": "Successfully joined chat room"
}
```

- Leave a chat-room

```
Endpoint:  /chat/rooms/:roomId/leave
Method: POST
Request:
{
  "playerId": "player-uuid-123"
}
Response:
{
  "message": "Successfully left chat room"
}
```

#### WebSocket Events

Players connect to the WebSocket server with authentication parameters.

**Connection URL:**

```
ws://localhost:3000?playerId=player-uuid-123&gameId=game-uuid-456
```

**`join_room`**

Join a chat room to receive real-time messages.

**Payload:**

```json
{
  "roomId": "room-uuid-789"
}
```

**`leave_room`**

Leave a chat room to stop receiving messages.

**Payload:**

```json
{
  "roomId": "room-uuid-789"
}
```

**`send_message`**

Send a message through WebSocket (alternative to REST API).

**Payload:**

```json
{
  "roomId": "room-uuid-789",
  "content": "Hello everyone!",
  "type": "text"
}
```

**`new_message` (Received)**

Real-time message broadcast to room participants.

**Payload:**

```json
{
  "id": "msg-uuid-123",
  "chatRoomId": "room-uuid-789",
  "senderId": "player-uuid-456",
  "content": "Hello everyone!",
  "type": "text",
  "createdAt": "2025-09-21T12:00:00Z"
}
```

**`player_joined` (Received)**

Notification when a player joins the room.

**Payload:**

```json
{
  "playerId": "player-uuid-789",
  "roomId": "room-uuid-123",
  "timestamp": "2025-09-21T12:00:00Z"
}
```

**`player_left` (Received)**

Notification when a player leaves the room.

**Payload:**

```json
{
  "playerId": "player-uuid-789",
  "roomId": "room-uuid-123",
  "timestamp": "2025-09-21T12:00:00Z"
}
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
Response body:
{
  "task_id": 101,
  "role": "cop",
  "task_description": "Perform a routine checkup on locations x, y and z.",
  "status": "open",
  "current_assignee": null,
  "created_at": "2025-09-22T09:10:12Z"
}

```

- Endpoint for tasks retrieval

```
Endpoint: /tasks
Method: GET
# Optional query params:
# ?status: displays task status (open|assigned|in_progress|completed|cancelled)
# ?limit=50&?offset=0: pagination for displaying a set number of tasks
Response: 200 OK
Response body:
{
  "tasks": [
    {
      "task_id": 101,
      "role": "cop",
      "task_description": "Perform a routine checkup on locations x, y and z.",
      "status": "open",
      "current_assignee": null
    },
    {
      "task_id": 102,
      "role": "doctor",
      "task_description": "Perform a physical on player 12.",
      "status": "assigned",
      "current_assignee": 2
    },
    {
      "task_id": 103,
      "role": "investigator",
      "task_description": "Interview witness at location 7.",
      "status": "completed",
      "current_assignee": null
    }
  ],
  "meta": { "limit": 50, "offset": 0, "total": 3 }
}

```

- Endpoint for task retrieval

```
Endpoint: /tasks/{task_id}
Method: GET
Response: 200 OK
Response body:
{
  "task_id": 101,
  "role": "cop",
  "task_description": "Perform a routine checkup on locations x, y and z.",
  "status": "open",
  "current_assignee": null,
  "created_at": "2025-09-22T09:10:12Z",
  "updated_at": "2025-09-22T09:10:12Z"
}
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
  "task_id": 102
}
Response: 201 Created
Response body:
{
  "assignment_id": 1001,
  "task_id": 102,
  "assignee_id": 1
  "created_at": "2025-09-22T10:05:00Z",
  "note": "Assigned via operator UI"
}
```

- Endpoint for removing assigned task

```
Endpoint: /tasks/assign
Method: DELETE
Payload: {
  "user_id": 1,
  "task_id": 102
}
Response: 204 No Content
```

- Endpoint for listing assignment audit for a task

```
Endpoint: /tasks/{task_id}/history/assignments
Method: GET
Response: 200 OK
Response body:
[
  {
    "assignment_id": 1001,
    "task_id": 102,
    "assignee_id": 1,
    "created_at": "2025-09-22T10:05:00Z"
  },
  {
    "assignment_id": 1002,
    "task_id": 102,
    "assignee_id": 2,
    "created_at": "2025-09-21T14:00:00Z"
  }
]
```

#### Task status endpoint

- Endpoint for changing a task's status

```
Endpoint: /tasks/{task_id}/status
Method: PATCH
Payload: {
  "status": "in_progress",
  "updated_by": 2,
  "note": "Started by assignee"
}
Response: 200 OK
Response body:
{
  "task_id": 102,
  "status": "in_progress",
  "current_assignee": 1,
  "updated_at": "2025-09-22T11:00:00Z"
}
```

- Endpoint for completing a task

```
Endpoint: /tasks/{task_id}/complete
Method: POST
Payload: {
  "completed_by": 1,
  "status": "completed"
}
Response: 200 OK
Response body:
{
  "task_id": 102,
  "status": "completed",
  "current_assignee": null,
  "completed_at": "2025-09-22T11:30:00Z"
}
```

- Endpoint for viewing history of task completions

```
Endpoint: /tasks/{task_id}/history/completions
Method: GET
Response: 200 OK
Response body:
[
  {
    "user_id": 1,
    "status": "completed",
    "completed_at": "2025-09-22T11:30:00Z"
  },
  {
    "user_id": 2,
    "status": "failed",
    "completed_at": "2025-09-20T09:00:00Z"
  }
]
```

### Task helper endpoint

- Endpoint for listing all available tasks to assign

```
Endpoint: /tasks/available
Method: GET
# Optional query params:
# ?role: search by role-specific tasks
# ?limit=50&?offset=0: offset results
Response: 200 OK
Response body:
{
  "tasks": [
    {
      "task_id": 101,
      "role": "cop",
      "task_description": "Perform a routine checkup on locations x, y and z.",
      "created_at": "2025-09-22T09:10:12Z"
    },
    {
      "task_id": 104,
      "role": "cop",
      "task_description": "Patrol sector 5 between 20:00-22:00.",
      "created_at": "2025-09-22T08:00:00Z"
    }
  ]
}
```

- Endpoint for fetching candidate users for a given task (for delegation)

```
Endpoint: /tasks/{task_id}/candidates
Method: GET
Response: 200 OK
Response body:
[
  { "user_id": 1, "eligible_by": ["role:doctor"] },
  { "user_id": 3, "eligible_by": ["role:cop"] }
]
```

- Endpoint for getting task status at the end of the day

```
Endpoint: /tasks/status
Method: GET
Response: 200 OK
Response body:
{
  "day": "1",
  "tasks": [
    {
      "user_id": 1,
      "task_completed": true
    },
    {
      "user_id": 2,
      "task_completed": false
    },
    {
      "user_id": 3,
      "task_completed": true
    }
  ]
}
```

### Voting Service


### Voting endpoints

- Endpoint to create/start a voting round for a game

```
Endpoint: POST /games/{game_id}/rounds
Method: POST
Payload:
{
  "name": "Day 3 Vote",
  "starts_at": Datetime.now(),
}
Response: 201 Created
Response body:
{
  "round_id": "round-9f3a2b",
  "game_id": "game-AAA",
  "name": "Day 3 Vote",
  "status": "open",
  "starts_at": "2025-09-22T12:00:00Z",
  "created_at": "2025-09-22T12:00:00Z"
}

```

- Endpoint to close a voting round

```
Endpoint: PATCH /games/{game_id}/rounds/{round_id}/close
Method: PATCH
Payload: {} 
Response: 200 OK
Response body:
{
  "round_id": "round-9f3a2b",
  "game_id": "game-AAA",
  "status": "closed",
  "closed_at": "2025-09-22T12:30:00Z"
}
```

- Endpoint to list rounds for a game

```
Endpoint: GET /games/{game_id}/rounds?status=open|closed
Method: GET
Response: 200 OK
Response body:
{
  "rounds": [
    { "round_id": "round-9f3a2b", "status": "open",  "starts_at": "2025-09-21T11:00:00Z", "ends_at": null },
    { "round_id": "round-8e2b1c", "status": "closed", "starts_at": "2025-09-21T11:55:00Z", "ends_at": "2025-09-21T12:00:00Z" }
  ]
}
```

- Endpoint to get the current voting round for a game
```
Endpoint: GET /games/{game_id}/rounds/active
Method: GET
Response: 200 OK
Response body:
{
  "round_id": "round-9f3a2b",
  "status": "open",
  "starts_at": "2025-09-21T11:00:00Z",
  "ends_at": null
}
```

#### Voting control endpoints

- Endpoint to cast or change a user's vote for the active round

```
Endpoint: POST /games/{game_id}/votes
Method: POST
Payload:
{
  "user_id": 1,
  "voted_user_id": 3,
  "round_id": "round-9f3a2b"
}
Response: 201 Created
Response body:
{
  "user_id": 1,
  "voted_user_id": 3,
  "round_id": "round-9f3a2b"
}
```

- Endpoint for getting all votes

```
Endpoint: GET /games/{game_id}/votes?round_id={round_id}&?limit=500&?offset=0
Method: GET
Response: 200 OK
Response body:
{
  "votes": [
    { "user_id": 1, "voted_user_id": 3},
    { "user_id": 2, "voted_user_id": 1}
  ]
}
```

- Endpoint to get a single player's vote for a given round
```
Endpoint: GET /games/{game_id}/votes/{user_id}?round_id={round_id}
Method: GET
Response: 200 OK
Response body:
{
  "user_id": 2,
  "voted_user_id": 1,
  "round_id": "round-9f3a2b"
}
```

- Endpoint to remove a user's vote
```
Endpoint: DELETE /games/{game_id}/votes/{user_id}?round_id={round_id}
Method: DELETE
Response: 204 No Content
```

#### Voting results endpoints

- Endpoint to get voting results for a closed round

```
Endpoint: GET /games/{game_id}/rounds/{round_id}/results
Method: GET
Response: 200 OK
Response body:
{
  "round_id": "round-9f3a2b",
  "game_id": "game-AAA",
  "generated_at": "2025-09-22T12:30:01Z",
  "results": [
    { "user_id": 1, "votes": 5 },
    { "user_id": 2, "votes": 1 }
  ],
  "total_votes": 6,
  "tied": false,
  "voted_out_id": 1
}

```

#### Voting logs endpoints

- Endpoint for creating voting logs

```
Endpoint: GET /games/{game_id}/rounds/logs
Method: GET
Response: 200 OK
Response body:
{
  "logs": [
    {
      "round_id": "round-8e2b1c",
      "name": "Day 2 Vote",
      "closed_at": "2025-09-21T12:00:00Z",
      "voted_out_id": 4
    },
    {
      "round_id": "round-7d1a0f",
      "name": "Day 1 Vote",
      "closed_at": "2025-09-20T12:00:00Z",
      "voted_out_id": null
    }
  ]
}
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
<type>(<optional scope>): <description>

<optional body>
```

Types:

- Changes relevant to the API:
  - `feat` commits that add, adjust or remove a new feature to the API
  - `fix` commits that fix an API bug of a preceded `feat` commit
- `refactor` commits that rewrite or restructure code without altering API behavior
- `style` commits that address code style (e.g., white-space, formatting, missing semi-colons) and do not affect application behavior
- `test` commits that add missing tests or correct existing ones
- `docs` commits that exclusively affect documentation
- `build` commits that affect build-related components such as build tools, dependencies, project version, CI/CD pipelines, ...
- `ops` commits that affect operational components like infrastructure, deployment, backup, recovery procedures, ...
- `chore` miscellaneous commits e.g. modifying .gitignore, ...

## Pull request requirements

- Clear title that is descriptive
- Detailed description
- Linked issues, if applicable
- Breaking changes - how it impacts other services, if applicable

## Test coverage

- Unit Tests - 80% code coverage minimum

## Quick Start Development Script

### Rumors Service

**1. Start the Service**

```bash
# Start PostgreSQL database and the service
./scripts/start.sh
```

This script will:

- Start PostgreSQL container with Docker Compose
- Wait for database to be ready
- Launch Prisma Studio for database inspection
- Start the NestJS service on http://localhost:3000

**2. Populate Database**

```bash
# Add initial rumor data (run after service is up)
./scripts/populate-db.sh
```

This script will:

- Check if the API is reachable
- Count existing rumors in the database
- Add 20 diverse rumors (5 per category) if database is empty
- Skip population if data already exists

**3. Test Event System**

```bash
# Test role-based rumor purchases with event emission
./scripts/test-events.sh
```

This script demonstrates:

- Detective purchasing role rumors (300+ currency)
- Citizen purchasing location rumors (150-199 currency)
- Mafioso purchasing task rumors (200-299 currency)
- Invalid purchase attempts and error handling
- Event emission for chat system integration

### Communication Service

For rapid development setup, use the provided start-dev script:

```bash
# Make script executable (first time only)
chmod +x scripts/start-dev.sh

# Start complete development environment
./scripts/start-dev.sh
```

This script will:

- Start PostgreSQL database (localhost:5433)
- Start Redis cache (localhost:6379)
- Start the chat service (localhost:3001)
- Initialize database with sample data
- Provide test player IDs and game IDs for immediate testing

**Sample Test Data Provided:**

- Game ID: `550e8400-e29b-41d4-a716-446655440100`
- Player 1 (Townsperson): `550e8400-e29b-41d4-a716-446655440201`
- Player 2 (Mafia): `550e8400-e29b-41d4-a716-446655440202`
- Player 3 (Dead): `550e8400-e29b-41d4-a716-446655440203`

**Quick Health Check:**

```bash
curl http://localhost:3001/health
```

## Docker Deployment

### Town Service

This service and its versions are deployed on Docker Hub on a public repo at https://hub.docker.com/repository/docker/nelldino/character-service/general

```bash
#Pull the latest version
docker build -t nelldino/character-service:1.0

# Run with Docker Compose
docker-compose up --build

# Build production image
docker build -t nelldino/town-service:1.0

```

### Character Service

The service is containerized and available on Docker Hub at https://hub.docker.com/repository/docker/nelldino/town-service/general

```bash
# Pull the latest version
docker pull nelldino/character-service:1.0

# Run with Docker Compose
docker-compose up -d

# Build locally
docker build -t nelldino/character-service:1.0
```

### Rumors Service

This service and its versions are deployed on Docker Hub on a public repo at https://hub.docker.com/r/valeriafz/rumors-service:

```bash
# Build production image
docker build -t valeriafz/rumors-service:latest .

# Run with Docker Compose
docker-compose up --build

# In case of prisma errors check if user exists
docker exec -it rumor_db psql -U rumor_user -d mafia_rumor

# Enter password, grant permissions if needed:
CREATE USER rumor_user WITH PASSWORD 'yourpassword';
CREATE DATABASE rumor_db OWNER rumor_user;
GRANT ALL PRIVILEGES ON DATABASE rumor_db TO rumor_user;

# Migrate the prisma schemas inside the container
docker exec -it rumor_service npx prisma migrate dev --name init --schema=./prisma/schema.prisma

# Populate the empty database
chmod +x ./db/rumors_service.sh
./db/rumors_service.sh
```

### Communication Service

The service is containerized and available on Docker Hub at https://hub.docker.com/r/valeriafz/mafia-communication-service:

```bash
# Pull the latest version
docker pull valeriafz/mafia-communication-service:1.0.0

# Run with Docker Compose
docker-compose up -d

# Build locally
docker build -t mafia-communication-service .
```

### Shop Service

This service and its versions are deployed on Docker Hub on a public repo at
https://hub.docker.com/repository/docker/mycallangel0/shop-service/general:
```bash
# Build production image
docker build -t mycallangel0/shop-service:latest

# Run with Docker Compose
docker-compose up --build
```

### Roleplay Service

This service and its versions are deployed on Docker Hub on a public repo at
https://hub.docker.com/repository/docker/mycallangel0/roleplay-service/general:
```bash
# Build production image
docker build -t mycallangel0/roleplay-service:latest

# Run with Docker Compose
docker-compose up --build
```

### Task Service

This service is available on Docker Hub at:
https://hub.docker.com/repository/docker/lucianlupan/task_service/general
```bash
# Pull the latest version from Docker Hub
docker pull lucianlupan/task_service:1.0

# Or build the production image locally
docker build -t lucianlupan/task_service:1.0 .

# Populate the docker image with data
docker compose exec -T task_service bash < ./db/task_service.sh

# Run the service with Docker Compose
docker-compose up --build
```

### Voting Service

This service is available on Docker Hub at:
https://hub.docker.com/repository/docker/lucianlupan/voting_service/general
```bash
# Pull the latest version from Docker Hub
docker pull lucianlupan/voting_service:1.0

# Or build the production image locally
docker build -t lucianlupan/voting_service:1.0 .

# Populate the docker image with data
docker compose exec -T voting_service bash < ./db/voting_service.sh

# Run the service with Docker Compose
docker-compose up --build
```
