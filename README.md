A Multi-Tool Analysis of India's Mobile Market
📖 Business Case & Data Story

In the hyper-competitive Indian mobile market, brands often default to aggressive discounting to capture market share. This project investigates a critical question: Does deep discounting improve long-term standing, or does it permanently damage brand perception?

By analyzing 3,000+ Flipkart records, I combined Data Engineering (SQL) with Econometric Modeling (Python/R) to show that high discounts correlate with a significant drop in customer satisfaction, suggesting a "race to the bottom" Nash Equilibrium.
🛠️ Technical Stack

    SQL (SQLite): ETL Pipeline, Window Functions, CASE Logic.

    Python: A/B Testing (SciPy), OLS Regression (Statsmodels), Data Wrangling (Pandas).

    R: Game Theory Modeling, Strategy Visualization (ggplot2).

    Tableau: Executive Dashboard & Strategic Storytelling.

⚙️ Analytical Flow & Implementation
1. Data Engineering & Transformation (SQL)

    Cleaning: Standardized inconsistent brand names and handled NULL values in rating and selling_price to ensure statistical reliability.

    Feature Engineering: Created discount_percentage metrics and segmented the market into Premium, Mid-Range, and Budget tiers using CASE WHEN logic.

    Transformation: Utilized Window Functions (RANK(), OVER(PARTITION BY)) to analyze discount depth within specific price brackets to identify market outliers.

2. Statistical Inference & Research (Python)

    A/B Testing: Partitioned data into "Aggressive" (>40% discount) and "Conservative" groups to test the "Price-Quality Schema."

    Hypothesis Testing: Conducted Independent T-Tests identifying a statistically significant rating drop (p=0.014) for highly discounted products.

    Correlation Analysis: Used OLS Regression to prove that hardware specifications—not price—are the true drivers of long-term satisfaction (R2 analysis).

3. Strategic Modeling (R)

    Market Interaction: Modeled a 2×2 Payoff Matrix between market leaders (e.g., Samsung vs. Xiaomi).

    Game Theory: Identified the Nash Equilibrium proving that despite the negative impact on brand perception, brands are mathematically "forced" to discount to avoid losing immediate market share.

💡 Key Insights

    The Discount Paradox: Aggressive discounting acts as a signal of lower quality to consumers, leading to a measurable decline in average ratings.

    Strategic Shift: The data suggests brands should pivot from price-based competition to feature-based differentiation, as consumers value hardware specs over temporary price cuts.

🎓 Technical Concepts Mastered

    Full-Cycle ETL: Transforming raw, messy scraped data into structured, analysis-ready tables.

    Inference Testing: Applying p-values and confidence intervals to validate business assumptions.

    Econometric Strategy: Bridging the gap between Nash Equilibrium and practical Data Science.

    Data Storytelling: Translating technical coefficients (Regression/T-tests) into a visual Tableau narrative.

📂 Repository Structure

    sql/ - Scripts for ETL, Cleaning, and Segmentation.

    notebooks/ - Python scripts for A/B testing and Regression.

    scripts/ - R code for Game Theory and strategy maps.

    visuals/ - Dashboard screenshots and charts.

    reports/ - Final Executive Summary (PDF).
