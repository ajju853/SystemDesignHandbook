# Food Delivery System

## Requirements

- Browse restaurants and menus
- Place orders with real-time tracking
- Rider assignment and route optimization
- Live order status (preparing → picked up → delivered)
- Payment integration
- Ratings and reviews
- 1M daily orders, 300K active riders

## Capacity Estimation

```
Orders:         1M/day ≈ 12 orders/sec (40/sec peak at lunch)
Restaurants:    100K registered, 50K active daily
Menu updates:   500K item changes/day
Location pings: 300K riders × 1 req/5s = 60K writes/sec
Order reads:    2M status checks/day
Search queries: 10M/day (restaurants, cuisines, dishes)
Storage:        1M orders × 2KB = 2GB/day → 730GB/year
```

## API Design

```
// Discovery
GET /restaurants?lat=...&lng=...&cuisine=... → [{id, name, eta, rating}]
GET /restaurants/{id}/menu → [{category, items}]
GET /restaurants/{id}/reviews?page=...

// Ordering
POST /orders → {restaurant_id, items[], address, payment_method}
GET /orders/{id} → {status, items, rider, eta}
POST /orders/{id}/cancel

// Rider
PUT /riders/location → {lat, lng}
GET /riders/orders → [pending_delivery]
PATCH /orders/{id}/status → {status: picked_up | delivered}

// Real-time (WebSocket)
WS /orders/{id}/track
  → rider_location, order_status, estimated_arrival
WS /riders/assignments
  → new_order_assignment, route_update
```

## Database Design

```sql
-- Restaurants
CREATE TABLE restaurants (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    cuisines TEXT[], -- ['indian', 'chinese']
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    address TEXT,
    rating DECIMAL(2,1),
    price_range INT, -- 1-4
    is_open BOOLEAN,
    avg_prep_time INT, -- minutes
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_location USING GIST (ll_to_earth(lat, lng)),
    INDEX idx_cuisines USING GIN (cuisines)
);

-- Menu items
CREATE TABLE menu_items (
    id UUID PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id),
    name VARCHAR(255),
    description TEXT,
    price DECIMAL(10,2),
    category VARCHAR(100),
    is_available BOOLEAN DEFAULT TRUE,
    image_url TEXT,
    INDEX idx_restaurant_category (restaurant_id, category)
);

-- Orders
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    restaurant_id UUID NOT NULL,
    rider_id UUID,
    status VARCHAR(20) CHECK (status IN (
        'pending', 'confirmed', 'preparing', 'ready',
        'picked_up', 'en_route', 'delivered', 'cancelled'
    )),
    items JSONB NOT NULL, -- [{item_id, quantity, special_instructions, price}]
    total_amount DECIMAL(10,2),
    delivery_fee DECIMAL(10,2),
    payment_method VARCHAR(20),
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    delivery_address TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    delivered_at TIMESTAMP,
    INDEX idx_user_orders (user_id, created_at DESC),
    INDEX idx_restaurant_status (restaurant_id, status),
    INDEX idx_rider_status (rider_id, status)
);

-- Rider location (time-series)
CREATE TABLE rider_locations (
    rider_id UUID NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMP DEFAULT NOW()
) PARTITION BY RANGE (recorded_at);
```

## High-Level Design

```
┌──────────────────────────────────────────────────────────────┐
│                 Food Delivery Architecture                     │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  User App                          Rider App                  │
│    │                                  │                       │
│    ▼                                  ▼                       │
│  ┌──────────┐                   ┌──────────┐                 │
│  │ API      │                   │ WebSocket │                 │
│  │ Gateway  │                   │ Gateway   │                 │
│  └────┬─────┘                   └────┬──────┘                │
│       │                              │                        │
│  ┌────┴──────────────────────────────┴─────┐                 │
│  │           Order Service                  │                 │
│  └────┬──────────────────────────────┬──────┘                 │
│       │                              │                        │
│  ┌────┴────┐                   ┌─────┴─────┐                │
│  │ Matching│                   │ Dispatch  │                 │
│  │ Service │                   │ & Routing │                 │
│  └─────────┘                   └─────┬─────┘                │
│                                      │                        │
│  ┌──────────┐  ┌──────────┐  ┌───────┴──────┐               │
│  │Search(ES)│  │PostgreSQL│  │Redis (geo +  │               │
│  │          │  │(orders)  │  │ rider cache) │               │
│  └──────────┘  └──────────┘  └──────────────┘               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Low-Level Design: Order Flow

```
1. User searches → Search Service (Elasticsearch)
2. User places order → Order Service:
   a. Validate restaurant, items, availability
   b. Calculate total + delivery fee
   c. Process payment (Payment Service)
   d. Create order (status: pending)
3. Restaurant confirms → status → preparing
4. Rider assignment (Dispatch Service):
   a. Find nearby riders (H3 geospatial query on Redis)
   b. Score riders by: distance, current load, history
   c. Send assignment to top 3 riders
   d. First to accept → rider_id assigned
   e. Compute optimal route (restaurant → delivery address)
5. Rider picks up → status: picked_up
6. Rider arrives → status: delivered
7. Rating prompt sent to user
```

## Rider Assignment Algorithm

```
function assign_rider(order):
    candidates = []
    h3_cells = get_h3_cells(order.restaurant_location, radius=3km)
    
    for cell in h3_cells:
        riders = redis.smembers(f"riders_online:{cell}")
        for rider in riders:
            score = (
                proximity_weight * distance(rider, restaurant) +
                load_weight * (1 / rider.current_orders + 1) +
                rating_weight * rider.rating +
                direction_weight * alignment(rider.direction, order.direction)
            )
            candidates.append((rider, score))
    
    candidates.sort(key=score, reverse=True)
    return candidates[:3]
```

## Scaling Strategy

| Component | Strategy |
|-----------|----------|
| **Geospatial search** | H3 grid in Redis; restaurants indexed by hex cell |
| **Order writes** | PostgreSQL partitioned by date; read replicas |
| **Rider location** | High-throughput ingestion → Kafka → Cassandra (time-series) |
| **Dispatch** | Workers partitioned by H3 cell |
| **Real-time tracking** | WebSocket to nearest region; Redis pub/sub |
| **Search** | Elasticsearch with cuisine, rating, price filters |
| **Menu cache** | Redis: restaurant menus cached with TTL 5 min |
| **Peak traffic** | Auto-scale order processing; queue overflow to SQS |

## Deployment

```yaml
services:
  api-gateway: # Nginx/Kong, rate limiting
  order-service: # Order lifecycle management
  dispatch-service: # Rider assignment + routing
  search-service: # Elasticsearch
  payment-service: # Payment processing
  notification-service: # Push + SMS
  
infrastructure:
  db: PostgreSQL (orders, restaurants, users)
  stream: Kafka (order events, rider location)
  cache: Redis Cluster (geo index, session, menus)
  search: Elasticsearch
  storage: S3 (menu images)
  time-series: Cassandra (rider location history)
```

## Interview Questions

1. How do you find nearby restaurants efficiently?
2. How does rider assignment work at scale?
3. How would you design real-time order tracking?
4. How do you handle surge pricing during peak hours?
5. Design the restaurant recommendation and search system
