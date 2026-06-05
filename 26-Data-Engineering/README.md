# 26 — Data Engineering

> Master the design, architecture, and operation of data pipelines, warehouses, lakehouses, streaming systems, and the modern data stack — from ingestion to analytics to ML.

## Module Overview

Data Engineering is the foundation of every data-driven organization. This module covers the full data lifecycle: ingestion, storage, transformation, orchestration, quality, governance, and reverse ETL. Each file dives into architecture, hands-on examples, best practices, and real-world usage.

```mermaid
mindmap
  root((Data Engineering))
    Storage
      Data Lakehouse
      Iceberg / Delta Lake
      Parquet / ORC / Avro
      Partitioning / Clustering
    Processing
      Batch (Spark, dbt)
      Stream (Flink, Kafka Streams)
      Real-Time (ClickHouse, Druid)
      Workflow Orchestration
    Ingestion
      Airbyte / Fivetran
      Kafka Connect
      CDC (Debezium)
      Reverse ETL
    Quality & Governance
      Data Quality (Great Expectations)
      Data Catalog (DataHub)
      Data Lineage
      PII / Masking / RBAC
    Platform
      Data Warehouse (Snowflake, BigQuery)
      Schema Registry
      Observability
      Cost Optimization
```

```mermaid
graph LR
    subgraph "Ingestion"
        A[Sources<br/>DBs, APIs, Events] --> B[Ingestion<br/>Airbyte, Kafka, Fivetran]
    end
    subgraph "Storage"
        B --> C[Data Lake<br/>S3/ADLS/GCS + Iceberg]
        C --> D[Warehouse<br/>Snowflake/BigQuery]
    end
    subgraph "Transformation"
        D --> E[dbt / Spark]
        C --> E
    end
    subgraph "Orchestration"
        E --> F[Airflow / Dagster]
    end
    subgraph "Consumption"
        F --> G[BI Tools<br/>Looker, Tableau]
        F --> H[ML / AI<br/>Feature Store]
        F --> I[Reverse ETL<br/>Census, Hightouch]
    end
    subgraph "Quality & Governance"
        J[Great Expectations]
        K[DataHub / Atlan]
        C --> J
        D --> J
        D --> K
    end
    style A fill:#4a90d9,color:#fff
    style B fill:#7b68ee,color:#fff
    style C fill:#e67e22,color:#fff
    style D fill:#2ecc71,color:#fff
    style E fill:#e74c3c,color:#fff
    style F fill:#1abc9c,color:#fff
    style G fill:#f39c12,color:#fff
    style H fill:#f39c12,color:#fff
    style I fill:#f39c12,color:#fff
    style J fill:#95a5a6,color:#fff
    style K fill:#95a5a6,color:#fff
```

## Topics

| # | File | Topics |
|---|------|--------|
| 01 | [Data Engineering Overview](01-data-engineering-overview.md) | Modern data stack, data pipeline architecture, data engineer role |
| 02 | [Data Lakehouse Architecture](02-data-lakehouse-architecture.md) | Lake vs warehouse vs lakehouse, Apache Iceberg, Delta Lake, Hudi |
| 03 | [Batch Processing](03-batch-processing.md) | Spark, dbt, ETL/ELT, Kimball vs Inmon, incremental models |
| 04 | [Stream Processing](04-stream-processing.md) | Kafka, Kafka Streams, Flink, streaming patterns, exactly-once |
| 05 | [Schema Registry & Evolution](05-schema-registry-evolution.md) | Avro/Protobuf/JSON Schema, compatibility, schema migration |
| 06 | [Data Quality](06-data-quality.md) | Great Expectations, data profiling, observability, anomaly detection |
| 07 | [ETL & ELT Pipelines](07-etl-elt-pipelines.md) | Airbyte, Fivetran, dbt, data ingestion strategies, incremental syncs |
| 08 | [Data Warehousing](08-data-warehousing.md) | Snowflake, BigQuery, Redshift, Databricks SQL, architecture comparison |
| 09 | [Data Lake Storage](09-data-lake-storage.md) | S3/ADLS/GCS, file formats (Parquet, ORC, Avro), partitioning, compression |
| 10 | [Workflow Orchestration](10-workflow-orchestration.md) | Airflow, Prefect, Dagster, DAGs, retries, SLAs, observability |
| 11 | [Data Catalog & Metadata](11-data-catalog-metadata.md) | DataHub, Amundsen, Atlan, data discovery, lineage, ownership |
| 12 | [Real-Time Analytics](12-real-time-analytics.md) | ClickHouse, Druid, Pinot, real-time dashboards, OLAP vs OLTP |
| 13 | [Reverse ETL](13-reverse-etl.md) | Census, Hightouch, operational data, CDP, audience sync |
| 14 | [Data Governance & Security](14-data-governance-security.md) | RBAC, column-level security, masking, PII, compliance (GDPR/SOC2) |
| 15 | [Data Platform Architecture](15-data-platform-architecture.md) | End-to-end platform design, cost optimization, maturity model |

## Learning Path

1. **Start with the overview** (01) — understand the modern data stack and how pieces fit together
2. **Master storage** (02, 09) — data lakehouse architecture and file formats are the foundation
3. **Learn processing patterns** (03, 04) — batch and stream processing for different latency needs
4. **Build pipelines** (07, 10) — ETL/ELT, orchestration, and scheduling
5. **Enforce quality and governance** (06, 11, 14) — data quality, catalog, and security
6. **Enable analytics** (08, 12) — warehousing, real-time analytics, and BI consumption
7. **Close the loop** (13) — reverse ETL for operational data activation
8. **Put it together** (05, 15) — schema management and end-to-end platform architecture

## Prerequisites

- Basic understanding of databases and SQL
- Familiarity with cloud storage (S3, GCS, ADLS)
- Some experience with Python or JVM languages
- Understanding of basic data modeling concepts

---

Previous: [25 — Clean Architecture & Design Patterns](../25-Clean-Architecture-Design-Patterns/README.md)
Next: [27 — Frontend System Design](../27-Frontend-System-Design/README.md)
