SET search_path TO public, auth;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

CREATE OR REPLACE FUNCTION public.check_is_admin()
    RETURNS boolean AS
$$
SELECT EXISTS (SELECT 1
               FROM public.users
               WHERE auth_id = auth.uid()
                 AND ug_id = 0
                 AND NOT deleted);
$$ LANGUAGE sql STABLE
                SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_my_u_id()
    RETURNS integer AS
$$
SELECT u_id
FROM public.users
WHERE auth_id = auth.uid();
$$ LANGUAGE sql STABLE
                SECURITY DEFINER;

SET search_path TO public, auth, pg_temp;

-- User Groups -------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_groups
(
    ug_id serial PRIMARY KEY,
    name  bpchar NOT NULL
);
INSERT INTO user_groups (ug_id, name)
VALUES (0, 'Admin'),
       (1, 'PI and Chief of Staff'),
       (2, 'Students and Staff');
SELECT setval(
               pg_get_serial_sequence('user_groups', 'ug_id'),
               COALESCE((SELECT max(ug_id) FROM user_groups), 0)
       );
ALTER TABLE "public"."user_groups"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.user_groups TO authenticated;
GRANT SELECT ON TABLE public.user_groups TO authenticated;
create policy "UserGroupsSelectAuth"
    on "public"."user_groups"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (
    check_is_admin()
    );

-- Users -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users
(
    u_id    serial PRIMARY KEY,
    name    bpchar                                 NOT NULL,
    ug_id   integer REFERENCES user_groups (ug_id) NOT NULL,
    auth_id uuid REFERENCES auth.users             NOT NULL UNIQUE,
    deleted boolean                                NOT NULL
);
ALTER TABLE "public"."users"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.users TO authenticated;
GRANT SELECT, INSERT ON TABLE public.users TO authenticated;
REVOKE UPDATE ON public.users FROM authenticated;
GRANT UPDATE (deleted) ON public.users TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE users_u_id_seq TO authenticated;
create policy "UsersSelectAuth"
    on "public"."users"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (
    NOT deleted
    );
create policy "UsersInsertAuth"
    on "public"."users"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "UsersUpdateAuth"
    on "public"."users"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Facilities --------------------------------------------------------
CREATE TABLE IF NOT EXISTS facilities
(
    f_id    serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);
INSERT INTO facilities (f_id, name, deleted)
VALUES (0, 'Surgery', FALSE),
       (1, 'Storage', FALSE),
       (2, 'Cage Wash', FALSE),
       (3, 'Housing', FALSE),
       (4, 'Hibernaculum', FALSE);
SELECT setval(
               pg_get_serial_sequence('facilities', 'f_id'),
               COALESCE((SELECT max(f_id) FROM facilities), 0)
       );
ALTER TABLE "public"."facilities"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.facilities TO authenticated;
GRANT SELECT, INSERT ON TABLE public.facilities TO authenticated;
REVOKE UPDATE ON public.facilities FROM authenticated;
GRANT UPDATE (deleted) ON public.facilities TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE facilities_f_id_seq TO authenticated;
create policy "FacilitiesSelectAuth"
    on "public"."facilities"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "FacilitiesInsertAuth"
    on "public"."facilities"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "FacilitiesUpdateAuth"
    on "public"."facilities"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Labs --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS labs
(
    l_id    serial PRIMARY KEY,
    color   integer NOT NULL,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);
INSERT INTO labs (l_id, color, name, deleted)
VALUES (0, 16777215, 'Merriman', false),
       (1, 16776960, 'Fauna', false),
       (2, 16711935, 'Boonpattrawong', false),
       (3, 65535, 'Kurtz', false);
SELECT setval(
               pg_get_serial_sequence('labs', 'l_id'),
               COALESCE((SELECT max(l_id) FROM labs), 0)
       );
ALTER TABLE "public"."labs"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.labs TO authenticated;
GRANT SELECT, INSERT ON TABLE public.labs TO authenticated;
REVOKE UPDATE ON public.labs FROM authenticated;
GRANT UPDATE (color, deleted) ON public.labs TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE labs_l_id_seq TO authenticated;
create policy "LabsSelectAuth"
    on "public"."labs"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "LabsInsertAuth"
    on "public"."labs"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "LabsUpdateAuth"
    on "public"."labs"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Enrichment Lists --------------------------------------------------
CREATE TABLE IF NOT EXISTS enrichment_lists
(
    el_id   serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);
ALTER TABLE "public"."enrichment_lists"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.enrichment_lists TO authenticated;
GRANT SELECT, INSERT ON TABLE public.enrichment_lists TO authenticated;
REVOKE UPDATE ON public.enrichment_lists FROM authenticated;
GRANT UPDATE (deleted) ON public.enrichment_lists TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE enrichment_lists_el_id_seq TO authenticated;
create policy "EnrichmentListsSelectAuth"
    on "public"."enrichment_lists"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "EnrichmentListsInsertAuth"
    on "public"."enrichment_lists"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "EnrichmentListsUpdateAuth"
    on "public"."enrichment_lists"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Rooms -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rooms
(
    r_id    serial PRIMARY KEY,
    name    bpchar                               NOT NULL,
    f_id    integer REFERENCES facilities (f_id) NOT NULL,
    l_id    integer REFERENCES labs (l_id),
    el_id   integer REFERENCES enrichment_lists (el_id),
    deleted boolean                              NOT NULL
);
INSERT INTO rooms(r_id, name, f_id, l_id, el_id, deleted)
VALUES (0, 'CACF 36B', 3, 0, NULL, false),
       (1, 'CACF 36C', 3, 0, NULL, false),
       (2, 'CACF 36D', 3, 0, NULL, false),
       (3, 'CACF 36E', 3, 0, NULL, false),
       (4, 'CACF 36F', 3, 0, NULL, false),
       (5, 'CACF 36G', 1, 0, NULL, false),
       (6, 'CACF 36H', 3, 0, NULL, false),
       (7, 'CACF 36J', 0, 0, NULL, false),
       (8, 'CACF 36K', 0, 0, NULL, false),
       (9, 'CACF 36L', 2, 0, NULL, false),
       (10, 'HACF 17', 1, 3, NULL, false),
       (11, 'HACF 19A', 3, 3, NULL, false),
       (12, 'HACF 19B', 3, 0, NULL, false),
       (13, 'HACF 19C', 3, 3, NULL, false),
       (14, 'HACF 19D', 4, 0, NULL, false),
       (15, 'HACF 19E/F', 2, 3, NULL, false),
       (16, 'HACF 19G', 0, 3, NULL, false),
       (17, 'HACF 19H', 3, 3, NULL, false),
       (18, 'HACF 19J', 3, 3, NULL, false),
       (19, 'HACF 56A', 4, NULL, NULL, false);
SELECT setval(
               pg_get_serial_sequence('rooms', 'r_id'),
               COALESCE((SELECT max(r_id) FROM rooms), 0)
       );
ALTER TABLE "public"."rooms"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.rooms TO authenticated;
GRANT SELECT, INSERT ON TABLE public.rooms TO authenticated;
REVOKE UPDATE ON public.rooms FROM authenticated;
GRANT UPDATE (deleted) ON public.rooms TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE rooms_r_id_seq TO authenticated;
create policy "RoomsSelectAuth"
    on "public"."rooms"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "RoomsInsertAuth"
    on "public"."rooms"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "RoomsUpdateAuth"
    on "public"."rooms"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Lab Group Memberships ---------------------------------------------
CREATE TABLE IF NOT EXISTS lab_group_memberships
(
    l_id integer REFERENCES labs (l_id)  NOT NULL,
    u_id integer REFERENCES users (u_id) NOT NULL,
    PRIMARY KEY (l_id, u_id)
);
ALTER TABLE "public"."lab_group_memberships"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.lab_group_memberships TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.lab_group_memberships TO authenticated;
create policy "LabGroupMembershipsSelectAuth"
    on "public"."lab_group_memberships"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "LabGroupMembershipsInsertAuth"
    on "public"."lab_group_memberships"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "LabGroupMembershipsUpdateAuth"
    on "public"."lab_group_memberships"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Censuses ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS censuses
(
    c_id      serial PRIMARY KEY,
    date_time timestamptz                     NOT NULL,
    r_id      integer REFERENCES rooms (r_id) NOT NULL,
    u_id      integer REFERENCES users (u_id) NOT NULL
);
ALTER TABLE "public"."censuses"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.censuses TO authenticated;
GRANT SELECT, INSERT ON TABLE public.censuses TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE censuses_c_id_seq TO authenticated;
create policy "CensusesSelectAuth"
    on "public"."censuses"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "CensusesInsertAuth"
    on "public"."censuses"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (true);

-- Animals -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS animals
(
    a_id    serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);
ALTER TABLE "public"."animals"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.animals TO authenticated;
GRANT SELECT, INSERT ON TABLE public.animals TO authenticated;
REVOKE UPDATE ON public.animals FROM authenticated;
GRANT UPDATE (deleted) ON public.animals TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE animals_a_id_seq TO authenticated;
create policy "AnimalsSelectAuth"
    on "public"."animals"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "AnimalsInsertAuth"
    on "public"."animals"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "AnimalsUpdateAuth"
    on "public"."animals"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Census Records ----------------------------------------------------
CREATE TABLE IF NOT EXISTS census_records
(
    c_id              integer REFERENCES censuses (c_id) NOT NULL,
    a_id              integer REFERENCES animals (a_id)  NOT NULL,
    number_of_animals smallint                           NOT NULL,
    PRIMARY KEY (c_id, a_id)
);
ALTER TABLE "public"."census_records"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.census_records TO authenticated;
GRANT SELECT, INSERT ON TABLE public.census_records TO authenticated;
create policy "CensusRecordsSelectAuth"
    on "public"."census_records"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "CensusRecordsInsertAuth"
    on "public"."census_records"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (true);

-- Week Day ----------------------------------------------------------
CREATE TYPE week_day AS ENUM (
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
    );

-- Enrichment Types --------------------------------------------------
CREATE TABLE IF NOT EXISTS enrichment_types
(
    et_id       serial PRIMARY KEY,
    description bpchar  NOT NULL,
    deleted     boolean NOT NULL
);
ALTER TABLE "public"."enrichment_types"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.enrichment_types TO authenticated;
GRANT SELECT, INSERT ON TABLE public.enrichment_types TO authenticated;
REVOKE UPDATE ON public.enrichment_types FROM authenticated;
GRANT UPDATE (deleted) ON public.enrichment_types TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE enrichment_types_et_id_seq TO authenticated;
create policy "EnrichmentTypesSelectAuth"
    on "public"."enrichment_types"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "EnrichmentTypesInsertAuth"
    on "public"."enrichment_types"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "EnrichmentTypesUpdateAuth"
    on "public"."enrichment_types"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Enrichments -------------------------------------------------------
CREATE TABLE IF NOT EXISTS enrichments
(
    e_id        serial PRIMARY KEY,
    day_of_week week_day                                    NOT NULL,
    et_id       integer REFERENCES enrichment_types (et_id) NOT NULL,
    deleted     boolean                                     NOT NULL
);
ALTER TABLE "public"."enrichments"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.enrichments TO authenticated;
GRANT SELECT, INSERT ON TABLE public.enrichments TO authenticated;
REVOKE UPDATE ON public.enrichments FROM authenticated;
GRANT UPDATE (deleted) ON public.enrichments TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE enrichments_e_id_seq TO authenticated;
create policy "EnrichmentsSelectAuth"
    on "public"."enrichments"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "EnrichmentsInsertAuth"
    on "public"."enrichments"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "EnrichmentsUpdateAuth"
    on "public"."enrichments"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Enrichment List Memberships ---------------------------------------
CREATE TABLE IF NOT EXISTS enrichment_list_memberships
(
    el_id integer REFERENCES enrichment_lists (el_id) NOT NULL,
    e_id  integer REFERENCES enrichments (e_id)       NOT NULL,
    PRIMARY KEY (el_id, e_id)
);
ALTER TABLE "public"."enrichment_list_memberships"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.enrichment_list_memberships TO authenticated;
GRANT SELECT, INSERT ON TABLE public.enrichment_list_memberships TO authenticated;
create policy "EnrichmentListMembershipsSelectAuth"
    on "public"."enrichment_list_memberships"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "EnrichmentListMembershipsInsertAuth"
    on "public"."enrichment_list_memberships"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());

-- Enrichment List Assignment Dates ----------------------------------
CREATE TABLE IF NOT EXISTS enrichment_list_assignment_dates
(
    ela_id    serial PRIMARY KEY,
    date_time timestamptz                                 NOT NULL,
    el_id     integer REFERENCES enrichment_lists (el_id) NOT NULL,
    r_id      integer REFERENCES rooms (r_id)             NOT NULL
);
ALTER TABLE "public"."enrichment_list_assignment_dates"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.enrichment_list_assignment_dates TO authenticated;
GRANT SELECT, INSERT ON TABLE public.enrichment_list_assignment_dates TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE enrichment_list_assignment_dates_ela_id_seq TO authenticated;
create policy "EnrichmentListAssignment_DatesSelectAuth"
    on "public"."enrichment_list_assignment_dates"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "EnrichmentListAssignmentDatesInsertAuth"
    on "public"."enrichment_list_assignment_dates"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());

-- Task Frequency ----------------------------------------------------
CREATE TYPE task_frequency AS ENUM (
    'Daily',
    'Weekly',
    'Monthly'
    );

-- Task Lists --------------------------------------------------------
CREATE TABLE IF NOT EXISTS task_lists
(
    tl_id     serial PRIMARY KEY,
    name      bpchar         NOT NULL,
    frequency task_frequency NOT NULL,
    deleted   boolean        NOT NULL
);
INSERT INTO task_lists (tl_id, name, frequency, deleted)
VALUES (0, 'Empty/Idle Room Daily Tasks', 'Daily', false),
       (1, 'Surgery Room Daily Tasks', 'Daily', false),
       (2, 'Storage Room Daily Tasks', 'Daily', false),
       (3, 'Cagewash Room Daily Tasks', 'Daily', false),
       (4, 'Housing Daily Tasks', 'Daily', false),
       (5, 'Hibernaculum Daily Tasks', 'Daily', false),

       (6, 'Empty/Idle Room Weekly Tasks', 'Weekly', false),
       (7, 'Surgery Room Weekly Tasks', 'Weekly', false),
       (8, 'Storage Room Weekly Tasks', 'Weekly', false),
       (9, 'Cagewash Room Weekly Tasks', 'Weekly', false),
       (10, 'Housing Weekly Tasks', 'Weekly', false),
       (11, 'Hibernaculum Weekly Tasks', 'Weekly', false),

       (12, 'Surgery Room Monthly Tasks', 'Monthly', false),
       (13, 'Storage Room Monthly Tasks', 'Monthly', false),
       (14, 'Cagewash Room Monthly Tasks', 'Monthly', false),
       (15, 'Housing Monthly Tasks', 'Monthly', false),
       (16, 'Hibernaculum Monthly Tasks', 'Monthly', false);
SELECT setval(
               pg_get_serial_sequence('task_lists', 'tl_id'),
               COALESCE((SELECT max(tl_id) FROM task_lists), 0)
       );
ALTER TABLE "public"."task_lists"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.task_lists TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_lists TO authenticated;
REVOKE UPDATE ON public.task_lists FROM authenticated;
GRANT UPDATE (deleted) ON public.task_lists TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE task_lists_tl_id_seq TO authenticated;
create policy "Task_ListsSelectAuth"
    on "public"."task_lists"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "TaskListsInsertAuth"
    on "public"."task_lists"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "TaskListsUpdateAuth"
    on "public"."task_lists"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Tasks -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tasks
(
    t_id    serial PRIMARY KEY,
    name    bpchar  NOT NULL,
    deleted boolean NOT NULL
);
INSERT INTO tasks (t_id, name, deleted)
VALUES (0, 'Room Temperature', false),
       (1, 'Hibernaculum Temperature', false),
       (2, 'Room Humidity', false),
       (3, 'Hibernaculum Humidity', false),
       (4, 'Wipe Counters & Sweep', false),
       (5, 'Check Vermin Trap', false),
       (6, 'Sweep', false),
       (7, 'View Each Animal', false),
       (8, 'Give/Check Food & Water', false),
       (9, 'Double Check Water', false),
       (10, 'Mop Floor', false),
       (11, 'Manager Walkthrough', false),
       (12, 'Manager Check Expiration Dates on Drugs/Supplies',
        false),
       (13, 'Perform Cage Wash Temp Strip Test', false),
       (14, 'Change Cage/Bedding', false),
       (15, 'Change Water Bottle', false),
       (16, 'Sanitize Enrichment', false),
       (17, 'Check Light Timer', false),
       (18, 'Mop Walls and Ceiling', false),
       (19, 'Sanitize Garbage Can', false),
       (20, 'Sanitize Mop Buckets & Cloth Mop Heads', false),
       (21, 'Sanitize Dust Pans', false),
       (22, 'Replace Disinfectant', false),
       (23, 'Check Function of Heaters or Dehumidifiers, If Present',
        false),
       (24, 'Sanitize Storage Barrels & Scoops', false),
       (25, 'Sanitize Small Containers, If Present', false),
       (26, 'Refill Bins With Bedding, If Present', false),
       (27, 'Sanitize bedding disposal station', false),
       (28, 'Clean Sink With Comet, Then Spray With WD-40', false),
       (29, 'Wipe Cage Washer Exterior With WD-40', false),
       (30, 'Sanitize Water Bottle Filler', false),
       (31, 'Clean Paper Towel & Soap Dispensers', false),
       (32, 'Sanitize All Garbage Cans, Including Any In Hallway',
        false),
       (33, 'Disinfect Drain Per Sign Taped to the Wall', false),
       (34, 'Clean Sink With Comet', false),
       (35, 'Clean Refrigerator', false),
       (36, 'Check Euthanasia Equipment', false),
       (37, 'Check Anaesthesia Equipment', false),
       (38,
        'Lab Animal Manager Checks Expiration Dates and Replaces as Needed',
        false),
       (39, 'Sanitize Shelves/Racks/Carts', false);
SELECT setval(
               pg_get_serial_sequence('tasks', 't_id'),
               COALESCE((SELECT max(t_id) FROM tasks), 0)
       );
ALTER TABLE "public"."tasks"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.tasks TO authenticated;
GRANT SELECT, INSERT ON TABLE public.tasks TO authenticated;
REVOKE UPDATE ON public.tasks FROM authenticated;
GRANT UPDATE (deleted) ON public.tasks TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE tasks_t_id_seq TO authenticated;
create policy "TasksSelectAuth"
    on "public"."tasks"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "TasksInsertAuth"
    on "public"."tasks"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "TasksUpdateAuth"
    on "public"."tasks"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Quantitative Ranges -----------------------------------------------
CREATE TABLE IF NOT EXISTS quantitative_ranges
(
    qr_id    serial PRIMARY KEY,
    unit     bpchar  NOT NULL,
    required boolean NOT NULL,
    maximum  numeric NOT NULL,
    minimum  numeric NOT NULL,
    deleted  boolean NOT NULL,
    CHECK ( minimum < maximum )
);
INSERT INTO quantitative_ranges (qr_id, unit, required, maximum,
                                 minimum, deleted)
VALUES (0, 'Fahrenheit', false, 79, 32, false),
       (1, 'Fahrenheit', false, 42, 32, false),
       (2, 'RH', true, 99.9, 0, false),
       (3, 'RH', false, 70, 30, false),
       (4, 'RH', false, 40, 30, false);
SELECT setval(
               pg_get_serial_sequence('quantitative_ranges', 'qr_id'),
               COALESCE((SELECT max(qr_id) FROM quantitative_ranges),
                        0)
       );
ALTER TABLE "public"."quantitative_ranges"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.quantitative_ranges TO authenticated;
GRANT SELECT, INSERT ON TABLE public.quantitative_ranges TO authenticated;
REVOKE UPDATE ON public.quantitative_ranges FROM authenticated;
GRANT UPDATE (deleted) ON public.quantitative_ranges TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE quantitative_ranges_qr_id_seq TO authenticated;
create policy "QuantitativeRangesSelectAuth"
    on "public"."quantitative_ranges"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "QuantitativeRangesInsertAuth"
    on "public"."quantitative_ranges"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());
create policy "QuantitativeRangesUpdateAuth"
    on "public"."quantitative_ranges"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Quantitative Tasks ------------------------------------------------
CREATE TABLE IF NOT EXISTS quantitative_tasks
(
    t_id  integer REFERENCES tasks (t_id)                NOT NULL,
    qr_id integer REFERENCES quantitative_ranges (qr_id) NOT NULL,
    PRIMARY KEY (t_id, qr_id)
);
INSERT INTO quantitative_tasks (t_id, qr_id)
VALUES (0, 0),
       (1, 1),
       (2, 2),
       (3, 2),
       (2, 3),
       (3, 4);
ALTER TABLE "public"."quantitative_tasks"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.quantitative_tasks TO authenticated;
GRANT SELECT, INSERT ON TABLE public.quantitative_tasks TO authenticated;
create policy "QuantitativeTasksSelectAuth"
    on "public"."quantitative_tasks"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "QuantitativeTasksInsertAuth"
    on "public"."quantitative_tasks"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());

-- Task List Task Memberships ---------------------------------------------
CREATE TABLE IF NOT EXISTS task_list_task_memberships
(
    tl_id integer REFERENCES task_lists (tl_id) NOT NULL,
    t_id  integer REFERENCES tasks (t_id)       NOT NULL,
    PRIMARY KEY (tl_id, t_id)
);
INSERT INTO task_list_task_memberships (tl_id, t_id)
VALUES (0, 0),
       (0, 2),

       (1, 0),
       (1, 2),
       (1, 4),
       (1, 5),

       (2, 0),
       (2, 2),
       (2, 4),
       (2, 5),

       (3, 0),
       (3, 2),
       (3, 6),
       (3, 5),

       (4, 0),
       (4, 2),
       (4, 7),
       (4, 8),
       (4, 4),
       (4, 5),
       (4, 9),

       (5, 1),
       (5, 3),
       (5, 7),
       (5, 8),
       (5, 4),
       (5, 5),
       (5, 9),

       (6, 11),

       (7, 10),
       (7, 11),
       (7, 12),

       (8, 10),
       (8, 11),

       (9, 13),
       (9, 10),
       (9, 11),

       (10, 14),
       (10, 15),
       (10, 16),
       (10, 17),
       (10, 10),
       (10, 11),

       (11, 14),
       (11, 15),
       (11, 16),
       (11, 17),
       (11, 10),
       (11, 11),

       (12, 18),
       (12, 39),
       (12, 34),
       (12, 31),
       (12, 19),
       (12, 20),
       (12, 24),
       (12, 25),
       (12, 21),
       (12, 22),
       (12, 26),
       (12, 35),
       (12, 36),
       (12, 37),

       (13, 18),
       (13, 39),
       (13, 19),
       (13, 20),
       (13, 24),
       (13, 25),
       (13, 21),
       (13, 22),
       (13, 26),

       (14, 18),
       (14, 27),
       (14, 28),
       (14, 29),
       (14, 30),
       (14, 31),
       (14, 32),
       (14, 20),
       (14, 21),
       (14, 22),
       (14, 33),

       (15, 18),
       (15, 39),
       (15, 19),
       (15, 20),
       (15, 21),
       (15, 22),
       (15, 26);
ALTER TABLE "public"."task_list_task_memberships"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.task_list_task_memberships TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_list_task_memberships TO authenticated;
create policy "TaskListTaskMembershipsSelectAuth"
    on "public"."task_list_task_memberships"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "TaskListTaskMembershipsInsertAuth"
    on "public"."task_list_task_memberships"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());

-- Task List Room Memberships ----------------------------------------
CREATE TABLE IF NOT EXISTS task_list_room_memberships
(
    tl_id integer REFERENCES task_lists (tl_id) NOT NULL,
    r_id  integer REFERENCES rooms (r_id)       NOT NULL,
    PRIMARY KEY (tl_id, r_id)
);
INSERT INTO task_list_room_memberships (tl_id, r_id)
VALUES (4, 0),
       (10, 0),
       (15, 0),

       (4, 1),
       (10, 1),
       (15, 1),

       (4, 2),
       (10, 2),
       (15, 2),

       (4, 3),
       (10, 3),
       (15, 3),

       (4, 4),
       (10, 4),
       (15, 4),

       (2, 5),
       (8, 5),
       (13, 5),

       (4, 6),
       (10, 6),
       (15, 6),

       (1, 7),
       (7, 7),
       (12, 7),

       (1, 8),
       (7, 8),
       (12, 8),

       (3, 9),
       (9, 9),
       (14, 9),

       (2, 10),
       (8, 10),
       (13, 10),

       (4, 11),
       (10, 11),
       (15, 11),

       (4, 12),
       (10, 12),
       (15, 12),

       (4, 13),
       (10, 13),
       (15, 13),

       (5, 14),
       (11, 14),
       (16, 14),

       (3, 15),
       (9, 15),
       (14, 15),

       (1, 16),
       (7, 16),
       (12, 16),

       (4, 17),
       (10, 17),
       (15, 17),

       (4, 18),
       (10, 18),
       (15, 18),

       (5, 19),
       (11, 19),
       (16, 19);
ALTER TABLE "public"."task_list_room_memberships"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.task_list_room_memberships TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_list_room_memberships TO authenticated;
create policy "TaskListRoomMembershipsSelectAuth"
    on "public"."task_list_room_memberships"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "TaskListRoomMembershipsInsertAuth"
    on "public"."task_list_room_memberships"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (check_is_admin());

-- Room Check State --------------------------------------------------
CREATE TYPE room_check_state AS ENUM ('not_started', 'started', 'done');

-- Room Check Slots --------------------------------------------------
CREATE TABLE IF NOT EXISTS room_check_slots
(
    rc_id     serial PRIMARY KEY,
    date_time timestamptz                     NOT NULL,
    r_id      integer REFERENCES rooms (r_id) NOT NULL,
    state     room_check_state                NOT NULL,
    comment   bpchar,
    u_id      integer REFERENCES users (u_id)
);
ALTER TABLE "public"."room_check_slots"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.room_check_slots TO authenticated;
GRANT SELECT, INSERT ON TABLE public.room_check_slots TO authenticated;
REVOKE UPDATE ON public.room_check_slots FROM authenticated;
GRANT UPDATE (state, comment, u_id) ON public.room_check_slots TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE room_check_slots_rc_id_seq TO authenticated;
create policy "RoomCheckSlotsSelectAuth"
    on "public"."room_check_slots"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "RoomCheckSlotsInsertAuth"
    on "public"."room_check_slots"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (
    check_is_admin() OR
    u_id IS NULL OR
    u_id = get_my_u_id()
    );
create policy "RoomCheckSlotsUpdateAuth"
    on "public"."room_check_slots"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    true
    )
    WITH CHECK (
    ((comment IS NULL) OR
     (comment = (SELECT r.comment
                 FROM room_check_slots r
                 WHERE r.rc_id = rc_id))) AND
    ((check_is_admin() OR
      u_id = get_my_u_id())));

-- Task Records ------------------------------------------------------
CREATE TABLE IF NOT EXISTS task_records
(
    tr_id     serial PRIMARY KEY,
    t_id      integer REFERENCES tasks (t_id)             NOT NULL,
    rc_id     integer REFERENCES room_check_slots (rc_id) NOT NULL,
    date_time timestamptz                                 NOT NULL
);
ALTER TABLE task_records
    ADD CONSTRAINT unique_task_per_check UNIQUE (t_id, rc_id);
ALTER TABLE "public"."task_records"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.task_records TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_records TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE task_records_tr_id_seq TO authenticated;
create policy "TaskRecordsSelectAuth"
    on "public"."task_records"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "TaskRecordsInsertAuth"
    on "public"."task_records"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (date_time::date = CURRENT_DATE);

-- Quantitative Task Records -----------------------------------------
CREATE TABLE IF NOT EXISTS quantitative_task_records
(
    tr_id integer PRIMARY KEY REFERENCES task_records (tr_id),
    value numeric NOT NULL
);
ALTER TABLE "public"."quantitative_task_records"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.quantitative_task_records TO authenticated;
GRANT SELECT, INSERT ON TABLE public.quantitative_task_records TO authenticated;
REVOKE UPDATE ON public.quantitative_task_records FROM authenticated;
GRANT UPDATE (value) ON public.quantitative_task_records TO authenticated;
create policy "Quantitative_Task_RecordsSelectAuth"
    on "public"."quantitative_task_records"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "QuantitativeTaskRecordsInsertAuth"
    on "public"."quantitative_task_records"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (true);
create policy "QuantitativeTaskRecordsUpdateAuth"
    on "public"."quantitative_task_records"
    as PERMISSIVE
    for UPDATE
    to authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

-- Task Record Users -------------------------------------------------
CREATE TABLE IF NOT EXISTS task_record_users
(
    tr_id integer REFERENCES task_records (tr_id) NOT NULL,
    u_id  integer REFERENCES users (u_id)         NOT NULL,
    PRIMARY KEY (tr_id, u_id)
);
ALTER TABLE "public"."task_record_users"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.task_record_users TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_record_users TO authenticated;
create policy "Task_Record_UsersSelectAuth"
    on "public"."task_record_users"
    as PERMISSIVE
    for SELECT
    to authenticated
    using (true);
create policy "TaskRecordUsersInsertAuth"
    on "public"."task_record_users"
    as PERMISSIVE
    for INSERT
    to authenticated
    WITH CHECK (true);