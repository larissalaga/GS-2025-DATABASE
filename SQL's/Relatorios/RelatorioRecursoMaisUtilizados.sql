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
