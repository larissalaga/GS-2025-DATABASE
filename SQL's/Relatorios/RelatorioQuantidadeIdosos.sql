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
