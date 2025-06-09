/*
FUNÇÃO CRIADA PARA LISTAR AS PESSOAS DESAPARECIDAS
---------------
-- Drop da função (deve vir primeiro para evitar erro por dependência nos tipos)
DROP FUNCTION "FUN_REL_PESSOAS_DESAPARECIDAS";

-- Drop do tipo TABLE (precisa ser antes do tipo OBJECT que ele usa)
DROP TYPE "T_PESSOA_DESAPARECIDA";

-- Drop do tipo OBJECT
DROP TYPE "T_PESSOA_DESAPARECIDA_OBJ";
*/
---------------
-- Objeto com os dados da pessoa desaparecida
CREATE OR REPLACE TYPE "T_PESSOA_DESAPARECIDA_OBJ" AS OBJECT (
    "nm_pessoa"     VARCHAR2(100),
    "nr_cpf"        VARCHAR2(14),
    "nm_cidade"     VARCHAR2(100),
    "nm_abrigo"     VARCHAR2(100),
    "dt_entrada"    DATE
);
/
---------------
-- Tabela do tipo objeto
CREATE OR REPLACE TYPE "T_PESSOA_DESAPARECIDA" AS TABLE OF "T_PESSOA_DESAPARECIDA_OBJ";
/
---------------
CREATE OR REPLACE FUNCTION "FUN_REL_PESSOAS_DESAPARECIDAS"
RETURN "T_PESSOA_DESAPARECIDA" IS
    v_resultado "T_PESSOA_DESAPARECIDA" := "T_PESSOA_DESAPARECIDA"();

    CURSOR cur_desaparecidos IS
        SELECT
            p."nm_pessoa",
            p."nr_cpf",
            c."nm_cidade",
            a."nm_abrigo",
            ci."dt_entrada"
        FROM "t_gsab_pessoa" p
        JOIN "t_gsab_endereco" e ON p."id_endereco" = e."id_endereco"
        JOIN "t_gsab_cidade" c ON e."id_cidade" = c."id_cidade"
        LEFT JOIN "t_gsab_check_in" ci ON p."id_pessoa" = ci."id_pessoa" AND ci."dt_saida" IS NULL
        LEFT JOIN "t_gsab_abrigo" a ON ci."id_abrigo" = a."id_abrigo"
        WHERE p."st_desaparecido" = 'S';

BEGIN
    FOR r IN cur_desaparecidos LOOP
        v_resultado.EXTEND;
        v_resultado(v_resultado.COUNT) := "T_PESSOA_DESAPARECIDA_OBJ"(
            r."nm_pessoa",
            r."nr_cpf",
            r."nm_cidade",
            r."nm_abrigo",
            r."dt_entrada"
        );
    END LOOP;

    RETURN v_resultado;
END;
/
---------------
--Testando a função
SELECT * FROM TABLE("FUN_REL_PESSOAS_DESAPARECIDAS");
--------------------------------------------------------------------------------------------------------------------------------
--FUNÇÃO CRIADA PARA LISTAR OS CHECK-IN'S ATIVOS
---------------
/*
-- Drop da função (primeiro, pois depende dos tipos)
DROP FUNCTION "FUN_REL_CHECKINS_ATIVOS";

-- Drop do tipo TABLE (vem antes do tipo OBJECT)
DROP TYPE "T_CHECKIN_ATIVO";

-- Drop do tipo OBJECT
DROP TYPE "T_CHECKIN_ATIVO_OBJ";
*/

---------------
-- Objeto com dados do check-in ativo
CREATE OR REPLACE TYPE "T_CHECKIN_ATIVO_OBJ" AS OBJECT (
    "nm_pessoa"   VARCHAR2(100),
    "nr_cpf"      VARCHAR2(14),
    "nm_abrigo"   VARCHAR2(100),
    "dt_entrada"  DATE
);
/
---------------
-- Tabela do tipo objeto
CREATE OR REPLACE TYPE "T_CHECKIN_ATIVO" AS TABLE OF "T_CHECKIN_ATIVO_OBJ";
/
---------------
CREATE OR REPLACE FUNCTION "FUN_REL_CHECKINS_ATIVOS"
RETURN "T_CHECKIN_ATIVO" IS
    v_resultado "T_CHECKIN_ATIVO" := "T_CHECKIN_ATIVO"();

    CURSOR cur_checkin IS
        SELECT
            p."nm_pessoa",
            p."nr_cpf",
            a."nm_abrigo",
            c."dt_entrada"
        FROM "t_gsab_check_in" c
        JOIN "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
        JOIN "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
        WHERE c."dt_saida" IS NULL;

BEGIN
    FOR r IN cur_checkin LOOP
        v_resultado.EXTEND;
        v_resultado(v_resultado.COUNT) := "T_CHECKIN_ATIVO_OBJ"(
            r."nm_pessoa",
            r."nr_cpf",
            r."nm_abrigo",
            r."dt_entrada"
        );
    END LOOP;

    RETURN v_resultado;
END;
/
---------------
SELECT * FROM TABLE("FUN_REL_CHECKINS_ATIVOS");

