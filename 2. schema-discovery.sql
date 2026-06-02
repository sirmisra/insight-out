CREATE OR REPLACE PROCEDURE RCA_DEMO.RCA_TOOLS.SCHEMA_DISCOVERY(
    TARGET_DATABASE STRING,
    TARGET_SCHEMA STRING
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json
import pandas as pd

ID_SUFFIXES = ("_ID", "_KEY", "_FK", "_PK", "_CODE", "_NUM", "_NUMBER", "_SEQ", "_IDX")
ID_EXACT = ("ID", "KEY", "PK", "FK", "INDEX", "SEQ", "ROW_NUMBER", "ROWNUM")

def is_id_column(col_name):
    cu = col_name.upper()
    if cu in ID_EXACT:
        return True
    for suffix in ID_SUFFIXES:
        if cu.endswith(suffix):
            return True
    if cu.startswith("SK_") or cu.startswith("FK_") or cu.startswith("PK_"):
        return True
    return False

def run(session, target_database, target_schema):
    tables_df = session.sql(f"""
        SELECT TABLE_NAME, TABLE_TYPE, ROW_COUNT, BYTES, COMMENT
        FROM {target_database}.INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = '{target_schema}'
        AND TABLE_TYPE IN ('BASE TABLE', 'VIEW')
        ORDER BY ROW_COUNT DESC NULLS LAST
    """).to_pandas()

    domain_keywords = {
        "healthcare": ["patient", "diagnosis", "clinic", "hospital", "appointment", "doctor", "treatment", "ward", "intake", "discharge", "prescription", "lab", "vitals", "footfall", "readmission", "icd", "cpt"],
        "retail_fmcg": ["product", "sku", "store", "sales", "transaction", "customer", "order", "inventory", "promotion", "price", "category", "brand", "pos", "market_share", "basket", "churn"],
        "logistics": ["shipment", "port", "container", "route", "carrier", "warehouse", "delivery", "tracking", "freight", "transit", "delay", "vessel", "export", "import", "customs"],
        "finance": ["account", "transaction", "balance", "payment", "loan", "credit", "debit", "revenue", "expense", "profit", "margin", "budget", "forex", "interest", "default"],
        "manufacturing": ["production", "defect", "assembly", "machine", "quality", "batch", "yield", "downtime", "maintenance", "capacity", "oee"],
        "marketing": ["campaign", "impression", "click", "ctr", "conversion", "cpc", "spend", "roi", "channel", "attribution", "lead", "funnel", "engagement"]
    }

    table_details = []
    for _, row in tables_df.iterrows():
        tbl = row["TABLE_NAME"]
        cols_df = session.sql(f"""
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COMMENT
            FROM {target_database}.INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '{target_schema}' AND TABLE_NAME = '{tbl}'
            ORDER BY ORDINAL_POSITION
        """).to_pandas()

        numeric_cols = cols_df[cols_df["DATA_TYPE"].isin(["NUMBER", "FLOAT", "DECIMAL", "NUMERIC", "INT", "INTEGER", "BIGINT", "SMALLINT", "DOUBLE", "REAL"])]["COLUMN_NAME"].tolist()
        date_cols = cols_df[cols_df["DATA_TYPE"].isin(["DATE", "TIMESTAMP_NTZ", "TIMESTAMP_LTZ", "TIMESTAMP_TZ", "DATETIME"])]["COLUMN_NAME"].tolist()
        text_cols = cols_df[cols_df["DATA_TYPE"].isin(["VARCHAR", "TEXT", "STRING", "CHAR"])]["COLUMN_NAME"].tolist()
        bool_cols = cols_df[cols_df["DATA_TYPE"].isin(["BOOLEAN"])]["COLUMN_NAME"].tolist()

        id_columns = [c for c in numeric_cols if is_id_column(c)]
        measure_columns = [c for c in numeric_cols if not is_id_column(c)]

        sample_data = []
        try:
            sample_df = session.sql(f"SELECT * FROM {target_database}.{target_schema}.{tbl} LIMIT 3").to_pandas()
            sample_data = sample_df.astype(str).to_dict("records")
        except Exception:
            pass

        cardinality_checks = {}
        for c in numeric_cols:
            if is_id_column(c):
                continue
            try:
                card_df = session.sql(f"SELECT COUNT(DISTINCT {c}) AS dc, COUNT(*) AS tc FROM {target_database}.{target_schema}.{tbl} WHERE {c} IS NOT NULL").to_pandas()
                dc = int(card_df.iloc[0, 0])
                tc = int(card_df.iloc[0, 1])
                ratio = dc / tc if tc > 0 else 1
                if ratio > 0.9 and dc > 20:
                    id_columns.append(c)
                    if c in measure_columns:
                        measure_columns.remove(c)
                    cardinality_checks[c] = {"distinct": dc, "total": tc, "classified_as": "likely_id"}
            except Exception:
                pass

        table_details.append({
            "table_name": tbl,
            "table_type": row["TABLE_TYPE"],
            "row_count": int(row["ROW_COUNT"]) if row["ROW_COUNT"] else 0,
            "columns": cols_df[["COLUMN_NAME", "DATA_TYPE"]].to_dict("records"),
            "id_columns_DO_NOT_USE_AS_METRICS": id_columns,
            "measure_columns_USE_AS_METRICS_OR_TREATMENTS": measure_columns,
            "dimension_columns_USE_FOR_SLICING": text_cols + bool_cols,
            "date_columns": date_cols,
            "sample_rows": sample_data[:3]
        })

    all_names = " ".join(
        [t["table_name"].lower() for t in table_details] +
        [c["COLUMN_NAME"].lower() for t in table_details for c in t["columns"]]
    )
    domain_scores = {}
    for domain, keywords in domain_keywords.items():
        score = sum(1 for kw in keywords if kw in all_names)
        if score > 0:
            domain_scores[domain] = score

    detected_domain = max(domain_scores, key=domain_scores.get) if domain_scores else "general"

    semantic_views = []
    try:
        sv_df = session.sql(f"SHOW SEMANTIC VIEWS IN SCHEMA {target_database}.{target_schema}").to_pandas()
        if len(sv_df) > 0:
            for _, sv_row in sv_df.iterrows():
                semantic_views.append({
                    "name": sv_row.get("name", ""),
                    "fqn": f"{target_database}.{target_schema}.{sv_row.get('name', '')}"
                })
    except Exception:
        pass

    potential_metrics = []
    potential_dimensions = []
    potential_time_cols = []
    id_cols_all = []
    for t in table_details:
        for c in t["measure_columns_USE_AS_METRICS_OR_TREATMENTS"]:
            potential_metrics.append(f"{t['table_name']}.{c}")
        for c in t["dimension_columns_USE_FOR_SLICING"]:
            potential_dimensions.append(f"{t['table_name']}.{c}")
        for c in t["date_columns"]:
            potential_time_cols.append(f"{t['table_name']}.{c}")
        for c in t["id_columns_DO_NOT_USE_AS_METRICS"]:
            id_cols_all.append(f"{t['table_name']}.{c}")

    result = {
        "database": target_database,
        "schema": target_schema,
        "detected_domain": detected_domain,
        "domain_confidence_scores": domain_scores,
        "table_count": len(table_details),
        "tables": table_details,
        "semantic_views": semantic_views,
        "IMPORTANT_column_classification": {
            "id_columns_NEVER_USE_AS_TREATMENT_OR_METRIC": id_cols_all,
            "measure_columns_USE_AS_METRICS_AND_TREATMENTS": potential_metrics[:50],
            "dimension_columns_USE_FOR_SLICING_AND_CONFOUNDERS": potential_dimensions[:50],
            "time_columns": potential_time_cols[:20]
        },
        "summary": f"Discovered {len(table_details)} tables in {target_database}.{target_schema}. Domain: {detected_domain}. MEASURES (for metrics/treatments): {len(potential_metrics)}. DIMENSIONS (for slicing/confounders): {len(potential_dimensions)}. IDs (DO NOT use as factors): {len(id_cols_all)}. Time columns: {len(potential_time_cols)}. Semantic views: {len(semantic_views)}."
    }
    return result
$$;
