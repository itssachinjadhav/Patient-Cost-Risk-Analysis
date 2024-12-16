# 🏥 Patient Encounter Cost and Risk Analysis in Healthcare Systems

## 📊 Project Overview

This project focuses on identifying patients with frequent high-cost encounters, analyzing procedure costs, and evaluating financial risks due to payer coverage gaps. Leveraging SQL-based analysis and Power BI visualizations, the project aims to uncover insights to improve operational efficiency, patient care, and resource planning in healthcare organizations.

## 🔍 Problem Statement

Healthcare organizations face challenges in managing financial risks and costs due to:

1. Frequent High-Cost Encounters
2. Uncovered Costs by Payer Coverage
3. Trends in Procedure Costs and Diagnosis Correlations

The analysis uses SQL to identify patterns across 5 key tables:

* Encounters
* Patients
* Procedures
* Payers
* Organizations

## ⚙️ Tools & Technologies Used

* SQL: Data cleaning, querying, and analysis.
* Power BI: Interactive visualizations and dashboards.

## 🗂️ Dataset Description

* Encounters: Details of patient visits, cost, class, and duration.
* Patients: Demographic details of patients.
* Procedures: Information on procedures performed during encounters.
* Payers: Payer contributions and coverage gaps.
* Organizations: Geographical and organizational-level data.

## 🛠️ Data Preparation (Cleaning and Loading)
The data preparation phase involved creating tables, loading data from CSV files, and cleaning fields to ensure data consistency.
### 1. Database and Table Creation
* A new database named COST_AND_RISK_ENCOUNTER was created.
* Tables created:

  * **Encounters:** Stores patient encounter details including costs, codes, and descriptions.
  * **Organizations:** Contains information about healthcare organizations, locations, and addresses.
  * **Patients:** Includes patient demographics like gender, race, birthdate, and location.
  * **Procedures:** Captures information about medical procedures performed during encounters.
  * **Payers:** Contains details about payers and their coverage contributions.

**Example Table Schema** (for Encounters):
```sql
CREATE TABLE Encounters (
    ENCOUNTER_Id VARCHAR(MAX),
    START Datetime,
    STOP Datetime,
    PATIENT VARCHAR(MAX),
    ORGANIZATION VARCHAR(MAX),
    PAYER VARCHAR(MAX),
    ENCOUNTERCLASS VARCHAR(MAX),
    CODE VARCHAR(MAX),
    DESCRIPTION VARCHAR(MAX),
    BASE_ENCOUNTER_COST FLOAT,
    TOTAL_CLAIM_COST FLOAT,
    PAYER_COVERAGE FLOAT,
    REASONCODE FLOAT,
    REASONDESCRIPTION VARCHAR(MAX)
);
```

### 2. Data Loading
* Data was loaded into the tables using BULK INSERT from CSV files.
* Example:
```sql
BULK INSERT Encounters  
FROM 'C:\\Users\\getla\\OneDrive\\Desktop\\Dataset\\encounters.csv'  
WITH (Fieldterminator = ',', Rowterminator = '\\n', Firstrow = 2);
```
### 3. Data Cleaning
Cleaned the FIRST field in the Patients table to remove unnecessary characters:
```SQL
UPDATE Patients  
SET FIRST = REPLACE(REPLACE(FIRST, '0', ''), '"', '');
```


## 📈 Steps of Analysis

### 1.1 Evaluating Financial Risk by Encounter Outcome
* Objective: Identify ReasonCodes with the highest uncovered costs.
* Key Query:

```sql
WITH Encounter_Costs AS (
    SELECT 
        e.Encounter_Id,
        e.REASONCODE,
        e.DESCRIPTION AS EncounterDescription,
        e.TOTAL_CLAIM_COST,
        e.PAYER_COVERAGE,
        (CAST(e.TOTAL_CLAIM_COST AS DECIMAL(18,2)) - CAST(e.PAYER_COVERAGE AS DECIMAL(18,2))) AS UncoveredCost,
        e.ENCOUNTERCLASS AS EncounterOutcome,
		e.REASONDESCRIPTION,
        p.GENDER
    FROM 
        ENCOUNTERS e
    JOIN 
        PATIENTS p ON e.PATIENT = p.Id
),
Aggregated_Risk AS (
    SELECT 
        REASONCODE,
        EncounterOutcome,
		REASONDESCRIPTION,
        AVG(UncoveredCost) AS AvgUncoveredCost,
        SUM(UncoveredCost) AS TotalUncoveredCost,
        COUNT(Encounter_Id) AS TotalEncounters
    FROM 
        Encounter_Costs
    GROUP BY 
        REASONCODE, EncounterOutcome,REASONDESCRIPTION
)
SELECT 
    REASONCODE,
    EncounterOutcome,
    AvgUncoveredCost,
    TotalUncoveredCost,
    TotalEncounters,
	REASONDESCRIPTION  

FROM 
    Aggregated_Risk
ORDER BY 
    TotalUncoveredCost DESC;
```
### 1.2 Identifying Patients with Frequent High-Cost Encounters
* Objective: Find patients with >3 encounters per year with costs exceeding $10,000.
* Key Query:

```sql
WITH HighCostEncounters AS (
    SELECT 
        e.PATIENT,
        p.FIRST,
        p.LAST,
        p.GENDER,
        p.BIRTHDATE,
        YEAR(CAST(e.START AS DATE)) AS EncounterYear,
        COUNT(e.ENCOUNTER_Id) AS TotalEncounters,
        SUM(CAST(e.TOTAL_CLAIM_COST AS DECIMAL(18,2))) AS TotalClaimCost
    FROM 
        ENCOUNTERS e
    JOIN 
        PATIENTS p ON e.PATIENT = p.Id
    WHERE 
        CAST(e.TOTAL_CLAIM_COST AS DECIMAL(18,2)) > 10000
    GROUP BY 
        e.PATIENT, p.FIRST, p.LAST, p.GENDER, p.BIRTHDATE, YEAR(CAST(e.START AS DATE))
)
SELECT 
    PATIENT,
    FIRST,
    LAST,
    GENDER,
    BIRTHDATE,
    EncounterYear,
    TotalEncounters,
    TotalClaimCost
FROM 
    HighCostEncounters
WHERE 
    TotalEncounters > 3
ORDER BY 
    TotalEncounters DESC, TotalClaimCost DESC;
```

### 1.3 Identifying Risk Factors Based on Demographics
* Objective: Analyze frequent diagnosis codes and associated demographics.
* Key Query:

```sql

SELECT 
    ec.REASONCODE,
	ec.REASONDESCRIPTION,
    p.GENDER,
    p.RACE,
    p.ETHNICITY,
    AVG(ec.TOTAL_CLAIM_COST - ec.PAYER_COVERAGE) AS AvgUncoveredCost,
    SUM(ec.TOTAL_CLAIM_COST - ec.PAYER_COVERAGE) AS TotalUncoveredCost,
    COUNT(*) AS TotalEncounters
FROM 
    ENCOUNTERS ec
JOIN 
    PATIENTS p ON ec.PATIENT = p.Id
WHERE 
    ec.REASONCODE IN (
        SELECT TOP 3 REASONCODE
        FROM ENCOUNTERS
        WHERE REASONCODE IS NOT NULL
        GROUP BY REASONCODE
        ORDER BY COUNT(*) DESC
    )
GROUP BY 
    ec.REASONCODE, p.GENDER, p.RACE, p.ETHNICITY, ec.REASONDESCRIPTION
ORDER BY 
    TotalUncoveredCost DESC;
```
### 1.4 Assessing Payer Contributions
* Objective: Identify payer coverage gaps across procedure types.
* Key Query:

```sql
WITH Procedure_Costs AS (
    SELECT 
        p.CODE AS ProcedureCode,
        p.DESCRIPTION AS ProcedureDescription,
        e.PAYER,
        SUM(CAST(p.BASE_COST AS DECIMAL(18,2))) AS TotalBaseCost,
        SUM(CAST(e.TOTAL_CLAIM_COST AS DECIMAL(18,2))) AS TotalClaimCost,
        SUM(CAST(e.PAYER_COVERAGE AS DECIMAL(18,2))) AS TotalPayerCoverage,
        (SUM(CAST(e.TOTAL_CLAIM_COST AS DECIMAL(18,2))) - SUM(CAST(e.PAYER_COVERAGE AS DECIMAL(18,2)))) AS UncoveredCost
    FROM 
        Proceduree p
    JOIN 
        ENCOUNTERS e ON p.ENCOUNTER = e.ENCOUNTER_Id
    GROUP BY 
        p.CODE, p.DESCRIPTION, e.PAYER
)
SELECT	 
    ProcedureCode,
    ProcedureDescription,
    PAYER,
    TotalBaseCost,
    TotalClaimCost,
    TotalPayerCoverage,
    UncoveredCost
FROM 
    Procedure_Costs
ORDER BY 
    UncoveredCost DESC;
```
### 1.5 Analyzing Encounter Duration
* Objective: Identify encounters exceeding 24 hours per organization.
* Key Query:

```sql
WITH EncounterDurations AS (
    SELECT 
        e.ORGANIZATION,
        o.NAME AS OrganizationName,
        e.ENCOUNTERCLASS,
        e.ENCOUNTER_Id,
        e.START,
        e.STOP,
        DATEDIFF(HOUR, CAST(e.START AS DATETIME), CAST(e.STOP AS DATETIME)) AS DurationHours
    FROM 
        ENCOUNTERS e
    JOIN 
        ORGANIZATIONS o ON e.ORGANIZATION = o.ORGANIZATION_Id
    WHERE 
        e.START IS NOT NULL 
        AND e.STOP IS NOT NULL 
)
-- Calculating the average encounter duration per class and identify long encounters
SELECT 
    ORGANIZATION,
    OrganizationName,
    ENCOUNTERCLASS,
    AVG(DurationHours) AS AverageDurationHours,
    COUNT(CASE WHEN DurationHours > 24 THEN 1 END) AS EncountersExceeding24Hours
FROM 
    EncounterDurations
GROUP BY 
    ORGANIZATION, OrganizationName, ENCOUNTERCLASS
ORDER BY 
    AverageDurationHours DESC;
```
### 1.6 Identifying Patients with Multiple Procedures Across Encounters
* Objective: Patients who had multiple procedures across different encounters.
* Key Query:
```sql
WITH Patient_Procedure_Count AS (
    SELECT 
        p.PATIENT,
        p.REASONCODE,
        COUNT(DISTINCT p.ENCOUNTER) AS DistinctEncounters,
        COUNT(p.CODE) AS TotalProcedures,
        COUNT(DISTINCT p.CODE) AS DistinctProcedures
    FROM 
        Proceduree p
    WHERE 
        p.REASONCODE IS NOT NULL -- Only include rows where ReasonCode is available
    GROUP BY 
        p.PATIENT, p.REASONCODE
),
Filtered_Patients AS (
    SELECT 
        PATIENT,
        REASONCODE,
        DistinctEncounters,
        TotalProcedures,
        DistinctProcedures
    FROM 
        Patient_Procedure_Count
    WHERE 
        DistinctEncounters > 1 -- Ensure multiple encounters
)
SELECT 
    fp.PATIENT,
    fp.REASONCODE,
    fp.DistinctEncounters,
    fp.TotalProcedures,
    fp.DistinctProcedures,
    pt.FIRST,
    pt.LAST,
    pt.GENDER,
    pt.BIRTHDATE
FROM 
    Filtered_Patients fp
JOIN 
    PATIENTS pt ON fp.PATIENT = pt.Id
ORDER BY 
    fp.DistinctEncounters DESC, fp.TotalProcedures DESC;
```

  








  
