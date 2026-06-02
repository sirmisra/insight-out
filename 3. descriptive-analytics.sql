CREATE OR REPLACE PROCEDURE RCA_DEMO.RCA_TOOLS.DESCRIPTIVE_ANALYTICS(
    QUERY_CONTEXT STRING,
    METRIC_COLUMN STRING,
    DIMENSION_COLUMNS STRING,
    TIME_COLUMN STRING,
    TABLE_FQN STRING,
    COMPARISON_PERIODS STRING DEFAULT NULL,
    FILTERS STRING DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'scipy', 'numpy', 'statsmodels')
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json
import numpy as np
import pandas as pd
from scipy import stats as sp_stats
import statsmodels.api as sm

def run(session, query_context, metric_column, dimension_columns, time_column, table_fqn, comparison_periods, filters):
    dims = [d.strip() for d in dimension_columns.split(",") if d.strip()]
    where_clause = f"WHERE {filters}" if filters else ""

    select_cols = [time_column, metric_column] + dims
    base_sql = f"SELECT {', '.join(select_cols)} FROM {table_fqn} {where_clause} ORDER BY {time_column}"
    df = session.sql(base_sql).to_pandas()
    df.columns = [c.upper() for c in df.columns]
    tc = time_column.split(".")[-1].upper()
    mc = metric_column.split(".")[-1].upper()

    results = {
        "query_context": query_context,
        "verification": {},
        "hypothesis_tests": [],
        "anomalies": [],
        "slicing_analysis": [],
        "trend_analysis": {}
    }

    total_rows = len(df)
    if total_rows == 0:
        results["verification"] = {"total_records": 0, "metric_mean": 0, "metric_std": 0, "metric_median": 0, "metric_min": 0, "metric_max": 0, "null_count": 0, "date_range": {"min": "N/A", "max": "N/A"}}
        results["summary"] = f"Analyzed 0 records. No data found matching filters. Check date range and table."
        return results

    overall_mean = float(df[mc].mean())
    overall_std = float(df[mc].std()) if total_rows > 1 else 0
    overall_median = float(df[mc].median())

    results["verification"] = {
        "total_records": total_rows,
        "metric_mean": round(overall_mean, 4),
        "metric_std": round(overall_std, 4),
        "metric_median": round(overall_median, 4),
        "metric_min": round(float(df[mc].min()), 4),
        "metric_max": round(float(df[mc].max()), 4),
        "metric_sum": round(float(df[mc].sum()), 4),
        "null_count": int(df[mc].isna().sum()),
        "date_range": {"min": str(df[tc].min()), "max": str(df[tc].max())}
    }

    if comparison_periods:
        try:
            periods = json.loads(comparison_periods)
            pa = periods.get("period_a", {})
            pb = periods.get("period_b", {})
            df[tc] = pd.to_datetime(df[tc])

            mask_a = (df[tc] >= pa["start"]) & (df[tc] <= pa["end"])
            mask_b = (df[tc] >= pb["start"]) & (df[tc] <= pb["end"])
            data_a = df.loc[mask_a, mc].dropna()
            data_b = df.loc[mask_b, mc].dropna()

            if len(data_a) > 1 and len(data_b) > 1:
                pct_change = ((data_b.mean() - data_a.mean()) / data_a.mean() * 100) if data_a.mean() != 0 else 0

                t_stat, t_p = sp_stats.ttest_ind(data_a, data_b, equal_var=False)
                results["hypothesis_tests"].append({
                    "test": "Welch t-test (period comparison)",
                    "period_a_mean": round(float(data_a.mean()), 4),
                    "period_b_mean": round(float(data_b.mean()), 4),
                    "pct_change": round(float(pct_change), 2),
                    "t_statistic": round(float(t_stat), 4),
                    "p_value": round(float(t_p), 6),
                    "significant_at_005": bool(t_p < 0.05),
                    "interpretation": f"{'Statistically significant' if t_p < 0.05 else 'Not statistically significant'} difference of {round(pct_change,1)}% between periods (p={round(t_p,4)})"
                })

                u_stat, u_p = sp_stats.mannwhitneyu(data_a, data_b, alternative='two-sided')
                results["hypothesis_tests"].append({
                    "test": "Mann-Whitney U (non-parametric period comparison)",
                    "u_statistic": round(float(u_stat), 4),
                    "p_value": round(float(u_p), 6),
                    "significant_at_005": bool(u_p < 0.05),
                    "interpretation": f"Non-parametric test {'confirms' if u_p < 0.05 else 'does not confirm'} significant difference (p={round(u_p,4)})"
                })
        except Exception:
            pass

    for dim in dims:
        dim_upper = dim.strip().upper()
        if dim_upper not in df.columns:
            continue

        df[dim_upper] = df[dim_upper].astype(str)
        group_stats = df.groupby(dim_upper)[mc].agg(["mean", "std", "count", "sum"]).reset_index()
        group_stats.columns = [dim_upper, "mean", "std", "count", "sum"]
        group_stats = group_stats.sort_values("sum", ascending=False).head(20)

        slice_results = []
        total_sum = df[mc].sum()
        for _, row in group_stats.iterrows():
            slice_results.append({
                "dimension_value": str(row[dim_upper]),
                "mean": round(float(row["mean"]), 4),
                "std": round(float(row["std"]), 4) if not pd.isna(row["std"]) else 0,
                "count": int(row["count"]),
                "total": round(float(row["sum"]), 4),
                "pct_of_total": round(float(row["sum"]) / total_sum * 100, 2) if total_sum != 0 else 0
            })

        results["slicing_analysis"].append({
            "dimension": dim_upper,
            "unique_values": int(df[dim_upper].nunique()),
            "top_segments": slice_results
        })

        groups = [grp[mc].dropna().values for _, grp in df.groupby(dim_upper) if len(grp[mc].dropna()) > 1]
        n_groups = len(groups)
        if n_groups >= 2:
            try:
                if n_groups == 2:
                    t_s, t_p = sp_stats.ttest_ind(groups[0], groups[1], equal_var=False)
                    results["hypothesis_tests"].append({
                        "test": f"Welch t-test across {dim_upper} (2 groups)",
                        "t_statistic": round(float(t_s), 4),
                        "p_value": round(float(t_p), 6),
                        "significant_at_005": bool(t_p < 0.05),
                        "interpretation": f"{'Significant' if t_p < 0.05 else 'No significant'} difference in {mc} between {dim_upper} groups (p={round(t_p,4)})"
                    })
                else:
                    f_stat, f_p = sp_stats.f_oneway(*groups[:15])
                    results["hypothesis_tests"].append({
                        "test": f"ANOVA across {dim_upper} ({n_groups} groups)",
                        "f_statistic": round(float(f_stat), 4),
                        "p_value": round(float(f_p), 6),
                        "significant_at_005": bool(f_p < 0.05),
                        "interpretation": f"{'Significant' if f_p < 0.05 else 'No significant'} variance in {mc} across {dim_upper} groups (F={round(f_stat,2)}, p={round(f_p,4)})"
                    })

                    h_stat, h_p = sp_stats.kruskal(*groups[:15])
                    results["hypothesis_tests"].append({
                        "test": f"Kruskal-Wallis H across {dim_upper} ({n_groups} groups, non-parametric)",
                        "h_statistic": round(float(h_stat), 4),
                        "p_value": round(float(h_p), 6),
                        "significant_at_005": bool(h_p < 0.05),
                        "interpretation": f"Non-parametric test {'confirms' if h_p < 0.05 else 'does not confirm'} significant group differences (p={round(h_p,4)})"
                    })
            except Exception:
                pass

    if overall_std > 0:
        z_scores = np.abs((df[mc] - overall_mean) / overall_std)
        anomaly_mask = z_scores > 2.5
        if anomaly_mask.sum() > 0:
            anom_df = df[anomaly_mask].head(20)
            for _, row in anom_df.iterrows():
                results["anomalies"].append({
                    "date": str(row[tc]),
                    "value": round(float(row[mc]), 4),
                    "z_score": round(float((row[mc] - overall_mean) / overall_std), 2),
                    "dimensions": {d.upper(): str(row[d.upper()]) for d in dims if d.upper() in row.index}
                })

    try:
        df[tc] = pd.to_datetime(df[tc])
        ts = df.groupby(tc)[mc].mean().sort_index().reset_index()
        if len(ts) >= 3:
            ts["t"] = range(len(ts))
            X = sm.add_constant(ts["t"].values)
            model = sm.OLS(ts[mc].values, X).fit()
            slope = float(model.params[1])
            slope_p = float(model.pvalues[1])
            results["trend_analysis"] = {
                "slope_per_period": round(slope, 6),
                "slope_p_value": round(slope_p, 6),
                "trend_direction": "increasing" if slope > 0 else "decreasing",
                "trend_significant": bool(slope_p < 0.05),
                "r_squared": round(float(model.rsquared), 4),
                "interpretation": f"Metric shows a {'significant' if slope_p < 0.05 else 'non-significant'} {'upward' if slope > 0 else 'downward'} trend (slope={round(slope,4)}/period, p={round(slope_p,4)})"
            }
    except Exception:
        results["trend_analysis"] = {"note": "Insufficient time variation for trend analysis"}

    results["summary"] = (
        f"Analyzed {total_rows} records. Metric {mc}: mean={round(overall_mean,2)}, "
        f"median={round(overall_median,2)}, sum={round(float(df[mc].sum()),2)}. "
        f"Found {len(results['anomalies'])} anomalies. "
        f"Ran {len(results['hypothesis_tests'])} hypothesis tests."
    )
    return results
$$;
