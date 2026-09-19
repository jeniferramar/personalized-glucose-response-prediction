# Personalized Glucose Response Prediction

## Project Overview
This healthcare data science project investigates why individuals can have
different glucose responses even when consuming meals with similar recorded
macronutrient composition.

The project combines CGM, nutrition, metabolic, activity, gut-health,
and microbiome data to analyze and predict personalized post-meal glucose response.

## Dataset
- 45 participants
- 687K+ CGM and wearable records
- 1,698 complete meal-response windows
- Normal, Prediabetes, and Type 2 Diabetes groups

## Technologies
- Python
- SQL / PostgreSQL
- Pandas
- NumPy
- scikit-learn
- Machine Learning
- Power BI
- Jupyter Notebook

## Data Science Methods
- Data cleaning and preprocessing
- Feature engineering
- Exploratory data analysis
- Mixed-effects modeling
- K-Means clustering
- Hierarchical clustering
- Random Forest regression
- GroupKFold cross-validation
- Permutation feature importance
- Model evaluation using R², MAE, and RMSE
- Matched-meal analysis

## Predictive Modeling

The project evaluated whether meal composition, individual metabolic
characteristics, and activity could predict post-meal glucose response.

### Peak Glucose Rise Prediction

- Meal Only: R² = 0.159
- Meal + Person: R² = 0.339
- Meal + Person + Activity: R² = 0.376

The best predictive performance came from combining meal composition,
individual metabolic characteristics, and activity.

## Key Predictors
The strongest predictors included:

- Fasting glucose
- Carbohydrates
- Meal type
- Baseline glucose
- Diabetes group

## Key Insight

Post-meal glucose response is personalized.

The response depends not only on:

**What a person eats**

but also on:

**The person's metabolic condition and activity.**

## Validation

To prevent data leakage, 5-fold GroupKFold cross-validation was performed
by participant.

This ensured that all meals from a participant were either in the training
set or the test set, allowing evaluation on completely unseen participants.

## Limitations

The study included only 45 participants.

Therefore, the predictive models should be considered exploratory
and are not clinically validated.

Gut and microbiome features were also evaluated but did not improve
prediction in this exploratory dataset.

## Dashboard

An interactive Power BI storyboard was developed to communicate:

- Metabolic progression
- Prediabetes continuum
- Meal-response differences
- Predictive model comparison
- Feature importance
- Matched-meal case study
