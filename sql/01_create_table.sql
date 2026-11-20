-- 01_create_table.sql
-- Raw table that mirrors the CSV one-to-one. No cleaning happens here;
-- anything derived is built later in 04_data_model.sql.

DROP TABLE IF EXISTS instagram_posts CASCADE;

CREATE TABLE instagram_posts (
    post_id                  VARCHAR(20) PRIMARY KEY,
    account_id               INTEGER     NOT NULL,
    account_type             VARCHAR(20) NOT NULL,
    follower_count           INTEGER     NOT NULL,
    media_type               VARCHAR(20) NOT NULL,
    content_category         VARCHAR(50) NOT NULL,
    traffic_source           VARCHAR(30) NOT NULL,
    has_call_to_action       BOOLEAN     NOT NULL,
    post_datetime            TIMESTAMP   NOT NULL,
    post_date                DATE        NOT NULL,
    post_hour                SMALLINT    NOT NULL,
    day_of_week              VARCHAR(10) NOT NULL,
    likes                    INTEGER     NOT NULL,
    comments                 INTEGER     NOT NULL,
    shares                   INTEGER     NOT NULL,
    saves                    INTEGER     NOT NULL,
    reach                    INTEGER     NOT NULL,
    impressions              INTEGER     NOT NULL,
    engagement_rate          NUMERIC(6,4) NOT NULL,
    followers_gained         INTEGER     NOT NULL,
    caption_length           INTEGER     NOT NULL,
    hashtags_count           INTEGER     NOT NULL,
    performance_bucket_label VARCHAR(10) NOT NULL
);
