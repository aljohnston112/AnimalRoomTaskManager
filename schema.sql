CREATE TABLE facilities
(
    f_id    serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);

INSERT INTO facilities (f_id, name, deleted)
VALUES (0, "Surgery", FALSE),
       (1, "Storage", FALSE),
       (2, "Cage Wash", FALSE),
       (3, "Housing", FALSE),
       (4, "Hibernaculum", FALSE);

CREATE TABLE labs
(
    l_id    serial PRIMARY KEY,
    color   integer NOT NULL,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);

INSERT INTO labs (l_id, color, name, deleted)
VALUES (0, FF81637083, "Merriman", false),
       (1, FF88330166, "Fauna", false),
       (2, FF79975068, "Boonpattrawong", false);
<--TODO figure out lab colors -->

CREATE TABLE enrichment_lists
(
    el_id   serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);

CREATE TABLE rooms
(
    r_id  serial PRIMARY KEY,
    name  bpchar                               NOT NULL,
    f_id  integer REFERENCES facilities (f_id) NOT NULL,
    l_id  integer REFERENCES labs (l_id)       NOT NULL,
    el_id integer REFERENCES enrichment_lists (el_id)
);

CREATE TABLE user_groups
(
    ug_id serial PRIMARY KEY,
    name  bpchar NOT NULL
);

CREATE TABLE users
(
    u_id    serial PRIMARY KEY,
    name    bpchar                                 NOT NULL,
    ug_id   integer REFERENCES user_groups (ug_id) NOT NULL,
    deleted boolean                                NOT NULL
);


CREATE TABLE censuses
(
    c_id      serial PRIMARY KEY,
    date_time timestamptz                     NOT NULL,
    r_id      integer REFERENCES rooms (r_id) NOT NULL,
    u_id      integer REFERENCES users (u_id) NOT NULL
);

CREATE TABLE animals
(
    a_id serial PRIMARY KEY,
    name bpchar NOT NULL
);

CREATE TABLE census_records
(
    c_id              integer REFERENCES censuses (c_id) NOT NULL,
    a_id              integer REFERENCES animals (a_id)  NOT NULL,
    number_of_animals smallint                           NOT NULL,
    PRIMARY KEY (c_id, a_id)
);

CREATE TYPE week_day AS ENUM (
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
);

CREATE TABLE enrichment_types
(
    et_id       serial PRIMARY KEY,
    description bpchar  NOT NULL,
    deleted     boolean NOT NULL
);

CREATE TABLE enrichments
(
    e_id        serial PRIMARY KEY,
    day_of_week week_day                                    NOT NULL,
    et_id       integer REFERENCES enrichment_types (et_id) NOT NULL
);

CREATE TABLE enrichment_list_memberships
(
    el_id integer REFERENCES enrichment_lists (el_id) NOT NULL,
    e_id  integer REFERENCES enrichments (e_id)       NOT NULL,
    PRIMARY KEY (el_id, e_id)
);

CREATE TABLE tasks
(
    t_id    serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);

CREATE TABLE quantitative_ranges
(
    qr_id   serial PRIMARY KEY,
    unit    bpchar  NOT NULL,
    maximum numeric NOT NULL,
    minimum numeric NOT NULL,
    CHECK ( minimum < maximum )
);

CREATE TABLE quantitative_tasks
(
    t_id  integer PRIMARY KEY REFERENCES tasks (t_id)    NOT NULL,
    qr_id integer REFERENCES quantitative_ranges (qr_id) NOT NULL
);

CREATE TYPE task_frequency AS ENUM (
    'Daily',
    'Weekly',
    'Monthly'
);

CREATE TABLE task_lists
(
    tl_id     serial PRIMARY KEY,
    name      bpchar         NOT NULL,
    frequency task_frequency NOT NULL,
    deleted   boolean        NOT NULL
);

CREATE TABLE task_list_task_memberships
(
    tl_id integer REFERENCES task_lists (tl_id) NOT NULL,
    t_id  integer REFERENCES tasks (t_id)       NOT NULL,
    PRIMARY KEY (tl_id, t_id)
);

CREATE TABLE task_list_room_memberships
(
    tl_id integer REFERENCES task_lists (tl_id) NOT NULL,
    r_id  integer REFERENCES rooms (r_id)       NOT NULL,
    PRIMARY KEY (tl_id, r_id)
);

CREATE TABLE room_check_slots
(
    rc_id     serial PRIMARY KEY,
    date_time timestamptz                     NOT NULL,
    r_id      integer REFERENCES rooms (r_id) NOT NULL,
    done      boolean                         NOT NULL,
    u_id      integer REFERENCES users (u_id) NOT NULL
);

CREATE TABLE task_records
(
    tr_id     serial PRIMARY KEY,
    t_id      integer REFERENCES tasks (t_id)             NOT NULL,
    rc_id     integer REFERENCES room_check_slots (rc_id) NOT NULL,
    date_time timestamptz                                 NOT NULL,
    comment   bpchar                                      NOT NULL
);

CREATE TABLE quantitative_task_records
(
    tr_id integer PRIMARY KEY REFERENCES task_records (tr_id),
    value numeric NOT NULL
);

CREATE TABLE task_record_users
(
    tr_id integer REFERENCES task_records (tr_id) NOT NULL,
    u_id  integer REFERENCES users (u_id)         NOT NULL,
    PRIMARY KEY (tr_id, u_id)
);

CREATE TABLE enrichment_list_assignment_dates
(
    ela_id    serial PRIMARY KEY,
    date_time timestamptz                                 NOT NULL,
    el_id     integer REFERENCES enrichment_lists (el_id) NOT NULL,
    r_id      integer REFERENCES rooms (r_id)             NOT NULL
);