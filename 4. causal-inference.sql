CREATE OR REPLACE PROCEDURE RCA_DEMO.RCA_TOOLS.CAUSAL_INFERENCE(
    OUTCOME_COLUMN STRING,
    TREATMENT_COLUMNS STRING,
    CONFOUNDER_COLUMNS STRING,
    TABLE_FQN STRING,
    TIME_COLUMN STRING DEFAULT NULL,
    FILTERS STRING DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'scipy', 'numpy', 'statsmodels', 'scikit-learn')
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json
import numpy as np
import pandas as pd
from scipy import stats
import statsmodels.api as sm
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.linear_model import LogisticRegression

def run(session, outcome_column, treatment_columns, confounder_columns, table_fqn, time_column, filters):
    treatments = [t.strip() for t in treatment_columns.split(",") if t.strip()]
    confounders = [c.strip() for c in confounder_columns.split(",") if c.strip()]

    select_cols = [outcome_column] + treatments + confounders
    if time_column:
        select_cols.append(time_column)
    where_clause = f"WHERE {filters}" if filters else ""

    sql = f"SELECT {', '.join(select_cols)} FROM {table_fqn} {where_clause}"
    df = session.sql(sql).to_pandas()
    df.columns = [c.upper() for c in df.columns]
    oc = outcome_column.split(".")[-1].upper()

    results = {"causal_analysis": [], "granger_tests": [], "regression_diagnostics": {}, "attribution": []}

    le_dict = {}
    for col in df.columns:
        if df[col].dtype == "object":
            le = LabelEncoder()
            df[col] = le.fit_transform(df[col].astype(str))
            le_dict[col] = le

    df = df.dropna()
    if len(df) < 10:
        return {"error": "Insufficient data for causal analysis", "rows_available": len(df)}

    treatment_uppers = [t.split(".")[-1].upper() for t in treatments]
    confounder_uppers = [c.split(".")[-1].upper() for c in confounders]

    all_predictors = treatment_uppers + confounder_uppers
    existing_preds = [p for p in all_predictors if p in df.columns]
    X = df[existing_preds].astype(float)
    y = df[oc].astype(float)

    X_const = sm.add_constant(X)
    try:
        model = sm.OLS(y, X_const).fit()
        results["regression_diagnostics"] = {
            "r_squared": round(float(model.rsquared), 4),
            "adj_r_squared": round(float(model.rsquared_adj), 4),
            "f_statistic": round(float(model.fvalue), 4),
            "f_pvalue": round(float(model.f_pvalue), 6),
            "aic": round(float(model.aic), 2),
            "bic": round(float(model.bic), 2),
            "observations": int(model.nobs)
        }

        total_abs_effect = sum(abs(model.params.get(t, 0)) * df[t].std() for t in treatment_uppers if t in model.params and t in df.columns)

        for t in treatment_uppers:
            if t not in model.params:
                continue
            coef = float(model.params[t])
            se = float(model.bse[t])
            p = float(model.pvalues[t])
            ci = model.conf_int().loc[t]
            std_effect = coef * float(df[t].std()) if t in df.columns else coef

            attribution_pct = (abs(std_effect) / total_abs_effect * 100) if total_abs_effect > 0 else 0

            results["causal_analysis"].append({
                "treatment": t,
                "coefficient": round(coef, 6),
                "std_error": round(se, 6),
                "t_statistic": round(coef / se if se > 0 else 0, 4),
                "p_value": round(p, 6),
                "ci_lower": round(float(ci[0]), 6),
                "ci_upper": round(float(ci[1]), 6),
                "standardized_effect": round(std_effect, 4),
                "significant": bool(p < 0.05),
                "attribution_pct": round(attribution_pct, 1),
                "interpretation": f"A 1-unit increase in {t} is associated with a {round(coef,4)} change in {oc} (p={round(p,4)}, {'significant' if p<0.05 else 'not significant'}). Controlling for {len(confounder_uppers)} confounders."
            })

            results["attribution"].append({
                "factor": t,
                "attribution_pct": round(attribution_pct, 1),
                "direction": "positive" if coef > 0 else "negative",
                "confidence": round((1 - p) * 100, 1)
            })
    except Exception as e:
        results["regression_diagnostics"]["error"] = str(e)

    for t in treatment_uppers:
        if t not in df.columns:
            continue
        for treat2 in treatment_uppers:
            if treat2 == t or treat2 not in df.columns:
                continue
            try:
                binary_t = (df[t] > df[t].median()).astype(int)
                if binary_t.nunique() < 2:
                    continue

                conf_cols = [c for c in confounder_uppers if c in df.columns]
                if not conf_cols:
                    continue

                X_ps = df[conf_cols].astype(float)
                scaler = StandardScaler()
                X_ps_scaled = scaler.fit_transform(X_ps)

                ps_model = LogisticRegression(max_iter=1000, random_state=42)
                ps_model.fit(X_ps_scaled, binary_t)
                ps = ps_model.predict_proba(X_ps_scaled)[:, 1]

                ps_clipped = np.clip(ps, 0.05, 0.95)
                weights = np.where(binary_t == 1, 1 / ps_clipped, 1 / (1 - ps_clipped))

                treated_outcome = np.average(y[binary_t == 1], weights=weights[binary_t == 1])
                control_outcome = np.average(y[binary_t == 0], weights=weights[binary_t == 0])
                ate = treated_outcome - control_outcome

                results["causal_analysis"].append({
                    "treatment": t,
                    "method": "Inverse Propensity Weighting (IPW)",
                    "average_treatment_effect": round(float(ate), 4),
                    "treated_mean": round(float(treated_outcome), 4),
                    "control_mean": round(float(control_outcome), 4),
                    "interpretation": f"IPW estimate: Being in high-{t} group causes a {round(ate,4)} change in {oc} after controlling for confounders."
                })
                break
            except Exception:
                pass

    if time_column:
        tc = time_column.split(".")[-1].upper()
        if tc in df.columns:
            ts_df = df.sort_values(tc)
            for t in treatment_uppers:
                if t not in ts_df.columns:
                    continue
                try:
                    from statsmodels.tsa.stattools import grangercausalitytests
                    test_data = ts_df[[oc, t]].dropna()
                    if len(test_data) > 20:
                        max_lag = min(5, len(test_data) // 5)
                        gc_result = grangercausalitytests(test_data, maxlag=max_lag, verbose=False)
                        best_lag = min(gc_result.keys(), key=lambda k: gc_result[k][0]["ssr_ftest"][1])
                        f_val = gc_result[best_lag][0]["ssr_ftest"][0]
                        p_val = gc_result[best_lag][0]["ssr_ftest"][1]

                        results["granger_tests"].a  ppend({
                            "cause": t,
                            "effect": oc,
                            "best_lag": int(best_lag),
                            "f_statistic": round(float(f_val), 4),
                            "p_value": round(float(p_val), 6),
                            "granger_causal": bool(p_val < 0.05),
                            "interpretation": f"{t} {'Granger-causes' if p_val < 0.05 else 'does not Granger-cause'} {oc} at lag {best_lag} (p={round(p_val,4)})"
                        })
                except Exception:
                    pass

    results["attribution"].sort(key=lambda x: x["attribution_pct"], reverse=True)
    results["summary"] = f"Causal analysis complete. Analyzed {len(treatment_uppers)} treatment variables controlling for {len(confounder_uppers)} confounders across {len(df)} observations. R²={results['regression_diagnostics'].get('r_squared', 'N/A')}."
    return results
$$