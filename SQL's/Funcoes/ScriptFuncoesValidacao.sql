-- Remoção de caracteres : "FUN_SOMENTE_NUMEROS"
CREATE OR REPLACE FUNCTION "FUN_SOMENTE_NUMEROS"(
    "valor" VARCHAR2
) RETURN VARCHAR2 IS
    "resultado" VARCHAR2(4000);
BEGIN
    -- Remove tudo que não for número
    "resultado" := REGEXP_REPLACE("valor", '[^0-9]', '');

    RETURN "resultado";

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Erro ao limpar valor: ' || SQLERRM);
        RETURN NULL;
END;
/

--------------------------------------------------------------------------------------------------------------------------------
-- Validação de CPF: "FUN_VALIDA_CPF"

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
    -- Chama a função de limpeza para manter apenas os números
    "cpf_limpo" := "FUN_SOMENTE_NUMEROS"("cpf");

    -- Verifica se tem 11 dígitos numéricos
    IF LENGTH("cpf_limpo") != 11 OR NOT REGEXP_LIKE("cpf_limpo", '^\d{11}$') THEN
        RETURN FALSE;
    END IF;

    -- Verifica se todos os dígitos são iguais
    IF "cpf_limpo" = LPAD(SUBSTR("cpf_limpo", 1, 1), 11, SUBSTR("cpf_limpo", 1, 1)) THEN
        RETURN FALSE;
    END IF;

    -- Cálculo do primeiro dígito verificador
    FOR "i" IN 1..9 LOOP
        "sum1" := "sum1" + TO_NUMBER(SUBSTR("cpf_limpo", "i", 1)) * (11 - "i");
    END LOOP;

    "digit1" := ("sum1" * 10) MOD 11;
    IF "digit1" = 10 THEN
        "digit1" := 0;
    END IF;

    IF "digit1" != TO_NUMBER(SUBSTR("cpf_limpo", 10, 1)) THEN
        RETURN FALSE;
    END IF;

    -- Cálculo do segundo dígito verificador
    FOR "i" IN 1..10 LOOP
        "sum2" := "sum2" + TO_NUMBER(SUBSTR("cpf_limpo", "i", 1)) * (12 - "i");
    END LOOP;

    "digit2" := ("sum2" * 10) MOD 11;
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
--------------------------------------------------------------------------------------------------------------------------------
-- Validação de Nascimento: "FUN_VALIDA_NASCIMENTO"

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
--------------------------------------------------------------------------------------------------------------------------------
-- Validação de Telefone: "FUN_VALIDA_TELEFONE"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_TELEFONE"(
    "telefone" VARCHAR2
) RETURN BOOLEAN IS
    "telefone_limpo" VARCHAR2(11);
BEGIN
    -- Usa a função de limpeza para manter apenas os números
    "telefone_limpo" := "FUN_SOMENTE_NUMEROS"("telefone");

    -- Verifica se tem exatamente 11 dígitos numéricos
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
--------------------------------------------------------------------------------------------------------------------------------
-- Validação de Email: "FUN_VALIDA_EMAIL"
CREATE OR REPLACE FUNCTION "FUN_VALIDA_EMAIL"(
    "email" VARCHAR2
) RETURN BOOLEAN IS
BEGIN
    RETURN REGEXP_LIKE(
        "email",
        '^[A-Za-z0-9._%-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
        'c'
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro na validação do e-mail: ' || SQLERRM);
        RETURN FALSE;
END;
/
--------------------------------------------------------------------------------------------------------------------------------
-- Validação de Sexo: "FUN_VALIDA_SEXO"
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