# Mafia Platform

## General Overview

The platform is an online multiplayer game system similar to a Mafia party game, where players interact within a virtual town, manage characters, and participate in strategic gameplay.
The architecture of the platform is service-oriented, with multiple specialized services working together. In the subchapters below, each service is described, its responsibilities, and how they communicate to create a consistent, interactive game experience.

## Service Boundaries

Out platform consists of the following microservices, each with their primary role and main functionalities:

### User Management Service

### Game service

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

### Voting Service

The diagram below represents the architecture diagram and how the microservices communicate between each other.

## Technology Stack and Communication Patterns

## Data Management

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

`POST /rumors/buy`

- Player spends currency to get a random rumor.

**Request (JSON)**:

```json
{
  "playerId": "123e4567-e89b-12d3-a456-426614174000",
  "currencySpent": 50
}
```

**Response (JSON)**:

```json
{
  "rumorId": "987e6543-e21b-12d3-a456-426614174999",
  "content": "Player X was last seen near the warehouse.",
  "category": "task"
}
```

`GET /rumors/:playerId`

- Fetch all rumors a player has purchased.

**Response (JSON)**:

```json
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

`GET /rumors/random`

- (Admin/debug use) Preview a random rumor from the pool.

**Response (JSON)**:

```json
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

`POST /chat/send`

- Send a message to a chat room.

**Request (JSON):**

```json
{
  "chatRoomId": "abc123",
  "senderId": "player123",
  "content": "Did anyone see who was near the warehouse?"
}
```

**Response (JSON):**

```json
{
  "messageId": "msg987",
  "chatRoomId": "abc123",
  "senderId": "player123",
  "content": "Did anyone see who was near the warehouse?",
  "createdAt": "2025-09-07T12:00:00Z"
}
```

`GET /chat/:chatRoomId/messages`

- Fetch all messages for a chat room.

**Response (JSON):**

```json
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

`GET /chat/rooms/:playerId`

- Fetch all chat rooms a player has access to (Mafia, location-based, or global during voting hours).

**Response (JSON):**

```json
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
