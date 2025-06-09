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
--------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "verificar_estoque_para_reposicao" (
    "p_id_abrigo" IN "t_gsab_abrigo"."id_abrigo"%TYPE
) IS
    "v_encontrado" BOOLEAN := FALSE;
BEGIN
    FOR recurso IN (
        SELECT e."qt_disponivel", r."ds_recurso"
          FROM "t_gsab_estoque_recurso" e
          JOIN "t_gsab_recurso" r ON e."id_recurso" = r."id_recurso"
         WHERE e."id_abrigo" = "p_id_abrigo"
           AND e."qt_disponivel" < 10
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
--------------------------------------------------------------------------------------------------------------------------------
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
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao avaliar ocupação do abrigo: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "verificar_pessoas_risco_idade" IS
    "v_encontrado" BOOLEAN := FALSE;
BEGIN
    FOR p IN (
        SELECT p."nm_pessoa",
               TRUNC(MONTHS_BETWEEN(SYSDATE, p."dt_nascimento") / 12) AS "idade",
               a."nm_abrigo"
          FROM "t_gsab_check_in" c
          JOIN "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
          JOIN "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
         WHERE c."dt_saida" IS NULL
    ) LOOP
        IF p."idade" >= 60 THEN
            "v_encontrado" := TRUE;
            DBMS_OUTPUT.PUT_LINE('⚠️ Idoso(a) no abrigo "' || p."nm_abrigo" || '": ' || p."nm_pessoa" || ' (' || p."idade" || ' anos)');
        END IF;
    END LOOP;

    IF NOT "v_encontrado" THEN
        DBMS_OUTPUT.PUT_LINE('✅ Nenhuma pessoa com 60 anos ou mais em abrigos no momento.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao verificar pessoas em risco por idade: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "verificar_checkin_prolongado" IS
    "v_encontrado" BOOLEAN := FALSE;
BEGIN
    FOR c IN (
        SELECT p."nm_pessoa", a."nm_abrigo", c."dt_entrada"
          FROM "t_gsab_check_in" c
          JOIN "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
          JOIN "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
         WHERE c."dt_saida" IS NULL
           AND SYSDATE - c."dt_entrada" > 30
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
--------------------------------------------------------------------------------------------------------------------------------
BEGIN
    FOR c IN (
        SELECT p."nm_pessoa", a."nm_abrigo", c."dt_entrada"
          FROM "t_gsab_check_in" c
          JOIN "t_gsab_pessoa" p ON c."id_pessoa" = p."id_pessoa"
          JOIN "t_gsab_abrigo" a ON c."id_abrigo" = a."id_abrigo"
         WHERE c."dt_saida" IS NULL
           AND SYSDATE - c."dt_entrada" > 30
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('🕒 Pessoa em abrigo há mais de 30 dias: ' || c."nm_pessoa" ||
                             ' (Abrigo: ' || c."nm_abrigo" || ', Entrada: ' || TO_CHAR(c."dt_entrada", 'DD/MM/YYYY') || ')');
    END LOOP;
END;
/

