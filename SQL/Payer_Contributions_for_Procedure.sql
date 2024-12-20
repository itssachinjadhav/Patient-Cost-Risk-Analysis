Objective:
--        Analyze payer contributions for the base cost of procedures and identify any gaps between total claim cost and payer coverage.


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