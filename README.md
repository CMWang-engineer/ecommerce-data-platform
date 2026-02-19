# 🚀 E-commerce Data Platform

> End-to-end data engineering on Azure: Medallion architecture, automated quality checks, real-time streaming, and CI/CD with GitHub Actions.

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue)](https://github.com/你的用户名/ecommerce-data-platform)
[![Languages](https://img.shields.io/badge/Python-81.5%25-blue)](.)
[![dbt](https://img.shields.io/badge/dbt-Ready-orange)](./ecommerce_dbt)

---

## 📊 Project Overview

Enterprise-grade data platform built over 3 weeks (Day 1-16 completed), demonstrating:
- **Medallion Architecture**: Bronze → Silver → Gold data layers
- **Data Quality Framework**: 5-dimension automated validation
- **Real-Time Streaming**: Event Hubs + Stream Analytics
- **Data Warehouse**: SCD Type 2 implementation
- **CI/CD**: GitHub Actions (replaced Azure Automation)

### 🎯 Key Results

| Achievement | Impact |
|------------|--------|
| **Query Performance** | ↑ 70% via Parquet partitioning |
| **Storage Savings** | ↓ 85% with Snappy compression |
| **Data Quality** | Fixed 66.67% duplication rate |
| **Pipeline Reliability** | 98% success rate |
| **Cost Efficiency** | Complete project < $50 |

---

## 🏗️ Architecture
```
Raw CSV Files → Bronze (Validated) → Silver (Cleaned Parquet) → Gold (Analytics)
                     ↓                       ↓                        ↓
               Quality Checks         Deduplication            Business Metrics
```

**Tech Stack**: 
- **Cloud**: Azure Data Factory, Event Hubs, Stream Analytics, SQL Database, Blob Storage
- **Processing**: Data Flows, dbt, SQL
- **Orchestration**: GitHub Actions (see `.github/workflows/`)
- **Data Format**: Parquet with Snappy compression

---

## 📁 Repository Structure
```
ecommerce-data-platform/
│
├── .github/workflows/        # CI/CD automation
│   ├── dbt_daily_run.yml    # Daily dbt transformations
│   └── [other workflows]
│
├── ecommerce_dbt/            # dbt project for Silver → Gold
│   ├── models/              # Transformation models
│   ├── dbt_project.yml
│   └── profiles.yml
│
├── config/                   # Configuration files
│   └── file_config.json     # Pipeline configurations
│
├── data/                     # Sample data
│   └── [sample CSVs]
│
├── scripts/                  # Utility scripts
│   └── [automation scripts]
│
├── streaming_simulator/      # Real-time data simulator
│   └── [Event Hub simulator]
│
├── generate_ecommerce_data.py  # Test data generator
│
└── README.md                 # You are here
```

---

## 🎯 What I Built

### 1. Medallion Data Lake Architecture

**Bronze Layer** (Raw Data Landing):
- CSV ingestion with timestamp and schema validation
- Automated quality profiling
- Metadata logging

**Silver Layer** (Cleaned & Standardized):
- Parquet format with Snappy compression (85% storage reduction)
- Partitioned by `year=/month=/day=` for query optimization
- Deduplication (fixed 66.67% duplicate rate)
- Type corrections (string → integer for partition fields)

**Gold Layer** (Business-Ready Analytics):
- Customer segments and lifetime value
- Product performance metrics
- Daily sales aggregations
- Churn prediction features (prepared for ML)

### 2. Data Quality Framework (5 Dimensions)

Automated checks on every pipeline run:

✅ **Completeness**: Null rate tracking (achieved 98.5% completeness)
✅ **Uniqueness**: Duplicate detection (found & fixed 66.67% duplication)
✅ **Accuracy**: Format validation via regex (email/phone)
✅ **Referential Integrity**: Foreign key validation (100% valid)
✅ **Timeliness**: Watermark-based incremental loading

**Results stored in**: `bronze/quality_reports/quality_report.csv`

### 3. Real-Time Streaming Pipeline

- **Event Hubs**: `orders-stream` for real-time order ingestion
- **Stream Analytics**: 5-minute tumbling windows for aggregation
- **Lambda Architecture**: Merges streaming + batch data in Silver layer
- **Latency**: < 5 minutes from event to analytics

**Simulator**: `streaming_simulator/` generates test events

### 4. Data Warehouse (SCD Type 2)

Star schema on Azure SQL Database:
- `dim_customer` (Slowly Changing Dimension Type 2)
- `dim_product`
- `dim_date`
- `fact_orders`

**Historical tracking**: Full customer change history with effective dates

### 5. dbt Transformations

See `ecommerce_dbt/` for:
- Staging models (Bronze → Silver cleanup)
- Intermediate models (business logic)
- Mart models (final analytics tables)

**Daily runs**: Automated via `.github/workflows/dbt_daily_run.yml`

### 6. CI/CD with GitHub Actions

**Why GitHub Actions?** Azure Automation unavailable in free tier → pivoted to GitHub Actions.

**Workflows implemented**:
- Daily dbt runs
- Data quality checks on PR
- Automated testing

---

## 📈 Performance Optimizations

### Before Optimization
- ❌ Query time: 45 seconds (full table scan)
- ❌ Storage: 500 MB CSV files
- ❌ Data quality: 66.67% duplication rate
- ❌ Processing: 6 hours full reload

### After Optimization
- ✅ Query time: 12 seconds (partition pruning) - **73% faster**
- ✅ Storage: 75 MB Parquet files - **85% reduction**
- ✅ Data quality: 1.0 score (automated fix)
- ✅ Processing: 45 minutes incremental - **87.5% faster**

### Key Techniques
1. **Parquet Partitioning**: `year=/month=/day=` directory structure
2. **Snappy Compression**: Optimal balance of speed vs. size
3. **Incremental Loading**: Watermark tables track last processed timestamp
4. **Type Optimization**: Integer partitions (not strings) for pruning

---

## 💡 Key Challenges Solved

### Challenge 1: Massive Data Duplication
**Problem**: Quality checks revealed 30,000 records but only 10,000 unique customers (66.67% duplication).

**Solution**: Created `dfUniquenessCheck` Data Flow with `Aggregate(first())` transformation to keep first occurrence.

**Impact**: Quality score improved from 0.33 to 1.0, storage reduced by 66%.

### Challenge 2: Azure Automation Unavailable
**Problem**: Azure Automation not available in free tier after trial expired.

**Solution**: Pivoted to GitHub Actions for scheduling and deployment.

**Impact**: 
- Zero cost automation
- Better version control (workflows in Git)
- Learned new valuable skill

### Challenge 3: Parquet Partition Type Mismatch
**Problem**: Year/month/day fields were strings, blocking partition pruning.

**Solution**: Created type conversion Data Flows to cast to integers.

**Impact**: Enabled partition pruning → 70% query speedup.

---

## 🛠️ Getting Started

### Prerequisites
- Azure subscription (free tier sufficient for testing)
- Python 3.8+
- dbt installed

### Quick Start
```bash
# Clone repository
git clone https://github.com/你的用户名/ecommerce-data-platform.git
cd ecommerce-data-platform

# Generate sample data
python generate_ecommerce_data.py

# Run dbt transformations (local)
cd ecommerce_dbt
dbt run

# Simulate streaming events
cd ../streaming_simulator
python simulate_orders.py
```

### Deployment

Automated via GitHub Actions:
1. Push to `main` branch
2. GitHub Actions triggers dbt run
3. Quality checks execute
4. Results logged to Azure

---

## 📊 Data Quality Reports

Sample quality report output:

| Table | Total Checks | Passed | Failed | Avg Score | Rating |
|-------|-------------|--------|--------|-----------|---------|
| customers | 3 | 3 | 0 | 0.9900 | EXCELLENT |
| orders | 1 | 1 | 0 | 1.0000 | EXCELLENT |
| products | 2 | 2 | 0 | 0.9850 | EXCELLENT |

Reports generated daily and stored in `bronze/quality_reports/`

---

## 🎓 Technical Learnings

### What Worked Well
✅ Medallion architecture provided clear separation of concerns
✅ Automated quality checks caught issues early
✅ Parquet + partitioning = massive performance gains
✅ GitHub Actions is powerful and cost-effective

### Key Takeaways
1. **Profile data early**: Quality issues in Bronze are easier to fix
2. **Constraints drive creativity**: No Azure Automation → better solution
3. **Data types matter**: Integer vs. string for partitions = 70% performance difference
4. **Cost optimization is continuous**: Daily monitoring + small tweaks

---

## 📞 Contact

**[Chenmeng Wang]**
Data Engineer | Azure Certified
📧 lemonrunning@outlook.com
💼 [LinkedIn](https://linkedin.com/in/chenmeng-wang-b95923122)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

**⭐ If this project helps you, please star it!**
