WITH pasakumu_parametri AS (
SELECT p.pasakuma_nosaukums, p.sakuma_laiks, t.ietilpigums,
	(SELECT count(*) FROM darbinieki_pasakumi dp WHERE dp.pasakuma_nosaukums = p.pasakuma_nosaukums AND dp.sakuma_laiks  = p.sakuma_laiks) as darbinieku_skaits,
	(SELECT count(*) FROM viesi_pasakumi vp WHERE vp.pasakuma_nosaukums = p.pasakuma_nosaukums AND vp.sakuma_laiks  = p.sakuma_laiks) as viesu_skaits
	-- telpas ietilpilgums
	FROM pasakumi p
	JOIN telpas t ON t.telpas_numurs = p.telpas_numurs 
) SELECT darbinieku_skaits, viesu_skaits, (darbinieku_skaits + viesu_skaits) dalibnieku_skaits, ietilpigums FROM pasakumu_parametri
	

SELECT 
SELECT dsb.darbinieka_id, dsb.registrets FROM darba_sakumi_beigas dsb
WHERE darbinieka_id in 
	(SELECT dl1.darbinieka_id FROM (SELECT dl.darbinieka_id, NULLIF(MAX(COALESCE(darba_beigas ,'9999-12-31')),'9999-12-31') maksimalas_darba_beigas FROM darba_ligumi dl
	WHERE dl.stavokla_kods = 1 OR dl.darba_sakums > '2023-06-06' GROUP BY dl.darbinieka_id) dl1)
-- 
--SELECT dsb.darbinieka_id, dsb.registrets FROM darba_sakumi_beigas dsb
--JOIN 