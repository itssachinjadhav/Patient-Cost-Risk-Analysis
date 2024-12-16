
Objective:
--         Determine which ReasonCodes lead to the highest financial risk based on the total uncovered cost (difference between total claim cost and payer coverage). 
--         Analyze this by combining patient demographics and encounter outcomes.


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
