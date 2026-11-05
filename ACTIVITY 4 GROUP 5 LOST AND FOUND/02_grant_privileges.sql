-- APPLICATION ACCOUNT

GRANT USAGE ON SCHEMA public
TO lostandfound_app;

GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO lostandfound_app;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO lostandfound_app;

GRANT DELETE ON TABLE potential_matches
TO lostandfound_app;

GRANT SELECT, INSERT, UPDATE, DELETE
ON item_images, lost_report_images, claim_images
TO lostandfound_app;

GRANT USAGE, SELECT
ON SEQUENCE item_images_item_image_id_seq,
             lost_report_images_report_image_id_seq,
             claim_images_claim_image_id_seq
TO lostandfound_app;


-- PUBLIC ACCOUNT

GRANT CONNECT ON DATABASE grp05_lostandfounddb
TO lostandfound_public;

GRANT USAGE ON SCHEMA public
TO lostandfound_public;

GRANT SELECT ON TABLE
    categories,
    items,
    lost_reports,
    claims,
    potential_matches,
    item_images,
    lost_report_images
TO lostandfound_public;

GRANT INSERT ON TABLE
    lost_reports,
    claims,
    potential_matches,
    lost_report_images,
    claim_images
TO lostandfound_public;

GRANT UPDATE (status) ON TABLE lost_reports
TO lostandfound_public;

GRANT DELETE ON TABLE potential_matches
TO lostandfound_public;

GRANT USAGE, SELECT ON SEQUENCE
    lost_reports_report_id_seq,
    claims_claim_id_seq,
    potential_matches_match_id_seq,
    lost_report_images_report_image_id_seq,
    claim_images_claim_image_id_seq
TO lostandfound_public;