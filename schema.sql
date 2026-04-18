DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
SET search_path TO public, auth;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

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
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('user_groups', 'ug_id'),
               COALESCE((SELECT MAX(ug_id) FROM user_groups), 0)
       );
ALTER TABLE "public"."user_groups"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.user_groups TO authenticated;
GRANT SELECT ON TABLE public.user_groups TO authenticated;

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
CREATE POLICY "UsersSelectAuth"
    ON "public"."users"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
    NOT deleted
    );
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
SET search_path TO public, auth, pg_temp;
CREATE POLICY "UserGroupsSelectAuth"
    ON "public"."user_groups"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
    check_is_admin()
    );
CREATE POLICY "UsersInsertAuth"
    ON "public"."users"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "UsersUpdateAuth"
    ON "public"."users"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

CREATE OR REPLACE FUNCTION get_my_u_id()
    RETURNS integer AS
$$
SELECT u_id
FROM public.users
WHERE auth_id = auth.uid();
$$ LANGUAGE sql STABLE
                SECURITY DEFINER;
SET search_path TO public, auth, pg_temp;

CREATE TABLE IF NOT EXISTS email_whitelist
(
    email bpchar PRIMARY KEY,
    ug_id integer REFERENCES user_groups (ug_id) NOT NULL
);
ALTER TABLE "public"."email_whitelist"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.email_whitelist TO authenticated;
GRANT SELECT, INSERT, DELETE ON TABLE public.email_whitelist TO authenticated;
CREATE POLICY "EmailWhitelistSelectAuth"
    ON "public"."email_whitelist"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (check_is_admin() OR email = auth.email());
CREATE POLICY "EmailWhitelistInsertAuth"
    ON "public"."email_whitelist"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "EmailWhitelistDeleteAuth"
    ON "public"."email_whitelist"
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (check_is_admin());
CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS trigger AS
$$
DECLARE
    _ug_id integer;
BEGIN
    SELECT ug_id
    INTO _ug_id
    FROM public.email_whitelist
    WHERE email = NEW.email;
    IF _ug_id IS NOT NULL THEN
        INSERT INTO public.users (name, ug_id, auth_id, deleted)
        VALUES (NEW.email, _ug_id, NEW.id, FALSE);
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'This email is not authorized to register.';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
SET search_path TO public, auth, pg_temp;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT
    ON auth.users
    FOR EACH ROW
EXECUTE PROCEDURE public.handle_new_user();

CREATE OR REPLACE FUNCTION public.on_user_deleted_purge()
    RETURNS trigger AS
$$
BEGIN
    IF (NEW.deleted = TRUE AND OLD.deleted = FALSE) THEN
        DELETE
        FROM public.email_whitelist
        WHERE email =
              (SELECT email FROM auth.users WHERE id = NEW.auth_id);
        DELETE FROM auth.users WHERE id = NEW.auth_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
SET search_path TO public, auth, pg_temp;

CREATE TRIGGER trigger_purge_user
    AFTER UPDATE OF deleted
    ON public.users
    FOR EACH ROW
EXECUTE PROCEDURE public.on_user_deleted_purge();

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
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('facilities', 'f_id'),
               COALESCE((SELECT MAX(f_id) FROM facilities), 0)
       );
ALTER TABLE "public"."facilities"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.facilities TO authenticated;
GRANT SELECT, INSERT ON TABLE public.facilities TO authenticated;
REVOKE UPDATE ON public.facilities FROM authenticated;
GRANT UPDATE (deleted) ON public.facilities TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE facilities_f_id_seq TO authenticated;
CREATE POLICY "FacilitiesSelectAuth"
    ON "public"."facilities"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "FacilitiesInsertAuth"
    ON "public"."facilities"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "FacilitiesUpdateAuth"
    ON "public"."facilities"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
VALUES (0, 16777215, 'Merriman', FALSE),
       (1, 16776960, 'Fauna', FALSE),
       (2, 16711935, 'Boonpattrawong', FALSE),
       (3, 65535, 'Kurtz', FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('labs', 'l_id'),
               COALESCE((SELECT MAX(l_id) FROM labs), 0)
       );
ALTER TABLE "public"."labs"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.labs TO authenticated;
GRANT SELECT, INSERT ON TABLE public.labs TO authenticated;
REVOKE UPDATE ON public.labs FROM authenticated;
GRANT UPDATE (color, deleted) ON public.labs TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE labs_l_id_seq TO authenticated;
CREATE POLICY "LabsSelectAuth"
    ON "public"."labs"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "LabsInsertAuth"
    ON "public"."labs"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "LabsUpdateAuth"
    ON "public"."labs"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "EnrichmentListsSelectAuth"
    ON "public"."enrichment_lists"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "EnrichmentListsInsertAuth"
    ON "public"."enrichment_lists"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "EnrichmentListsUpdateAuth"
    ON "public"."enrichment_lists"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
VALUES (0, 'CACF 36B', 3, 0, NULL, FALSE),
       (1, 'CACF 36C', 3, 0, NULL, FALSE),
       (2, 'CACF 36D', 3, 0, NULL, FALSE),
       (3, 'CACF 36E', 3, 0, NULL, FALSE),
       (4, 'CACF 36F', 3, 0, NULL, FALSE),
       (5, 'CACF 36G', 1, 0, NULL, FALSE),
       (6, 'CACF 36H', 3, 0, NULL, FALSE),
       (7, 'CACF 36J', 0, 0, NULL, FALSE),
       (8, 'CACF 36K', 0, 0, NULL, FALSE),
       (9, 'CACF 36L', 2, 0, NULL, FALSE),
       (10, 'HACF 17', 1, 3, NULL, FALSE),
       (11, 'HACF 19A', 3, 3, NULL, FALSE),
       (12, 'HACF 19B', 3, 0, NULL, FALSE),
       (13, 'HACF 19C', 3, 3, NULL, FALSE),
       (14, 'HACF 19D', 4, 0, NULL, FALSE),
       (15, 'HACF 19E/F', 2, 3, NULL, FALSE),
       (16, 'HACF 19G', 0, 3, NULL, FALSE),
       (17, 'HACF 19H', 3, 3, NULL, FALSE),
       (18, 'HACF 19J', 3, 3, NULL, FALSE),
       (19, 'HACF 56A', 4, NULL, NULL, FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('rooms', 'r_id'),
               COALESCE((SELECT MAX(r_id) FROM rooms), 0)
       );
ALTER TABLE "public"."rooms"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.rooms TO authenticated;
GRANT SELECT, INSERT ON TABLE public.rooms TO authenticated;
REVOKE UPDATE ON public.rooms FROM authenticated;
GRANT UPDATE (deleted) ON public.rooms TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE rooms_r_id_seq TO authenticated;
CREATE POLICY "RoomsSelectAuth"
    ON "public"."rooms"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "RoomsInsertAuth"
    ON "public"."rooms"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "RoomsUpdateAuth"
    ON "public"."rooms"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "LabGroupMembershipsSelectAuth"
    ON "public"."lab_group_memberships"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "LabGroupMembershipsInsertAuth"
    ON "public"."lab_group_memberships"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "LabGroupMembershipsUpdateAuth"
    ON "public"."lab_group_memberships"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "CensusesSelectAuth"
    ON "public"."censuses"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "CensusesInsertAuth"
    ON "public"."censuses"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);

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
CREATE POLICY "AnimalsSelectAuth"
    ON "public"."animals"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "AnimalsInsertAuth"
    ON "public"."animals"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "AnimalsUpdateAuth"
    ON "public"."animals"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "CensusRecordsSelectAuth"
    ON "public"."census_records"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "CensusRecordsInsertAuth"
    ON "public"."census_records"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);

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
CREATE POLICY "EnrichmentTypesSelectAuth"
    ON "public"."enrichment_types"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "EnrichmentTypesInsertAuth"
    ON "public"."enrichment_types"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "EnrichmentTypesUpdateAuth"
    ON "public"."enrichment_types"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "EnrichmentsSelectAuth"
    ON "public"."enrichments"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "EnrichmentsInsertAuth"
    ON "public"."enrichments"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "EnrichmentsUpdateAuth"
    ON "public"."enrichments"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "EnrichmentListMembershipsSelectAuth"
    ON "public"."enrichment_list_memberships"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "EnrichmentListMembershipsInsertAuth"
    ON "public"."enrichment_list_memberships"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
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
CREATE POLICY "EnrichmentListAssignment_DatesSelectAuth"
    ON "public"."enrichment_list_assignment_dates"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "EnrichmentListAssignmentDatesInsertAuth"
    ON "public"."enrichment_list_assignment_dates"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
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
VALUES (0, 'Empty/Idle Room Daily Tasks', 'Daily', FALSE),
       (1, 'Surgery Room Daily Tasks', 'Daily', FALSE),
       (2, 'Storage Room Daily Tasks', 'Daily', FALSE),
       (3, 'Cagewash Room Daily Tasks', 'Daily', FALSE),
       (4, 'Housing Daily Tasks', 'Daily', FALSE),
       (5, 'Hibernaculum Daily Tasks', 'Daily', FALSE),

       (6, 'Empty/Idle Room Weekly Tasks', 'Weekly', FALSE),
       (7, 'Surgery Room Weekly Tasks', 'Weekly', FALSE),
       (8, 'Storage Room Weekly Tasks', 'Weekly', FALSE),
       (9, 'Cagewash Room Weekly Tasks', 'Weekly', FALSE),
       (10, 'Housing Weekly Tasks', 'Weekly', FALSE),
       (11, 'Hibernaculum Weekly Tasks', 'Weekly', FALSE),

       (12, 'Surgery Room Monthly Tasks', 'Monthly', FALSE),
       (13, 'Storage Room Monthly Tasks', 'Monthly', FALSE),
       (14, 'Cagewash Room Monthly Tasks', 'Monthly', FALSE),
       (15, 'Housing Monthly Tasks', 'Monthly', FALSE),
       (16, 'Hibernaculum Monthly Tasks', 'Monthly', FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('task_lists', 'tl_id'),
               COALESCE((SELECT MAX(tl_id) FROM task_lists), 0)
       );
ALTER TABLE "public"."task_lists"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.task_lists TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_lists TO authenticated;
REVOKE UPDATE ON public.task_lists FROM authenticated;
GRANT UPDATE (deleted) ON public.task_lists TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE task_lists_tl_id_seq TO authenticated;
CREATE POLICY "Task_ListsSelectAuth"
    ON "public"."task_lists"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskListsInsertAuth"
    ON "public"."task_lists"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "TaskListsUpdateAuth"
    ON "public"."task_lists"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());

DROP VIEW IF EXISTS room_check_tasks_view;

CREATE OR REPLACE VIEW room_check_tasks_view
            WITH
            (security_invoker = on)
AS
SELECT r.r_id,
       r.name                AS room_name,
       tl.name               AS task_list_name,
       tl.frequency,
       COALESCE(JSONB_AGG(JSONB_BUILD_OBJECT(
               't_id', t.t_id,
               'task_name', t.name,
               'manager_only', t.manager_only,
               'quantitative', CASE
                                   WHEN qt.t_id IS NOT NULL
                                       THEN
                                       JSONB_BUILD_OBJECT(
                                               'unit',
                                               qr.unit,
                                               'min',
                                               qr.minimum,
                                               'max',
                                               qr.maximum,
                                               'required',
                                               qr.required
                                       ) END)) FILTER (
                    WHERE t.t_id IS NOT NULL),
                '[]'::jsonb) AS tasks
FROM rooms r
         LEFT JOIN task_list_room_memberships tlrm
                   ON r.r_id = tlrm.r_id
         LEFT JOIN task_lists tl ON tlrm.tl_id = tl.tl_id
         LEFT JOIN task_list_task_memberships tltm
                   ON tlrm.tl_id = tltm.tl_id
         LEFT JOIN tasks t ON tltm.t_id = t.t_id
         LEFT JOIN quantitative_tasks qt ON t.t_id = qt.t_id
         LEFT JOIN quantitative_ranges qr ON qt.qr_id = qr.qr_id
GROUP BY r.r_id,
         tl.name,
         tl.frequency;

GRANT SELECT ON TABLE public.room_check_tasks_view TO authenticated;
-- Tasks -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tasks
(
    t_id         serial PRIMARY KEY,
    name         bpchar  NOT NULL,
    manager_only boolean NOT NULL,
    deleted      boolean NOT NULL
);
INSERT INTO tasks (t_id, name, manager_only, deleted)
VALUES (0, 'Room Temperature', FALSE, FALSE),
       (1, 'Hibernaculum Temperature', FALSE, FALSE),
       (2, 'Room Humidity', FALSE, FALSE),
       (3, 'Hibernaculum Humidity', FALSE, FALSE),
       (4, 'Wipe Counters & Sweep', FALSE, FALSE),
       (5, 'Check Vermin Trap', FALSE, FALSE),
       (6, 'Sweep', FALSE, FALSE),
       (7, 'View Each Animal', FALSE, FALSE),
       (8, 'Give/Check Food & Water', FALSE, FALSE),
       (9, 'Double Check Water', FALSE, FALSE),
       (10, 'Mop Floor', FALSE, FALSE),
       (11, 'Manager Walkthrough', FALSE, FALSE),
       (12, 'Manager Check Expiration Dates on Drugs/Supplies',
        FALSE, FALSE),
       (13, 'Perform Cage Wash Temp Strip Test', FALSE, FALSE),
       (14, 'Change Cage/Bedding', FALSE, FALSE),
       (15, 'Change Water Bottle', FALSE, FALSE),
       (16, 'Sanitize Enrichment', FALSE, FALSE),
       (17, 'Check Light Timer', FALSE, FALSE),
       (18, 'Mop Walls and Ceiling', FALSE, FALSE),
       (19, 'Sanitize Garbage Can', FALSE, FALSE),
       (20, 'Sanitize Mop Buckets & Cloth Mop Heads', FALSE, FALSE),
       (21, 'Sanitize Dust Pans', FALSE, FALSE),
       (22, 'Replace Disinfectant', FALSE, FALSE),
       (23, 'Check Function of Heaters or Dehumidifiers, If Present',
        FALSE, FALSE),
       (24, 'Sanitize Storage Barrels & Scoops', FALSE, FALSE),
       (25, 'Sanitize Small Containers, If Present', FALSE, FALSE),
       (26, 'Refill Bins With Bedding, If Present', FALSE, FALSE),
       (27, 'Sanitize bedding disposal station', FALSE, FALSE),
       (28, 'Clean Sink With Comet, Then Spray With WD-40', FALSE,
        FALSE),
       (29, 'Wipe Cage Washer Exterior With WD-40', FALSE, FALSE),
       (30, 'Sanitize Water Bottle Filler', FALSE, FALSE),
       (31, 'Clean Paper Towel & Soap Dispensers', FALSE, FALSE),
       (32, 'Sanitize All Garbage Cans, Including Any In Hallway',
        FALSE, FALSE),
       (33, 'Disinfect Drain Per Sign Taped to the Wall', FALSE,
        FALSE),
       (34, 'Clean Sink With Comet', FALSE, FALSE),
       (35, 'Clean Refrigerator', FALSE, FALSE),
       (36, 'Check Euthanasia Equipment', FALSE, FALSE),
       (37, 'Check Anaesthesia Equipment', FALSE, FALSE),
       (38,
        'Lab Animal Manager Checks Expiration Dates and Replaces as Needed',
        TRUE, FALSE),
       (39, 'Sanitize Shelves/Racks/Carts', FALSE, FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('tasks', 't_id'),
               COALESCE((SELECT MAX(t_id) FROM tasks), 0)
       );
ALTER TABLE "public"."tasks"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.tasks TO authenticated;
GRANT SELECT, INSERT ON TABLE public.tasks TO authenticated;
REVOKE UPDATE ON public.tasks FROM authenticated;
GRANT UPDATE (deleted) ON public.tasks TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE tasks_t_id_seq TO authenticated;
CREATE POLICY "TasksSelectAuth"
    ON "public"."tasks"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TasksInsertAuth"
    ON "public"."tasks"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "TasksUpdateAuth"
    ON "public"."tasks"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
VALUES (0, 'Fahrenheit', FALSE, 79, 32, FALSE),
       (1, 'Fahrenheit', FALSE, 42, 32, FALSE),
       (2, 'RH', TRUE, 99.9, 0, FALSE),
       (3, 'RH', FALSE, 70, 30, FALSE),
       (4, 'RH', FALSE, 40, 30, FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('quantitative_ranges', 'qr_id'),
               COALESCE((SELECT MAX(qr_id) FROM quantitative_ranges),
                        0)
       );
ALTER TABLE "public"."quantitative_ranges"
    ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON TYPE public.quantitative_ranges TO authenticated;
GRANT SELECT, INSERT ON TABLE public.quantitative_ranges TO authenticated;
REVOKE UPDATE ON public.quantitative_ranges FROM authenticated;
GRANT UPDATE (deleted) ON public.quantitative_ranges TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE quantitative_ranges_qr_id_seq TO authenticated;
CREATE POLICY "QuantitativeRangesSelectAuth"
    ON "public"."quantitative_ranges"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "QuantitativeRangesInsertAuth"
    ON "public"."quantitative_ranges"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "QuantitativeRangesUpdateAuth"
    ON "public"."quantitative_ranges"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "QuantitativeTasksSelectAuth"
    ON "public"."quantitative_tasks"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "QuantitativeTasksInsertAuth"
    ON "public"."quantitative_tasks"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
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
CREATE POLICY "TaskListTaskMembershipsSelectAuth"
    ON "public"."task_list_task_memberships"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskListTaskMembershipsInsertAuth"
    ON "public"."task_list_task_memberships"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
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
CREATE POLICY "TaskListRoomMembershipsSelectAuth"
    ON "public"."task_list_room_memberships"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskListRoomMembershipsInsertAuth"
    ON "public"."task_list_room_memberships"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
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
    frequency public.task_frequency           NOT NULL,
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
CREATE POLICY "RoomCheckSlotsSelectAuth"
    ON "public"."room_check_slots"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "RoomCheckSlotsInsertAuth"
    ON "public"."room_check_slots"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
    check_is_admin() OR
    u_id IS NULL OR
    u_id = get_my_u_id()
    );
CREATE POLICY "RoomCheckSlotsUpdateAuth"
    ON "public"."room_check_slots"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
    TRUE
    )
    WITH CHECK (
    ((comment IS NULL)
        OR
     (comment = (SELECT r.comment
                 FROM room_check_slots r
                 WHERE r.rc_id = rc_id))) AND
    ((check_is_admin()
--          OR
--       u_id = get_my_u_id())
        )));
DROP VIEW IF EXISTS room_check_slots_view;
CREATE OR REPLACE VIEW room_check_slots_view WITH (security_invoker = on) AS
SELECT rcs.rc_id,
       rcs.date_time,
       rcs.state,
       r.r_id,
       r.name AS room_name,
       rcs.frequency,
       rcs.comment,
       u.u_id,
       u.name
FROM room_check_slots rcs
         JOIN rooms r ON rcs.r_id = r.r_id
         LEFT JOIN users u ON rcs.u_id = u.u_id;
GRANT SELECT ON TABLE public.room_check_slots_view TO authenticated;

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
CREATE POLICY "TaskRecordsSelectAuth"
    ON "public"."task_records"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskRecordsInsertAuth"
    ON "public"."task_records"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
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
CREATE POLICY "Quantitative_Task_RecordsSelectAuth"
    ON "public"."quantitative_task_records"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "QuantitativeTaskRecordsInsertAuth"
    ON "public"."quantitative_task_records"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);
CREATE POLICY "QuantitativeTaskRecordsUpdateAuth"
    ON "public"."quantitative_task_records"
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
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
CREATE POLICY "TaskRecordUsersSelectAuth"
    ON "public"."task_record_users"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskRecordUsersInsertAuth"
    ON "public"."task_record_users"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);
-- TODO a quantitative range can have at most 2 ranges
-- One range that can be required, and one that is not required
-- If another range is added to a tast, the units must match