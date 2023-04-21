USE master;
ALTER DATABASE Universidade SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE Universidade;
GO
USE master;
CREATE DATABASE Universidade;
GO
USE Universidade;
GO

-----Tables-----
CREATE TABLE ALUNOS(
	MATRICULA INT NOT NULL IDENTITY
		CONSTRAINT PK_ALUNO PRIMARY KEY,
	NOME VARCHAR(50) NOT NULL
);
GO

CREATE TABLE CURSOS(
	CURSO CHAR(3) NOT NULL
		CONSTRAINT PK_CURSO PRIMARY KEY,
	NOME VARCHAR(50) NOT NULL
);
GO

CREATE TABLE PROFESSOR(
	PROFESSOR INT IDENTITY NOT NULL
		CONSTRAINT PK_PROFESSOR PRIMARY KEY,
	NOME VARCHAR(50) NOT NULL
);
GO

CREATE TABLE MATERIAS(
	SIGLA CHAR(3) NOT NULL,
	NOME VARCHAR(50) NOT NULL,
	CARGAHORARIA INT NOT NULL,
	CURSO CHAR(3) NOT NULL,
	PROFESSOR INT
		CONSTRAINT PK_MATERIA
		PRIMARY KEY (SIGLA,CURSO,PROFESSOR) CONSTRAINT FK_CURSO 
		FOREIGN KEY (CURSO) REFERENCES CURSOS (CURSO),
		CONSTRAINT FK_PROFESSOR
		FOREIGN KEY (PROFESSOR)
		REFERENCES PROFESSOR (PROFESSOR)
);
GO

CREATE TABLE MATRICULA(
	MATRICULA INT,
	CURSO CHAR(3),
	MATERIA CHAR(3),
	PROFESSOR INT,
	PERLETIVO INT,
	N1 FLOAT,
	N2 FLOAT,
	N3 FLOAT,
	N4 FLOAT,
	TOTALPONTOS FLOAT,
	MEDIA FLOAT,
	F1 INT,
	F2 INT,
	F3 INT,
	F4 INT,
	TOTALFALTAS INT,
	PERCFREQ FLOAT,
	RESULTADO VARCHAR(20)
		CONSTRAINT PK_MATRICULA
		PRIMARY KEY (MATRICULA,CURSO,MATERIA,PROFESSOR,PERLETIVO),
	CONSTRAINT FK_ALUNOS_MATRICULA
		FOREIGN KEY (MATRICULA)
		REFERENCES ALUNOS (MATRICULA),
	CONSTRAINT FK_CURSOS_MATRICULA
		FOREIGN KEY (CURSO)
		REFERENCES CURSOS (CURSO),
		
	CONSTRAINT FK_PROFESSOR_MATRICULA
		FOREIGN KEY (PROFESSOR)
		REFERENCES PROFESSOR (PROFESSOR)
);
	
ALTER TABLE MATRICULA ADD MEDIAFINAL FLOAT
GO
ALTER TABLE MATRICULA ADD NOTAEXAME FLOAT
GO

-----Procedures-----
CREATE PROCEDURE procCadastroAluno (  
    @NOME VARCHAR(50),  
    @SIGLA CHAR(3) 
)  
AS  
BEGIN  
	INSERT ALUNOS(NOME) VALUES(@NOME) 
	DECLARE @matriAlunos INT 
	SET @matriAlunos = (SELECT @@IDENTITY) 
	INSERT MATRICULA(MATRICULA, CURSO, MATERIA, PROFESSOR, PERLETIVO) 
	SELECT @matriAlunos AS MATRICULA, CURSO, SIGLA, PROFESSOR, 
	YEAR(GETDATE()) AS PERLETIVO FROM MATERIAS 
		WHERE CURSO = @SIGLA 
END  
GO 

CREATE PROCEDURE procCadastroCurso (  
    @SIGLA CHAR(3),  
    @CURSO VARCHAR(50)  
) 
AS  
BEGIN   
	INSERT CURSOS(CURSO, NOME) 
		VALUES(@SIGLA, @CURSO)  
END  
GO

CREATE PROCEDURE procCadastroProfessor (  
    @NOMEPROF VARCHAR(50) 
)  
AS  
BEGIN  
	INSERT PROFESSOR(NOME) 
		VALUES(@NOMEPROF)  
END  
GO  

CREATE PROCEDURE procCadastroMateria (  
    @SIGLAMAT CHAR(3),  
    @NOMEMAT VARCHAR(50),  
    @CARGAHORARIA INT, 
    @SIGLA CHAR (3), 
    @ID_PROF INT  
)  
AS  
BEGIN   
	INSERT MATERIAS(SIGLA, NOME, CARGAHORARIA, CURSO, PROFESSOR) 
	VALUES(@SIGLAMAT, @NOMEMAT, @CARGAHORARIA, @SIGLA, @ID_PROF)
END
GO

ALTER PROCEDURE procCadastroNotas(
	@MATRICULA INT,
	@CURSO CHAR(3),
	@MATERIA CHAR(3),
	@PERLETIVO CHAR(4),
	@NOTA FLOAT,
	@FALTA INT,
	@PARAMETRO INT
)
AS
BEGIN
	IF @PARAMETRO = 1
		BEGIN
			UPDATE MATRICULA
			SET N1 = @NOTA,
				F1 = @FALTA,
				TOTALPONTOS = @NOTA,
				TOTALFALTAS = @FALTA,
				MEDIA = @NOTA
			WHERE MATRICULA = @MATRICULA
				  AND CURSO = @CURSO
				  AND MATERIA = @MATERIA
				  AND PERLETIVO = @PERLETIVO;
		END;
	ELSE IF @PARAMETRO = 2
		BEGIN
			UPDATE MATRICULA
			SET N2 = @NOTA,
				F2 = @FALTA,
				TOTALPONTOS = @NOTA + N1,
				TOTALFALTAS = @FALTA + F1,
				MEDIA = (@NOTA + N1) / 2
			WHERE MATRICULA = @MATRICULA
				  AND CURSO = @CURSO
				  AND MATERIA = @MATERIA
				  AND PERLETIVO = @PERLETIVO;
		END;
	ELSE IF @PARAMETRO = 3
		BEGIN
			UPDATE MATRICULA
			SET N3 = @NOTA,
				F3 = @FALTA,
				TOTALPONTOS = @NOTA + N1 + N2,
				TOTALFALTAS = @FALTA + F1 + F2,
				MEDIA = (@NOTA + N1 + N2) / 3
			WHERE MATRICULA = @MATRICULA
				  AND CURSO = @CURSO
				  AND MATERIA = @MATERIA
				  AND PERLETIVO = @PERLETIVO;
		END;
	ELSE IF @PARAMETRO = 4
		BEGIN
			DECLARE @RESULTADO VARCHAR(50),
					@FREQUENCIA FLOAT,
					@MEDIAFINAL FLOAT;
			DECLARE @CARGAHORA INT 
			SET @CARGAHORA = (SELECT CARGAHORARIA FROM MATERIAS WHERE SIGLA = @MATERIA)
			UPDATE MATRICULA
			SET N4 = @NOTA,
				F4 = @FALTA,
				TOTALPONTOS = @NOTA + N1 + N2 + N3,
				TOTALFALTAS = @FALTA + F1 + F2 + F3,
				MEDIA = (@NOTA + N1 + N2 + N3) / 4,
                @MEDIAFINAL = (@NOTA + N1 + N2 + N3) / 4,
				MEDIAFINAL = @MEDIAFINAL,
				@FREQUENCIA = 100 - ((@FALTA + F1 + F2 + F3) * 100) / ((@CARGAHORA * 60) / 45),
				PERCFREQ = @FREQUENCIA
                	WHERE MATRICULA = @MATRICULA
						AND CURSO = @CURSO
				  		AND MATERIA = @MATERIA
				  		AND PERLETIVO = @PERLETIVO;
			
			IF @MEDIAFINAL >= 7 AND @FREQUENCIA >= 70
				BEGIN
					SET @RESULTADO = 'Aprovado'
						UPDATE MATRICULA
						SET RESULTADO = @RESULTADO
							WHERE MATRICULA = @MATRICULA
								AND CURSO = @CURSO 
                				AND MATERIA = @MATERIA 
                				AND PERLETIVO = @PERLETIVO;
				END;
			ELSE IF @MEDIAFINAL >= 7 AND @FREQUENCIA < 70 
            	BEGIN 
                	SET @RESULTADO = 'Reprovado'
                		UPDATE MATRICULA 
                		SET RESULTADO = @RESULTADO 
                		WHERE MATRICULA = @MATRICULA 
                			AND CURSO = @CURSO 
                			AND MATERIA = @MATERIA 
                			AND PERLETIVO = @PERLETIVO; 
            	END;
			ELSE IF @MEDIAFINAL < 7 AND @FREQUENCIA >=70
                BEGIN 
                	SET @RESULTADO = 'Exame'
                		UPDATE MATRICULA 
                		SET RESULTADO = @RESULTADO 
                		WHERE MATRICULA = @MATRICULA 
                			AND CURSO = @CURSO 
                			AND MATERIA = @MATERIA 
                			AND PERLETIVO = @PERLETIVO; 
                END; 
		END;
	ELSE IF @PARAMETRO = 5 
    	BEGIN 
    		DECLARE @MEDIAEXAME FLOAT 
    		UPDATE MATRICULA 
    			SET NOTAEXAME = @NOTA,
				@MEDIAEXAME = (@NOTA + MEDIAFINAL) / 2, 
				MEDIAFINAL = @MEDIAEXAME
				WHERE MATRICULA = @MATRICULA 
                			AND CURSO = @CURSO 
                			AND MATERIA = @MATERIA 
                			AND PERLETIVO = @PERLETIVO;
			
			IF @MEDIAEXAME >= 5 
    		BEGIN 
    			SET @RESULTADO = 'Aprovado'
    				UPDATE MATRICULA  
    				SET RESULTADO = @RESULTADO 
    				WHERE MATRICULA = @MATRICULA 
    					AND CURSO = @CURSO 
    					AND MATERIA = @MATERIA 
    					AND PERLETIVO = @PERLETIVO; 
    		END;
			
			ELSE
			BEGIN 
        		SET @RESULTADO = 'Reprovado'
        			UPDATE MATRICULA 
        			SET RESULTADO = @RESULTADO 
        			WHERE MATRICULA = @MATRICULA 
        				AND CURSO = @CURSO 
        				AND MATERIA = @MATERIA 
        				AND PERLETIVO = @PERLETIVO; 
        	END; 
		END;
	SELECT * FROM MATRICULA
	WHERE MATRICULA = @MATRICULA;
END;
GO

-----Execs-----
EXEC procCadastroCurso 'ENG', 'Engenharia' 
EXEC procCadastroCurso 'SIS', 'Sistemas' 
EXEC procCadastroCurso 'LET', 'Letras' 

EXEC procCadastroProfessor 'Dornel' 
EXEC procCadastroProfessor 'Chaiene' 
EXEC procCadastroProfessor 'Leanderson' 
EXEC procCadastroProfessor 'Lucia' 
EXEC procCadastroProfessor 'Luciano' 
EXEC procCadastroProfessor 'Nedino'

EXEC procCadastroMateria 'BDA', 'Banco de Dados', 144, 'ENG', 1 
EXEC procCadastroMateria 'RES', 'Requisitos de Software', 144,  'ENG', 2  
EXEC procCadastroMateria 'TS', 'Teste de Software', 144, 'SIS', 2 
EXEC procCadastroMateria 'POO', 'Programação Objeto', 144, 'SIS', 3 
EXEC procCadastroMateria 'PRT', 'Português', 144, 'LET', 4 
EXEC procCadastroMateria 'ING', 'Inglês', 144, 'LET', 4 
EXEC procCadastroMateria 'DEW', 'Desenvolvimento Web', 144, 'ENG', 5
EXEC procCadastroMateria 'LP', 'Logica de porgramação', 144, 'SIS', 5
EXEC procCadastroMateria 'MTD', 'Matematica Discreta', 144, 'ENG', 6 

EXEC procCadastroAluno 'Eduardo', 'ENG' 
EXEC procCadastroAluno 'Felipe', 'ENG' 
EXEC procCadastroAluno 'Christian', 'ENG' 
EXEC procCadastroAluno 'Guilherme', 'SIS' 
EXEC procCadastroAluno 'Dimitri', 'SIS' 
EXEC procCadastroAluno 'Matheus', 'LET' 
EXEC procCadastroAluno 'Julia', 'LET' 
EXEC procCadastroAluno 'Alicia', 'LET' 
EXEC procCadastroAluno 'Gustavo', 'SIS'

EXEC procCadastroNotas 1, 'ENG', 'BDA', 2023, 7.0, 0, 1 
EXEC procCadastroNotas 1, 'ENG', 'BDA', 2023, 8.5, 0, 2 
EXEC procCadastroNotas 1, 'ENG', 'BDA', 2023, 7.0, 4, 3 
EXEC procCadastroNotas 1, 'ENG', 'BDA', 2023, 9.5, 2, 4

EXEC procCadastroNotas 1, 'ENG', 'DEW', 2023, 7.5, 0, 1 
EXEC procCadastroNotas 1, 'ENG', 'DEW', 2023, 6.0, 2, 2 
EXEC procCadastroNotas 1, 'ENG', 'DEW', 2023, 2.5, 2, 3 
EXEC procCadastroNotas 1, 'ENG', 'DEW', 2023, 1.0, 6, 4
EXEC procCadastroNotas 1, 'ENG', 'DEW', 2023, 8, 0, 5


EXEC procCadastroNotas 1, 'ENG', 'MTD', 2023, 7.5, 20, 1 
EXEC procCadastroNotas 1, 'ENG', 'MTD', 2023, 8.0, 12, 2 
EXEC procCadastroNotas 1, 'ENG', 'MTD', 2023, 9.0, 14, 3 
EXEC procCadastroNotas 1, 'ENG', 'MTD', 2023, 10.0, 16, 4 

---------------SELECTS--------------------------------------
SELECT * FROM ALUNOS
SELECT * FROM CURSOS
SELECT * FROM PROFESSOR
SELECT * FROM MATERIAS
SELECT * FROM MATRICULA

-- Aprovado em BDA com 8 de média e 96,8% de frequência
-- Exame em DEW com 4,25 de média e 94,7% de frequência  
-- Reprovado em MTD com 8,625 de média e 67,7% de frequência