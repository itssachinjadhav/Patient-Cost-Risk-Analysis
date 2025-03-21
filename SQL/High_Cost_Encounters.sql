

 Objective:
--          Identify patients who had more than 3 encounters in a year where each encounter had a total claim cost above a certain threshold (e.g., $10,000). 
--			The query should return the patient details, number of encounters, and the total cost for those encounters.

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
