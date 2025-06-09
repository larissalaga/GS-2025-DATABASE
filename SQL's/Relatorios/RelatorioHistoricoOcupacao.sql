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
