WITH uc_unit_id AS(
    WITH uc_viewing_id AS(
        WITH viewings_on_calendar AS (

            SELECT viewing_id AS "viewing_on_calendar"
            FROM dhs.dhs_viewings v
            WHERE ((v.hsu_viewing_outcome IS NULL OR v.hsu_viewing_outcome NOT IN ('Cancelled','Reschedule'))
                                    AND (v.dhs_viewing_outcome IS NULL OR v.dhs_viewing_outcome NOT ILIKE 'Reschedule'))
                                    AND v.viewing_date::date<=current_date
                                    AND v.viewing_date BETWEEN '2018-01-01' AND '2018-08-31'
        )

        , viewings_claimed AS (

            SELECT viewing_id AS "viewing_claimed"
            FROM dhs.dhs_units
            LEFT JOIN dhs.dhs_viewings AS v USING (unit_id)
            LEFT JOIN dhs.dhs_scheduling AS s USING (unit_id, viewing_id)
            WHERE ((v.hsu_viewing_outcome IS NULL OR v.hsu_viewing_outcome NOT IN ('Cancelled','Reschedule','Was Not Claimed'))
                                    AND (v.dhs_viewing_outcome IS NULL OR v.dhs_viewing_outcome NOT ILIKE 'Reschedule')
                                    AND (s.viewing_id IS NOT NULL OR v.attendee_capacity=0))
        )

        SELECT viewing_on_calendar
        FROM viewings_on_calendar
        LEFT JOIN viewings_claimed ON viewing_on_calendar = viewing_claimed
        WHERE viewing_claimed IS NULL
        ORDER BY viewing_on_calendar
    )

    SELECT unit_id
    FROM uc_viewing_id AS uc
    LEFT JOIN dhs.dhs_viewings AS v ON uc.viewing_on_calendar=v.viewing_id
    WHERE viewing_on_calendar is NOT NULL
    GROUP BY 1
    ORDER BY 1
)
SELECT unit_status
, COUNT(DISTINCT(uc_unit_id))
FROM dhs.dhs_units u
LEFT JOIN uc_unit_id AS ucid ON ucid.uc_unit_id=u.unit_id
WHERE viewing_on_calendar is not null
GROUP BY 1,2
ORDER BY 1,2
