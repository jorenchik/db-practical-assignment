-- 1. Atskaite par pasākumiem, kas satur datus, kā dalībnieki kā darbinieku un viesi un palikušās vietas
SELECT pp.pasakuma_nosaukums,pp.sakuma_laiks, pp.darbinieku_skaits, viesu_skaits, ietilpigums, (darbinieku_skaits + viesu_skaits) dalibnieku_skaits, ietilpigums - (darbinieku_skaits + viesu_skaits) palikusas_vietas FROM (
	SELECT p.pasakuma_nosaukums, p.sakuma_laiks, t.ietilpigums,
		(SELECT count(*) FROM darbinieki_pasakumi dp WHERE dp.pasakuma_nosaukums = p.pasakuma_nosaukums AND dp.sakuma_laiks  = p.sakuma_laiks) as darbinieku_skaits,
		(SELECT count(*) FROM viesi_pasakumi vp WHERE vp.pasakuma_nosaukums = p.pasakuma_nosaukums AND vp.sakuma_laiks  = p.sakuma_laiks) as viesu_skaits
		FROM pasakumi p
		JOIN telpas t ON t.telpas_numurs = p.telpas_numurs
) pp;

-- 2. Atsakaite par nostrādātām un pārtraukumu stundām katrā dienā katram darbiniekam noteikā periodā
DECLARE @PERIODA_SAKUMS1 datetime = '2023-06-01 00:00:00', @PERIODA_BEIGAS1 datetime = '2023-06-30 00:00:00';
SELECT dsb2.darbinieka_id, datepart(yy, dsb2.registrets) gads, datepart(mm, dsb2.registrets) menesis, datepart(dd, dsb2.registrets) menesa_diena, max(kumul_nostradats_diena) nostradats_stundas, max(kumul_partraukums_diena) partaukumi_stundas
	FROM (
		SELECT darbinieka_id, registrets,
			sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods not in (1,3) OR dsbi.veida_kods not in (2,4,5,6) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_nostradats_diena,
			sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods != 4 OR dsbi.veida_kods not in (2,3) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_partraukums_diena
		FROM (SELECT dsb.darbinieka_id, dsb.registrets, dsb.veida_kods, LAG(dsb.registrets) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_registrets, LAG(veida_kods) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_veida_kods FROM darba_sakumi_beigas dsb) dsbi
) dsb2
	WHERE registrets >= @PERIODA_SAKUMS1 AND registrets < @PERIODA_BEIGAS1
	GROUP BY dsb2.darbinieka_id, datepart(yy, dsb2.registrets), datepart(mm, dsb2.registrets), datepart(dd, dsb2.registrets);

-- 3. Atskaite ar aprēķinātām (aktīvo) darbinieku algām laika periodā un kontaktinformāciju
DECLARE @PERIODA_SAKUMS2 datetime = '2023-06-01 00:00:00', @PERIODA_BEIGAS2 datetime = '2023-06-30 00:00:00';
-- Palīgpieprasījums, lai atrastu aktīvo darbinieku stundas likmes
WITH dl3 AS (
	SELECT dl1.darbinieka_id,
		-- Parasti tādam ierakstam jābūt vienam, bet to nevar garantēt
		(SELECT TOP 1 stundas_likme FROM (
			SELECT dl2.darbinieka_id, dl2.stundas_likme
			FROM darba_ligumi dl2
			-- Darba līguma ieraksta laika intervāls pilnībā atrodas norādītajā laika periodā
			WHERE dl2.darba_sakums <= @PERIODA_SAKUMS2 AND dl2.darba_beigas >= @PERIODA_BEIGAS2
			AND dl2.stavokla_kods = 1 AND dl2.darbinieka_id = dl1.darbinieka_id
		) dl
	) stundas_likme FROM darba_ligumi dl1)
SELECT dsb3.darbinieka_id, sum(dsb3.nostradats) nostradats_laika_perioda, sum(dsb3.nostradats) * dl3.stundas_likme alga FROM (
	SELECT dsb2.darbinieka_id, datepart(dd, dsb2.registrets) menesa_diena, max(kumul_nostradats_diena) nostradats 
		FROM (
			SELECT darbinieka_id, registrets,
				sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods not in (1,3) OR dsbi.veida_kods not in (2,4,5,6) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_nostradats_diena
				FROM (SELECT dsb.darbinieka_id, dsb.registrets, dsb.veida_kods, LAG(dsb.registrets) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_registrets, LAG(veida_kods) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_veida_kods FROM darba_sakumi_beigas dsb) dsbi
		) dsb2
		WHERE registrets >= @PERIODA_SAKUMS2 AND registrets <= @PERIODA_BEIGAS2
		GROUP BY dsb2.darbinieka_id, datepart(dd, dsb2.registrets)
) dsb3
	JOIN dl3 ON dl3.darbinieka_id = dsb3.darbinieka_id
	GROUP BY dsb3.darbinieka_id, dl3.stundas_likme HAVING dl3.stundas_likme is NOT NULL;

-- 4. Atskaite par telpām, kas satur informāciju, kā ienesīgums, vidējā atzīme, rangs, atsauksmju daudzums, zemākā un augstākā atzīme
SELECT t.telpas_numurs, sum(r.summa_bez_pvn * 1.00) ienesigums,
	cast(avg(ta.vertejums * 1.00) as numeric(36,2)) videja_atzime, RANK() OVER (ORDER BY cast(avg(ta.vertejums * 1.00) as numeric(36,2)) DESC) rangs,
	COUNT(*) atsauksmju_skaits,
	min(ta.vertejums) zemaka_atzime, max(ta.vertejums) augstaka_atzime
	FROM telpas t
	JOIN telpas_ires_pieteikumi tip ON tip.telpas_numurs = t.telpas_numurs
	JOIN rekini r ON r.telpas_ires_pieteikuma_numurs = tip.telpas_ires_pieteikuma_numurs 
	LEFT JOIN telpu_atsauksmes ta ON ta.telpas_ires_pieteikuma_numurs = tip.telpas_ires_pieteikuma_numurs 
	-- Apstiprināts vai pabeigts
	WHERE tip.stavokla_kods in (2, 7)
	GROUP BY t.telpas_numurs;

-- 5. Atskaite par noteiktā darbinieka iepriekšējo, nākamo (tekošo sarakstā), un aiznākamo vizīti ar viesa kontaktiem
DECLARE @DARBINIEKA_ID datetime = 1010;
WITH vp1 AS (
	SELECT vp.darbinieka_id, v.vards, v.uzvards, v.epasts, v.telefona_numurs, vp.sakuma_laiks, vps.stavokla_kods , vps.stavoklis  FROM vizites_pieteikumi vp
		JOIN viesi v ON vp.viesa_id = v.viesa_id
		JOIN vizites_pieteikuma_stavokli vps ON vps.stavokla_kods = vp.stavokla_kods 
		WHERE vp.stavokla_kods in (2,4,7)
)
SELECT * FROM (SELECT TOP 1 * FROM vp1 WHERE vp1.darbinieka_id = @DARBINIEKA_ID AND vp1.stavokla_kods = 7 ORDER BY vp1.sakuma_laiks DESC
	UNION SELECT TOP 2 * FROM vp1 WHERE vp1.darbinieka_id = @DARBINIEKA_ID AND vp1.stavokla_kods in (2,4) ORDER BY vp1.sakuma_laiks ASC) vp3;

-- 6. Atskaite par darbiniekiem (izmantojot darba līgumus par pamatu), kas bija darbā noteiktā periodā: kurā telpā tie strādāja
DECLARE @PERIODA_SAKUMS3 datetime = '2023-06-06 00:00:00', @PERIODA_BEIGAS3 datetime = '2023-06-07 00:00:00';
SELECT * FROM (
	SELECT t.nodalas_nosaukums, dsb.telpas_numurs, dsb.veida_kods, dsb.registrets sakums, LEAD(dsb.registrets) OVER(PARTITION BY  dsb.darbinieka_id ORDER BY dsb.registrets ) beigas, dsb.darbinieka_id  FROM darba_sakumi_beigas dsb
	JOIN telpas t ON t.telpas_numurs = dsb.telpas_numurs 
	WHERE dsb.registrets > @PERIODA_SAKUMS3 AND @PERIODA_BEIGAS3 > dsb.registrets AND dsb.veida_kods != 7
) dsb1 WHERE dsb1.beigas is not null and dsb1.veida_kods in (1,3);
 
-- 7. Atskaite par dienas ienākumiem no telpas īres (izpildīto maksājumu summa)
DECLARE @PERIODA_SAKUMS4 datetime = '2023-06-06 00:00:00', @PERIODA_BEIGAS4 datetime = '2023-07-08 00:00:00';
SELECT  DATEPART(YEAR, m.izpildijuma_laiks) gads, DATEPART(MONTH, m.izpildijuma_laiks) mēnesis, DATEPART(DAY, m.izpildijuma_laiks) diena, sum(summa) summa
	FROM maksajumi m
	JOIN rekini r ON r.rekina_numurs = m.rekina_numurs
	JOIN telpas_ires_pieteikumi tip ON tip.telpas_ires_pieteikuma_numurs = r.telpas_ires_pieteikuma_numurs
	JOIN telpas t ON t.telpas_numurs = tip.telpas_numurs 
	WHERE m.izpildijuma_laiks > @PERIODA_SAKUMS4 AND @PERIODA_BEIGAS4 > m.izpildijuma_laiks
	GROUP BY DATEPART(YEAR, m.izpildijuma_laiks), DATEPART(MONTH, m.izpildijuma_laiks), DATEPART(DAY, m.izpildijuma_laiks);

-- 8. Atskaite par pieejamām (izmantošanai) telpām (tās, kas nav aizņemtas dotajā periodā)
 
DECLARE  @PERIODA_SAKUMS5 datetime = '2023-06-04 00:00:00', @PERIODA_BEIGAS5 datetime = '2023-06-08 20:19:00';
WITH dv1 AS (
	SELECT dv2.telpas_numurs, count(*) darba_vietu_skaits FROM darba_vietas dv2
	GROUP BY dv2.telpas_numurs
)
SELECT t2.telpas_numurs, t2.prezentesanas_iespeja, ietilpigums, (SELECT darba_vietu_skaits FROM dv1 WHERE dv1.telpas_numurs = t2.telpas_numurs) darba_vietu_skaits, t2.nodalas_nosaukums
	 FROM telpas t2
	 WHERE t2.darbinieku_izmantosanas_iespeja = 1
EXCEPT SELECT  t3.telpas_numurs, t3.prezentesanas_iespeja, ietilpigums, (SELECT darba_vietu_skaits FROM dv1 WHERE dv1.telpas_numurs = t3.telpas_numurs) darba_vietu_skaits, t3.nodalas_nosaukums
	 FROM telpas t3
	 JOIN telpas_izmantosanas_pieteikumi tip ON t3.telpas_numurs = tip.telpas_numurs
	 WHERE t3.darbinieku_izmantosanas_iespeja = 1 AND NOT (tip.beigu_laiks < @PERIODA_SAKUMS5 OR @PERIODA_BEIGAS5 < tip.sakuma_laiks);
	
-- 9. Atsakite, kas realizē rēķina summas_ar_pvn atribūta rēkināšanu; atskaite, kas sagatavo informāciju par rēķiniem, kas vēl netika sagatavoti

-- Esošie rēķini ar aprēķinātu PVN
SELECT *, summa_bez_pvn * 1.21 summa_ar_pvn FROM rekini r

-- Sagatavotie dati rēķiniem, kas vēl netika izveidoti
SELECT tip.telpas_ires_pieteikuma_numurs,
	v.vards, v.uzvards, v.epasts, v.telefona_numurs,
	tic.telpas_ires_cena * (DATEDIFF(MINUTE, tip.sakuma_laiks, beigu_laiks) / 60.0) aprekinata_summa_bez_pvn,
	tic.telpas_ires_cena * (DATEDIFF(MINUTE, tip.sakuma_laiks, beigu_laiks) / 60.0) * 1.21 aprekinata_summa_ar_pvn
	FROM telpas_ires_pieteikumi tip 
	LEFT JOIN rekini r ON r.telpas_ires_pieteikuma_numurs = tip.telpas_ires_pieteikuma_numurs
	JOIN telpas_ires_cenas tic ON tic.telpas_numurs = tip.telpas_numurs
	JOIN viesi v ON v.viesa_id = tip.viesa_id
	WHERE tip.stavokla_kods in (2,4) AND r.rekina_numurs IS NULL;