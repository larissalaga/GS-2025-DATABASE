-- 1. LIMPEZA (DROP DE OBJETOS)
/*
-- Removendo procedures de CRUD
DROP PROCEDURE "proc_inserir_pessoa";
DROP PROCEDURE "proc_atualizar_pessoa";
DROP PROCEDURE "proc_excluir_pessoa";
DROP PROCEDURE "proc_inserir_usuario";
DROP PROCEDURE "proc_atualizar_usuario";
DROP PROCEDURE "proc_excluir_usuario";
DROP PROCEDURE "proc_inserir_abrigo";
DROP PROCEDURE "proc_atualizar_abrigo";
DROP PROCEDURE "proc_excluir_abrigo";
DROP PROCEDURE "proc_inserir_recurso";
DROP PROCEDURE "proc_atualizar_recurso";
DROP PROCEDURE "proc_excluir_recurso";
DROP PROCEDURE "proc_inserir_estoque_recurso";
DROP PROCEDURE "proc_atualizar_estoque_recurso";
DROP PROCEDURE "proc_excluir_estoque_recurso";
DROP PROCEDURE "proc_inserir_checkin";
DROP PROCEDURE "proc_atualizar_checkin";
DROP PROCEDURE "proc_excluir_checkin";
DROP PROCEDURE "proc_inserir_pais";
DROP PROCEDURE "proc_atualizar_pais";
DROP PROCEDURE "proc_excluir_pais";
DROP PROCEDURE "proc_inserir_estado";
DROP PROCEDURE "proc_atualizar_estado";
DROP PROCEDURE "proc_excluir_estado";
DROP PROCEDURE "proc_inserir_cidade";
DROP PROCEDURE "proc_atualizar_cidade";
DROP PROCEDURE "proc_excluir_cidade";
DROP PROCEDURE "proc_inserir_endereco";
DROP PROCEDURE "proc_atualizar_endereco";
DROP PROCEDURE "proc_excluir_endereco";
DROP PROCEDURE "proc_inserir_tipo_usuario";
DROP PROCEDURE "proc_atualizar_tipo_usuario";
DROP PROCEDURE "proc_excluir_tipo_usuario";

-- Removendo procedures de relatórios
DROP PROCEDURE "verificar_desaparecimento_por_cpf";
DROP PROCEDURE "verificar_estoque_para_reposicao";
DROP PROCEDURE "avaliar_lotacao_abrigo";
DROP PROCEDURE "verificar_pessoas_risco_idade";
DROP PROCEDURE "verificar_checkin_prolongado";

-- Removendo funções (na ordem de dependência)
DROP FUNCTION "FUN_REL_PESSOAS_DESAPARECIDAS";
DROP FUNCTION "FUN_REL_CHECKINS_ATIVOS";
DROP FUNCTION "FUN_VALIDA_CPF";
DROP FUNCTION "FUN_VALIDA_NASCIMENTO";
DROP FUNCTION "FUN_VALIDA_TELEFONE";
DROP FUNCTION "FUN_VALIDA_EMAIL";
DROP FUNCTION "FUN_VALIDA_SEXO";
DROP FUNCTION "FUN_SOMENTE_NUMEROS";

-- Removendo tipos (tabelas antes de objetos)
DROP TYPE "T_PESSOA_DESAPARECIDA";
DROP TYPE "T_PESSOA_DESAPARECIDA_OBJ";
DROP TYPE "T_CHECKIN_ATIVO";
DROP TYPE "T_CHECKIN_ATIVO_OBJ";

-- Removendo triggers
DROP TRIGGER "trg_valida_estoque_nao_negativo";
DROP TRIGGER "trg_atualiza_ocupacao_checkin";
*/

------------------------------------------------------------------------------------------------------------------------
-- 2. TIPOS PARA RELATÓRIOS (TYPES)

-- TIPO PARA RELATÓRIO DE PESSOAS DESAPARECIDAS
CREATE OR REPLACE TYPE "T_PESSOA_DESAPARECIDA_OBJ" AS OBJECT (
    "nm_pessoa"     VARCHAR2(100),
    "nr_cpf"        VARCHAR2(14),
    "nm_cidade"     VARCHAR2(100),
    "nm_abrigo"     VARCHAR2(100),
    "dt_entrada"    DATE
);
/

CREATE OR REPLACE TYPE "T_PESSOA_DESAPARECIDA" AS TABLE OF "T_PESSOA_DESAPARECIDA_OBJ";
/

-- TIPO PARA RELATÓRIO DE CHECK-INS ATIVOS
CREATE OR REPLACE TYPE "T_CHECKIN_ATIVO_OBJ" AS OBJECT (
    "nm_pessoa"   VARCHAR2(100),
    "nr_cpf"      VARCHAR2(14),
    "nm_abrigo"   VARCHAR2(100),
    "dt_entrada"  DATE
);
/

CREATE OR REPLACE TYPE "T_CHECKIN_ATIVO" AS TABLE OF "T_CHECKIN_ATIVO_OBJ";
/
------------------------------------------------------------------------------------------------------------------------
-- 3. FUNÇÕES (FUNCTIONS)

-- FUNÇÃO UTILITÁRIA: "FUN_SOMENTE_NUMEROS"
CREATE OR REPLACE FUNCTION "FUN_SOMENTE_NUMEROS"(
    "valor" VARCHAR2
) RETURN VARCHAR2 IS
    "resultado" VARCHAR2(4000);
BEGIN
    "resultado" := REGEXP_REPLACE("valor", '[^0-9]', '');
    RETURN "resultado";
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Erro ao limpar valor: ' || SQLERRM);
        RETURN NULL;
END;
/

-- FUNÇÃO DE VALIDAÇÃO: "FUN_VALIDA_CPF"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_CPF"(
    "cpf" VARCHAR2
) RETURN BOOLEAN IS
    "cpf_limpo" VARCHAR2(11);
    "sum1"      NUMBER := 0;
    "sum2"      NUMBER := 0;
    "digit1"    NUMBER;
    "digit2"    NUMBER;
    "i"         NUMBER;
BEGIN
    "cpf_limpo" := "FUN_SOMENTE_NUMEROS"("cpf");
    IF LENGTH("cpf_limpo") != 11 OR NOT REGEXP_LIKE("cpf_limpo", '^\d{11}$') THEN
        RETURN FALSE;
    END IF;
    IF "cpf_limpo" = LPAD(SUBSTR("cpf_limpo", 1, 1), 11, SUBSTR("cpf_limpo", 1, 1)) THEN
        RETURN FALSE;
    END IF;
    FOR "i" IN 1..9 LOOP
        "sum1" := "sum1" + TO_NUMBER(SUBSTR("cpf_limpo", "i", 1)) * (11 - "i");
    END LOOP;
    "digit1" := MOD(("sum1" * 10), 11);
    IF "digit1" = 10 THEN
        "digit1" := 0;
    END IF;
    IF "digit1" != TO_NUMBER(SUBSTR("cpf_limpo", 10, 1)) THEN
        RETURN FALSE;
    END IF;
    FOR "i" IN 1..10 LOOP
        "sum2" := "sum2" + TO_NUMBER(SUBSTR("cpf_limpo", "i", 1)) * (12 - "i");
    END LOOP;
    "digit2" := MOD(("sum2" * 10), 11);
    IF "digit2" = 10 THEN
        "digit2" := 0;
    END IF;
    IF "digit2" != TO_NUMBER(SUBSTR("cpf_limpo", 11, 1)) THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Erro na validação do CPF: ' || SQLERRM);
        RETURN FALSE;
END;
/

-- FUNÇÃO DE VALIDAÇÃO: "FUN_VALIDA_NASCIMENTO"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_NASCIMENTO"(
    "data_nascimento" DATE
) RETURN BOOLEAN IS
BEGIN
    IF "data_nascimento" < TO_DATE('01/01/1900', 'DD/MM/YYYY') OR "data_nascimento" > CURRENT_DATE THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro na validação da data de nascimento: ' || SQLERRM);
        RETURN FALSE;
END;
/

-- FUNÇÃO DE VALIDAÇÃO: "FUN_VALIDA_TELEFONE"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_TELEFONE"(
    "telefone" VARCHAR2
) RETURN BOOLEAN IS
    "telefone_limpo" VARCHAR2(11);
BEGIN
    "telefone_limpo" := "FUN_SOMENTE_NUMEROS"("telefone");
    IF LENGTH("telefone_limpo") != 11 OR NOT REGEXP_LIKE("telefone_limpo", '^\d{11}$') THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro na validação do telefone: ' || SQLERRM);
        RETURN FALSE;
END;
/

-- FUNÇÃO DE VALIDAÇÃO: "FUN_VALIDA_EMAIL"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_EMAIL"(
    "email" VARCHAR2
) RETURN BOOLEAN IS
BEGIN
    RETURN REGEXP_LIKE(
        "email",
        '^[A-Za-z0-9._%-]+@[A-Za-z0-9-]+(.[A-Za-z0-9-]+)*.[A-Za-z]{2,}$',
        'c'
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro na validação do e-mail: ' || SQLERRM);
        RETURN FALSE;
END;
/

-- FUNÇÃO DE VALIDAÇÃO: "FUN_VALIDA_SEXO"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_SEXO"(
    "sexo" VARCHAR2
) RETURN BOOLEAN IS
BEGIN
    RETURN UPPER("sexo") IN ('M', 'F', 'N');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Erro na validação do sexo: ' || SQLERRM);
        RETURN FALSE;
END;
/

-- FUNÇÃO DE RELATÓRIO: "FUN_REL_PESSOAS_DESAPARECIDAS"
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

-- FUNÇÃO DE RELATÓRIO: "FUN_REL_CHECKINS_ATIVOS"
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
------------------------------------------------------------------------------------------------------------------------
-- 4. PROCEDIMENTOS (PROCEDURES)

-- CRUD PAÍS
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_pais" (
    "p_nm_pais" IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    pais_exists   EXCEPTION;
    "v_pais_id"   NUMBER;
BEGIN
    -- 1. Verifica duplicidade
    BEGIN
        SELECT "id_pais"
        INTO "v_pais_id"
        FROM "t_gsab_pais"
        WHERE "nm_pais" = "p_nm_pais";

        RAISE pais_exists;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- OK, país não existe.
    END;

    -- 2. Insere o país
    INSERT INTO "t_gsab_pais" ("id_pais", "nm_pais")
    VALUES (seq_t_gsab_pais.NEXTVAL, "p_nm_pais");

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('País inserido com sucesso: ' || "p_nm_pais");

EXCEPTION
    WHEN pais_exists THEN
        RAISE_APPLICATION_ERROR(-20001, 'País já cadastrado: ' || "p_nm_pais");
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao inserir país: ' || SQLERRM);
END "proc_inserir_pais";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_pais" (
    "p_id_pais" IN "t_gsab_pais"."id_pais"%TYPE,
    "p_nm_pais" IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    pais_nao_encontrado EXCEPTION;
    v_id_existente NUMBER;
BEGIN
    BEGIN
        SELECT "id_pais" INTO v_id_existente
          FROM "t_gsab_pais"
         WHERE "id_pais" = "p_id_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pais_nao_encontrado;
    END;

    UPDATE "t_gsab_pais"
       SET "nm_pais" = "p_nm_pais"
     WHERE "id_pais" = "p_id_pais";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('País atualizado com sucesso: ID = ' || "p_id_pais");
EXCEPTION
    WHEN pais_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'País com ID ' || "p_id_pais" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Erro ao atualizar país: ' || SQLERRM);
END "proc_atualizar_pais";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_pais" (
    "p_id_pais" IN "t_gsab_pais"."id_pais"%TYPE
) IS
    pais_nao_encontrado EXCEPTION;
    pais_em_uso         EXCEPTION;
    v_id_pais           NUMBER;
    v_tem_vinculo       NUMBER;
BEGIN
    BEGIN
        SELECT "id_pais" INTO v_id_pais
          FROM "t_gsab_pais"
         WHERE "id_pais" = "p_id_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pais_nao_encontrado;
    END;

    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_estado"
         WHERE "id_pais" = v_id_pais
           AND ROWNUM = 1;
        RAISE pais_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    DELETE FROM "t_gsab_pais"
     WHERE "id_pais" = v_id_pais;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('País excluído com sucesso. ID: ' || "p_id_pais");
EXCEPTION
    WHEN pais_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20080, 'País com ID ' || "p_id_pais" || ' não encontrado.');
    WHEN pais_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20081, 'Não é possível excluir o país. Existem estados vinculados.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20082, 'Erro ao excluir país: ' || SQLERRM);
END "proc_excluir_pais";
/

-- CRUD ESTADO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_estado" (
  "p_nm_estado" IN "t_gsab_estado"."nm_estado"%TYPE,
  "p_nm_pais"   IN "t_gsab_pais"."nm_pais"%TYPE
) IS
  estado_exists EXCEPTION;
  v_estado_id   NUMBER;
  v_pais_id     NUMBER;
BEGIN
  BEGIN
    SELECT e."id_estado" INTO v_estado_id
      FROM "t_gsab_estado" e
      JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
     WHERE e."nm_estado" = "p_nm_estado" AND p."nm_pais" = "p_nm_pais";
     RAISE estado_exists;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;

  BEGIN
    SELECT "id_pais" INTO v_pais_id
      FROM "t_gsab_pais"
     WHERE "nm_pais" = "p_nm_pais";
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      "proc_inserir_pais"("p_nm_pais");
      SELECT "id_pais" INTO v_pais_id
        FROM "t_gsab_pais"
       WHERE "nm_pais" = "p_nm_pais";
  END;

  INSERT INTO "t_gsab_estado" ("id_estado","nm_estado","id_pais") VALUES (
    seq_t_gsab_estado.NEXTVAL, "p_nm_estado", v_pais_id
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Estado inserido com sucesso: ' || "p_nm_estado");
EXCEPTION
  WHEN estado_exists THEN
    RAISE_APPLICATION_ERROR(-20001, 'Estado já cadastrado para esse país.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20000, 'Erro ao inserir estado: ' || SQLERRM);
END "proc_inserir_estado";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_estado" (
    "p_id_estado" IN "t_gsab_estado"."id_estado"%TYPE,
    "p_nm_estado" IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"   IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    estado_nao_encontrado EXCEPTION;
    duplicado_estado      EXCEPTION;
    v_pais_id             NUMBER;
    v_estado_existente    NUMBER;
BEGIN
    BEGIN
        SELECT "id_estado" INTO v_estado_existente
          FROM "t_gsab_estado"
         WHERE "id_estado" = "p_id_estado";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estado_nao_encontrado;
    END;

    BEGIN
        SELECT e."id_estado" INTO v_estado_existente
          FROM "t_gsab_estado" e
          JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
         WHERE e."nm_estado" = "p_nm_estado"
           AND p."nm_pais"   = "p_nm_pais"
           AND e."id_estado" <> "p_id_estado";
        RAISE duplicado_estado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    BEGIN
        SELECT "id_pais" INTO v_pais_id
          FROM "t_gsab_pais"
         WHERE "nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_pais"("p_nm_pais");
            SELECT "id_pais" INTO v_pais_id
              FROM "t_gsab_pais"
             WHERE "nm_pais" = "p_nm_pais";
    END;

    UPDATE "t_gsab_estado"
       SET "nm_estado" = "p_nm_estado", "id_pais"   = v_pais_id
     WHERE "id_estado" = "p_id_estado";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estado atualizado com sucesso. ID = ' || "p_id_estado");
EXCEPTION
    WHEN estado_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Estado com ID ' || "p_id_estado" || ' não encontrado.');
    WHEN duplicado_estado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Já existe outro estado com esse nome neste país.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Erro ao atualizar estado: ' || SQLERRM);
END "proc_atualizar_estado";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_estado" (
    "p_id_estado" IN "t_gsab_estado"."id_estado"%TYPE
) IS
    estado_nao_encontrado EXCEPTION;
    estado_em_uso         EXCEPTION;
    v_id_estado           NUMBER;
    v_tem_vinculo         NUMBER;
BEGIN
    BEGIN
        SELECT "id_estado" INTO v_id_estado
          FROM "t_gsab_estado"
         WHERE "id_estado" = "p_id_estado";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estado_nao_encontrado;
    END;

    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_cidade"
         WHERE "id_estado" = v_id_estado
           AND ROWNUM = 1;
        RAISE estado_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    DELETE FROM "t_gsab_estado"
     WHERE "id_estado" = v_id_estado;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estado excluído com sucesso. ID: ' || "p_id_estado");
EXCEPTION
    WHEN estado_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20070, 'Estado com ID ' || "p_id_estado" || ' não encontrado.');
    WHEN estado_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20071, 'Não é possível excluir o estado. Há cidades vinculadas.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20072, 'Erro ao excluir estado: ' || SQLERRM);
END "proc_excluir_estado";
/

-- CRUD CIDADE
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_cidade" (
    "p_nm_cidade" IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado" IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"   IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    cidade_exists EXCEPTION;
    "v_cidade_id" NUMBER;
    "v_estado_id" NUMBER;
BEGIN
    BEGIN
        SELECT c."id_cidade" INTO "v_cidade_id"
          FROM "t_gsab_cidade" c
          JOIN "t_gsab_estado" e ON c."id_estado" = e."id_estado"
          JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
         WHERE c."nm_cidade" = "p_nm_cidade"
           AND e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais";
        RAISE cidade_exists;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    BEGIN
        SELECT e."id_estado" INTO "v_estado_id"
            FROM "t_gsab_estado" e
            JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
            WHERE e."nm_estado" = "p_nm_estado"
            AND p."nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_estado"("p_nm_estado", "p_nm_pais");
            SELECT e."id_estado" INTO "v_estado_id"
            FROM "t_gsab_estado" e
            JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
            WHERE e."nm_estado" = "p_nm_estado"
            AND p."nm_pais" = "p_nm_pais";
    END;

    INSERT INTO "t_gsab_cidade" ("id_cidade", "nm_cidade", "id_estado")
    VALUES (seq_t_gsab_cidade.NEXTVAL, "p_nm_cidade", "v_estado_id");
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cidade inserida com sucesso: ' || "p_nm_cidade");
EXCEPTION
    WHEN cidade_exists THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cidade já cadastrada para esse estado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20000, 'Erro ao inserir cidade: ' || SQLERRM);
END "proc_inserir_cidade";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_cidade" (
    "p_id_cidade"  IN "t_gsab_cidade"."id_cidade"%TYPE,
    "p_nm_cidade"  IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"  IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"    IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    cidade_nao_encontrada EXCEPTION;
    duplicado_cidade      EXCEPTION;
    v_estado_id           NUMBER;
    v_cidade_exists       NUMBER;
BEGIN
    BEGIN
        SELECT "id_cidade" INTO v_cidade_exists
          FROM "t_gsab_cidade"
         WHERE "id_cidade" = "p_id_cidade";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE cidade_nao_encontrada;
    END;

    BEGIN
        SELECT c."id_cidade" INTO v_cidade_exists
          FROM "t_gsab_cidade" c
          JOIN "t_gsab_estado" e ON c."id_estado" = e."id_estado"
          JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
         WHERE c."nm_cidade" = "p_nm_cidade"
           AND e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais"
           AND c."id_cidade" <> "p_id_cidade";
        RAISE duplicado_cidade;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    BEGIN
        SELECT e."id_estado" INTO v_estado_id
          FROM "t_gsab_estado" e
          JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
         WHERE e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_estado"("p_nm_estado", "p_nm_pais");
            SELECT e."id_estado" INTO v_estado_id
              FROM "t_gsab_estado" e
              JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
             WHERE e."nm_estado" = "p_nm_estado"
               AND p."nm_pais" = "p_nm_pais";
    END;

    UPDATE "t_gsab_cidade"
       SET "nm_cidade" = "p_nm_cidade", "id_estado" = v_estado_id
     WHERE "id_cidade" = "p_id_cidade";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cidade atualizada com sucesso. ID = ' || "p_id_cidade");
EXCEPTION
    WHEN cidade_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, 'Cidade com ID ' || "p_id_cidade" || ' não encontrada.');
    WHEN duplicado_cidade THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Já existe outra cidade com esse nome neste estado e país.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Erro ao atualizar cidade: ' || SQLERRM);
END "proc_atualizar_cidade";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_cidade" (
    "p_id_cidade" IN "t_gsab_cidade"."id_cidade"%TYPE
) IS
    cidade_nao_encontrada EXCEPTION;
    cidade_em_uso         EXCEPTION;
    v_id_cidade           NUMBER;
    v_tem_vinculo         NUMBER;
BEGIN
    BEGIN
        SELECT "id_cidade" INTO v_id_cidade
          FROM "t_gsab_cidade"
         WHERE "id_cidade" = "p_id_cidade";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE cidade_nao_encontrada;
    END;

    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_endereco"
         WHERE "id_cidade" = v_id_cidade
           AND ROWNUM = 1;
        RAISE cidade_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    DELETE FROM "t_gsab_cidade"
     WHERE "id_cidade" = v_id_cidade;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cidade excluída com sucesso. ID: ' || "p_id_cidade");
EXCEPTION
    WHEN cidade_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Cidade com ID ' || "p_id_cidade" || ' não encontrada.');
    WHEN cidade_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20051, 'Não é possível excluir a cidade. Há endereços vinculados.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20052, 'Erro ao excluir cidade: ' || SQLERRM);
END "proc_excluir_cidade";
/

-- CRUD ENDEREÇO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_endereco" (
    "p_ds_cep"          IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"   IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"       IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"  IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"       IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"       IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"         IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_endereco_id"     OUT NUMBER
) IS
    "v_cidade_id"   NUMBER;
BEGIN
    BEGIN
        SELECT c."id_cidade" INTO "v_cidade_id"
          FROM "t_gsab_cidade" c
          JOIN "t_gsab_estado" e ON c."id_estado" = e."id_estado"
          JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
         WHERE c."nm_cidade" = "p_nm_cidade"
           AND e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_cidade"("p_nm_cidade", "p_nm_estado", "p_nm_pais");
            SELECT c."id_cidade" INTO "v_cidade_id"
              FROM "t_gsab_cidade" c
              JOIN "t_gsab_estado" e ON c."id_estado" = e."id_estado"
              JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
             WHERE c."nm_cidade" = "p_nm_cidade"
               AND e."nm_estado" = "p_nm_estado"
               AND p."nm_pais" = "p_nm_pais";
    END;

    INSERT INTO "t_gsab_endereco" (
        "id_endereco", "ds_cep", "ds_logradouro", "nr_numero", "ds_complemento", "id_cidade"
    ) VALUES (
        seq_t_gsab_endereco.NEXTVAL, "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento", "v_cidade_id"
    );
    COMMIT;
    "p_endereco_id" := seq_t_gsab_endereco.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Endereço inserido. ID: ' || "p_endereco_id");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20000, 'Erro ao inserir endereço: ' || SQLERRM);
END "proc_inserir_endereco";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_endereco" (
    "p_id_endereco"       IN "t_gsab_endereco"."id_endereco"%TYPE,
    "p_ds_cep"            IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"     IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"         IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"    IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"         IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"         IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"           IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    endereco_nao_encontrado EXCEPTION;
    v_cidade_id            NUMBER;
    v_endereco_id          NUMBER;
BEGIN
    BEGIN
        SELECT "id_endereco" INTO v_endereco_id
          FROM "t_gsab_endereco"
         WHERE "id_endereco" = "p_id_endereco";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE endereco_nao_encontrado;
    END;

    BEGIN
        SELECT c."id_cidade" INTO v_cidade_id
          FROM "t_gsab_cidade" c
          JOIN "t_gsab_estado" e ON c."id_estado" = e."id_estado"
          JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
         WHERE c."nm_cidade" = "p_nm_cidade"
           AND e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_cidade"("p_nm_cidade", "p_nm_estado", "p_nm_pais");
            SELECT c."id_cidade" INTO v_cidade_id
              FROM "t_gsab_cidade" c
              JOIN "t_gsab_estado" e ON c."id_estado" = e."id_estado"
              JOIN "t_gsab_pais" p ON e."id_pais" = p."id_pais"
             WHERE c."nm_cidade" = "p_nm_cidade"
               AND e."nm_estado" = "p_nm_estado"
               AND p."nm_pais" = "p_nm_pais";
    END;

    UPDATE "t_gsab_endereco"
       SET "ds_cep" = "p_ds_cep", "ds_logradouro" = "p_ds_logradouro", "nr_numero" = "p_nr_numero",
           "ds_complemento" = "p_ds_complemento", "id_cidade" = v_cidade_id
     WHERE "id_endereco" = "p_id_endereco";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Endereço atualizado com sucesso. ID = ' || "p_id_endereco");
EXCEPTION
    WHEN endereco_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'Endereço com ID ' || "p_id_endereco" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20031, 'Erro ao atualizar endereço: ' || SQLERRM);
END "proc_atualizar_endereco";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_endereco" (
    "p_id_endereco" IN "t_gsab_endereco"."id_endereco"%TYPE
) IS
    endereco_nao_encontrado EXCEPTION;
    endereco_em_uso         EXCEPTION;
    v_id_endereco           NUMBER;
    v_tem_vinculo           NUMBER;
BEGIN
    BEGIN
        SELECT "id_endereco" INTO v_id_endereco
          FROM "t_gsab_endereco"
         WHERE "id_endereco" = "p_id_endereco";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE endereco_nao_encontrado;
    END;

    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_pessoa"
         WHERE "id_endereco" = v_id_endereco AND ROWNUM = 1;
        RAISE endereco_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_abrigo"
         WHERE "id_endereco" = v_id_endereco AND ROWNUM = 1;
        RAISE endereco_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    DELETE FROM "t_gsab_endereco"
     WHERE "id_endereco" = v_id_endereco;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Endereço excluído com sucesso. ID: ' || "p_id_endereco");
EXCEPTION
    WHEN endereco_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20094, 'Endereço com ID ' || "p_id_endereco" || ' não encontrado.');
    WHEN endereco_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20095, 'Não é possível excluir o endereço. Ele está vinculado a pessoa ou abrigo.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20096, 'Erro ao excluir endereço: ' || SQLERRM);
END "proc_excluir_endereco";
/

-- CRUD PESSOA
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_pessoa" (
    "p_nm_pessoa"           IN "t_gsab_pessoa"."nm_pessoa"%TYPE,
    "p_nr_cpf"              IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_dt_nascimento"       IN "t_gsab_pessoa"."dt_nascimento"%TYPE,
    "p_ds_condicao_medica"  IN "t_gsab_pessoa"."ds_condicao_medica"%TYPE,
    "p_st_desaparecido"     IN "t_gsab_pessoa"."st_desaparecido"%TYPE,
    "p_nm_emergencial"      IN "t_gsab_pessoa"."nm_emergencial"%TYPE,
    "p_contato_emergencia"  IN "t_gsab_pessoa"."contato_emergencia"%TYPE,
    "p_ds_cep"              IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"       IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"           IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"      IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"           IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"           IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"             IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_pessoa_id"           OUT NUMBER
) IS
    "v_endereco_id"     NUMBER;
    "v_pessoa_id"       NUMBER;
    cpf_ja_cadastrado   EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_pessoa" INTO "v_pessoa_id"
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";
        RAISE cpf_ja_cadastrado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento",
        "p_nm_cidade", "p_nm_estado", "p_nm_pais", "v_endereco_id"
    );

    INSERT INTO "t_gsab_pessoa" (
        "id_pessoa", "nm_pessoa", "nr_cpf", "dt_nascimento", "ds_condicao_medica",
        "st_desaparecido", "nm_emergencial", "contato_emergencia", "id_endereco"
    ) VALUES (
        seq_t_gsab_pessoa.NEXTVAL, "p_nm_pessoa", "p_nr_cpf", "p_dt_nascimento", "p_ds_condicao_medica",
        "p_st_desaparecido", "p_nm_emergencial", "p_contato_emergencia", "v_endereco_id"
    );
    COMMIT;
    "p_pessoa_id" := seq_t_gsab_pessoa.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Pessoa inserida com sucesso. ID: ' || "p_pessoa_id");
EXCEPTION
    WHEN cpf_ja_cadastrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'CPF já cadastrado: ' || "p_nr_cpf");
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Erro ao inserir pessoa: ' || SQLERRM);
END "proc_inserir_pessoa";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_pessoa" (
    "p_nr_cpf"              IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_nm_pessoa"           IN "t_gsab_pessoa"."nm_pessoa"%TYPE,
    "p_dt_nascimento"       IN "t_gsab_pessoa"."dt_nascimento"%TYPE,
    "p_ds_condicao_medica"  IN "t_gsab_pessoa"."ds_condicao_medica"%TYPE,
    "p_st_desaparecido"     IN "t_gsab_pessoa"."st_desaparecido"%TYPE,
    "p_nm_emergencial"      IN "t_gsab_pessoa"."nm_emergencial"%TYPE,
    "p_contato_emergencia"  IN "t_gsab_pessoa"."contato_emergencia"%TYPE,
    "p_ds_cep"              IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"       IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"           IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"      IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"           IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"           IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"             IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    "v_pessoa_id"    NUMBER;
    "v_endereco_id"  NUMBER;
    pessoa_nao_encontrada EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_pessoa" INTO "v_pessoa_id"
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pessoa_nao_encontrada;
    END;

    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento",
        "p_nm_cidade", "p_nm_estado", "p_nm_pais", "v_endereco_id"
    );

    UPDATE "t_gsab_pessoa"
       SET "nm_pessoa" = "p_nm_pessoa", "dt_nascimento" = "p_dt_nascimento",
           "ds_condicao_medica" = "p_ds_condicao_medica", "st_desaparecido" = "p_st_desaparecido",
           "nm_emergencial" = "p_nm_emergencial", "contato_emergencia" = "p_contato_emergencia",
           "id_endereco" = "v_endereco_id"
     WHERE "id_pessoa" = "v_pessoa_id";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pessoa atualizada com sucesso. ID: ' || "v_pessoa_id");
EXCEPTION
    WHEN pessoa_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, 'Pessoa com CPF ' || "p_nr_cpf" || ' não encontrada.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Erro ao atualizar pessoa: ' || SQLERRM);
END "proc_atualizar_pessoa";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_pessoa" (
    "p_id_pessoa" IN "t_gsab_pessoa"."id_pessoa"%TYPE
) IS
    v_id_existente NUMBER;
    pessoa_nao_encontrada EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_pessoa" INTO v_id_existente
          FROM "t_gsab_pessoa"
         WHERE "id_pessoa" = "p_id_pessoa";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pessoa_nao_encontrada;
    END;

    DELETE FROM "t_gsab_check_in" WHERE "id_pessoa" = "p_id_pessoa";
    DELETE FROM "t_gsab_usuario" WHERE "id_pessoa" = "p_id_pessoa";
    DELETE FROM "t_gsab_pessoa" WHERE "id_pessoa" = "p_id_pessoa";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pessoa e todos os seus vínculos foram excluídos com sucesso. ID: ' || "p_id_pessoa");
EXCEPTION
    WHEN pessoa_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Pessoa com ID ' || "p_id_pessoa" || ' não encontrada.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20023, 'Erro ao excluir pessoa: ' || SQLERRM);
END "proc_excluir_pessoa";
/

-- CRUD TIPO DE USUÁRIO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_tipo_usuario" (
    "p_ds_tipo_usuario"  IN "t_gsab_tipo_usuario"."ds_tipo_usuario"%TYPE,
    "p_id_tipo_usuario"  OUT NUMBER
) IS
BEGIN
    INSERT INTO "t_gsab_tipo_usuario" ("id_tipo_usuario", "ds_tipo_usuario")
    VALUES (seq_t_gsab_tipo_usuario.NEXTVAL, "p_ds_tipo_usuario");
    COMMIT;
    "p_id_tipo_usuario" := seq_t_gsab_tipo_usuario.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Tipo de usuário inserido. ID: ' || "p_id_tipo_usuario");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao inserir tipo de usuário: ' || SQLERRM);
END "proc_inserir_tipo_usuario";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_tipo_usuario" (
    "p_id_tipo_usuario"  IN "t_gsab_tipo_usuario"."id_tipo_usuario"%TYPE,
    "p_ds_tipo_usuario"  IN "t_gsab_tipo_usuario"."ds_tipo_usuario"%TYPE
) IS
    v_id_tipo_usuario_existente  NUMBER;
    tipo_usuario_nao_encontrado  EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_tipo_usuario" INTO v_id_tipo_usuario_existente
          FROM "t_gsab_tipo_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE tipo_usuario_nao_encontrado;
    END;

    UPDATE "t_gsab_tipo_usuario"
       SET "ds_tipo_usuario" = "p_ds_tipo_usuario"
     WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Tipo de usuário atualizado. ID: ' || "p_id_tipo_usuario");
EXCEPTION
    WHEN tipo_usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20040, 'Tipo de usuário com ID ' || "p_id_tipo_usuario" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20041, 'Erro ao atualizar tipo de usuário: ' || SQLERRM);
END "proc_atualizar_tipo_usuario";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_tipo_usuario" (
    "p_id_tipo_usuario" IN "t_gsab_tipo_usuario"."id_tipo_usuario"%TYPE
) IS
    tipo_usuario_nao_encontrado EXCEPTION;
    tipo_usuario_em_uso EXCEPTION;
    v_id_existente NUMBER;
    v_vinculo_existente NUMBER;
BEGIN
    BEGIN
        SELECT "id_tipo_usuario" INTO v_id_existente
          FROM "t_gsab_tipo_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE tipo_usuario_nao_encontrado;
    END;

    BEGIN
        SELECT 1 INTO v_vinculo_existente
          FROM "t_gsab_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario"
           AND ROWNUM = 1;
        RAISE tipo_usuario_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    DELETE FROM "t_gsab_tipo_usuario"
     WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Tipo de usuário excluído com sucesso. ID: ' || "p_id_tipo_usuario");
EXCEPTION
    WHEN tipo_usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20042, 'Tipo de usuário com ID ' || "p_id_tipo_usuario" || ' não encontrado.');
    WHEN tipo_usuario_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20043, 'Não é possível excluir o tipo de usuário. Existem usuários vinculados.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20044, 'Erro ao excluir tipo de usuário: ' || SQLERRM);
END "proc_excluir_tipo_usuario";
/

-- CRUD USUÁRIO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_usuario" (
    "p_nm_usuario"         IN "t_gsab_usuario"."nm_usuario"%TYPE,
    "p_ds_email"           IN "t_gsab_usuario"."ds_email"%TYPE,
    "p_ds_senha"           IN "t_gsab_usuario"."ds_senha"%TYPE,
    "p_ds_codigo_google"   IN "t_gsab_usuario"."ds_codigo_google"%TYPE,
    "p_id_tipo_usuario"    IN "t_gsab_usuario"."id_tipo_usuario"%TYPE,
    "p_nr_cpf"             IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_pessoa_id"          IN "t_gsab_pessoa"."id_pessoa"%TYPE,
    "p_id_usuario"         OUT NUMBER
) IS
    "v_id_pessoa" NUMBER;
BEGIN
    BEGIN
        SELECT "id_pessoa" INTO "v_id_pessoa"
        FROM "t_gsab_pessoa"
        WHERE "nr_cpf" = "p_nr_cpf" OR "id_pessoa" = "p_pessoa_id";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Pessoa com CPF ou ID informado não existe.');
    END;

    INSERT INTO "t_gsab_usuario" (
        "id_usuario", "nm_usuario", "ds_email", "ds_senha", "ds_codigo_google",
        "id_tipo_usuario", "id_pessoa"
    ) VALUES (
        seq_t_gsab_usuario.NEXTVAL, "p_nm_usuario", "p_ds_email", "p_ds_senha",
        "p_ds_codigo_google", "p_id_tipo_usuario", "v_id_pessoa"
    );
    COMMIT;
    "p_id_usuario" := seq_t_gsab_usuario.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Usuário inserido. ID: ' || "p_id_usuario");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Erro ao inserir usuário: ' || SQLERRM);
END "proc_inserir_usuario";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_usuario" (
    "p_id_usuario"         IN "t_gsab_usuario"."id_usuario"%TYPE,
    "p_nm_usuario"         IN "t_gsab_usuario"."nm_usuario"%TYPE,
    "p_ds_email"           IN "t_gsab_usuario"."ds_email"%TYPE,
    "p_ds_senha"           IN "t_gsab_usuario"."ds_senha"%TYPE,
    "p_ds_codigo_google"   IN "t_gsab_usuario"."ds_codigo_google"%TYPE,
    "p_id_tipo_usuario"    IN "t_gsab_usuario"."id_tipo_usuario"%TYPE
) IS
    usuario_nao_encontrado EXCEPTION;
    "v_id_existente" NUMBER;
BEGIN
    BEGIN
        SELECT "id_usuario" INTO "v_id_existente"
          FROM "t_gsab_usuario"
         WHERE "id_usuario" = "p_id_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE usuario_nao_encontrado;
    END;

    UPDATE "t_gsab_usuario"
       SET "nm_usuario" = "p_nm_usuario", "ds_email" = "p_ds_email", "ds_senha" = "p_ds_senha",
           "ds_codigo_google" = "p_ds_codigo_google", "id_tipo_usuario" = "p_id_tipo_usuario"
     WHERE "id_usuario" = "p_id_usuario";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Usuário atualizado com sucesso. ID: ' || "p_id_usuario");
EXCEPTION
    WHEN usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20031, 'Usuário com ID ' || "p_id_usuario" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20032, 'Erro ao atualizar usuário: ' || SQLERRM);
END "proc_atualizar_usuario";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_usuario" (
    "p_id_usuario" IN "t_gsab_usuario"."id_usuario"%TYPE
) IS
    usuario_nao_encontrado EXCEPTION;
    v_id_usuario  NUMBER;
BEGIN
    BEGIN
        SELECT "id_usuario" INTO v_id_usuario
          FROM "t_gsab_usuario"
         WHERE "id_usuario" = "p_id_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE usuario_nao_encontrado;
    END;

    DELETE FROM "t_gsab_usuario"
     WHERE "id_usuario" = v_id_usuario;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Usuário excluído com sucesso. ID: ' || "p_id_usuario");
EXCEPTION
    WHEN usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20033, 'Usuário com ID ' || "p_id_usuario" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20034, 'Erro ao excluir usuário: ' || SQLERRM);
END "proc_excluir_usuario";
/

-- CRUD ABRIGO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_abrigo" (
    "p_nm_abrigo"         IN "t_gsab_abrigo"."nm_abrigo"%TYPE,
    "p_nr_capacidade"     IN "t_gsab_abrigo"."nr_capacidade"%TYPE,
    "p_nr_ocupacao_atual" IN "t_gsab_abrigo"."nr_ocupacao_atual"%TYPE,
    "p_ds_cep"            IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"     IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"         IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"    IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"         IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"         IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"           IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_abrigo_id"         OUT NUMBER
) IS
    "v_endereco_id" NUMBER;
BEGIN
    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento",
        "p_nm_cidade", "p_nm_estado", "p_nm_pais", "v_endereco_id"
    );

    INSERT INTO "t_gsab_abrigo" (
        "id_abrigo", "nm_abrigo", "nr_capacidade", "nr_ocupacao_atual", "id_endereco"
    ) VALUES (
        seq_t_gsab_abrigo.NEXTVAL, "p_nm_abrigo", "p_nr_capacidade", "p_nr_ocupacao_atual", "v_endereco_id"
    );
    COMMIT;
    "p_abrigo_id" := seq_t_gsab_abrigo.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Abrigo inserido com sucesso. ID: ' || "p_abrigo_id");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20014, 'Erro ao inserir abrigo: ' || SQLERRM);
END "proc_inserir_abrigo";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_abrigo" (
    "p_id_abrigo"        IN "t_gsab_abrigo"."id_abrigo"%TYPE,
    "p_nm_abrigo"        IN "t_gsab_abrigo"."nm_abrigo"%TYPE,
    "p_nr_capacidade"    IN "t_gsab_abrigo"."nr_capacidade"%TYPE,
    "p_nr_ocupacao_atual" IN "t_gsab_abrigo"."nr_ocupacao_atual"%TYPE,
    "p_ds_cep"           IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"    IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"        IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"   IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"        IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"        IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"          IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    "v_endereco_id"  NUMBER;
    "v_id_existente" NUMBER;
    abrigo_nao_encontrado EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_abrigo" INTO "v_id_existente"
          FROM "t_gsab_abrigo"
         WHERE "id_abrigo" = "p_id_abrigo";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE abrigo_nao_encontrado;
    END;

    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento",
        "p_nm_cidade", "p_nm_estado", "p_nm_pais", "v_endereco_id"
    );

    UPDATE "t_gsab_abrigo"
       SET "nm_abrigo" = "p_nm_abrigo", "nr_capacidade" = "p_nr_capacidade",
           "nr_ocupacao_atual" = "p_nr_ocupacao_atual", "id_endereco" = "v_endereco_id"
     WHERE "id_abrigo" = "p_id_abrigo";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Abrigo atualizado com sucesso. ID: ' || "p_id_abrigo");
EXCEPTION
    WHEN abrigo_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20060, 'Abrigo com ID ' || "p_id_abrigo" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20061, 'Erro ao atualizar abrigo: ' || SQLERRM);
END "proc_atualizar_abrigo";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_abrigo" (
    "p_id_abrigo" IN "t_gsab_abrigo"."id_abrigo"%TYPE
) IS
    "v_id_existente" NUMBER;
    abrigo_nao_encontrado EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_abrigo" INTO "v_id_existente"
          FROM "t_gsab_abrigo"
         WHERE "id_abrigo" = "p_id_abrigo";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE abrigo_nao_encontrado;
    END;

    DELETE FROM "t_gsab_estoque_recurso" WHERE "id_abrigo" = "p_id_abrigo";
    DELETE FROM "t_gsab_check_in" WHERE "id_abrigo" = "p_id_abrigo";
    DELETE FROM "t_gsab_abrigo" WHERE "id_abrigo" = "p_id_abrigo";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Abrigo e todos os seus vínculos foram excluídos com sucesso. ID: ' || "p_id_abrigo");
EXCEPTION
    WHEN abrigo_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20062, 'Abrigo com ID ' || "p_id_abrigo" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20063, 'Erro ao excluir abrigo: ' || SQLERRM);
END "proc_excluir_abrigo";
/

-- CRUD RECURSO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_recurso" (
    "p_ds_recurso"     IN "t_gsab_recurso"."ds_recurso"%TYPE,
    "p_qt_pessoa_dia"  IN "t_gsab_recurso"."qt_pessoa_dia"%TYPE,
    "p_st_consumivel"  IN "t_gsab_recurso"."st_consumivel"%TYPE,
    "p_recurso_id"     OUT NUMBER
) IS
    "v_existente" NUMBER;
BEGIN
    SELECT COUNT(*) INTO "v_existente"
      FROM "t_gsab_recurso"
     WHERE UPPER("ds_recurso") = UPPER("p_ds_recurso");

    IF "v_existente" > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Recurso já cadastrado: ' || "p_ds_recurso");
    END IF;

    INSERT INTO "t_gsab_recurso" (
        "id_recurso", "ds_recurso", "qt_pessoa_dia", "st_consumivel"
    ) VALUES (
        seq_t_gsab_recurso.NEXTVAL, "p_ds_recurso", "p_qt_pessoa_dia", "p_st_consumivel"
    );
    COMMIT;
    "p_recurso_id" := seq_t_gsab_recurso.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Recurso inserido com sucesso. ID: ' || "p_recurso_id");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Erro ao inserir recurso: ' || SQLERRM);
END "proc_inserir_recurso";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_recurso" (
    "p_id_recurso"     IN "t_gsab_recurso"."id_recurso"%TYPE,
    "p_ds_recurso"     IN "t_gsab_recurso"."ds_recurso"%TYPE,
    "p_qt_pessoa_dia"  IN "t_gsab_recurso"."qt_pessoa_dia"%TYPE,
    "p_st_consumivel"  IN "t_gsab_recurso"."st_consumivel"%TYPE
) IS
    v_id_existente     NUMBER;
    recurso_nao_encontrado EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_recurso" INTO v_id_existente
          FROM "t_gsab_recurso"
         WHERE "id_recurso" = "p_id_recurso";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE recurso_nao_encontrado;
    END;

    UPDATE "t_gsab_recurso"
       SET "ds_recurso" = "p_ds_recurso", "qt_pessoa_dia" = "p_qt_pessoa_dia", "st_consumivel" = "p_st_consumivel"
     WHERE "id_recurso" = "p_id_recurso";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Recurso atualizado com sucesso. ID: ' || "p_id_recurso");
EXCEPTION
    WHEN recurso_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20080, 'Recurso com ID ' || "p_id_recurso" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20081, 'Erro ao atualizar recurso: ' || SQLERRM);
END "proc_atualizar_recurso";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_recurso" (
    "p_id_recurso" IN "t_gsab_recurso"."id_recurso"%TYPE
) IS
    recurso_nao_encontrado EXCEPTION;
    recurso_em_uso EXCEPTION;
    v_id_existente NUMBER;
    v_vinculado NUMBER;
BEGIN
    BEGIN
        SELECT "id_recurso" INTO v_id_existente
          FROM "t_gsab_recurso"
         WHERE "id_recurso" = "p_id_recurso";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE recurso_nao_encontrado;
    END;

    BEGIN
        SELECT 1 INTO v_vinculado
          FROM "t_gsab_estoque_recurso"
         WHERE "id_recurso" = "p_id_recurso" AND ROWNUM = 1;
        RAISE recurso_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    DELETE FROM "t_gsab_recurso"
     WHERE "id_recurso" = "p_id_recurso";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Recurso excluído com sucesso. ID: ' || "p_id_recurso");
EXCEPTION
    WHEN recurso_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20082, 'Recurso com ID ' || "p_id_recurso" || ' não encontrado.');
    WHEN recurso_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20084, 'Não é possível excluir o recurso. Ele está vinculado ao estoque.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20083, 'Erro ao excluir recurso: ' || SQLERRM);
END "proc_excluir_recurso";
/

-- CRUD ESTOQUE
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_estoque_recurso" (
    "p_qt_disponivel"     IN "t_gsab_estoque_recurso"."qt_disponivel"%TYPE,
    "p_dt_atualizacao"    IN "t_gsab_estoque_recurso"."dt_atualizacao"%TYPE,
    "p_id_abrigo"         IN "t_gsab_abrigo"."id_abrigo"%TYPE,
    "p_id_recurso"        IN "t_gsab_recurso"."id_recurso"%TYPE,
    "p_estoque_id"        OUT NUMBER
) IS
BEGIN
    INSERT INTO "t_gsab_estoque_recurso" (
        "id_estoque", "qt_disponivel", "dt_atualizacao", "id_abrigo", "id_recurso"
    ) VALUES (
        seq_t_gsab_estoque_recurso.NEXTVAL, "p_qt_disponivel", "p_dt_atualizacao", "p_id_abrigo", "p_id_recurso"
    );
    COMMIT;
    "p_estoque_id" := seq_t_gsab_estoque_recurso.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Estoque de recurso inserido. ID: ' || "p_estoque_id");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20017, 'Erro ao inserir estoque de recurso: ' || SQLERRM);
END "proc_inserir_estoque_recurso";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_estoque_recurso" (
    "p_id_estoque"         IN "t_gsab_estoque_recurso"."id_estoque"%TYPE,
    "p_qt_disponivel"      IN "t_gsab_estoque_recurso"."qt_disponivel"%TYPE,
    "p_dt_atualizacao"     IN "t_gsab_estoque_recurso"."dt_atualizacao"%TYPE,
    "p_id_abrigo"          IN "t_gsab_abrigo"."id_abrigo"%TYPE,
    "p_id_recurso"         IN "t_gsab_recurso"."id_recurso"%TYPE
) IS
    estoque_nao_encontrado EXCEPTION;
    "v_id_existente" NUMBER;
BEGIN
    BEGIN
        SELECT "id_estoque" INTO "v_id_existente"
          FROM "t_gsab_estoque_recurso"
         WHERE "id_estoque" = "p_id_estoque";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estoque_nao_encontrado;
    END;

    UPDATE "t_gsab_estoque_recurso"
       SET "qt_disponivel" = "p_qt_disponivel", "dt_atualizacao" = "p_dt_atualizacao",
           "id_abrigo" = "p_id_abrigo", "id_recurso" = "p_id_recurso"
     WHERE "id_estoque" = "p_id_estoque";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estoque de recurso atualizado com sucesso. ID: ' || "p_id_estoque");
EXCEPTION
    WHEN estoque_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20070, 'Estoque com ID ' || "p_id_estoque" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20071, 'Erro ao atualizar estoque de recurso: ' || SQLERRM);
END "proc_atualizar_estoque_recurso";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_estoque_recurso" (
    "p_id_estoque" IN "t_gsab_estoque_recurso"."id_estoque"%TYPE
) IS
    estoque_nao_encontrado EXCEPTION;
    v_id_existente NUMBER;
BEGIN
    BEGIN
        SELECT "id_estoque" INTO v_id_existente
          FROM "t_gsab_estoque_recurso"
         WHERE "id_estoque" = "p_id_estoque";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estoque_nao_encontrado;
    END;

    DELETE FROM "t_gsab_estoque_recurso"
     WHERE "id_estoque" = "p_id_estoque";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estoque de recurso excluído com sucesso. ID: ' || "p_id_estoque");
EXCEPTION
    WHEN estoque_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20072, 'Estoque com ID ' || "p_id_estoque" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20073, 'Erro ao excluir estoque de recurso: ' || SQLERRM);
END "proc_excluir_estoque_recurso";
/

-- CRUD CHECK-IN
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "proc_inserir_checkin" (
    "p_dt_entrada"  IN "t_gsab_check_in"."dt_entrada"%TYPE,
    "p_dt_saida"    IN "t_gsab_check_in"."dt_saida"%TYPE,
    "p_id_abrigo"   IN "t_gsab_check_in"."id_abrigo"%TYPE,
    "p_id_pessoa"   IN "t_gsab_check_in"."id_pessoa"%TYPE,
    "p_id_checkin"  OUT NUMBER
) IS
BEGIN
    INSERT INTO "t_gsab_check_in" (
        "id_checkin", "dt_entrada", "dt_saida", "id_abrigo", "id_pessoa"
    ) VALUES (
        seq_t_gsab_check_in.NEXTVAL, "p_dt_entrada", "p_dt_saida", "p_id_abrigo", "p_id_pessoa"
    );
    COMMIT;
    "p_id_checkin" := seq_t_gsab_check_in.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Check-in inserido. ID: ' || "p_id_checkin");
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'Erro ao inserir check-in: ' || SQLERRM);
END "proc_inserir_checkin";
/

CREATE OR REPLACE PROCEDURE "proc_atualizar_checkin" (
    "p_id_checkin"  IN "t_gsab_check_in"."id_checkin"%TYPE,
    "p_dt_entrada"  IN "t_gsab_check_in"."dt_entrada"%TYPE,
    "p_dt_saida"    IN "t_gsab_check_in"."dt_saida"%TYPE,
    "p_id_abrigo"   IN "t_gsab_check_in"."id_abrigo"%TYPE,
    "p_id_pessoa"   IN "t_gsab_check_in"."id_pessoa"%TYPE
) IS
    checkin_nao_encontrado EXCEPTION;
    v_checkin_id NUMBER;
BEGIN
    BEGIN
        SELECT "id_checkin" INTO v_checkin_id
          FROM "t_gsab_check_in"
         WHERE "id_checkin" = "p_id_checkin";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE checkin_nao_encontrado;
    END;

    UPDATE "t_gsab_check_in"
       SET "dt_entrada" = "p_dt_entrada", "dt_saida" = "p_dt_saida",
           "id_abrigo"  = "p_id_abrigo", "id_pessoa" = "p_id_pessoa"
     WHERE "id_checkin" = "p_id_checkin";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Check-in atualizado com sucesso. ID: ' || "p_id_checkin");
EXCEPTION
    WHEN checkin_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Check-in com ID ' || "p_id_checkin" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20051, 'Erro ao atualizar check-in: ' || SQLERRM);
END "proc_atualizar_checkin";
/

CREATE OR REPLACE PROCEDURE "proc_excluir_checkin" (
    "p_id_checkin" IN "t_gsab_check_in"."id_checkin"%TYPE
) IS
    v_id_existente NUMBER;
    checkin_nao_encontrado EXCEPTION;
BEGIN
    BEGIN
        SELECT "id_checkin" INTO v_id_existente
          FROM "t_gsab_check_in"
         WHERE "id_checkin" = "p_id_checkin";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE checkin_nao_encontrado;
    END;

    DELETE FROM "t_gsab_check_in"
     WHERE "id_checkin" = "p_id_checkin";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Check-in excluído com sucesso. ID: ' || "p_id_checkin");
EXCEPTION
    WHEN checkin_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20052, 'Check-in com ID ' || "p_id_checkin" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20053, 'Erro ao excluir check-in: ' || SQLERRM);
END "proc_excluir_checkin";
/

-- PROCEDURES DE RELATÓRIO / VERIFICAÇÃO
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "verificar_desaparecimento_por_cpf" (
    "p_nr_cpf" IN "t_gsab_pessoa"."nr_cpf"%TYPE
) IS
    "v_st_desaparecido" CHAR(1);
    "v_nm_pessoa"       "t_gsab_pessoa"."nm_pessoa"%TYPE;
BEGIN
    SELECT "st_desaparecido", "nm_pessoa"
      INTO "v_st_desaparecido", "v_nm_pessoa"
      FROM "t_gsab_pessoa"
     WHERE "nr_cpf" = "p_nr_cpf";

    IF "v_st_desaparecido" = 'S' THEN
        DBMS_OUTPUT.PUT_LINE('Pessoa desaparecida: ' || "v_nm_pessoa");
    ELSE
        DBMS_OUTPUT.PUT_LINE('Pessoa encontrada: ' || "v_nm_pessoa");
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('CPF não encontrado.');
END;
/

CREATE OR REPLACE PROCEDURE "verificar_estoque_para_reposicao" (
    "p_id_abrigo" IN "t_gsab_abrigo"."id_abrigo"%TYPE
) IS
    "v_encontrado" BOOLEAN := FALSE;
BEGIN
    FOR recurso IN (
        SELECT e."qt_disponivel", r."ds_recurso"
          FROM "t_gsab_estoque_recurso" e
          JOIN "t_gsab_recurso" r ON e."id_recurso" = r."id_recurso"
         WHERE e."id_abrigo" = "p_id_abrigo" AND e."qt_disponivel" < 10
    ) LOOP
        "v_encontrado" := TRUE;
        DBMS_OUTPUT.PUT_LINE('⚠️ Recurso com estoque baixo: ' || recurso."ds_recurso" ||
                             ' (Qtd: ' || recurso."qt_disponivel" || ')');
    END LOOP;

    IF NOT "v_encontrado" THEN
        DBMS_OUTPUT.PUT_LINE('✅ Todos os recursos estão com estoque adequado.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao verificar estoque: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE "avaliar_lotacao_abrigo" (
    "p_id_abrigo" IN "t_gsab_abrigo"."id_abrigo"%TYPE
) IS
    "v_capacidade"       NUMBER;
    "v_ocupacao_atual"   NUMBER;
    "v_porcentagem"      NUMBER;
    "v_nm_abrigo"        "t_gsab_abrigo"."nm_abrigo"%TYPE;
BEGIN
    SELECT "nr_capacidade", "nr_ocupacao_atual", "nm_abrigo"
      INTO "v_capacidade", "v_ocupacao_atual", "v_nm_abrigo"
      FROM "t_gsab_abrigo"
     WHERE "id_abrigo" = "p_id_abrigo";

    "v_porcentagem" := ("v_ocupacao_atual" / "v_capacidade") * 100;

    IF "v_porcentagem" >= 90 THEN
        DBMS_OUTPUT.PUT_LINE('🚨 Abrigo "' || "v_nm_abrigo" || '" acima de 90% da capacidade (' || ROUND("v_porcentagem", 2) || '%)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✅ Abrigo "' || "v_nm_abrigo" || '" com ocupação sob controle (' || ROUND("v_porcentagem", 2) || '%)');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('❌ Abrigo não encontrado.');
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('❌ Abrigo "' || "v_nm_abrigo" || '" com capacidade zero, impossível calcular lotação.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao avaliar ocupação do abrigo: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE "verificar_pessoas_risco_idade" IS
    "v_encontrado" BOOLEAN := FALSE;
BEGIN
    FOR p IN (
        SELECT p."nm_pessoa", TRUNC(MONTHS_BETWEEN(SYSDATE, p."dt_nascimento") / 12) AS "idade", a."nm_abrigo"
          FROM "t_gsab_check_in" c
          JOIN "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
          JOIN "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
         WHERE c."dt_saida" IS NULL AND TRUNC(MONTHS_BETWEEN(SYSDATE, p."dt_nascimento") / 12) >= 60
    ) LOOP
        "v_encontrado" := TRUE;
        DBMS_OUTPUT.PUT_LINE('⚠️ Idoso(a) no abrigo "' || p."nm_abrigo" || '": ' || p."nm_pessoa" || ' (' || p."idade" || ' anos)');
    END LOOP;

    IF NOT "v_encontrado" THEN
        DBMS_OUTPUT.PUT_LINE('✅ Nenhuma pessoa com 60 anos ou mais em abrigos no momento.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao verificar pessoas em risco por idade: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE "verificar_checkin_prolongado" IS
    "v_encontrado" BOOLEAN := FALSE;
BEGIN
    FOR c IN (
        SELECT p."nm_pessoa", a."nm_abrigo", c."dt_entrada"
          FROM "t_gsab_check_in" c
          JOIN "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
          JOIN "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
         WHERE c."dt_saida" IS NULL AND SYSDATE - c."dt_entrada" > 30
    ) LOOP
        "v_encontrado" := TRUE;
        DBMS_OUTPUT.PUT_LINE('🕒 Pessoa em abrigo há mais de 30 dias: ' || c."nm_pessoa" ||
                             ' (Abrigo: ' || c."nm_abrigo" || ', Entrada: ' || TO_CHAR(c."dt_entrada", 'DD/MM/YYYY') || ')');
    END LOOP;

    IF NOT "v_encontrado" THEN
        DBMS_OUTPUT.PUT_LINE('✅ Nenhum check-in ativo com mais de 30 dias.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao verificar check-ins prolongados: ' || SQLERRM);
END;
/
------------------------------------------------------------------------------------------------------------------------
-- 5. GATILHOS (TRIGGERS)


CREATE OR REPLACE TRIGGER "trg_valida_estoque_nao_negativo"
BEFORE INSERT OR UPDATE ON "t_gsab_estoque_recurso"
FOR EACH ROW
DECLARE
    v_ds_recurso VARCHAR2(100);
BEGIN
    IF :NEW."qt_disponivel" < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'A quantidade disponível não pode ser negativa.');
    ELSIF :NEW."qt_disponivel" = 0 THEN
        SELECT "ds_recurso" INTO v_ds_recurso
          FROM "t_gsab_recurso"
         WHERE "id_recurso" = :NEW."id_recurso";
        DBMS_OUTPUT.PUT_LINE('ALERTA: O recurso "' || v_ds_recurso || '" zerou no estoque.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER "trg_atualiza_ocupacao_checkin"
AFTER INSERT OR UPDATE OR DELETE ON "t_gsab_check_in"
FOR EACH ROW
DECLARE
    v_ocupacao NUMBER;
    v_id_abrigo NUMBER;
BEGIN
    v_id_abrigo := NVL(:NEW."id_abrigo", :OLD."id_abrigo");

    SELECT COUNT(*) INTO v_ocupacao
      FROM "t_gsab_check_in"
     WHERE "id_abrigo" = v_id_abrigo AND "dt_saida" IS NULL;

    UPDATE "t_gsab_abrigo"
       SET "nr_ocupacao_atual" = v_ocupacao
     WHERE "id_abrigo" = v_id_abrigo;
END;
/
------------------------------------------------------------------------------------------------------------------------
--Relatório: Histórico de ocupação dos abrigos
-- 6. RELATÓRIOS
SELECT
    a."nm_abrigo",
    p."nm_pessoa",
    c."dt_entrada",
    c."dt_saida",
    CASE
        WHEN c."dt_saida" IS NULL THEN 'ATIVO'
        ELSE 'ENCERRADO'
    END AS "status_checkin",
    CASE
        WHEN c."dt_saida" IS NULL THEN TRUNC(SYSDATE - c."dt_entrada")
        ELSE TRUNC(c."dt_saida" - c."dt_entrada")
    END AS "dias_permanencia"
FROM
    "t_gsab_check_in" c
JOIN
    "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
JOIN
    "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
ORDER BY
    a."nm_abrigo", c."dt_entrada" DESC;
------------------
--Relatório: Quantidade de idosos por abrigo
SELECT
    a."nm_abrigo",
    COUNT(*) AS "qtd_idosos"
FROM
    "t_gsab_check_in" c
JOIN
    "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
JOIN
    "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
WHERE
    c."dt_saida" IS NULL
    AND TRUNC(MONTHS_BETWEEN(SYSDATE, p."dt_nascimento") / 12) >= 60
GROUP BY
    a."nm_abrigo"
ORDER BY
    "qtd_idosos" DESC;


------------------
-- Relatório: Recurso mais utilizado (estoque mais baixo) por abrigo
SELECT
    a."nm_abrigo",
    r."ds_recurso",
    er."qt_disponivel"
FROM (
    SELECT
        "id_abrigo",
        MIN("qt_disponivel") AS "menor_qt"
    FROM
        "t_gsab_estoque_recurso" er
    JOIN
        "t_gsab_recurso" r ON er."id_recurso" = r."id_recurso"
    WHERE
        r."st_consumivel" = 'S'
    GROUP BY
        "id_abrigo"
) sub
JOIN "t_gsab_estoque_recurso" er
    ON sub."id_abrigo" = er."id_abrigo" AND sub."menor_qt" = er."qt_disponivel"
JOIN "t_gsab_recurso" r
    ON er."id_recurso" = r."id_recurso"
JOIN "t_gsab_abrigo" a
    ON er."id_abrigo" = a."id_abrigo"
ORDER BY
    a."nm_abrigo";



------------------------------------------------------------------------------------------------------------------------
-- 7. BLOCOS DE TESTE

