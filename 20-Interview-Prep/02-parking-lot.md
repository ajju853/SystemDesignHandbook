# Design Parking Lot

## Problem
Design a parking lot system with multiple floors, vehicle types, and payment.

## Key Classes

```mermaid
classDiagram
    class ParkingLot {
        +List~Floor~ floors
        +List~Gate~ entry_gates
        +List~Gate~ exit_gates
    }
    class Floor {
        +Dict~VehicleType, List~ParkingSpot~~ spots
    }
    class ParkingSpot {
        +int id
        +string type
        +bool is_available
    }
    class Vehicle {
        +string license_plate
        +string type
    }
    class Ticket {
        +int id
        +int spot_id
        +DateTime entry_time
        +string vehicle_plate
    }
    class Payment {
        +int ticket_id
        +float amount
        +string method
        +DateTime time
    }
    ParkingLot "1" --> "*" Floor
    Floor "1" --> "*" ParkingSpot
    Ticket "1" --> "1" ParkingSpot
    Ticket "1" --> "1" Vehicle
    Payment "1" --> "1" Ticket
```

```python
class ParkingLot:
    floors: List[Floor]
    entry_gates: List[Gate]
    exit_gates: List[Gate]

class Floor:
    spots: Dict[VehicleType, List[ParkingSpot]]

class ParkingSpot:
    id, type, is_available

class Vehicle:
    license_plate, type

class Ticket:
    id, spot, entry_time, vehicle

class Payment:
    ticket, amount, method, time
```

## Key Design Points

| Aspect | Considerations |
|--------|---------------|
| Spot assignment | Nearest to entry/exit, spot type matching |
| Pricing | Per-hour, peak/off-peak, vehicle type |
| Availability | Display real-time availability |
| Reservations | Pre-booking spots (optional) |
| Payment | Cash, card, mobile, subscription |

## Interview Discussion
1. How do you find the nearest available spot efficiently?
2. How do you handle concurrency (two cars entering at same time)?
3. Design the pricing strategy
4. How do you handle electric vehicle charging spots?
