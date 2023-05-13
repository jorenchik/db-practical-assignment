-- 1. Atskaite par pasākumiem: dalībnieki kā darbinieku un viesi un palikušās vietas
SELECT pp.pasakuma_nosaukums,pp.sakuma_laiks, pp.darbinieku_skaits, viesu_skaits, ietilpigums, (darbinieku_skaits + viesu_skaits) dalibnieku_skaits, ietilpigums - (darbinieku_skaits + viesu_skaits) palikusas_vietas FROM (
	SELECT p.pasakuma_nosaukums, p.sakuma_laiks, t.ietilpigums,
		(SELECT count(*) FROM darbinieki_pasakumi dp WHERE dp.pasakuma_nosaukums = p.pasakuma_nosaukums AND dp.sakuma_laiks  = p.sakuma_laiks) as darbinieku_skaits,
		(SELECT count(*) FROM viesi_pasakumi vp WHERE vp.pasakuma_nosaukums = p.pasakuma_nosaukums AND vp.sakuma_laiks  = p.sakuma_laiks) as viesu_skaits
	FROM pasakumi p
	JOIN telpas t ON t.telpas_numurs = p.telpas_numurs
) pp 


-- 2. Atsakaite par nostrādātām stundām katrā dienā noteikā periodā
SELECT dsb2.darbinieka_id, datepart(dd, dsb2.registrets) menesa_diena, max(kumul_nostradats_diena) nostradats FROM 
(
	SELECT darbinieka_id, registrets,
		sum(DATEDIFF(minute,ieprieksejais_registrets, CASE WHEN dsbi.ieprieksejais_veida_kods not in (1,3) OR dsbi.veida_kods not in (2,4,5,6) OR dsbi.ieprieksejais_registrets IS NULL THEN dsbi.ieprieksejais_registrets ELSE dsbi.registrets END)) OVER (PARTITION BY darbinieka_id ORDER BY registrets) / 60.0 kumul_nostradats_diena
	FROM (SELECT dsb.darbinieka_id, dsb.registrets, dsb.veida_kods, LAG(dsb.registrets) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_registrets, LAG(veida_kods) OVER(PARTITION BY dsb.darbinieka_id ORDER BY dsb.registrets) ieprieksejais_veida_kods FROM darba_sakumi_beigas dsb) dsbi
) dsb2
WHERE registrets >= '2023-06-01 00:00:00' AND registrets < '2023-07-01 00:00:00'
GROUP BY dsb2.darbinieka_id, datepart(dd, dsb2.registrets) 

-- 3. Atskaite (aktīvo) darbinieku algas rēķins

-- 4. Atskaite par telpām: vidējā atzīme, atsauksmju daudzums, ienesīgums, darbinieku izmantošanas daudzums

-- 5. OVER Atskaite par noteiktā darbinieka iepriekšējo, nākamo, un aiznākamo vizīti: viesa kontakti, vizītes mērķis

-- 6. Atskaite par darbiniekiem (izmantojot darba līgumus par pamatu), kas bija darbā noteiktā periodā: kurā telpā tie strādāja

-- 7. Atskaite par nedēļu ienesīgumu, ienesīgako telpu nedēļā (no rēķiniem).

-- 8. Atskaite par pieejamām (izmantošanai) telpām, kas ir darbiniekam atbilstošajā nodaļā (no darba līgumiem) 

-- 9. Atskaite par darbiniekiem, kuriem pašlaik ir aktīvi darba līgumi

-- 10. Atskaite par katras nodaļas prognozētām/bijušām izmaksām (darbinieku algām) kādā nedēļa

-- 11. Atskaite no maksājumiem, kas neizdevās (veidojot jaunos rēķinus)