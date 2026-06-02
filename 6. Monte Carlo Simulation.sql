CREATE OR REPLACE PROCEDURE RCA_DEMO.RCA_TOOLS.MONTE_CARLO_SIMULATION(
    STRATEGY_JSON STRING,
    VARIABLE_DISTRIBUTIONS STRING,
    NUM_SIMULATIONS INT DEFAULT 10000,
    TABLE_FQN STRING DEFAULT NULL,
    METRIC_COLUMN STRING DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'numpy', 'scipy')
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json
import numpy as np
import pandas as pd
from scipy import stats as sp_stats

def run(session, strategy_json, variable_distributions, num_simulations, table_fqn, metric_column):
    np.random.seed(42)
    strategy = json.loads(strategy_json)
    var_dists = json.loads(variable_distributions)
    n = num_simulations

    results = {"simulation_config": {}, "outcome_distribution": {}, "risk_assessment": {}, "scenario_analysis": {}, "var_analysis": {}}

    if table_fqn and metric_column:
        try:
            hist_sql = f"""
                SELECT AVG({metric_column}) as mu, STDDEV({metric_column}) as sigma,
                       MIN({metric_column}) as min_val, MAX({metric_column}) as max_val
                FROM {table_fqn}
                WHERE {metric_column} IS NOT NULL
            """
            hist_df = session.sql(hist_sql).to_pandas()
            baseline_mu = float(hist_df.iloc[0, 0]) if not pd.isna(hist_df.iloc[0, 0]) else 0
            baseline_sigma = float(hist_df.iloc[0, 1]) if not pd.isna(hist_df.iloc[0, 1]) else 1
        except Exception:
            baseline_mu, baseline_sigma = 0, 1
    else:
        baseline_mu = strategy.get("baseline_value", 100)
        baseline_sigma = strategy.get("baseline_std", 10)

    simulated_vars = {}
    for var in var_dists:
        name = var["name"]
        dist_type = var.get("distribution", "normal")
        params = var.get("params", {})

        if dist_type == "normal":
            simulated_vars[name] = np.random.normal(params.get("mean", 0), params.get("std", 1), n)
        elif dist_type == "uniform":
            simulated_vars[name] = np.random.uniform(params.get("low", 0), params.get("high", 1), n)
        elif dist_type == "triangular":
            simulated_vars[name] = np.random.triangular(params.get("left", 0), params.get("mode", 0.5), params.get("right", 1), n)
        elif dist_type == "lognormal":
            simulated_vars[name] = np.random.lognormal(params.get("mean", 0), params.get("sigma", 1), n)
        elif dist_type == "beta":
            simulated_vars[name] = np.random.beta(params.get("a", 2), params.get("b", 5), n)
        else:
            simulated_vars[name] = np.random.normal(params.get("mean", 0), params.get("std", 1), n)

    outcome_formula = strategy.get("outcome_formula", "baseline")
    expected_effect = strategy.get("expected_effect", 0)
    effect_std = strategy.get("effect_std", abs(expected_effect) * 0.3 if expected_effect != 0 else 1)

    base_outcomes = np.random.normal(baseline_mu, baseline_sigma, n)
    strategy_effect = np.random.normal(expected_effect, effect_std, n)

    noise = np.zeros(n)
    for var_name, var_vals in simulated_vars.items():
        var_config = next((v for v in var_dists if v["name"] == var_name), {})
        impact_coeff = var_config.get("impact_coefficient", 0)
        noise += impact_coeff * var_vals

    outcomes = base_outcomes + strategy_effect + noise

    success_threshold = strategy.get("success_threshold", baseline_mu + expected_effect * 0.5)
    success_rate = float(np.mean(outcomes >= success_threshold))

    results["simulation_config"] = {
        "num_simulations": n,
        "baseline_mean": round(baseline_mu, 4),
        "baseline_std": round(baseline_sigma, 4),
        "expected_effect": round(expected_effect, 4),
        "num_stochastic_variables": len(var_dists)
    }

    percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    pct_vals = {f"p{p}": round(float(np.percentile(outcomes, p)), 4) for p in percentiles}

    results["outcome_distribution"] = {
        "mean": round(float(np.mean(outcomes)), 4),
        "median": round(float(np.median(outcomes)), 4),
        "std": round(float(np.std(outcomes)), 4),
        "min": round(float(np.min(outcomes)), 4),
        "max": round(float(np.max(outcomes)), 4),
        "skewness": round(float(sp_stats.skew(outcomes)), 4),
        "kurtosis": round(float(sp_stats.kurtosis(outcomes)), 4),
        "percentiles": pct_vals
    }

    results["risk_assessment"] = {
        "probability_of_success": round(success_rate * 100, 2),
        "probability_of_failure": round((1 - success_rate) * 100, 2),
        "success_threshold": round(success_threshold, 4),
        "expected_outcome": round(float(np.mean(outcomes)), 4),
        "worst_case_p10": round(float(np.percentile(outcomes, 10)), 4),
        "best_case_p90": round(float(np.percentile(outcomes, 90)), 4),
        "downside_risk_p5": round(float(np.percentile(outcomes, 5)), 4),
        "confidence_interval_90": {
            "lower": round(float(np.percentile(outcomes, 5)), 4),
            "upper": round(float(np.percentile(outcomes, 95)), 4)
        },
        "confidence_interval_95": {
            "lower": round(float(np.percentile(outcomes, 2.5)), 4),
            "upper": round(float(np.percentile(outcomes, 97.5)), 4)
        }
    }

    var_95 = float(np.percentile(outcomes, 5))
    cvar_95 = float(np.mean(outcomes[outcomes <= var_95]))
    results["var_analysis"] = {
        "value_at_risk_95": round(var_95, 4),
        "conditional_var_95": round(cvar_95, 4),
        "interpretation": f"There is a 5% chance the outcome will be below {round(var_95,2)}. In the worst 5% of scenarios, the average outcome is {round(cvar_95,2)}."
    }

    scenarios = {
        "optimistic": {"percentile_range": (75, 100), "label": "Best 25% of outcomes"},
        "expected": {"percentile_range": (25, 75), "label": "Middle 50% of outcomes"},
        "pessimistic": {"percentile_range": (0, 25), "label": "Worst 25% of outcomes"},
        "worst_case": {"percentile_range": (0, 10), "label": "Worst 10% of outcomes (tail risk)"}
    }
    for scenario_name, config in scenarios.items():
        low_p, high_p = config["percentile_range"]
        low_v = np.percentile(outcomes, low_p)
        high_v = np.percentile(outcomes, high_p)
        mask = (outcomes >= low_v) & (outcomes <= high_v)
        scenario_outcomes = outcomes[mask]
        results["scenario_analysis"][scenario_name] = {
            "label": config["label"],
            "mean_outcome": round(float(np.mean(scenario_outcomes)), 4) if len(scenario_outcomes) > 0 else 0,
            "outcome_range": {"low": round(float(low_v), 4), "high": round(float(high_v), 4)},
            "probability": f"{high_p - low_p}%"
        }

    results["summary"] = (
        f"Monte Carlo simulation complete ({n:,} iterations). "
        f"Expected outcome: {round(float(np.mean(outcomes)),2)}. "
        f"Probability of success: {round(success_rate*100,1)}%. "
        f"90% CI: [{round(float(np.percentile(outcomes,5)),2)}, {round(float(np.percentile(outcomes,95)),2)}]. "
        f"Worst-case (10th pctl): {round(float(np.percentile(outcomes,10)),2)}."
    )
    return results
$$