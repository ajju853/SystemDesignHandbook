# RabbitMQ

## Definition
RabbitMQ is a message broker implementing AMQP (Advanced Message Queuing Protocol). It supports flexible routing, delivery guarantees, and multiple messaging patterns.

## Real-World Example
**Instagram**: Uses RabbitMQ for notification delivery (likes, comments, follows). When a user performs an action, RabbitMQ routes the notification to the appropriate channel.

## Architecture

```
Producer ──► Exchange ──► Binding ──► Queue ──► Consumer
                │
        ┌───────┼───────┐
        │       │       │
    Direct  Topic   Fanout
    Exchange Exchange Exchange
```

## Exchange Types

| Type | Routing | Use Case |
|------|---------|----------|
| **Direct** | Exact routing key match | Point-to-point |
| **Topic** | Pattern matching (routing.*) | Pub/sub with filtering |
| **Fanout** | Broadcast to all queues | Event broadcasting |
| **Headers** | Header-based routing | Complex routing logic |

## Interview Questions
1. How does RabbitMQ's exchange model differ from Kafka's topics?
2. What happens when a queue reaches its max length?
3. How does RabbitMQ handle message acknowledgments?
4. Compare RabbitMQ and Kafka for task queues
5. Design a notification system using RabbitMQ
