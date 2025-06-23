-- EJERCICIO FIANL: EMISIONES

-- . Combinación de datos de diferentes años 
-- . Crear la base de datos y la tabla total.
create database emisiones;

use emisiones;

CREATE TABLE emisiones_total AS
SELECT * FROM emisiones2020
where 1=0;

-- . Insertar los datos de las tablas de los años 2020, 2021, 2022 y 2023 en la tabla total.
insert into emisiones_total select * from emisiones2021;
insert into emisiones_total select * from emisiones2022;
insert into emisiones_total select * from emisiones2023;

-- . Verificar que todos los datos se han insertado correctamente, mostrando el número total de
-- registros y los años disponibles en la tabla.
select count(*), count(DISTINCT ANO) from emisiones_total;
select distinct ano from emisiones_total;


-- . Creación de la columna valor_dia
-- . Añadir la columna valor_dia a la tabla total.
alter table emisiones_total add valor_dia int;

-- . Rellenar esta columna con los valores de dia d01
update emisiones_total set valor_dia = D01;

-- . Añadir una columna fecha
-- . Crear la columna fecha en la tabla total con formato YYYY-MM-DD
alter table emisiones_total add fecha date;

-- . Actualizar la columna fecha con los valores correspondientes a cada mes y año
update emisiones_total
set fecha = STR_TO_DATE(CONCAT(ano, '-', mes), '%Y-%m');

UPDATE emisiones_total
SET fecha = STR_TO_DATE(CONCAT(ano, '-', mes, '-', 
    CASE 
        WHEN valor_dia < 1 OR valor_dia > 31 OR valor_dia IS NULL THEN 00
        ELSE valor_dia
    END), '%Y-%m-%d');

-- . Consultar estaciones y contaminantes disponibles
-- . Mostrar las estaciones y los contaminantes únicos que existen en la tabla total
select distinct magnitud, estacion from emisiones_total;

-- . Filtrar datos por estación y contaminante

-- . Comparar los valores diarios de contaminación entre las estaciones "Ramon y Cajal" y "Escuelas Aguirre"
-- durante el año 2020, calcula la diferencia entre los valores de ambas estaciones para cada fecha y
-- devuelve las columnas: fecha, valor de "Ramon y Cajal", valor de "Escuelas Aguirre" y la diferencia de
-- valores, filtrando solo los registros donde la magnitud sea 1 y el rango de fechas sea del 1 de
-- enero de 2020 al 31 de diciembre de 2020, ordenando los resultados por fecha.

-- Opcion 1
select fecha, 
       sum(case when estacion = 'Ramon y Cajal' then valor_dia else null end) as Ramon_y_Cajal, 
       sum(case when estacion = 'Escuelas Aguirre' then valor_dia else null end) as Escuelas_Aguirre, 
       sum(case when estacion = 'Ramon y Cajal' then valor_dia else 0 end) - 
       sum(case when estacion = 'Escuelas Aguirre' then valor_dia else 0 end) as diferencia
from emisiones_total
where fecha between '2020-01-01' and '2020-12-31'
and magnitud = 1
group by fecha
order by fecha;

-- Opcion 2
with ramonycajal as (
    select
        fecha,
        valor_dia as valor_ramon_y_cajal
    from
        emisiones_total
    where
        estacion = 'ramon y cajal'
        and magnitud = 1
        and fecha >= '2020-01-01'
        and fecha <= '2020-12-31'
),
escuelasaguirre as (
    select
        fecha,
        valor_dia as valor_escuelas_aguirre
    from
        emisiones_total
    where
        estacion = 'escuelas aguirre'
        and magnitud = 1
        and fecha >= '2020-01-01'
        and fecha <= '2020-12-31'
)
select
    ryc.fecha,
    ryc.valor_ramon_y_cajal,
    ea.valor_escuelas_aguirre,
    ryc.valor_ramon_y_cajal - ea.valor_escuelas_aguirre as diferencia_valores
from
    ramonycajal ryc
join
    escuelasaguirre ea on ryc.fecha = ea.fecha
order by
    ryc.fecha;


-- . Resumen descriptivo por contaminante (Magnitud)

-- . Mostrar el valor mínimo, máximo, promedio y la desviación estándar de los valores de contaminación para cada contaminante.

-- Con un solo dia
select magnitud, 
       min(valor_dia) as minimo, 
       max(valor_dia) as maximo, 
       avg(valor_dia) as promedio, 
       stddev(valor_dia) as desviacion_estandar
from emisiones_total
group by magnitud;


-- . Resumen descriptivo por estación

-- . Muestra el valor mínimo, máximo, promedio y la desviación estándar de los valores de contaminación para cada estación
select estacion, 
       min(valor_dia) as minimo, 
       max(valor_dia) as maximo, 
       avg(valor_dia) as promedio, 
       stddev(valor_dia) as desviacion_estandar
from emisiones_total
group by estacion;

-- . Calcular medias mensuales de contaminación
-- 
-- . ¿Cómo podemos calcular el promedio mensual de valores por estación y año, transformando los
-- números de los meses en palabras y agrupándolos además en trimestres?
select
    estacion, ano,
    case mes
        when 1 then 'enero'
        when 2 then 'febrero'
        when 3 then 'marzo'
        when 4 then 'abril'
        when 5 then 'mayo'
        when 6 then 'junio'
        when 7 then 'julio'
        when 8 then 'agosto'
        when 9 then 'septiembre'
        when 10 then 'octubre'
        when 11 then 'noviembre'
        when 12 then 'diciembre'
        else 'mes inválido'
    end as nombre_mes,
    case
        when mes between 1 and 3 then 'primer trimestre'
        when mes between 4 and 6 then 'segundo trimestre'
        when mes between 7 and 9 then 'tercer trimestre'
        when mes between 10 and 12 then 'cuarto trimestre'
        else 'trimestre inválido'
    end as trimestre,
    avg(valor_dia) as promedio_mensual
from emisiones_total
group by estacion, ano,  mes
ORDER BY ano, estacion, mes;

-- . Medias mensuales por estación con nombre largo

-- . Mostrar la media mensual de contaminación para estaciones con nombres largos (más de 10
-- caracteres), agrupado por estación, contaminante y mes.

-- Opcion 1: utilizando valor_dia para obtener media mensual
SELECT
    estacion,
    magnitud,
    mes,
    AVG(valor_dia) AS media_mensual
FROM emisiones_total
WHERE LENGTH(estacion) > 10 -- Filtro de nombres largos (más de 10 caracteres)
GROUP BY estacion, magnitud, mes
ORDER BY estacion, magnitud, mes;


-- Opcion 2: sumar valor de todos los días para obtener el media mensual
SELECT 
    estacion,
    magnitud,
    mes,
    AVG((D01 + D02 + D03 + D04 + D05 + D06 + D07 + D08 + D09 + D10 + 
         D11 + D12 + D13 + D14 + D15 + D16 + D17 + D18 + D19 + D20 +
         D21 + D22 + D23 + D24 + D25 + D26 + D27 + D28 + D29 +
         COALESCE(D30, 0) + COALESCE(D31, 0)) / 
        (CASE 
            WHEN mes IN (4, 6, 9, 11) THEN 30 
            WHEN mes = 2 THEN 28 
            ELSE 31 
         END)
    ) AS promedio
FROM emisiones_total
WHERE LENGTH(estacion) > 10
GROUP BY estacion, magnitud, mes
ORDER BY estacion, magnitud, mes;



-- . Niveles de contaminación acumulados por estación y
-- contaminante
-- . Calcular la media anual de las emisiones (valor_dia) por estación y magnitud para cada año, y asigna un
-- ranking de emisiones dentro de cada año y magnitud, donde el primer lugar corresponde al valor más alto. 
-- Ordena los resultados por año, magnitud y ranking de emisiones.
SELECT estacion,
		magnitud,
		ano, 
       AVG(valor_dia) AS media_anual, 
       RANK() OVER (PARTITION BY ano, magnitud ORDER BY AVG(valor_dia) DESC) AS ranking_emisiones
FROM emisiones_total
GROUP BY ano, magnitud, estacion
ORDER BY ano, magnitud, ranking_emisiones;

-- . Promedio acumulado de emisiones por estación

-- . ¿Cómo podemos calcular el promedio acumulado anual y el promedio acumulado total de emisiones por estación a lo largo de los años?
SELECT
    estacion,
    ano,
    AVG(valor_dia) AS promedio_anual,
    SUM(AVG(valor_dia)) OVER (PARTITION BY estacion ORDER BY ano) AS promedio_acumulado_anual,
    SUM(AVG(valor_dia)) OVER (PARTITION BY estacion) AS promedio_acumulado_total
FROM emisiones_total
GROUP BY estacion, ano;

-- . Días con datos de contaminación por estación y mes

-- . Mostrar el número de días con datos de contaminación registrados por estación y nombre del mes
SELECT
    estacion,
    CASE
        WHEN mes = 1 THEN 'Enero'
        WHEN mes = 2 THEN 'Febrero'
        WHEN mes = 3 THEN 'Marzo'
        WHEN mes = 4 THEN 'Abril'
        WHEN mes = 5 THEN 'Mayo'
        WHEN mes = 6 THEN 'Junio'
        WHEN mes = 7 THEN 'Julio'
        WHEN mes = 8 THEN 'Agosto'
        WHEN mes = 9 THEN 'Septiembre'
        WHEN mes = 10 THEN 'Octubre'
        WHEN mes = 11 THEN 'Noviembre'
        WHEN mes = 12 THEN 'Diciembre'
    END AS nombre_mes,
    COUNT(valor_dia) AS dias_con_datos
FROM emisiones_total
WHERE valor_dia IS NOT NULL
GROUP BY estacion, mes
ORDER BY estacion, mes;

-- . Días transcurridos desde la última medición por estación

-- . ¿Cómo podemos identificar la última fecha de registro de datos para cada estación y calcular el
-- número de días transcurridos desde esa fecha hasta hoy?
SELECT
    estacion,
    MAX(fecha) AS ultima_fecha,
    DATEDIFF(CURRENT_DATE, MAX(fecha)) AS dias_transcurridos
FROM emisiones_total
WHERE valor_dia IS NOT NULL -- Aseguramos que existan datos válidos
GROUP BY estacion
ORDER BY estacion;

-- . Variación de contaminación entre días anteriores y posteriores

-- . Mostrar cómo varió la contaminación de cada estación y contaminante en comparación con el día
-- anterior y el día siguiente, y también muestra el primer y último valor registrado de cada estación y
-- contaminante durante el año.

-- Opcion 1
SELECT estacion, 
       magnitud, 
       fecha, 
       valor_dia AS valor_actual,
       LAG(valor_dia) OVER (PARTITION BY estacion, magnitud ORDER BY fecha) AS valor_dia_anterior,
       LEAD(valor_dia) OVER (PARTITION BY estacion, magnitud ORDER BY fecha) AS valor_dia_siguiente,
       valor_dia - LAG(valor_dia) OVER (PARTITION BY estacion, magnitud ORDER BY fecha) AS variacion_anterior,
       LEAD(valor_dia) OVER (PARTITION BY estacion, magnitud ORDER BY fecha) - valor_dia AS variacion_siguiente
FROM emisiones_total
ORDER BY estacion, magnitud, fecha;

-- Opcion 2
with datosordenados as (
    select
        provincia,  municipio,   estacion,
        magnitud,
        punto_muestreo,
        ano,
        mes,
        valor_dia,
        fecha,
        row_number() over (partition by estacion, magnitud, ano order by fecha) as rn,
        count(*) over (partition by estacion, magnitud, ano) as total_registros,
        first_value(valor_dia) over (partition by estacion, magnitud, ano order by fecha) as primer_valor,
        last_value(valor_dia) over (partition by estacion, magnitud, ano order by fecha) as ultimo_valor,
        min(fecha) over (partition by estacion, magnitud, ano) as primera_fecha,
        max(fecha) over (partition by estacion, magnitud, ano) as ultima_fecha
    from
        emisiones_total
)
select
    do.provincia,  do.municipio,  do.estacion,  do.magnitud, do.punto_muestreo,
    do.ano,
    do.mes,
    do.fecha,
    do.valor_dia,
    lag(do.valor_dia, 1, null) over (partition by do.estacion, do.magnitud order by do.fecha) as valor_dia_anterior,
    lead(do.valor_dia, 1, null) over (partition by do.estacion, do.magnitud order by do.fecha) as valor_dia_siguiente,
    do.primera_fecha,
    do.primer_valor,
    do.ultima_fecha,
    do.ultimo_valor
from
    datosordenados do
order by
    do.estacion,
    do.magnitud,
    do.fecha;



-- 15. Usando la tabla total::

-- • Calcular el promedio anual de emisiones (media_anual) para cada estación (estación) y magnitud (magnitud), solo
-- para la magnitud 1. Considera solo los años 2020 y 2021.

-- • Generar un ranking por año y magnitud, ordenando las estaciones por su media_anual de emisiones (de mayor a menor).

-- • Determinar el mes con la mayor media mensual de emisiones para cada estación en los años 2020 y 2021.

-- • Combinar todos estos cálculos en un único query que incluya: ano, magnitud, estacion, media_anual, ranking_emisiones, 
-- el mes con la mayor media mensual de emisiones (mes_max) y el valor promedio mensual de ese mes (max_media_mensual).

-- • Ordenar los resultados por año, magnitud y ranking_emisiones.


with mediaanualestacionmagnitud as (
    select
        estacion,
        magnitud,
        ano,
        avg(valor_dia) as media_anual
    from
        emisiones_total
    where magnitud = 1 and ano in (2020, 2021)
    group by
        estacion,
        magnitud,
        ano
),
rankingemisiones as (
    select
        estacion,
        magnitud,
        ano,
        media_anual,
        rank() over (partition by ano, magnitud order by media_anual desc) as ranking_emisiones
    from
        mediaanualestacionmagnitud
),
mediamensualestacion as (
    select
        estacion,
        ano,
        mes,
        avg(valor_dia) as media_mensual
    from
        emisiones_total
    where magnitud = 1 and ano in (2020, 2021)
    group by
        estacion,
        ano,
        mes
),
maxmediamensualestacion as (
  select
        estacion,
        ano,
        first_value(mes) over (partition by estacion, ano order by media_mensual desc) as mes_max,
        max(media_mensual) over (partition by estacion, ano) as max_media_mensual
    from mediamensualestacion
)
select
    re.ano,
    re.magnitud,
    re.estacion,
    re.media_anual,
    re.ranking_emisiones,
    mm.mes_max,
    mm.max_media_mensual
from
    rankingemisiones re
join maxmediamensualestacion mm on re.estacion = mm.estacion and re.ano = mm.ano
order by
    re.ano,
    re.magnitud,
    re.ranking_emisiones;





