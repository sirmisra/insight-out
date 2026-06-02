CREATE OR REPLACE PROCEDURE RCA_DEMO.RCA_TOOLS.PRESCRIPTIVE_OPTIMIZATION(
    OBJECTIVE STRING,
    DECISION_VARIABLES STRING,
    CONSTRAINTS_JSON STRING,
    TABLE_FQN STRING,
    HISTORICAL_CONTEXT STRING DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'numpy', 'scipy', 'pulp')
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json
import numpy as np
import pandas as pd
from pulp import LpProblem, LpMaximize, LpMinimize, LpVariable, LpStatus, value

def run(session, objective, decision_variables, constraints_json, table_fqn, historical_context):
    dec_vars_config = json.loads(decision_variables)
    constraints_config = json.loads(constraints_json)

    results = {"optimization": {}, "decision_variables": [], "constraints_applied": [], "sensitivity": [], "historical_bounds": {}}

    hist_bounds = {}
    for var_cfg in dec_vars_config:
        col_name = var_cfg.get("column")
        if col_name:
            try:
                stats_sql = f"""
                    SELECT
                        MIN({col_name}) as min_val,
                        MAX({col_name}) as max_val,
                        AVG({col_name}) as avg_val,
                        STDDEV({col_name}) as std_val,
                        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY {col_name}) as p5,
                        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY {col_name}) as p95
                    FROM {table_fqn}
                    WHERE {col_name} IS NOT NULL
                """
                stats_df = session.sql(stats_sql).to_pandas()
                hist_bounds[col_name] = {
                    "min": float(stats_df.iloc[0, 0]) if not pd.isna(stats_df.iloc[0, 0]) else 0,
                    "max": float(stats_df.iloc[0, 1]) if not pd.isna(stats_df.iloc[0, 1]) else 1000,
                    "avg": float(stats_df.iloc[0, 2]) if not pd.isna(stats_df.iloc[0, 2]) else 0,
                    "std": float(stats_df.iloc[0, 3]) if not pd.isna(stats_df.iloc[0, 3]) else 0,
                    "p5": float(stats_df.iloc[0, 4]) if not pd.isna(stats_df.iloc[0, 4]) else 0,
                    "p95": float(stats_df.iloc[0, 5]) if not pd.isna(stats_df.iloc[0, 5]) else 1000
                }
            except Exception:
                hist_bounds[col_name] = {"min": 0, "max": 1000, "avg": 500, "std": 100, "p5": 50, "p95": 950}

    results["historical_bounds"] = hist_bounds

    obj_config = json.loads(objective)
    sense = LpMaximize if obj_config.get("direction", "maximize") == "maximize" else LpMinimize
    prob = LpProblem("RCA_Optimization", sense)

    lp_vars = {}
    for var_cfg in dec_vars_config:
        name = var_cfg["name"]
        col = var_cfg.get("column", name)
        bounds = hist_bounds.get(col, {})

        lb = var_cfg.get("lower_bound", bounds.get("p5", 0))
        ub = var_cfg.get("upper_bound", bounds.get("p95", 1000))

        if var_cfg.get("use_historical_bounds", True) and col in hist_bounds:
            lb = max(lb, hist_bounds[col].get("p5", lb))
            ub = min(ub, hist_bounds[col].get("p95", ub))

        lp_vars[name] = LpVariable(name, lowBound=lb, upBound=ub)
        results["decision_variables"].append({
            "name": name,
            "lower_bound": round(lb, 4),
            "upper_bound": round(ub, 4),
            "historical_avg": round(bounds.get("avg", 0), 4)
        })

    obj_terms = obj_config.get("terms", [])
    obj_expr = sum(t["coefficient"] * lp_vars[t["variable"]] for t in obj_terms if t["variable"] in lp_vars)
    prob += obj_expr

    for i, constr in enumerate(constraints_config):
        lhs_terms = constr.get("terms", [])
        lhs = sum(t["coefficient"] * lp_vars[t["variable"]] for t in lhs_terms if t["variable"] in lp_vars)
        rhs = constr.get("rhs", 0)
        op = constr.get("operator", "<=")
        name = constr.get("name", f"constraint_{i}")

        if op == "<=":
            prob += (lhs <= rhs, name)
        elif op == ">=":
            prob += (lhs >= rhs, name)
        elif op == "==":
            prob += (lhs == rhs, name)

        results["constraints_applied"].append({
            "name": name,
            "operator": op,
            "rhs": rhs,
            "description": constr.get("description", "")
        })

    prob.solve()

    status = LpStatus[prob.status]
    results["optimization"] = {
        "status": status,
        "optimal_value": round(value(prob.objective), 4) if status == "Optimal" else None,
        "objective_direction": obj_config.get("direction", "maximize")
    }

    recommendations = []
    for var_cfg in dec_vars_config:
        name = var_cfg["name"]
        col = var_cfg.get("column", name)
        if name in lp_vars:
            opt_val = float(lp_vars[name].varValue) if lp_vars[name].varValue is not None else 0
            hist_avg = hist_bounds.get(col, {}).get("avg", 0)
            change_pct = ((opt_val - hist_avg) / hist_avg * 100) if hist_avg != 0 else 0

            recommendations.append({
                "variable": name,
                "optimal_value": round(opt_val, 4),
                "current_average": round(hist_avg, 4),
                "change_pct": round(change_pct, 2),
                "direction": "increase" if change_pct > 0 else "decrease",
                "recommendation": f"{'Increase' if change_pct > 0 else 'Decrease'} {name} from {round(hist_avg,2)} to {round(opt_val,2)} ({'+' if change_pct > 0 else ''}{round(change_pct,1)}%)"
            })

    results["recommendations"] = recommendations

    sensitivity = []
    for var_cfg in dec_vars_config:
        name = var_cfg["name"]
        if name in lp_vars and lp_vars[name].varValue is not None:
            base_val = float(lp_vars[name].varValue)
            for pct in [-10, -5, 5, 10]:
                sensitivity.append({
                    "variable": name,
                    "perturbation_pct": pct,
                    "note": f"If {name} is constrained {pct}% from optimal ({round(base_val,2)}), re-solve to assess impact"
                })
    results["sensitivity"] = sensitivity

    results["summary"] = f"Optimization {status}. " + (f"Optimal objective value: {round(value(prob.objective), 4)}. " if status == "Optimal" else "") + f"{len(recommendations)} recommended actions generated with {len(constraints_config)} constraints applied."
    return results
$$