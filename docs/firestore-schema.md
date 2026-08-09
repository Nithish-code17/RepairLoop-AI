# Firestore schema

## `users/{uid}`

- `email`
- `displayName`
- `role`: `customer | manufacturer | technician | admin`
- `createdAt`, `updatedAt`

## `products/{productId}`

- `passportId`
- `ownerId`, `manufacturerId`
- `name`, `brand`, `model`, `category`, `serialNumber`
- `status`
- `purchaseDate`, `warrantyEnd`
- `createdAt`, `updatedAt`

## `products/{productId}/components/{componentId}`

- `productId`, optional `repairId`
- `name`, `partNumber`, `condition`
- `isOriginal`
- `installedAt`, `replacedAt`

## `diagnoses/{diagnosisId}`

- `productId`, `userId`
- `symptoms`, `imageUrl`
- structured assessment fields
- `provider`, `model`
- `createdAt`

## `repairs/{repairId}`

- `productId`, `ownerId`, `manufacturerId`, `diagnosisId`
- `technicianId`
- `status`, `issueSummary`, `technicianNotes`
- `createdAt`, `updatedAt`, `completedAt`

## `lifecycleEvents/{eventId}`

- `productId`
- `type`, `title`, `description`
- `actorId`
- `createdAt`

Lifecycle events are created only by trusted Cloud Functions and are append-only to clients.
