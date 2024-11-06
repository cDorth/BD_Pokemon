--CRIAÇÃO DO BANCO

CREATE DATABASE BDpokemon
GO

USE BDpokemon

GO

--CRIANDO TABELAS 

CREATE TABLE Usuario(
idUsuario INT PRIMARY KEY,
nome VARCHAR(50),
idade INT,
genero BIT
);
GO

CREATE TABLE Pokemon(
idPokemon INT PRIMARY KEY,
nome VARCHAR(50),
genero BIT,
nivel INT,
idUsuario INT,
idPokeCenter INT
);
GO

CREATE TABLE tipo(
idTipo INT PRIMARY KEY,
tipo VARCHAR(40)
);
GO

CREATE TABLE tipoPokemon(
idTipoPokemon INT PRIMARY KEY,
idTipo INT,
idPokemon INT
);
GO

CREATE TABLE PokeCenter(
idPokeCenter INT PRIMARY KEY,
realizar varchar(20)
);
GO

INSERT INTO Usuario(idUsuario,nome,idade,genero)
VALUES 
(1,'Carlos',17,1),
(2,'Edgar',70,1),
(3,'Odake',5,1),
(4,'Rafa',20,0),
(5,'Bruna',10,0)
GO

INSERT INTO Pokemon(idPokemon,nome,genero,nivel,idUsuario,idPokeCenter)
VALUES 
(1,'Goku',1,8000,1,1),
(2,'Freeza',1,100,2,1),
(3,'Pikachu',0,30,1,2),
(4,'Snorlax',1,1,4,2),
(5,'Ratata',0,4,5,3)
GO

INSERT INTO tipo(idTipo,tipo)
VALUES 
(1,'Fogo'),
(2,'Sono'),
(3,'Raio'),
(4,'Reptil'),
(5,'Ki')
GO
INSERT INTO PokeCenter(idPokeCenter,realizar)
VALUES 
(1,'Guardado'),
(2,'Curando'),
(3,'aguardando')
GO

INSERT INTO tipoPokemon(idTipoPokemon,idPokemon,idTipo)
VALUES 
(1,1,5),
(2,2,4),
(3,3,3),
(4,4,2),
(5,5,1),
(6,1,2)
GO
--Logica das chaves:
--1 Usuario pode ter N pokemons e 1 pokemon pode ter 1 usuario
--1 pokemon pode ter N tipos e 1 tipo pode ter N pokemons 
--1 Hospital pode ter N pokemons e 1 pokemon pode estar em 1 Hospital

--POKEMON
ALTER TABLE Pokemon
ADD CONSTRAINT FK_Usuario FOREIGN KEY (idUsuario)
REFERENCES Usuario(idUsuario);
GO
ALTER TABLE Pokemon
ADD CONSTRAINT FK_PokeCenter FOREIGN KEY (idPokeCenter)
REFERENCES PokeCenter(idPokeCenter);
GO


--TipoPokemon

ALTER TABLE tipoPokemon
ADD CONSTRAINT FK_IdPokemon FOREIGN KEY (IdPokemon)
REFERENCES Pokemon(IdPokemon);
GO

ALTER TABLE tipoPokemon
ADD CONSTRAINT FK_IdTipo FOREIGN KEY (IdTipo)
REFERENCES Tipo(IdTipo);
GO

--VIEW QUE MOSTRA O NOME DO POKEMON,SEU NIVEL,GENERO E SEU TIPO
CREATE VIEW vw_ConsultarTipo AS
SELECT 
A.nome,
A.nivel,
	CASE genero
    WHEN 1 THEN 'Masculino' 
    ELSE 'Feminino'
	END  AS genero,
C.tipo
 FROM Pokemon AS A 
INNER JOIN tipoPokemon AS B  ON A.idPokemon = B.idPokemon
INNER JOIN tipo AS C ON B.idTipo = C.idtipo
GO
SELECT * FROM vw_ConsultarTipo

--SUBQUERY QUE RETORNA POKEMONS QUE ESTÃO SENDO CURADOS

SELECT A.nome
FROM Pokemon AS A
WHERE idPokeCenter IN (
    SELECT idPokeCenter
    FROM PokeCenter
    WHERE realizar = 'Curando'
);

--CTE's QUE RETORNA UMA CONSULTA DETALHADA SOBRE O POKEMON E AS RELAÇÕES


WITH ConsultaDetalhada AS (
	SELECT 
		A.Nome AS Nome_Pokemon,
		D.tipo,
		A.nivel,
	CASE A.genero
    WHEN 1 THEN 'Masculino' 
    ELSE 'Feminino'
	END  AS genero_Pokemon,
	    B.nome
    
	FROM 
		Pokemon AS A
    
INNER JOIN Usuario AS B ON B.idUsuario = A.idUsuario 
INNER JOIN tipoPokemon AS C  ON A.idPokemon = C.idPokemon
INNER JOIN tipo AS D ON C.idTipo = D.idtipo
)
SELECT 
		Nome_Pokemon,
		tipo,
		nivel,
		genero_Pokemon,
		nome
FROM 
	ConsultaDetalhada
    
	--WINDOW FUNCTION DIVISAO DE GRUPO POR NIVEL 

	SELECT
*
 FROM (
SELECT
NOME,
NIVEL,
NTILE(5) OVER (ORDER BY NIVEL DESC) AS GRUPO_Niveis
FROM
    Pokemon
) AS Subquery
WHERE
GRUPO_Niveis = 1
GO


--LOOP QUE MUDA TIPO DE ACORDO COM O ID(DEMORA PARA CARREGAR)

DECLARE @title VARCHAR(200), @contador INT
SET @title = 'Fogo'
SET @contador = 1

SET ROWCOUNT 1

WHILE EXISTS(SELECT 1 FROM tipo WHERE idTipo = 1)
BEGIN
	UPDATE tipo SET tipo = @title WHERE idTipo = 1
	PRINT 'Itens atualizados: ' + CONVERT(VARCHAR(10), @contador)
	SET @contador = @contador + 1
	BREAK
END
SET ROWCOUNT 0

SELECT * from tipo
GO
--LOOP QUE RETORNA QUANTIDADE DE REGISTROS NAS TABELAS PRINCIPAIS 
DECLARE @tabelaAtual INT = 1;
DECLARE @totalTabelas INT = 3;
DECLARE @nomeTabela VARCHAR(50);
DECLARE @quantidade INT;

WHILE @tabelaAtual <= @totalTabelas
BEGIN
    SET @nomeTabela = CASE @tabelaAtual
                      WHEN 1 THEN 'Usuario'
                      WHEN 2 THEN 'Pokemon'
                      WHEN 3 THEN 'PokeCenter'
                      END; 

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'SELECT @quantidade = COUNT(*) FROM ' + @nomeTabela;

    EXEC sp_executesql @sql, N'@quantidade INT OUTPUT', @quantidade OUTPUT;

    PRINT 'A tabela ' + @nomeTabela + ' possui ' + CAST(@quantidade AS VARCHAR) + ' registros.';

    SET @tabelaAtual = @tabelaAtual + 1;
END
GO
--FUNCTION QUE BUSCA UM POKEMON ESPECIFICO 

CREATE FUNCTION ConsultarPokemon (@idPokemon INT)
RETURNS @TabelaConsultas TABLE (
    IdPokemon INT,
    Nome VARCHAR(20),
    Tipo VARCHAR(20),
	Nivel INT,
    Usuario VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @TabelaConsultas
    SELECT 
	A.idPokemon,
	A.nome,
	D.tipo,
	A.nivel,
	B.nome
    
	FROM 
		Pokemon AS A
INNER JOIN Usuario AS B ON B.idUsuario = A.idUsuario
INNER JOIN tipoPokemon AS C  ON A.idPokemon = C.idPokemon
INNER JOIN tipo AS D ON C.idTipo = D.idtipo
    WHERE A.idPokemon = @idPokemon;

    RETURN;
END;
GO
SELECT *
FROM dbo.ConsultarPokemon(1)

--PROCEDURE QUE ADD UM POKEMON CAPTURADO

IF EXISTS (SELECT 1 FROM SYS.objects WHERE TYPE = 'P' AND NAME = 'SP_ADD_POKEMON')
	BEGIN
		DROP PROCEDURE SP_ADD_POKEMON
	END
GO

CREATE PROCEDURE SP_ADD_POKEMON
@idPokemon INT,
@nome VARCHAR(50),
@genero BIT,
@nivel INT,
@idUsuario INT,
@idPokeCenter INT
AS
    INSERT INTO Pokemon(idPokemon,nome,genero,nivel,idUsuario,idPokeCenter)
    VALUES (@idPokemon,@nome,@genero,@nivel,@idUsuario,@idPokeCenter)
GO

EXEC SP_ADD_POKEMON
@idPokemon = 7,
@nome = 'CHARIZAARDD',
@genero = 1,
@nivel = 99999,
@idUsuario = 1,
@idPokeCenter = 3
GO
SELECT * FROM Pokemon
--DELETE Pokemon
--WHERE idPokemon = 6


GO
--TRIGGER QUE MOSTRA O POKEMON ADICIONADO

CREATE OR ALTER TRIGGER Pokemon_Adicionado
ON Pokemon 
AFTER INSERT 
AS
BEGIN
	DECLARE @ultimo_nome VARCHAR(100);
	SELECT @ultimo_nome = Nome FROM Pokemon ORDER BY idPokemon ASC;

	PRINT @ultimo_nome + ' adicionado com sucesso'
END
GO
