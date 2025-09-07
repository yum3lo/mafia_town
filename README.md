# Mafia Platform

## General Overview
The platform is an online multiplayer game system similar to a Mafia party game, where players interact within a virtual town, manage characters, and participate in strategic gameplay.
The architecture of the platform is service-oriented, with multiple specialized services working together. In the subchapters below, each service is described, its responsibilities, and how they communicate to create a consistent, interactive game experience.

## Service Boundaries

Out platform consists of the following microservices, each with their primary role and main functionalities:

### User Management Service

### Game service

### Shop Service
### Roleplay Service
### Town Service

Primary role: Central user identity and account management system

Functionalities:
- Location management - store and provices all places in town (including special ones like Shop and Informator Bureau), and reports these movements to the Task Service.
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
### Communication Service
### Task Service
### Voting Service

The diagram below represents the architecture diagram and how the microservices communicate between each other.

## Technology Stack and Communication Patterns

## Data Management

### Town Service
#### Location Management endpoints

- Endpoint for retrieveing all the available  locations
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
