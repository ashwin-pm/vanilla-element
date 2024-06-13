SELECT
    new_logs.id,
    DATEDIFF(ss, new_logs.audit_time, in_progress_logs.audit_time) AS new_to_in_progress_time,
    DATEDIFF(ss, in_progress_logs.audit_time, sending_logs_first.audit_time) AS in_progress_to_sending_time,
    DATEDIFF(ss, sending_logs_first.audit_time, pending_review_logs.audit_time) AS sending_to_pending_review_time,
    DATEDIFF(ss, pending_review_logs.audit_time, sending_logs_second.audit_time) AS pending_review_to_sending_time,
    DATEDIFF(ss, sending_logs_second.audit_time, sent_logs.audit_time) AS sending_to_sent_time,
    DATEDIFF(ss, new_logs.audit_time, in_progress_logs.audit_time) +
    DATEDIFF(ss, in_progress_logs.audit_time, sending_logs_first.audit_time) +
    DATEDIFF(ss, sending_logs_first.audit_time, pending_review_logs.audit_time) -
    DATEDIFF(ss, pending_review_logs.audit_time, sending_logs_second.audit_time) +
    DATEDIFF(ss, sending_logs_second.audit_time, sent_logs.audit_time) AS adjusted_time_diff_seconds
FROM
    audit_logs new_logs
JOIN
    audit_logs in_progress_logs ON new_logs.id = in_progress_logs.id
    AND new_logs.status = 'NEW'
    AND in_progress_logs.status = 'IN_PROGRESS'
    AND in_progress_logs.audit_time = (
        SELECT MIN(c.audit_time)
        FROM audit_logs c
        WHERE c.id = new_logs.id
        AND c.status = 'IN_PROGRESS'
        AND c.audit_time > new_logs.audit_time
    )
JOIN
    audit_logs sending_logs_first ON new_logs.id = sending_logs_first.id
    AND sending_logs_first.status = 'SENDING'
    AND sending_logs_first.audit_time = (
        SELECT MIN(c.audit_time)
        FROM audit_logs c
        WHERE c.id = in_progress_logs.id
        AND c.status = 'SENDING'
        AND c.audit_time > in_progress_logs.audit_time
    )
JOIN
    audit_logs pending_review_logs ON new_logs.id = pending_review_logs.id
    AND pending_review_logs.status = 'PENDING_REVIEW'
    AND pending_review_logs.audit_time = (
        SELECT MIN(c.audit_time)
        FROM audit_logs c
        WHERE c.id = sending_logs_first.id
        AND c.status = 'PENDING_REVIEW'
        AND c.audit_time > sending_logs_first.audit_time
    )
JOIN
    audit_logs sending_logs_second ON new_logs.id = sending_logs_second.id
    AND sending_logs_second.status = 'SENDING'
    AND sending_logs_second.audit_time = (
        SELECT MIN(c.audit_time)
        FROM audit_logs c
        WHERE c.id = pending_review_logs.id
        AND c.status = 'SENDING'
        AND c.audit_time > pending_review_logs.audit_time
    )
JOIN
    audit_logs sent_logs ON new_logs.id = sent_logs.id
    AND sent_logs.status = 'SENT'
    AND sent_logs.audit_time = (
        SELECT MIN(c.audit_time)
        FROM audit_logs c
        WHERE c.id = sending_logs_second.id
        AND c.status = 'SENT'
        AND c.audit_time > sending_logs_second.audit_time
    )
ORDER BY
    new_logs.id;
