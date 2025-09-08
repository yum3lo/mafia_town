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
- User profile management (including personal identification, account settings, and preferences)
- Single profile constraint (tracks device and location data)
- In-game economy (manages user currency balance, transaction history, etc.)

### Game Service

Primary role: Central user identity and account management system

Functionalities:

- User registration and authentication (account creation with email, username, password validation and secure authentication flows)
- User profile management (including personal identification, account settings, and preferences)
- Single profile constraint (tracks device and location data)
- In-game economy (manages user currency balance, transaction history, etc.)

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

## Technology Stack and Communication Patterns

### User Management Service
The User Management Service will be written in TypeScript with Node.js, which can handle concurrent authentication requests from up to 30 players per lobby joining simultaneously. JWT authentication provides secure token-based access control, while PostgreSQL ensures data integrity for user data and in-game currency with complex queries for device tracking and fraud prevention. For the communication pattern - Synchronous REST API with asynchronous event publishing enables fast authentication validation that improves user experience when joining a game, while effective fraud detection through device tracking protects app integrity. The service architecture provides reliable user authentication and authorization while maintaining the flexibility to publish events for other services to consume, though it requires additional complexity in managing token refresh cycles to maintain security standards.

### Game Service
The Game Service will be written in TypeScript with Socket.io, providing real-time bidirectional communication for day/night cycle transitions, instant death notifications, and live voting updates essential for interactive gameplay. PostgreSQL with JSONB columns can store complex game objects while maintaining relational integrity for player relationships and game history queries, complemented by Redis caching for frequently accessed game state to achieve super fast response times during active gameplay. For the communication pattern - Event-driven architecture with WebSocket connections and Redis pub/sub enables lightweight event broadcasting for cross-service notifications without external message queue overhead. The simple architecture reduces deployment complexity and infrastructure costs while maintaining performance, with Redis pub/sub providing reliable event delivery and single database technology across services simplifying development and infrastructure management, though it results in higher memory usage due to Redis caching requirements.

### Shop Service
The Shop Service will be written in Java Spring Boot, which has a lightweight nature and fast startup times, suitable for managing a microservice. It will be used for writing the algortihms necessary for checking which items should be sold during the game. For database manipulation Hibernate will be used with PostgreSQL for character customization storage. For storing temporary data like player currency during the game, Redis wil be used for fast communication and data retrieval between the shop service and the game service. The communication that the service will have are synchronous(REST API) between itself and Game Service for daytime shop item retrieval and purchasing, and another synchronous(REST API) communication between itself and Character Service for character customization items retrieval.

### Roleplay Service
The Roleplay Service will be written in Java Spring Boot, which has a lightweight nature and fast startup times, suitable for managing a microservice. It will be used for writing the functionalities necessary for role abilities usage, their validation and announcement creation and recording. For temporary information that is present during gameplay Redis will be used for storing the announcements and later be sent to game service when needed. The service will communicate with Game Service through REST API for announcement sending and role ability validation.

### Town Service
The Town Service will be written in Python with FastAPI, that provides rapid API development with automatic OpenAPI documentation generation, making it ideal for quick prototyping and iteration. FastAPI's native async support ensures the service can handle concurrent requests efficiently and maintain responsive performance when communicating with other services. For the communication pattern - REST API (JSON) for user location requests - straightforward implementation for location queries, movement commands, and area information retrieval. Town Service have to report to the Task Service, which enables event-based subscriptions, including location availability and accessibility that may change based on task completions, story progression, or time-based events. Event-driven architecture allows the Town Service to automatically update location states, unlock new areas, or modify existing locations without tight coupling to the Task Service.

### Character Service
The Character Service will be written in Python FastAPI, which enables rapid development of character customization endpoints with automatic validation of asset combinations and slot constraints. FastAPI's built-in async support ensures smooth performance when handling multiple simultaneous character updates and inventory modifications. REST API (JSON) is going to be used for character customization and inventory queries - provides intuitive endpoints for asset selection, slot management, and inventory operations. Event-based communication with Shop Service - when users purchase items, the Character Service automatically updates inventory without tight coupling. The Shop Service emits purchase events that the Character Service subscribes to, ensuring real-time inventory synchronization. Event-based communication with User Service - character creation and updates may need to validate user permissions and currency deductions

| Member | Service(s) | Responsibilities | Technology Stack |
|--------|------------|-----------------|-----------------|
| Cucos Maria | **User Management Service, Game Service** | Manage user profiles, authentication, in-game currency, device/location info; handle day/night cycle, lobby management, event notifications, and initiate voting | Typescript (NodeJS) + PostgreSQL + Redis|
| Mihalachi Mihail | **Shop Service, Roleplay Service** | Handle in-game item purchases, currency management, daily preparation mechanics; enforce role abilities, generate filtered announcements, balance daily activity | Java (Springboot) + Redis |
| Garbuz Nelli | **Town Service, Character Service** | Track locations and movements, report to Task Service; manage character customization and inventory, asset slots, and creative features | Python (FastAPI) + PostgreSQL |
| Frunza Valeria | **Rumors Service, Communication Service** | Generate role-based rumors purchasable with currency; manage global and private chats, voting-hour communication, and Mafia group chats | Typescript (NestJS) + Prisma ORM + PostgreSQL|
| Lupan Lucian | **Task Service, Voting Service** | Assign daily tasks per role/career, reward currency for completion; collect and count votes each evening, notify Game Service of results | Go + PostgreSQL|



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
Response: {
  "status": "success",
  "userId": "user_123",
  "message": "Account created successfully"
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
Response: [
  "status": "success",
  "accessToken": "jwt_token_here",
  "refreshToken": "refresh_token_here",
  "user": {
    "userId": "user_123",
    "username": "playerName",
    "currency": 150
  }
]
```

- Endpoint for token validation

```
Endpoint: /auth/validate
Method: POST
Payload: {
  "token": "jwt_token_here"
}
Response: {
  "status": "valid",
  "userId": "user_123",
  "username": "playerName"
}
```

#### User Profile Endpoints

- Get user profile

```
Endpoint: /users/{userId}
Method: GET
Response: {
  "userId": "user_123",
  "username": "playerName",
  "email": "player@example.com",
  "currency": 150,
  "gamesPlayed": 25,
  "winRate": 0.68,
  "accountCreated": "2025-01-15T10:30:00Z"
}
```

- Update user currency

```
Endpoint: /users/{userId}/currency
Method: PATCH
Payload: {
  "amount": 50,
  "operation": "add",
  "reason": "game_victory"
}
Response: {
  "status": "success",
  "newBalance": 200,
  "transactionId": "txn_456"
}
```

- Get currency balance

```
Endpoint: /users/{userId}/currency
Method: GET
Response: [
  "userId": "user_123",
  "currentBalance": 200,
  "lastTransaction": {
    "amount": 50,
    "type": "credit",
    "reason": "game_victory",
    "timestamp": "2025-01-15T14:30:00Z"
  }
]
```

### Game Service

#### Lobby Management Endpoints

- Create game lobby

```
Endpoint: /game/lobby/create
Method: POST
Payload: [
  "hostUserId": "user_123",
  "maxPlayers": 15,
  "gameSettings": {
    "dayDuration": 600,
    "nightDuration": 300,
    "votingDuration": 120
  }
]
Response: {
  "status": "success",
  "lobbyId": "lobby_789",
  "joinCode": "GAME123",
  "hostUserId": "user_123",
  "maxPlayers": 15,
  "currentPlayers": 1
}
```

- Join game lobby

```
Endpoint: /game/lobby/{lobbyId}/join
Method: POST
Payload: {
  "userId": "user_456",
  "joinCode": "GAME123"
}
Response: {
  "status": "success",
  "lobbyId": "lobby_789",
  "playerCount": 2,
  "gameStatus": "waiting"
}
```

- Get Lobby Status

```
Endpoint: /game/lobby/{lobbyId}
Method: GET
Response: {
  "lobbyId": "lobby_789",
  "status": "in_progress",
  "currentPhase": "day",
  "phaseTimeRemaining": 420,
  "players": [
    {
      "userId": "user_123",
      "username": "playerName",
      "isAlive": true,
      "role": "hidden"
    },
    {
      "userId": "user_456",
      "username": "player2",
      "isAlive": false,
      "role": "hidden"
    }
  ],
  "dayCount": 3
}
```

#### Game State Endpoints

- Start Game

```
Endpoint: /game/{lobbyId}/start
Method: POST
Payload: {
  "hostUserId": "user_123"
}
Response: {
  "status": "success",
  "gameId": "game_101",
  "phase": "day",
  "message": "Game started! Day phase begins."
}
```

- Get player game state

```
Endpoint: /game/{lobbyId}/player/{userId}/state
Method: GET
Response: {
  "userId": "user_123",
  "role": "sheriff",
  "career": "detective",
  "isAlive": true,
  "canVote": true,
  "availableActions": ["investigate", "vote"],
  "gamePhase": "day",
  "phaseTimeRemaining": 420
}
```

- Update player status

```
Endpoint: /game/{lobbyId}/player/{userId}/status
Method: PATCH
Payload: {
  "status": "dead",
  "cause": "mafia_kill",
  "timestamp": "2025-01-15T22:30:00Z"
}
Response: {
  "status": "success",
  "playerId": "user_123",
  "newStatus": "dead",
  "gamePhase": "night"
}
```

#### Game Event Endpoints

- Initiate voting phase

```
Endpoint: /game/{lobbyId}/voting/initiate
Method: POST
Payload: {
  "votingDuration": 120,
  "eligibleVoters": ["user_123", "user_456", "user_789"]
}
Response: {
  "status": "success",
  "votingId": "vote_202",
  "duration": 120,
  "eligiblePlayers": 3
}
```

- Broadcast game event

```
Endpoint: /game/{lobbyId}/events/broadcast
Method: POST
Payload: [
  "eventType": "player_death",
  "message": "PlayerName was found dead in their home!",
  "targetPlayers": "all",
  "metadata": {
    "victimId": "user_456",
    "cause": "mafia_kill"
  }
]
Response: {
  "status": "success",
  "eventId": "event_303",
  "broadcastTime": "2025-01-15T22:31:00Z",
  "recipients": 14
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
Types: ```feat ```,  ```fix ```,  ```docs ```,  ```style ```,  ```refactor ```,  ```test ```,  ```chore ```

## Pull request requirements
- Clear title that is descriptive
- Detailed description of what, why, and how
- Linked iussues - a reference, if relevant to GitHub issues
- Screenshots, test results, or logs, if applicable
- Breaking changes -how it impacts other services, if applicable

## Test coverage
- Unit Tests -  80% code coverage minimum
- Integration Tests - all API endpoints covered
- Service Communication - event-driven interactions tested
