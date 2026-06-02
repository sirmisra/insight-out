---
name: rca-prescriptive-agent
description: >
  Use this skill for root cause analysis, diagnostic analytics, prescriptive optimization,
  why something happened, how to fix a metric decline, causal inference, Monte Carlo simulation,
  or executive diagnostic reports. Works across ANY domain: healthcare, retail, FMCG, logistics,
  finance, manufacturing, marketing, exports.
  Triggers: RCA, root cause, why did, what caused, how to fix, prescriptive, optimization,
  Monte Carlo, simulation, hypothesis test, causal analysis, diagnostic report, low sales,
  low footfall, shortcoming, decline, drop, spike, anomaly.
---

# InsightOut: Autonomous RCA & Prescriptive Agent

## What This Is

A domain-agnostic Root Cause Analysis pipeline that runs entirely inside Snowflake.
Give it any database/schema (or a Cortex Analyst semantic view + business rules table) and ask
"Why did X happen?" — it discovers the data, verifies the claim statistically, identifies
root causes, optimizes a fix, stress-tests it with Monte Carlo simulation, and delivers
an executive report.

**Works for**: healthcare footfall, retail sales, FMCG market share, logistics delays,
export shortfalls, marketing CTR, manufacturing defects, finance defaults — any tabular data.

---

## Quick Start (5 minutes)

### Step 1: Create Infrastructure

```sql
CREATE DATABASE IF NOT EXISTS RCA_DEMO;
CREATE SCHEMA  IF NOT EXISTS RCA_DEMO.RCA_TOOLS;
CREATE STAGE   IF NOT EXISTS RCA_DEMO.RCA_TOOLS.RCA_STAGE;
```

### Step 2: Create All Stored Procedures

Run each SQL file in order from this workspace:

| File | Procedure Created |
|------|-------------------|
| `2. schema-discovery.sql` | `RCA_DEMO.RCA_TOOLS.SCHEMA_DISCOVERY` |
| `3. descriptive-analytics.sql` | `RCA_DEMO.RCA_TOOLS.DESCRIPTIVE_ANALYTICS` |
| `4. causal-inference.sql` | `RCA_DEMO.RCA_TOOLS.CAUSAL_INFERENCE` |
| `5. Prescriptive Optimization (PuLP).sql` | `RCA_DEMO.RCA_TOOLS.PRESCRIPTIVE_OPTIMIZATION` |
| `6. Monte Carlo Simulation.sql` | `RCA_DEMO.RCA_TOOLS.MONTE_CARLO_SIMULATION` |
| `7. Report Generator.sql` | `RCA_DEMO.RCA_TOOLS.GENERATE_RCA_REPORT` |

### Step 3: Create the Agent

Run `8. Cortex Agent.sql`. This creates the Cortex Agent object that orchestrates the tools.

> **Important**: Before running, update the `warehouse` value in the YAML spec to your warehouse name.

### Step 4: Test

Navigate to **AI & ML > Agents** in Snowsight, select `RCA_PRESCRIPTIVE_AGENT`, and ask:

> "I see low sales in 1st half of 2023 compared to 2nd. Data is in MY_DB.MY_SCHEMA."

Or invoke via SQL:

```sql
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'RCA_DEMO.RCA_TOOLS.RCA_PRESCRIPTIVE_AGENT',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"Why did sales drop in Q3? Check MY_DB.MY_SCHEMA."}]}],"stream":false}'
);
```

### Step 5: Cleanup (optional)

Run `9. clean-up.sql` to tear down everything.

---

## Architecture

```
User Query
  |
  v
Agent Orchestrator (claude-4-sonnet, budget: 300s / 60K tokens)
  |
  |-- Phase 0: Schema Discovery -----------> SCHEMA_DISCOVERY proc
  |       discovers tables, columns, domain, semantic views
  |       CLASSIFIES columns: IDs vs Measures vs Dimensions
  |
  |-- Phase 1: Descriptive Analytics ------> DESCRIPTIVE_ANALYTICS proc
  |       auto-selects stat tests, verifies claim, finds anomalies
  |       uses ONLY measures as metrics, dimensions for slicing
  |
  |-- Phase 2: Human Checkpoint (ONLY pause)
  |       presents findings, proposes treatments (measures only),
  |       confounders (dimensions only), asks user to confirm
  |
  |   [ USER CONFIRMS -> all remaining phases run automatically ]
  |
  |-- Phase 3: Causal Inference -----------> CAUSAL_INFERENCE proc
  |       OLS regression, IPW, Granger causality, attribution ranking
  |       treatments = measures, confounders = dimensions
  |
  |-- Phase 4: Prescriptive Optimization --> PRESCRIPTIVE_OPTIMIZATION proc
  |       PuLP LP/MILP, P5/P95 historical bounds, sensitivity analysis
  |
  |-- Phase 5: Monte Carlo Simulation ----> MONTE_CARLO_SIMULATION proc
  |       10K iterations, VaR/CVaR, scenario analysis
  |
  |-- Report Generation ------------------> GENERATE_RCA_REPORT proc
  |       Executive Diagnostic & Strategy Report
  v
User receives structured Markdown report
```

---

## Critical: Column Classification (ID vs Measure vs Dimension)

Schema Discovery automatically classifies every column. The agent enforces this throughout:

| Bucket | What Goes Here | Used For | NEVER Used For |
|--------|---------------|----------|----------------|
| **ID columns** | CUSTOMER_ID, PRODUCT_ID, TRANSACTION_ID, CLAIM_ID, ORDER_ID, HOUSE_ID | Nothing (excluded) | Metrics, treatments, confounders, slicing |
| **Measure columns** | REVENUE, QUANTITY, PRICE, DISCOUNT_PCT, DAYS_SUPPLY, WAIT_TIME | Outcome metric, treatment variables, decision variables | - |
| **Dimension columns** | REGION, CATEGORY, PHARMACY_TYPE, IS_REFILL, CHANNEL, STATUS | Dimension slicing, confounder variables | Outcome metric |

### How IDs Are Detected
1. **By suffix**: `_ID`, `_KEY`, `_FK`, `_PK`, `_CODE`, `_NUM`, `_NUMBER`, `_SEQ`, `_IDX`
2. **By exact name**: `ID`, `KEY`, `PK`, `FK`, `INDEX`, `SEQ`
3. **By prefix**: `SK_`, `FK_`, `PK_`
4. **By cardinality**: Numeric columns with >90% distinct values and >20 uniques → likely ID

### Why This Matters
Without this classification, the agent would pass `CUSTOMER_ID` or `PRODUCT_ID` as treatment
variables in causal inference — producing meaningless results like "CUSTOMER_ID has 77.7% attribution."
The classification ensures only real business measures drive the analysis.

---

## Execution Behavior: One Pause, Then Continuous

| Phase | Behavior |
|-------|----------|
| Phase 0: Schema Discovery | Auto-runs |
| Phase 1: Descriptive Analytics | Auto-runs |
| **Phase 2: Human Checkpoint** | **PAUSES** — only stop point |
| Phase 3: Causal Inference | Auto-runs after confirmation |
| Phase 4: Prescriptive Optimization | Auto-runs |
| Phase 5: Monte Carlo Simulation | Auto-runs |
| Report Generation | Auto-runs, delivers full report |

After the user confirms at Phase 2, the agent executes Phases 3 → 4 → 5 → Report **without
stopping or asking "should I proceed?"** between them.

**Budget**: 300 seconds / 60,000 tokens — required because the continuous chain can involve
4+ sequential tool calls, plus retries on errors.

---

## Tool Reference

### 1. SCHEMA_DISCOVERY

**What it does**: Introspects INFORMATION_SCHEMA. Auto-detects domain. **Classifies columns
into IDs, Measures, and Dimensions.** Checks for semantic views.

```sql
CALL RCA_DEMO.RCA_TOOLS.SCHEMA_DISCOVERY('MY_DATABASE', 'MY_SCHEMA');
```

**Key output fields**:
- `IMPORTANT_column_classification.id_columns_NEVER_USE_AS_TREATMENT_OR_METRIC`
- `IMPORTANT_column_classification.measure_columns_USE_AS_METRICS_AND_TREATMENTS`
- `IMPORTANT_column_classification.dimension_columns_USE_FOR_SLICING_AND_CONFOUNDERS`

**Packages**: `snowflake-snowpark-python`, `pandas`

---

### 2. DESCRIPTIVE_ANALYTICS

**What it does**: Statistical verification engine. Auto-selects the right tests:

| Data Shape | Test Selected |
|------------|---------------|
| 2-group comparison | Welch t-test + Mann-Whitney U |
| >2 groups in dimension | ANOVA + Kruskal-Wallis H |
| Outlier detection | Z-score (threshold 2.5) |
| Trend detection | OLS slope on time series |

```sql
CALL RCA_DEMO.RCA_TOOLS.DESCRIPTIVE_ANALYTICS(
  'Why is revenue low?',                    -- QUERY_CONTEXT
  'SALES_DOLLAR_AMOUNT',                    -- METRIC_COLUMN (measure, NOT ID)
  'PHARMACY_TYPE,IS_REFILL',                -- DIMENSION_COLUMNS (text/boolean only)
  'DELIVERY_DATE',                          -- TIME_COLUMN
  'DB.SCHEMA.TABLE',                        -- TABLE_FQN
  '{"period_a":{"start":"2023-01-01","end":"2023-06-30"},"period_b":{"start":"2023-07-01","end":"2023-12-31"}}',
  NULL
);
```

**Packages**: `snowflake-snowpark-python`, `pandas`, `scipy`, `numpy`, `statsmodels`

---

### 3. CAUSAL_INFERENCE

**What it does**: Root cause identification.

- **OLS Regression**: Coefficients, p-values, confidence intervals, R-squared
- **IPW**: Average Treatment Effect controlling for confounders
- **Granger Causality**: Temporal lag detection
- **Attribution Ranking**: % contribution per factor

```sql
CALL RCA_DEMO.RCA_TOOLS.CAUSAL_INFERENCE(
  'SALES_DOLLAR_AMOUNT',                    -- OUTCOME (measure)
  'SALES_PRICE,SALES_CASES_SOLD',           -- TREATMENTS (measures only, NEVER IDs)
  'CUSTOMER_ID,SOURCE_PRODUCT_ID',          -- CONFOUNDERS (text dimensions)
  'DB.SCHEMA.SALES_F',
  'SALES_DATE',
  NULL
);
```

**Packages**: `snowflake-snowpark-python`, `pandas`, `scipy`, `numpy`, `statsmodels`, `scikit-learn`

---

### 4. PRESCRIPTIVE_OPTIMIZATION

**What it does**: PuLP linear programming. Auto-derives variable bounds from P5/P95.

```sql
CALL RCA_DEMO.RCA_TOOLS.PRESCRIPTIVE_OPTIMIZATION(
  '{"direction":"maximize","terms":[{"variable":"cases_sold","coefficient":95.85}]}',
  '[{"name":"cases_sold","column":"SALES_CASES_SOLD","use_historical_bounds":true}]',
  '[{"name":"capacity","terms":[{"variable":"cases_sold","coefficient":1}],"operator":"<=","rhs":100}]',
  'DB.SCHEMA.SALES_F',
  NULL
);
```

**Packages**: `snowflake-snowpark-python`, `pandas`, `numpy`, `scipy`, `pulp`

---

### 5. MONTE_CARLO_SIMULATION

**What it does**: 10,000 randomized simulations. Distributions: normal, uniform, triangular, lognormal, beta.

```sql
CALL RCA_DEMO.RCA_TOOLS.MONTE_CARLO_SIMULATION(
  '{"baseline_value":325,"expected_effect":400,"success_threshold":400}',
  '[{"name":"competitor","distribution":"normal","params":{"mean":-3,"std":5},"impact_coefficient":0.4}]',
  10000,
  'DB.SCHEMA.SALES_F',
  'SALES_DOLLAR_AMOUNT'
);
```

**Packages**: `snowflake-snowpark-python`, `pandas`, `numpy`, `scipy`

---

### 6. GENERATE_RCA_REPORT

**What it does**: Compiles all outputs into Executive Diagnostic & Strategy Report.

```sql
CALL RCA_DEMO.RCA_TOOLS.GENERATE_RCA_REPORT(
  'Why did sales drop?',
  '<descriptive_json>',
  '<causal_json>',
  '<optimization_json>',
  '<simulation_json>'
);
```

---

## Agent Specification (Key Design Decisions)

| Decision | Value | Why |
|----------|-------|-----|
| Spec format | YAML | `CREATE AGENT FROM SPECIFICATION` requires YAML, not JSON |
| tool_spec type | `generic` | For stored procedure tools with `input_schema` |
| tool_resources type | `procedure` | Procedures use `type: "procedure"`, UDFs use `type: "function"` |
| `input_schema` | Required | Every `generic` tool must declare its parameters |
| `EXECUTE AS CALLER` | Yes | Procedures need caller's permissions to read any schema |
| Model | `claude-4-sonnet` | Best reasoning for multi-step statistical workflows |
| Budget | 300s / 60K tokens | Continuous execution of 4+ tools after checkpoint |
| Column classification | ID / Measure / Dimension | Prevents meaningless ID columns from being used as causal factors |

---

## Tested Datasets

| Dataset | Domain | Query | Result |
|---------|--------|-------|--------|
| `CHECKEDUP_SI_POC_DB.DATASETS` | Healthcare | "Low revenue in RXFACT" | IDs excluded (PATIENT_ID, DRUG_ID). Measures used (PATIENT_PAY, QUANTITY). |
| `RNDC_LLM_DB.RNDC_LLM_DATA` | Retail/Beverage | "Low sales in H1 2023" | IDs excluded (HOUSE_ID, SALES_INVOICE_ID). Full report: SALES_CASES_SOLD=85.5% attribution. |
| `BEHEALTHY_DB.CLINIC_DATA` | Healthcare Clinics | "Low footfall after 2024" | IDs excluded (APPOINTMENT_ID, DOCTOR_ID). Used WAIT_TIME_MINUTES. Full pipeline. |

---

## Files in This Project

| File | Purpose |
|------|---------|
| `1. preq-script.sql` | Creates database, schema, stage |
| `2. schema-discovery.sql` | Schema Discovery procedure (with ID classification) |
| `3. descriptive-analytics.sql` | Descriptive Analytics procedure (auto-test selection) |
| `4. causal-inference.sql` | Causal Inference procedure (OLS, IPW, Granger) |
| `5. Prescriptive Optimization (PuLP).sql` | Optimization procedure (PuLP LP) |
| `6. Monte Carlo Simulation.sql` | Monte Carlo procedure (10K simulations) |
| `7. Report Generator.sql` | Report compilation procedure |
| `8. Cortex Agent.sql` | CREATE AGENT statement (YAML, 300s budget) |
| `9. clean-up.sql` | DROP statements for teardown |
| `rca_agent_config.yaml` | Complete configuration reference |
| `arch.mmd` | Mermaid architecture diagram |
| `.snowflake/cortex/skills/rca-prescriptive-agent/SKILL.md` | This file |

---

## Example Prompts (Any Domain)

| Domain | Prompt |
|--------|--------|
| Healthcare | "Patient footfall dropped in our pediatric wing. What happened and how do we fix it?" |
| Retail | "Why did our sales drop in the South region last quarter?" |
| FMCG | "Market share for our detergent brand fell 3 points. Diagnose and prescribe." |
| Logistics | "Why are our port delays increasing and what's the optimal intervention?" |
| Exports | "Export volumes to EU declined this quarter. Identify the shortcoming." |
| Marketing | "Our email campaign CTR dropped 40%. What caused it and how do we recover?" |
| Finance | "Loan default rates spiked in Q3. Root cause and mitigation strategy?" |
| Manufacturing | "Defect rate on Line 3 increased 15%. Why and what's the fix?" |

---

## Granting Access to Other Users

```sql
GRANT USAGE ON DATABASE RCA_DEMO TO ROLE <target_role>;
GRANT USAGE ON SCHEMA RCA_DEMO.RCA_TOOLS TO ROLE <target_role>;
GRANT USAGE ON AGENT RCA_DEMO.RCA_TOOLS.RCA_PRESCRIPTIVE_AGENT TO ROLE <target_role>;
GRANT USAGE ON WAREHOUSE <your_warehouse> TO ROLE <target_role>;
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Unknown user-defined function` | tool_resources uses `type: "function"` for a stored procedure | Change to `type: "procedure"` |
| Agent returns error about `custom_tool` | tool_spec uses `type: "custom_tool"` | Change to `type: "generic"` |
| Agent doesn't call tools | Missing `input_schema` on generic tools | Add `input_schema` with properties and required |
| JSON spec fails | `CREATE AGENT` requires YAML, not JSON | Convert spec to YAML format |
| Procedure can't read user's tables | `EXECUTE AS OWNER` | Change to `EXECUTE AS CALLER` |
| `pulp` package not found | Missing from PACKAGES clause | Add `'pulp'` to PACKAGES list |
| Agent uses CUSTOMER_ID as treatment variable | Schema discovery not classifying IDs | Update schema discovery with ID suffix/cardinality detection |
| Agent stops after every phase asking to proceed | Orchestration instructions don't specify continuous execution | Add "PHASE 3 THROUGH REPORT - CONTINUOUS EXECUTION" rule |
| Agent times out during continuous execution | Budget too low for 4+ sequential tool calls | Increase to `seconds: 300, tokens: 60000` |
| Agent proposes IDs as causal factors at checkpoint | System instructions missing column classification rules | Add CRITICAL COLUMN CLASSIFICATION RULES to system instructions |
