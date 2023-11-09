-- 1.1 Estude e faça o download da base de dados disponível no link https://www.kaggle.com/datasets/csafrit2/higher-education-students-performance-evaluation

-- AGE: Student Age (1: 18-21, 2: 22-25, 3: above 26);
-- GENDER: Sex (1: female, 2: male);
-- SALARY: Total salary if available (1: USD 135-200, 2: USD 201-270, 3: USD 271-340, 4: USD 341-410, 5: above 410);
-- PREP_EXAM: Preparation to midterm exams 2: (1: closest date to the exam, 2: regularly during the semester, 3: never);
-- NOTES: Taking notes in classes: (1: never, 2: sometimes, 3: always);
-- GRADE: OUTPUT Grade (0: Fail, 1: DD, 2: DC, 3: CC, 4: CB, 5: BB, 6: BA, 7: AA);

-- 1.2 Crie uma tabela apropriada para o armazenamento dos itens. Não se preocupe com a normalização. Uma tabela basta.

CREATE TABLE IF NOT EXISTS student_prediction (
	AGE INT,
	GENDER INT,
	SALARY INT,
	PREP_EXAM INT,
	NOTES INT,
	GRADE INT
);

SELECT * FROM student_prediction;

-- 1.3 Copie os dados do arquivo .csv para a sua tabela. Veja como no link https://www.postgresql.org/docs/current/sql-copy.html

COPY student_prediction FROM '13_projeto_base_de_dados_student_prediction.csv' DELIMITER ',' CSV HEADER

SELECT * FROM student_prediction;

-- 1.4 Escreva os seguintes stored procedures (incluindo um bloco anônimo de teste para cada um):

-- 1.4.1 Exibe o número de estudantes maiores de idade.

CREATE OR REPLACE PROCEDURE estudantesAdultos(OUT total INT)
LANGUAGE plpgsql
AS $$
BEGIN
	SELECT COUNT(age) INTO total FROM student_prediction WHERE age >= 2;
	RAISE NOTICE 'estudantes maiores de idade: %', total;
END;	
$$

DO $$
DECLARE
	idade INT;
BEGIN
	CALL estudantesAdultos(idade);
END;
$$

-- 1.4.2 Exibe o percentual de estudantes de cada sexo.

CREATE OR REPLACE PROCEDURE porcentagemSexo(
	OUT porcentagemFeminina FLOAT, OUT porcentagemMasculina FLOAT)
LANGUAGE plpgsql
AS $$
DECLARE
	valorTotal FLOAT;
	valorFeminino FLOAT;
	valorMasculino FLOAT;
BEGIN
	SELECT COUNT(*) INTO valorTotal FROM student_prediction ;
	SELECT COUNT(*) INTO valorFeminino FROM student_prediction WHERE gender = 1 ;
	SELECT COUNT(*) INTO valorMasculino FROM student_prediction WHERE gender = 2 ;	

	porcentagemFeminina := (valorFeminino/valorTotal) * 100;
	porcentagemMasculina := (valorMasculino/valorTotal) * 100;

	RAISE NOTICE 'porcentagem feminina: %, porcentagem masculina: %',
	porcentagemFeminina, porcentagemMasculina;
END;	
$$

DO $$
DECLARE
	porcentagemFeminina FLOAT;
	porcentagemMasculina FLOAT;
BEGIN
	CALL porcentagemSexo(porcentagemFeminina,porcentagemMasculina);
END;
$$

-- 1.4.3 Recebe um sexo como parâmetro em modo IN e utiliza oito parâmetros em modo OUT para dizer qual o percentual de cada nota (variável grade) obtida por estudantes daquele sexo.

CREATE OR REPLACE PROCEDURE percentualNotasGenero(IN genero INT, OUT fail NUMERIC, OUT dd NUMERIC, OUT dc NUMERIC, OUT cc NUMERIC, OUT cb NUMERIC, OUT bb NUMERIC, OUT ba NUMERIC, OUT aa NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    totalEstudantes INT;
    totalFail INT := 0;
    totalDD INT := 0;
    totalDC INT := 0;
    totalCC INT := 0;
    totalCB INT := 0;
    totalBB INT := 0;
    totalBA INT := 0;
    totalAA INT := 0;
    r record;
BEGIN
    SELECT COUNT(grade) INTO totalEstudantes FROM student_prediction WHERE gender = genero;

    FOR r IN (SELECT grade FROM student_prediction WHERE gender = genero)
    LOOP
        CASE r.grade
            WHEN 0 THEN totalFail := totalFail + 1;
            WHEN 1 THEN totalDD := totalDD + 1;
            WHEN 2 THEN totalDC := totalDC + 1;
            WHEN 3 THEN totalCC := totalCC + 1;
            WHEN 4 THEN totalCB := totalCB + 1;
            WHEN 5 THEN totalBB := totalBB + 1;
            WHEN 6 THEN totalBA := totalBA + 1;
            WHEN 7 THEN totalAA := totalAA + 1;
        END CASE;
    END LOOP;

    fail := ROUND((totalFail * 100.0) / totalEstudantes, 1);
    dd := ROUND((totalDD * 100.0) / totalEstudantes, 1);
    dc := ROUND((totalDC * 100.0) / totalEstudantes, 1);
    cc := ROUND((totalCC * 100.0) / totalEstudantes, 1);
    cb := ROUND((totalCB * 100.0) / totalEstudantes, 1);
    bb := ROUND((totalBB * 100.0) / totalEstudantes, 1);
    ba := ROUND((totalBA * 100.0) / totalEstudantes, 1);
    aa := ROUND((totalAA * 100.0) / totalEstudantes, 1);
    
    RAISE NOTICE 'percentual de estudantes do genero % que obtiveram cada nota -> | Fail: % | DD: % | DC: % | CC: % | CB: % | BB: % | BA: % | AA: % |', genero, fail, dd, dc, cc, cb, bb, ba, aa;
END;
$$;

DO $$
DECLARE
    fail NUMERIC;
    dd NUMERIC;
    dc NUMERIC;
    cc NUMERIC;
    cb NUMERIC;
    bb NUMERIC;
    ba NUMERIC;
    aa NUMERIC;
BEGIN
	RAISE NOTICE 'genero 1 = feminino; genero 2 = masculino.';
    CALL percentualNotasGenero(1, fail, dd, dc, cc, cb, bb, ba, aa);
	CALL percentualNotasGenero(2, fail, dd, dc, cc, cb, bb, ba, aa);
END;
$$;

-- 1.5 Escreva as seguintes functions (incluindo um bloco anônimo de teste para cada uma):

-- 1.5.1 Responde (devolve boolean) se é verdade que todos os estudantes de renda acima de 410 são aprovados (grade > 0).


CREATE OR REPLACE FUNCTION teste_renda_aprovados () RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
	i record;
	teste BOOLEAN;
BEGIN
    FOR i IN (SELECT grade FROM student_prediction WHERE salary > 4) LOOP
		CASE i.grade
           WHEN 0 THEN teste := FALSE;
		ELSE
			teste := TRUE;
		END CASE;
	END LOOP;
	RETURN teste;
END;
$$

DO $$
DECLARE
	resultado BOOLEAN;
BEGIN
	SELECT teste_renda_aprovados ( ) INTO resultado;
	RAISE NOTICE '%', resultado;
END;
$$;

-- 1.5.2 Responde (devolve boolean) se é verdade que, entre os estudantes que fazem anotações pelo menos algumas vezes durante as aulas, pelo menos 70% são aprovados (grade > 0).



-- 1.5.3 Devolve o percentual de alunos que se preparam pelo menos um pouco para os “midterm exams” e que são aprovados (grade > 0).

