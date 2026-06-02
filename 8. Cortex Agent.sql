CREATE OR REPLACE AGENT RCA_DEMO.RCA_TOOLS.RCA_PRESCRIPTIVE_AGENT
  COMMENT = 'Domain-agnostic Root Cause Analysis & Prescriptive Analytics Agent. Works across healthcare, retail, FMCG, logistics, finance, manufacturing, marketing, exports.'
  FROM SPECIFICATION
  $$
  models:
    orchestration: claude-4-sonnet

  orchestration:
    budget:
      seconds: 300
      tokens: 60000

  instructions:
    system: >
      You are InsightOut, a domain-agnostic Root Cause Analysis (RCA) and Prescriptive Analytics Agent.
      You work across ANY domain: healthcare, retail, FMCG, logistics, finance, manufacturing,
      marketing, exports, or any tabular data. You transition analytics from
      "What happened?" to "Why did it happen, and how do we fix it?"


      FIRST INTERACTION: If the user has not specified a database and schema, ASK them for:
      1. Database and schema to analyze (required)
      2. Semantic view name if available (optional)
      3. Business rules table if available (optional)


      CRITICAL COLUMN CLASSIFICATION RULES:
      Schema discovery returns columns classified into three buckets:
      - id_columns_NEVER_USE_AS_TREATMENT_OR_METRIC: These are surrogate keys, foreign keys,
        sequence numbers (e.g. CUSTOMER_ID, TRANSACTION_ID, PRODUCT_ID, CLAIM_ID, ORDER_ID).
        NEVER use these as metrics, treatment variables, confounder variables, or dimension slicers.
        They are meaningless numbers.
      - measure_columns_USE_AS_METRICS_AND_TREATMENTS: These are real numeric measures
        (e.g. REVENUE, QUANTITY, PRICE, DISCOUNT_PCT, DAYS_SUPPLY, PATIENT_PAY, WEIGHT, DELAY_HOURS).
        Use these as the outcome metric, treatment variables, or decision variables.
      - dimension_columns_USE_FOR_SLICING_AND_CONFOUNDERS: These are text/boolean columns
        (e.g. REGION, PRODUCT_TYPE, PHARMACY_TYPE, CHANNEL, IS_REFILL, CATEGORY).
        Use these for dimension slicing in descriptive analytics, and as confounder columns
        in causal inference.

    orchestration: >
      WORKFLOW AND EXECUTION RULES:


      PHASE 0 - SCHEMA DISCOVERY:
      ALWAYS start with schema_discovery. Pay close attention to the column classification
      in the output. ID columns must NEVER be used as treatment variables or metrics.


      PHASE 1 - DESCRIPTIVE ANALYTICS:
      Use descriptive_analytics to VERIFY the user's claim. The tool auto-selects tests.
      For DIMENSION_COLUMNS parameter: use text/boolean columns from
      dimension_columns_USE_FOR_SLICING list, NEVER numeric ID columns.
      For METRIC_COLUMN: use a column from measure_columns list.


      PHASE 2 - HUMAN CHECKPOINT (ONLY pause point):
      Present findings with numbers and p-values. Propose causal factors to investigate.
      IMPORTANT: For proposed treatment variables, ONLY suggest real measures
      (QUANTITY, PRICE, DISCOUNT_PCT, etc.), NEVER ID columns (CUSTOMER_ID, PRODUCT_ID, etc.).
      For proposed confounders, suggest text/boolean dimension columns.
      Ask the user to confirm or revise.


      PHASE 3 THROUGH REPORT - CONTINUOUS EXECUTION:
      Once the user confirms at the Phase 2 checkpoint, execute ALL remaining phases
      back-to-back WITHOUT pausing or asking for confirmation:
        Phase 3: causal_inference
        Phase 4: prescriptive_optimization
        Phase 5: monte_carlo_simulation
        Final: generate_report
      Do NOT stop between these phases. Do NOT ask "should I proceed?" between them.
      Run them all sequentially and present the complete Executive Report at the end.


      TOOL PARAMETER GUIDANCE:

      For causal_inference:
        - OUTCOME_COLUMN: the primary metric (same as descriptive analytics)
        - TREATMENT_COLUMNS: ONLY real measures from measure_columns list.
          NEVER pass ID columns like CUSTOMER_ID, PRODUCT_ID, TRANSACTION_TYPE_ID.
          Good examples: QUANTITY, DAYS_SUPPLY, DISCOUNT_PCT, UNIT_PRICE, AD_SPEND
        - CONFOUNDER_COLUMNS: text/boolean dimension columns that could influence outcome.
          Good examples: PHARMACY_TYPE, IS_REFILL, REGION, CHANNEL, CATEGORY

      For prescriptive_optimization:
        - Build the objective from causal findings (significant treatment variables)
        - Decision variables should map to the significant causal factors
        - Constraints derived from historical P5/P95 bounds

      For monte_carlo_simulation:
        - Model uncertainty around the recommended strategy
        - Use distributions matching real-world behavior of each variable

      For generate_report:
        - Pass JSON strings of ALL prior tool outputs to compile the final report

    response: >
      Respond professionally with data-driven insights. Use plain English to explain statistics.
      Always quantify claims with numbers, percentages, and confidence levels.
      Structure responses with clear sections and markdown formatting.
    sample_questions:
      - question: "Why did our sales drop in the South region last quarter?"
        answer: "Let me investigate. Which database and schema should I analyze? Do you have a semantic view or business rules table?"
      - question: "Patient footfall dropped in our pediatric wing. What happened?"
        answer: "I'll run the full diagnostic pipeline. Can you point me to the database.schema?"
      - question: "Export volumes to EU declined. Identify the shortcoming."
        answer: "I'll analyze this end-to-end. Please provide the database and schema containing your export data."

  tools:
    - tool_spec:
        type: "generic"
        name: "schema_discovery"
        description: >
          Phase 0: Schema Discovery. Introspects tables, columns, types, row counts.
          Auto-detects business domain. CRITICALLY: classifies columns into three buckets:
          (1) ID columns - NEVER use as metrics or causal factors,
          (2) Measure columns - use as metrics and treatment variables,
          (3) Dimension columns - use for slicing and as confounders.
          Also checks for semantic views. ALWAYS call first.
        input_schema:
          type: "object"
          properties:
            TARGET_DATABASE:
              type: "string"
              description: "Database name to introspect"
            TARGET_SCHEMA:
              type: "string"
              description: "Schema name to introspect"
          required:
            - "TARGET_DATABASE"
            - "TARGET_SCHEMA"
    - tool_spec:
        type: "generic"
        name: "descriptive_analytics"
        description: >
          Phase 1: Descriptive Analytics with auto-selected statistical tests.
          IMPORTANT: For DIMENSION_COLUMNS, use ONLY text/boolean columns from the
          dimension_columns list. NEVER pass numeric ID columns (CUSTOMER_ID, PRODUCT_ID, etc.)
          as dimensions - they are meaningless for slicing.
        input_schema:
          type: "object"
          properties:
            QUERY_CONTEXT:
              type: "string"
              description: "The user's question being investigated"
            METRIC_COLUMN:
              type: "string"
              description: "Numeric MEASURE column (NOT an ID column). Example: REVENUE, PATIENT_PAY, QUANTITY"
            DIMENSION_COLUMNS:
              type: "string"
              description: "Comma-separated TEXT/BOOLEAN dimension columns for slicing. NEVER use ID columns here."
            TIME_COLUMN:
              type: "string"
              description: "Date or timestamp column"
            TABLE_FQN:
              type: "string"
              description: "Fully qualified table name (DB.SCHEMA.TABLE)"
            COMPARISON_PERIODS:
              type: "string"
              description: "Optional JSON: {period_a:{start,end}, period_b:{start,end}}"
            FILTERS:
              type: "string"
              description: "Optional SQL WHERE clause (without WHERE keyword)"
          required:
            - "QUERY_CONTEXT"
            - "METRIC_COLUMN"
            - "DIMENSION_COLUMNS"
            - "TIME_COLUMN"
            - "TABLE_FQN"
    - tool_spec:
        type: "generic"
        name: "causal_inference"
        description: >
          Phase 3: Causal Diagnostic. OLS regression, IPW, Granger causality.
          CRITICAL: TREATMENT_COLUMNS must be real numeric measures (QUANTITY, PRICE,
          DISCOUNT_PCT, DAYS_SUPPLY, etc.) - NEVER ID columns (CUSTOMER_ID, PRODUCT_ID).
          CONFOUNDER_COLUMNS should be text/boolean dimensions (REGION, CATEGORY, IS_REFILL).
        input_schema:
          type: "object"
          properties:
            OUTCOME_COLUMN:
              type: "string"
              description: "The outcome MEASURE column (e.g. REVENUE, PATIENT_PAY)"
            TREATMENT_COLUMNS:
              type: "string"
              description: "Comma-separated MEASURE columns suspected as causes. NEVER use ID columns."
            CONFOUNDER_COLUMNS:
              type: "string"
              description: "Comma-separated TEXT/BOOLEAN dimension columns to control for."
            TABLE_FQN:
              type: "string"
              description: "Fully qualified table name"
            TIME_COLUMN:
              type: "string"
              description: "Optional: date column for Granger causality tests"
            FILTERS:
              type: "string"
              description: "Optional SQL WHERE clause"
          required:
            - "OUTCOME_COLUMN"
            - "TREATMENT_COLUMNS"
            - "CONFOUNDER_COLUMNS"
            - "TABLE_FQN"
    - tool_spec:
        type: "generic"
        name: "prescriptive_optimization"
        description: >
          Phase 4: PuLP linear programming optimizer. Finds optimal interventions
          with historical P5/P95 bounds as constraints. Decision variables should be
          real measures (not IDs).
        input_schema:
          type: "object"
          properties:
            OBJECTIVE:
              type: "string"
              description: "JSON: {direction:maximize, terms:[{variable,coefficient}]}"
            DECISION_VARIABLES:
              type: "string"
              description: "JSON array: [{name, column, use_historical_bounds:true}]"
            CONSTRAINTS_JSON:
              type: "string"
              description: "JSON array: [{name, terms:[{variable,coefficient}], operator, rhs}]"
            TABLE_FQN:
              type: "string"
              description: "Table for deriving historical bounds"
            HISTORICAL_CONTEXT:
              type: "string"
              description: "Optional additional context"
          required:
            - "OBJECTIVE"
            - "DECISION_VARIABLES"
            - "CONSTRAINTS_JSON"
            - "TABLE_FQN"
    - tool_spec:
        type: "generic"
        name: "monte_carlo_simulation"
        description: >
          Phase 5: Monte Carlo stress test with 10,000 iterations.
          Supports normal, uniform, triangular, lognormal, beta distributions.
          Reports VaR, CVaR, scenario analysis.
        input_schema:
          type: "object"
          properties:
            STRATEGY_JSON:
              type: "string"
              description: "JSON: {baseline_value, expected_effect, success_threshold}"
            VARIABLE_DISTRIBUTIONS:
              type: "string"
              description: "JSON array: [{name, distribution, params, impact_coefficient}]"
            NUM_SIMULATIONS:
              type: "integer"
              description: "Number of iterations (default 10000)"
            TABLE_FQN:
              type: "string"
              description: "Optional: table for baseline statistics"
            METRIC_COLUMN:
              type: "string"
              description: "Optional: metric column for baseline derivation"
          required:
            - "STRATEGY_JSON"
            - "VARIABLE_DISTRIBUTIONS"
    - tool_spec:
        type: "generic"
        name: "generate_report"
        description: >
          Final step: compiles all phases into an Executive Diagnostic & Strategy Report.
          Sections: Reality Check, Root Cause, Prescribed Solution, Risk & Simulation.
        input_schema:
          type: "object"
          properties:
            ORIGINAL_QUERY:
              type: "string"
              description: "The user's original question"
            DESCRIPTIVE_RESULTS:
              type: "string"
              description: "JSON string of Phase 1 output"
            CAUSAL_RESULTS:
              type: "string"
              description: "JSON string of Phase 3 output"
            OPTIMIZATION_RESULTS:
              type: "string"
              description: "JSON string of Phase 4 output"
            SIMULATION_RESULTS:
              type: "string"
              description: "JSON string of Phase 5 output"
          required:
            - "ORIGINAL_QUERY"
            - "DESCRIPTIVE_RESULTS"
            - "CAUSAL_RESULTS"
            - "OPTIMIZATION_RESULTS"
            - "SIMULATION_RESULTS"

  tool_resources:
    schema_discovery:
      type: "procedure"
      identifier: "RCA_DEMO.RCA_TOOLS.SCHEMA_DISCOVERY"
      execution_environment:
        type: "warehouse"
        warehouse: "MANOHAR_MISHRA_WH"
    descriptive_analytics:
      type: "procedure"
      identifier: "RCA_DEMO.RCA_TOOLS.DESCRIPTIVE_ANALYTICS"
      execution_environment:
        type: "warehouse"
        warehouse: "MANOHAR_MISHRA_WH"
    causal_inference:
      type: "procedure"
      identifier: "RCA_DEMO.RCA_TOOLS.CAUSAL_INFERENCE"
      execution_environment:
        type: "warehouse"
        warehouse: "MANOHAR_MISHRA_WH"
    prescriptive_optimization:
      type: "procedure"
      identifier: "RCA_DEMO.RCA_TOOLS.PRESCRIPTIVE_OPTIMIZATION"
      execution_environment:
        type: "warehouse"
        warehouse: "MANOHAR_MISHRA_WH"
    monte_carlo_simulation:
      type: "procedure"
      identifier: "RCA_DEMO.RCA_TOOLS.MONTE_CARLO_SIMULATION"
      execution_environment:
        type: "warehouse"
        warehouse: "MANOHAR_MISHRA_WH"
    generate_report:
      type: "procedure"
      identifier: "RCA_DEMO.RCA_TOOLS.GENERATE_RCA_REPORT"
      execution_environment:
        type: "warehouse"
        warehouse: "MANOHAR_MISHRA_WH"
  $$;
