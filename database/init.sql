CREATE TABLE uporabniki (
    id SERIAL PRIMARY KEY,
    ime VARCHAR(100) NOT NULL,
    priimek VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefonska_stevilka VARCHAR(20),
    geslo_hash VARCHAR(255) NOT NULL,
    vloga VARCHAR(10) NOT NULL,
    ustvarjeno_ob TIMESTAMP DEFAULT NOW()
);
CREATE TABLE tecaji (
    id SERIAL PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL,
    opis TEXT,
    ustvarjeno_ob TIMESTAMP DEFAULT NOW()
);
CREATE TABLE ucitelji_tecajev (
    id SERIAL PRIMARY KEY,
    id_ucitelja INTEGER NOT NULL,
    id_tecaja INTEGER NOT NULL,
    FOREIGN KEY (id_ucitelja) REFERENCES uporabniki(id) ON DELETE CASCADE,
    FOREIGN KEY (id_tecaja) REFERENCES tecaji(id) ON DELETE CASCADE
);
CREATE TABLE gradiva (
    id SERIAL PRIMARY KEY,
    id_tecaja INTEGER NOT NULL,
    naslov VARCHAR(255) NOT NULL,
    tip VARCHAR(10) NOT NULL,
    vsebina TEXT NOT NULL,
    nalozeno_ob TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (id_tecaja) REFERENCES tecaji(id) ON DELETE CASCADE
);
CREATE TABLE naloge (
    id SERIAL PRIMARY KEY,
    id_tecaja INTEGER NOT NULL,
    naslov VARCHAR(255) NOT NULL,
    opis TEXT,
    rok_oddaje TIMESTAMP,
    ustvarjeno_ob TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (id_tecaja) REFERENCES tecaji(id) ON DELETE CASCADE
);
CREATE TABLE oddaje (
    id SERIAL PRIMARY KEY,
    id_naloge INTEGER NOT NULL,
    id_studenta INTEGER NOT NULL,
    pot_do_datoteke VARCHAR(512) NOT NULL,
    oddano_ob TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (id_naloge) REFERENCES naloge(id) ON DELETE CASCADE,
    FOREIGN KEY (id_studenta) REFERENCES uporabniki(id) ON DELETE CASCADE
);
CREATE TABLE ocene (
    id SERIAL PRIMARY KEY,
    id_oddaje INTEGER NOT NULL,
    id_ucitelja INTEGER,
    ocena VARCHAR(50) NOT NULL,
    povratna_informacija TEXT,
    ocenjeno_ob TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (id_oddaje) REFERENCES oddaje(id) ON DELETE CASCADE,
    FOREIGN KEY (id_ucitelja) REFERENCES uporabniki(id) ON DELETE SET NULL
);