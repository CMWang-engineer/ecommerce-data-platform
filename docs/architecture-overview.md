# Architecture Overview

## Medallion Pattern

### Bronze Layer
- Raw data ingestion
- Timestamp stamping
- Schema validation
- Quality profiling

### Silver Layer  
- Parquet format
- year=/month=/day= partitioning
- Deduplication
- Type corrections
- 85% storage savings

### Gold Layer
- Business aggregations
- Customer segments
- Product performance
- Sales trends

## Technology Stack

**Cloud Platform**: Azure
- Data Factory (orchestration)
- Event Hubs (streaming)
- Stream Analytics (real-time processing)
- SQL Database (data warehouse)
- Blob Storage (data lake)

**Processing**: 
- Data Flows (transformations)
- dbt (business logic)
- SQL (warehouse operations)

**Automation**:
- GitHub Actions (CI/CD)

**Data Formats**:
- CSV (raw input)
- Parquet (optimized storage)
- Snappy compression

## Performance

- Query: 45s → 12s (73% faster)
- Storage: 500MB → 75MB (85% smaller)  
- Processing: 6h → 45min (87.5% faster)
