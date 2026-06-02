CREATE OR REPLACE PROCEDURE RCA_DEMO.RCA_TOOLS.GENERATE_RCA_REPORT(
    ORIGINAL_QUERY STRING,
    DESCRIPTIVE_RESULTS STRING,
    CAUSAL_RESULTS STRING,
    OPTIMIZATION_RESULTS STRING,
    SIMULATION_RESULTS STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json

def run(session, original_query, descriptive_results, causal_results, optimization_results, simulation_results):
    desc = json.loads(descriptive_results) if descriptive_results else {}
    causal = json.loads(causal_results) if causal_results else {}
    optim = json.loads(optimization_results) if optimization_results else {}
    sim = json.loads(simulation_results) if simulation_results else {}

    report = []
    report.append("## Executive Diagnostic & Strategy Report")
    report.append("")
    report.append(f"**Query:** _{original_query}_")
    report.append("")

    report.append("### 1. The Reality Check (Descriptive Verification)")
    report.append("")
    if desc.get("verification"):
        v = desc["verification"]
        report.append(f"* **Total Records Analyzed:** {v.get('total_records', 'N/A'):,}")
        report.append(f"* **Metric Mean:** {v.get('metric_mean', 'N/A')} | **Median:** {v.get('metric_median', 'N/A')}")
        report.append(f"* **Date Range:** {v.get('date_range', {}).get('min', 'N/A')} to {v.get('date_range', {}).get('max', 'N/A')}")
        report.append(f"* **Anomalies Detected:** {len(desc.get('anomalies', []))}")
        report.append("")

    if desc.get("hypothesis_tests"):
        report.append("**Statistical Tests:**")
        for ht in desc["hypothesis_tests"]:
            report.append(f"* **{ht.get('test', 'Test')}:** {ht.get('interpretation', 'N/A')}")
        report.append("")

    if desc.get("slicing_analysis"):
        report.append("**Key Segments:**")
        for sa in desc["slicing_analysis"]:
            report.append(f"* **By {sa['dimension']}** ({sa['unique_values']} unique values):")
            for seg in sa.get("top_segments", [])[:5]:
                report.append(f"  - {seg['dimension_value']}: mean={seg['mean']}, {seg['pct_of_total']}% of total")
        report.append("")

    report.append("### 2. The Root Cause (Causal Diagnostic)")
    report.append("")
    if causal.get("regression_diagnostics"):
        rd = causal["regression_diagnostics"]
        report.append(f"* **Model Fit:** R²={rd.get('r_squared', 'N/A')}, Adj R²={rd.get('adj_r_squared', 'N/A')}")
        report.append(f"* **Observations:** {rd.get('observations', 'N/A')}")
        report.append("")

    if causal.get("attribution"):
        report.append("**Root Cause Attribution:**")
        for attr in causal["attribution"]:
            report.append(f"* **{attr['factor']}** ({attr['attribution_pct']}% attribution, {attr['direction']}, {attr['confidence']}% confidence)")
        report.append("")

    if causal.get("causal_analysis"):
        report.append("**Causal Evidence:**")
        for ca in causal["causal_analysis"]:
            if ca.get("interpretation"):
                report.append(f"* {ca['interpretation']}")
        report.append("")

    if causal.get("granger_tests"):
        report.append("**Temporal Causality (Granger Tests):**")
        for gt in causal["granger_tests"]:
            report.append(f"* {gt.get('interpretation', 'N/A')}")
        report.append("")

    report.append("### 3. The Prescribed Solution (Optimized Strategy)")
    report.append("")
    if optim.get("optimization"):
        opt = optim["optimization"]
        report.append(f"* **Optimization Status:** {opt.get('status', 'N/A')}")
        if opt.get("optimal_value"):
            report.append(f"* **Optimal Objective Value:** {opt['optimal_value']}")
        report.append("")

    if optim.get("recommendations"):
        report.append("**Recommended Actions:**")
        for rec in optim["recommendations"]:
            report.append(f"* **{rec['variable']}:** {rec.get('recommendation', 'N/A')}")
        report.append("")

    if optim.get("constraints_applied"):
        report.append(f"* **Business Constraints Applied:** {len(optim['constraints_applied'])}")
        for c in optim["constraints_applied"]:
            if c.get("description"):
                report.append(f"  - {c['name']}: {c['description']}")
        report.append("")

    report.append("### 4. Risk & Simulation (Monte Carlo Stress Test)")
    report.append("")
    if sim.get("simulation_config"):
        sc = sim["simulation_config"]
        report.append(f"* **Simulations Run:** {sc.get('num_simulations', 'N/A'):,}")
        report.append(f"* **Stochastic Variables Modeled:** {sc.get('num_stochastic_variables', 'N/A')}")
        report.append("")

    if sim.get("risk_assessment"):
        ra = sim["risk_assessment"]
        report.append(f"* **Expected Outcome:** {ra.get('expected_outcome', 'N/A')}")
        report.append(f"* **Probability of Success:** {ra.get('probability_of_success', 'N/A')}%")
        ci90 = ra.get("confidence_interval_90", {})
        report.append(f"* **90% Confidence Interval:** [{ci90.get('lower', 'N/A')}, {ci90.get('upper', 'N/A')}]")
        report.append(f"* **Worst-Case (10th Pctl):** {ra.get('worst_case_p10', 'N/A')}")
        report.append("")

    if sim.get("var_analysis"):
        va = sim["var_analysis"]
        report.append(f"* **Value at Risk (95%):** {va.get('value_at_risk_95', 'N/A')}")
        report.append(f"* {va.get('interpretation', '')}")
        report.append("")

    if sim.get("scenario_analysis"):
        report.append("**Scenario Breakdown:**")
        for scenario_name, scenario_data in sim["scenario_analysis"].items():
            report.append(f"* **{scenario_name.replace('_', ' ').title()}** ({scenario_data.get('label', '')}): Mean={scenario_data.get('mean_outcome', 'N/A')}")
        report.append("")

    report.append("---")
    report.append("*Report generated by the Autonomous RCA & Prescriptive Agent*")

    return "\n".join(report)
$$