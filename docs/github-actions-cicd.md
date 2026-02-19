# GitHub Actions CI/CD

## Why GitHub Actions?

**Original Plan**: Azure Automation
**Problem**: Not available in free tier
**Solution**: GitHub Actions

## Advantages

| Feature | Azure Automation | GitHub Actions |
|---------|------------------|----------------|
| Cost | Paid | Free (public repos) |
| Version Control | Separate | Native Git |
| Flexibility | Azure-focused | Multi-cloud |

## Workflows Implemented

### 1. dbt_daily_run.yml
- **Trigger**: Daily at midnight UTC
- **Action**: Runs dbt transformations
- **Duration**: ~15 minutes

### 2. Quality Checks
- **Trigger**: Pull request to main
- **Action**: Validates data quality
- **Blocks**: Merge if quality < 0.9

## Results

- ✅ Zero cost automation
- ✅ Full Git history
- ✅ Easy to modify (YAML)
- ✅ Transparent logs

## Key Learning

Sometimes constraints lead to better solutions!
