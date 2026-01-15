{% macro read_silver_table(table_name) %}
read_parquet(
  '{{ var("silver_data_path") }}/{{ table_name }}_partitioned/**',
  hive_partitioning = 1
)
{% endmacro %}

