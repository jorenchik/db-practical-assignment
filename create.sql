CREATE TABLE darbinieki (
	darbinieka_id int AUTO_INCREMENT,
    epasts varchar(128) UNIQUE,
	vards nvarchar(20) not null,
	uzvards nvarchar(20)  not null,
	darba_telefona_numurs char(8)  not null,
	-- 64 garums, lai varetu glabāt SHA-256 kontrolsummu
	konta_parole char(64)  not null,
	PRIMARY KEY(darbinieka_id)
);
ALTER TABLE darbinieki AUTO_INCREMENT=1000;

CREATE TABLE faili (
    faila_id int AUTO_INCREMENT,
    faila_adrese varchar(256),
    faila_autors int,
    FOREIGN KEY (faila_autors) REFERENCES darbinieki (darbinieka_id),
    PRIMARY KEY (faila_id)
);


CREATE TABLE nodalas (
	nodalas_nosaukums nvarchar(50),
	prieksnieka_id int not null,
	FOREIGN KEY (prieksnieka_id) REFERENCES darbinieki (darbinieka_id),
	PRIMARY KEY (nodalas_nosaukums)
);

CREATE TABLE nodalas_darbinieki (
	darbinieka_id int,
	nodalas_nosaukums nvarchar(50),
	FOREIGN KEY (darbinieka_id) REFERENCES darbinieki (darbinieka_id),
	FOREIGN KEY (nodalas_nosaukums) REFERENCES nodalas (nodalas_nosaukums),
	PRIMARY KEY (darbinieka_id, nodalas_nosaukums)
);

CREATE TABLE amati ( 
	amata_id int,
	amata_nosaukums nvarchar(50) not null UNIQUE,
	PRIMARY KEY (amata_id)
);

CREATE TABLE darba_liguma_stavokli (
	stavokla_kods int,
	stavoklis nvarchar(40) not null UNIQUE,
	PRIMARY KEY(stavokla_kods)
);

CREATE TABLE darba_ligumi (
	darba_liguma_numurs int AUTO_INCREMENT,
	darba_sakums date not null,
	darba_beigas date null,
	stundas_likme decimal(10, 2) not null,
	darbinieka_id int not null,
	stavokla_kods int not null,
	FOREIGN KEY (darbinieka_id) REFERENCES darbinieki (darbinieka_id),
	FOREIGN KEY (stavokla_kods) REFERENCES darba_liguma_stavokli (stavokla_kods),
	PRIMARY KEY (darba_liguma_numurs)
);
ALTER TABLE darba_ligumi AUTO_INCREMENT=3000;

CREATE TABLE darba_ligumi_amati (
	darba_liguma_numurs int,
	amata_id int,
	FOREIGN KEY (amata_id) REFERENCES amati (amata_id),
	FOREIGN KEY (darba_liguma_numurs) REFERENCES darba_ligumi (darba_liguma_numurs),
	PRIMARY KEY (darba_liguma_numurs, amata_id)
);

CREATE TABLE nodalas_amati (
	nodalas_nosaukums nvarchar(50),
	amata_id int,
	FOREIGN KEY (nodalas_nosaukums) REFERENCES nodalas (nodalas_nosaukums),	
	FOREIGN KEY (amata_id) REFERENCES amati (amata_id),
	PRIMARY KEY (nodalas_nosaukums,amata_id)
);


CREATE TABLE telpas (
	telpas_numurs int,
	prezentesanas_iespeja bit not null,
	iresanas_iespeja bit not null,
	pasakumu_iespeja bit not null,
	ietilpigums int not null,
	darbinieku_izmantosanas_iespeja bit not null,
	nodalas_nosaukums nvarchar(50) not null,
	FOREIGN KEY (nodalas_nosaukums) REFERENCES nodalas (nodalas_nosaukums),
	PRIMARY KEY(telpas_numurs)
);

CREATE TABLE telpas_ires_cenas (
	telpas_numurs int,
	telpas_ires_cena decimal(10,2) not null,
	FOREIGN KEY (telpas_numurs) REFERENCES telpas (telpas_numurs),
	PRIMARY KEY (telpas_numurs)
);

CREATE TABLE viesi (
	viesa_id int AUTO_INCREMENT,
	vards nvarchar(50) not null,
	uzvards nvarchar(50) not null,
	epasts nvarchar(50) not null UNIQUE,
	konta_parole varchar(64)  not null,
	telefona_numurs char(8)  not null UNIQUE,
	PRIMARY KEY (viesa_id)
);
ALTER TABLE viesi AUTO_INCREMENT=4000;

CREATE TABLE vizites_pieteikuma_stavokli(
	stavokla_kods int,
	stavoklis nvarchar(30) not null UNIQUE,
	PRIMARY KEY (stavokla_kods)
);

CREATE TABLE vizites_pieteikumi (
	vizites_pietiekuma_numurs int AUTO_INCREMENT,
	merkis nvarchar(100) not null,
	sakuma_laiks datetime not null,
	beigu_laiks datetime not null,
	stavokla_kods int not null,
	viesa_id int not null, 
	darbinieka_id int not null, 
	FOREIGN KEY (stavokla_kods) REFERENCES vizites_pieteikuma_stavokli (stavokla_kods),	
	FOREIGN KEY (viesa_id) REFERENCES viesi (viesa_id),
	FOREIGN KEY (darbinieka_id) REFERENCES darbinieki (darbinieka_id),
	PRIMARY KEY (vizites_pietiekuma_numurs)
);
ALTER TABLE vizites_pieteikumi AUTO_INCREMENT=5000;

CREATE TABLE telpas_ires_pieteikuma_stavokli(
	stavokla_kods int,
	stavoklis nvarchar(30) not null UNIQUE,
	PRIMARY KEY (stavokla_kods)
);

CREATE TABLE telpas_ires_pieteikumi (
	telpas_ires_pieteikuma_numurs int AUTO_INCREMENT,
	merkis nvarchar(100) not null,
	sakuma_laiks datetime not null,
	beigu_laiks datetime not null,
	stavokla_kods int not null,
	viesa_id int not null, 
	telpas_numurs int not null,
	FOREIGN KEY (stavokla_kods) REFERENCES telpas_ires_pieteikuma_stavokli (stavokla_kods),
	FOREIGN KEY (viesa_id) REFERENCES viesi (viesa_id),
	FOREIGN KEY (telpas_numurs) REFERENCES telpas (telpas_numurs),
	PRIMARY KEY (telpas_ires_pieteikuma_numurs)
);
ALTER TABLE telpas_ires_pieteikumi AUTO_INCREMENT=6000;

CREATE TABLE telpu_atsauksmes (
	telpas_ires_pieteikuma_numurs int,
	teksts nvarchar(5000),
	vertejums int not null,
	viesa_id int not null, 
	FOREIGN KEY (viesa_id) REFERENCES viesi (viesa_id),
	FOREIGN KEY (telpas_ires_pieteikuma_numurs) REFERENCES telpas_ires_pieteikumi (telpas_ires_pieteikuma_numurs),
	PRIMARY KEY (telpas_ires_pieteikuma_numurs)
);

CREATE TABLE rekina_stavokli (
	stavokla_kods int,
	stavoklis nvarchar(30) not null UNIQUE,
	PRIMARY KEY (stavokla_kods)
);

CREATE TABLE rekini (
	rekina_numurs int AUTO_INCREMENT,
	telpas_ires_pieteikuma_numurs int not null, 
	summa_bez_pvn int not null,
	stavokla_kods int not null,
	FOREIGN KEY (telpas_ires_pieteikuma_numurs) REFERENCES telpas_ires_pieteikumi (telpas_ires_pieteikuma_numurs),
	FOREIGN KEY (stavokla_kods) REFERENCES rekina_stavokli (stavokla_kods),
	PRIMARY KEY (rekina_numurs)
);
ALTER TABLE rekini AUTO_INCREMENT=7000;


CREATE TABLE maksajumi (
	maksajuma_numurs int AUTO_INCREMENT,
	bankas_konts varchar(30) not null,
	izpildijuma_laiks datetime not null,
	maksatajs nvarchar (60) not null,
	summa decimal(10, 2),
	rekina_numurs int not null, 
	FOREIGN KEY (rekina_numurs) REFERENCES rekini (rekina_numurs),
	PRIMARY KEY (maksajuma_numurs)
);
ALTER TABLE maksajumi AUTO_INCREMENT=8000;


CREATE TABLE telpas_izmantosanas_pieteikuma_stavokli (
	stavokla_kods int,
	stavoklis nvarchar(30) not null UNIQUE,
	PRIMARY KEY (stavokla_kods)
);

CREATE TABLE telpas_izmantosanas_pieteikumi (
	telpas_izmantosanas_pieteikuma_numurs int AUTO_INCREMENT,
	merkis nvarchar(100) not null,
	sakuma_laiks datetime not null,
	beigu_laiks datetime not null,
	stavokla_kods int not null,
	darbinieka_id int not null,	
	telpas_numurs int not null,
	FOREIGN KEY (stavokla_kods) REFERENCES telpas_izmantosanas_pieteikuma_stavokli (stavokla_kods),
	FOREIGN KEY (darbinieka_id) REFERENCES darbinieki (darbinieka_id),
	FOREIGN KEY (telpas_numurs) REFERENCES telpas (telpas_numurs),
	PRIMARY KEY (telpas_izmantosanas_pieteikuma_numurs)	
);
ALTER TABLE telpas_izmantosanas_pieteikumi AUTO_INCREMENT=9000;

CREATE TABLE pasakuma_stavokli (
	stavokla_kods int,
	stavoklis nvarchar(30) not null UNIQUE,
	PRIMARY KEY (stavokla_kods)
);

CREATE TABLE pasakumi (
	pasakuma_nosaukums nvarchar(50),
	sakuma_laiks datetime,
	beigu_laiks datetime not null,
	stavokla_kods int not null,
	telpas_numurs int not null,
	FOREIGN KEY (stavokla_kods) REFERENCES pasakuma_stavokli (stavokla_kods),
	FOREIGN KEY (telpas_numurs) REFERENCES telpas (telpas_numurs),
	PRIMARY KEY (pasakuma_nosaukums, sakuma_laiks)
);

CREATE TABLE darbinieki_pasakumi (
	darbinieka_id int not null,	
	sakuma_laiks datetime not null,
	pasakuma_nosaukums nvarchar(50) not null,
	FOREIGN KEY (darbinieka_id) REFERENCES darbinieki (darbinieka_id),
	FOREIGN KEY (pasakuma_nosaukums, sakuma_laiks) REFERENCES pasakumi (pasakuma_nosaukums, sakuma_laiks),
	PRIMARY KEY (darbinieka_id, sakuma_laiks, pasakuma_nosaukums)
);

CREATE TABLE viesi_pasakumi (
	viesa_id int not null,	
	sakuma_laiks datetime not null,
	pasakuma_nosaukums nvarchar(50) not null,
	FOREIGN KEY (viesa_id) REFERENCES viesi (viesa_id),
	FOREIGN KEY (pasakuma_nosaukums, sakuma_laiks) REFERENCES pasakumi (pasakuma_nosaukums, sakuma_laiks),
	PRIMARY KEY (viesa_id, sakuma_laiks, pasakuma_nosaukums)
);

CREATE TABLE darba_vietas (
	darba_vietas_numurs int,
	telpas_numurs int not null,
	FOREIGN KEY (telpas_numurs) REFERENCES telpas (telpas_numurs), 
	PRIMARY KEY(darba_vietas_numurs, telpas_numurs)
);

CREATE TABLE darba_sakumu_beigu_veidi (
	veida_kods int,
	veids nvarchar(30) not null UNIQUE,
	PRIMARY KEY (veida_kods)
);

CREATE TABLE darba_sakumi_beigas (
	registrets datetime,
	darbinieka_id int not null,
	veida_kods int not null,
	darba_vietas_numurs int not null,
	telpas_numurs int not null,
	FOREIGN KEY (veida_kods) REFERENCES darba_sakumu_beigu_veidi (veida_kods),
	FOREIGN KEY (darbinieka_id) REFERENCES darbinieki (darbinieka_id),
	FOREIGN KEY (darba_vietas_numurs,telpas_numurs) REFERENCES darba_vietas (darba_vietas_numurs,telpas_numurs),
	PRIMARY KEY (registrets, darbinieka_id)	
);
