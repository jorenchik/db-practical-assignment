-- 1. Atskaite par pasākumiem: dalībnieki kā darbinieku un viesi un palikušās vietas
SELECT pp.pasakuma_nosaukums,pp.sakuma_laiks, pp.darbinieku_skaits, viesu_skaits, ietilpigums, (darbinieku_skaits + viesu_skaits) dalibnieku_skaits, ietilpigums - (darbinieku_skaits + viesu_skaits) palikusas_vietas FROM (
	SELECT p.pasakuma_nosaukums, p.sakuma_laiks, t.ietilpigums,
		(SELECT count(*) FROM darbinieki_pasakumi dp WHERE dp.pasakuma_nosaukums = p.pasakuma_nosaukums AND dp.sakuma_laiks  = p.sakuma_laiks) as darbinieku_skaits,
		(SELECT count(*) FROM viesi_pasakumi vp WHERE vp.pasakuma_nosaukums = p.pasakuma_nosaukums AND vp.sakuma_laiks  = p.sakuma_laiks) as viesu_skaits
	FROM pasakumi p
	JOIN telpas t ON t.telpas_numurs = p.telpas_numurs
) pp 

-- 2. Atsakaite par nostrādātām stundām katrā dienā noteikā periodā
SELECT dsb2.darbinieka_id, datepart(dd, dsb2.registrets) menesa_diena, max(kumul_nostradats_diena) nostradats, max(kumul_partraukums_diena) partaukums FROM 
(
	SELECT darbinieka_id, registrets,
		sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods not in (1,3) OR dsbi.veida_kods not in (2,4,5,6) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_nostradats_diena,
		sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods != 4 OR dsbi.veida_kods not in (2,3) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_partraukums_diena
	FROM (SELECT dsb.darbinieka_id, dsb.registrets, dsb.veida_kods, LAG(dsb.registrets) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_registrets, LAG(veida_kods) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_veida_kods FROM darba_sakumi_beigas dsb) dsbi
) dsb2
WHERE registrets >= '2023-06-01 00:00:00' AND registrets < '2023-07-01 00:00:00'
GROUP BY dsb2.darbinieka_id, datepart(dd, dsb2.registrets) 

-- 3. Atskaite (aktīvo) ar aprēķinātām darbinieku algām laika periodā un kontaktinformāciju

DECLARE @PERIODA_SAKUMS datetime;
SET @PERIODA_SAKUMS = '2023-06-01 00:00:00';
DECLARE @PERIODA_BEIGAS datetime;
SET @PERIODA_BEIGAS = '2023-06-30 00:00:00';

WITH dl3 AS (SELECT dl1.darbinieka_id, (SELECT TOP 1 stundas_likme FROM (SELECT dl2.darbinieka_id, dl2.stundas_likme FROM darba_ligumi dl2 WHERE dl2.darba_sakums <= @PERIODA_SAKUMS AND dl2.darba_beigas >= @PERIODA_BEIGAS AND dl2.stavokla_kods = 1 AND dl2.darbinieka_id = dl1.darbinieka_id) dl) stundas_likme FROM darba_ligumi dl1)
SELECT dsb3.darbinieka_id, sum(dsb3.nostradats) nostradats_laika_perioda, sum(dsb3.nostradats) * dl3.stundas_likme alga FROM (
SELECT dsb2.darbinieka_id, datepart(dd, dsb2.registrets) menesa_diena, max(kumul_nostradats_diena) nostradats FROM 
	(
		SELECT darbinieka_id, registrets,
			sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods not in (1,3) OR dsbi.veida_kods not in (2,4,5,6) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_nostradats_diena
		FROM (SELECT dsb.darbinieka_id, dsb.registrets, dsb.veida_kods, LAG(dsb.registrets) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_registrets, LAG(veida_kods) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_veida_kods FROM darba_sakumi_beigas dsb) dsbi
	) dsb2
	WHERE registrets >= @PERIODA_SAKUMS AND registrets <= @PERIODA_BEIGAS
	GROUP BY dsb2.darbinieka_id, datepart(dd, dsb2.registrets)
) dsb3
JOIN dl3 ON dl3.darbinieka_id = dsb3.darbinieka_id
GROUP BY dsb3.darbinieka_id, dl3.stundas_likme HAVING dl3.stundas_likme is NOT NULL;

-- 4. Atskaite par telpām: vidējā atzīme, atsauksmju daudzums, ienesīgums, darbinieku izmantošanas daudzums
--- TODO?: add worst review and best review
SELECT t.telpas_numurs, sum(r.summa_bez_pvn * 1.00) ienesigums, cast(avg(ta.vertejums * 1.00) as numeric(36,2)) videja_atzime, RANK() OVER (ORDER BY cast(avg(ta.vertejums * 1.00) as numeric(36,2)) DESC) , min(ta.vertejums) zemaka_atzime, max(ta.vertejums) augstaka_atzime FROM telpas t
	JOIN telpas_ires_pieteikumi tip ON tip.telpas_numurs = t.telpas_numurs
	JOIN rekini r ON r.telpas_ires_pieteikuma_numurs = tip.telpas_ires_pieteikuma_numurs 
	LEFT JOIN telpu_atsauksmes ta ON ta.telpas_ires_pieteikuma_numurs = tip.telpas_ires_pieteikuma_numurs 
	WHERE r.stavokla_kods in (2, 6)
	GROUP BY t.telpas_numurs;

-- 5. Atskaite par noteiktā darbinieka iepriekšējo, nākamo, un aiznākamo vizīti: viesa kontakti, vizītes mērķis

DECLARE @DARBINIEKA_ID datetime;
SET @DARBINIEKA_ID=1031;

WITH vp1 AS (
SELECT vp.darbinieka_id, v.vards, v.uzvards, v.epasts, v.telefona_numurs, vp.sakuma_laiks, vps.stavokla_kods , vps.stavoklis  FROM vizites_pieteikumi vp
JOIN viesi v ON vp.viesa_id = v.viesa_id
JOIN vizites_pieteikuma_stavokli vps ON vps.stavokla_kods = vp.stavokla_kods 
WHERE vp.stavokla_kods in (2,4,7)
)
SELECT * FROM (SELECT TOP 1 * FROM vp1 WHERE vp1.darbinieka_id = @DARBINIEKA_ID AND vp1.stavokla_kods = 7 ORDER BY vp1.sakuma_laiks DESC
 UNION SELECT TOP 2 * FROM vp1 WHERE vp1.darbinieka_id = @DARBINIEKA_ID AND vp1.stavokla_kods in (2,4) ORDER BY vp1.sakuma_laiks ASC) vp3

-- 6. Atskaite par darbiniekiem (izmantojot darba līgumus par pamatu), kas bija darbā noteiktā periodā: kurā telpā tie strādāja
 
 -- ENded it here
DECLARE @PERIODA_SAKUMS datetime;
SET @PERIODA_SAKUMS = '2023-06-07 00:00:00';
DECLARE @PERIODA_BEIGAS datetime;
SET @PERIODA_BEIGAS = '2023-06-08 00:00:00';

SELECT
(SELECT *, rank() OVER(PATRITION BY darbinieka_id, DATEPA) FROM darba_sakumi_beigas dsb
WHERE dsb.registrets > @PERIODA_SAKUMS AND @PERIODA_BEIGAS > dsb.registrets
)
 
 
-- 7. Atskaite par dienas ienesīgumu, ienesīgako telpu nedēļā (no rēķiniem).

SELECT  DATEPART(DAY, m.izpildijuma_laiks), DATEPART(DAY, m.izpildijuma_laiks), sum(summa) FROM maksajumi m
JOIN rekini r ON r.rekina_numurs = m.rekina_numurs
JOIN telpas_ires_pieteikumi tip ON tip.telpas_ires_pieteikuma_numurs = r.telpas_ires_pieteikuma_numurs
JOIN telpas t ON t.telpas_numurs = tip.telpas_numurs 
GROUP BY DATEPART(DAY, m.izpildijuma_laiks), DATEPART(DAY, m.izpildijuma_laiks)

-- 8. Atskaite par pieejamām (izmantošanai) telpām, kas ir darbiniekam atbilstošajā nodaļā (no darba līgumiem) 

 -- Palīgpieprasījums, lai iegūtu nodaļu nosaukumu
SELECT nodalas_nosaukums FROM nodalas n;
 
DECLARE @NODALA nvarchar(50) = 'Datorikas nodaļa';
DECLARE @PERIODA_SAKUMS datetime = '2023-06-04 00:00:00';
DECLARE @PERIODA_BEIGAS datetime = '2023-06-06 20:19:00';

SELECT t3.telpas_numurs, t3.prezentesanas_iespeja, ietilpigums, darba_vietu_skaits FROM
(SELECT t2.* FROM telpas t2
	WHERE t2.darbinieku_izmantosanas_iespeja = 1
	EXCEPT SELECT t.*  FROM telpas t
		JOIN telpas_izmantosanas_pieteikumi tip ON t.telpas_numurs = tip.telpas_numurs
		WHERE t.nodalas_nosaukums = @NODALA 
			AND NOT (tip.beigu_laiks < @PERIODA_SAKUMS OR @PERIODA_BEIGAS < tip.sakuma_laiks)) t3

-- 9. Atskaite par darbiniekiem, kuriem pašlaik ir aktīvi darba līgumi

-- 10. Atskaite par nodaļu izmaksām (darbinieku algām)
	
			
-- 11. Atskaite no maksājumiem, kas neizdevās (veidojot jaunos rēķinus)

|-------------|---------|
--|1|Sanemts|
--|2|Parskaitits|
--|3|Izzinots|
--|4|Noraidits|
--|5|Atcelts|
--|6|Samaksats|
--|7|Nepabeigts|
--|8|Kavets|

--SELECT * FROM rekini r
--JOIN maksajumi m ON m.rekina_numurs = r.rekina_numurs 
--WHERE
--			
--SELECT *, ms.stavoklis  FROM maksajumi m 
--JOIN maksajuma_stavokli ms ON ms.stavokla_kods = m.stavokla_kods 
--
--SELECT * FROM maksajuma_stavokli ms 
--			