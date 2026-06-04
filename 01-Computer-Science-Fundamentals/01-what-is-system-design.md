# What is System Design

## Definition
System design is the process of defining the architecture, components, modules, interfaces, and data flow of a system to satisfy specified requirements. It bridges the gap between requirements and implementation.

## Real-World Example
**Amazon.com**: Handles millions of requests per second across thousands of microservices. The system design includes load balancers, CDN for static assets, product catalog service, recommendation engine, payment gateway, order processing, and inventory management — all working together seamlessly.

## Key Questions System Design Answers
- How many users can this system support?
- What happens when a server crashes?
- How fast can data be retrieved?
- How is data kept consistent across replicas?
- What is the cost of running this infrastructure?

## Advantages
- Prevents costly architectural mistakes
- Enables scaling before traffic hits
- Provides clear communication blueprint
- Identifies bottlenecks early
- Documents tradeoff decisions

## Disadvantages
- Time-consuming upfront
- Can over-engineer if requirements are unclear
- Requires experienced architects
- May need revision as requirements evolve

## When to Invest in System Design
- Building for millions of users
- Mission-critical systems (finance, healthcare)
- Systems that must evolve over years
- Multi-team projects requiring coordination

## Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  System Design Process                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Requirements ──► Estimation ──► Design ──► Tradeoffs   │
│       │              │              │           │        │
│       ▼              ▼              ▼           ▼        │
│  Functional      Capacity       High-Level    Decisions │
│  Non-Functional  Estimation     Low-Level     Documented│
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Interview Questions
1. What is system design and why is it important?
2. Walk through your approach to designing a new system
3. What's the difference between system design and software architecture?
4. How do you gather requirements for a system design?
5. What are the most common pitfalls in system design?
