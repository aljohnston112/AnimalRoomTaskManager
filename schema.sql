-- noinspection SqlSideEffectsForFile

SET search_path TO public, auth, pg_temp;
DROP TRIGGER IF EXISTS trigger_on_auth_user_created ON auth.users;
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT USAGE ON SCHEMA public TO authenticated;

-- User Groups -------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_groups
(
    ug_id serial PRIMARY KEY,
    name  text NOT NULL
);
INSERT INTO user_groups (ug_id, name)
VALUES (0, 'Admin'),
       (1, 'PI and Chief of Staff'),
       (2, 'Students and Staff');
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('user_groups', 'ug_id'),
               COALESCE((SELECT MAX(ug_id) FROM user_groups), 0)
       );
ALTER TABLE public.user_groups
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.user_groups TO authenticated;

-- Users -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users
(
    u_id    serial PRIMARY KEY,
    name    text                                   NOT NULL,
    ug_id   integer REFERENCES user_groups (ug_id) NOT NULL,
    auth_id uuid REFERENCES auth.users             NOT NULL UNIQUE,
    deleted boolean                                NOT NULL,
    CONSTRAINT unique_user_names UNIQUE (name)
);
ALTER TABLE public.users
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.users TO authenticated;
GRANT UPDATE (ug_id, deleted) ON public.users TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE users_u_id_seq TO authenticated;
ALTER PUBLICATION supabase_realtime ADD TABLE users;
CREATE POLICY "UsersSelectAuth"
    ON public.users
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (NOT deleted);
CREATE OR REPLACE FUNCTION public.check_is_admin()
    RETURNS boolean
    SET search_path TO public, auth, pg_temp AS
$$
SELECT EXISTS (SELECT 1
               FROM public.users
               WHERE auth_id = auth.uid()
                 AND ug_id = 0
                 AND NOT deleted);
$$ LANGUAGE sql STABLE
                SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION public.check_is_admin() TO authenticated;
CREATE POLICY "UserGroupsSelectAuth"
    ON public.user_groups
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (check_is_admin());
CREATE POLICY "UsersInsertAuth"
    ON public.users
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "UsersUpdateAuth"
    ON public.users
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
    check_is_admin()
    )
    WITH CHECK (check_is_admin());
-- Email whitelist ---------------------------------------------------
CREATE TABLE IF NOT EXISTS email_whitelist
(
    email text PRIMARY KEY,
    ug_id integer REFERENCES user_groups (ug_id) NOT NULL
);
ALTER TABLE public.email_whitelist
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON TABLE public.email_whitelist TO authenticated;
GRANT UPDATE (ug_id) ON public.email_whitelist TO authenticated;
ALTER PUBLICATION supabase_realtime ADD TABLE email_whitelist;
CREATE POLICY "EmailWhitelistSelectAuth"
    ON public.email_whitelist
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (check_is_admin());
CREATE POLICY "EmailWhitelistInsertAuth"
    ON public.email_whitelist
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "EmailWhitelistDeleteAuth"
    ON public.email_whitelist
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (check_is_admin());
CREATE POLICY "EmailWhitelistUpdateAuth"
    ON public.email_whitelist
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS trigger
    SET search_path TO public, auth, pg_temp AS
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

CREATE TRIGGER trigger_on_auth_user_created
    AFTER INSERT
    ON auth.users
    FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.on_user_deleted_purge()
    RETURNS trigger
    SET search_path TO public, auth, pg_temp AS
$$
BEGIN
    IF (NEW.deleted = TRUE AND OLD.deleted = FALSE) THEN
        DELETE
        FROM public.email_whitelist
        WHERE email = NEW.name;
        DELETE FROM auth.users WHERE id = NEW.auth_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_purge_user
    AFTER UPDATE OF deleted
    ON public.users
    FOR EACH ROW
EXECUTE FUNCTION public.on_user_deleted_purge();

-- Facilities --------------------------------------------------------
CREATE TABLE IF NOT EXISTS facilities
(
    f_id    serial PRIMARY KEY,
    name    text    NOT NULL,
    deleted boolean NOT NULL,
    CONSTRAINT "unique_facility_name" UNIQUE (name)
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
ALTER TABLE public.facilities
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.facilities TO authenticated;
GRANT UPDATE (deleted) ON public.facilities TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE facilities_f_id_seq TO authenticated;
ALTER PUBLICATION supabase_realtime ADD TABLE facilities;
CREATE POLICY "FacilitiesSelectAuth"
    ON public.facilities
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "FacilitiesInsertAuth"
    ON public.facilities
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "FacilitiesUpdateAuth"
    ON public.facilities
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Labs --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS labs
(
    l_id    serial PRIMARY KEY,
    color   bigint  NOT NULL,
    name    text    NOT NULL,
    deleted boolean NOT NULL
);
INSERT INTO labs (l_id, color, name, deleted)
VALUES (0, 4294901840, 'Merriman', FALSE),
       (1, 4278225151, 'Fauna', FALSE),
       (2, 4294950656, 'Boonpattrawong', FALSE),
       (3, 4278255568, 'Kurtz', FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('labs', 'l_id'),
               COALESCE((SELECT MAX(l_id) FROM labs), 0)
       );
ALTER TABLE public.labs
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.labs TO authenticated;
REVOKE UPDATE ON public.labs FROM authenticated;
GRANT UPDATE (color, deleted) ON public.labs TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE labs_l_id_seq TO authenticated;
ALTER PUBLICATION supabase_realtime ADD TABLE labs;
CREATE POLICY "LabsSelectAuth"
    ON public.labs
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "LabsInsertAuth"
    ON public.labs
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "LabsUpdateAuth"
    ON public.labs
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Enrichment Lists --------------------------------------------------
CREATE TABLE IF NOT EXISTS enrichment_lists
(
    el_id   serial PRIMARY KEY,
    name    text    NOT NULL,
    deleted boolean NOT NULL
);
ALTER TABLE public.enrichment_lists
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.enrichment_lists TO authenticated;
GRANT UPDATE (deleted) ON public.enrichment_lists TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE enrichment_lists_el_id_seq TO authenticated;
CREATE POLICY "EnrichmentListsSelectAuth"
    ON public.enrichment_lists
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "EnrichmentListsInsertAuth"
    ON public.enrichment_lists
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "EnrichmentListsUpdateAuth"
    ON public.enrichment_lists
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Buildings ---------------------------------------------------------
CREATE TABLE buildings
(
    b_id    serial PRIMARY KEY,
    name    text    NOT NULL,
    deleted boolean NOT NULL
);
INSERT INTO buildings(b_id, name, deleted)
VALUES (0, 'Halsey', FALSE),
       (1, 'Clow', FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('buildings', 'b_id'),
               COALESCE((SELECT MAX(b_id) FROM buildings), 0)
       );
ALTER TABLE public.buildings
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.buildings TO authenticated;
GRANT UPDATE (deleted) ON public.buildings TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE buildings_b_id_seq TO authenticated;
ALTER PUBLICATION supabase_realtime ADD TABLE buildings;
CREATE POLICY "BuildingsSelectAuth"
    ON public.buildings
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "BuildingsInsertAuth"
    ON public.buildings
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "BuildingsUpdateAuth"
    ON public.buildings
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Rooms -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rooms
(
    r_id    serial PRIMARY KEY,
    b_id    integer REFERENCES buildings (b_id)  NOT NULL,
    name    text                                 NOT NULL,
    f_id    integer REFERENCES facilities (f_id) NOT NULL,
    l_id    integer REFERENCES labs (l_id),
    el_id   integer REFERENCES enrichment_lists (el_id),
    deleted boolean                              NOT NULL
);
INSERT INTO rooms(r_id, name, f_id, l_id, el_id, deleted, b_id)
VALUES (0, '36B', 3, 0, NULL, FALSE, 1),
       (1, '36C', 3, 0, NULL, FALSE, 1),
       (2, '36D', 3, 0, NULL, FALSE, 1),
       (3, '36E', 3, 0, NULL, FALSE, 1),
       (4, '36F', 3, 0, NULL, FALSE, 1),
       (5, '36G', 1, 0, NULL, FALSE, 1),
       (6, '36H', 3, 0, NULL, FALSE, 1),
       (7, '36J', 0, 0, NULL, FALSE, 1),
       (8, '36K', 0, 0, NULL, FALSE, 1),
       (9, '36L', 2, 0, NULL, FALSE, 1),
       (10, '17', 1, 3, NULL, FALSE, 0),
       (11, '19A', 3, 3, NULL, FALSE, 0),
       (12, '19B', 3, 0, NULL, FALSE, 0),
       (13, '19C', 3, 3, NULL, FALSE, 0),
       (14, '19D', 4, 0, NULL, FALSE, 0),
       (15, '19E/F', 2, 3, NULL, FALSE, 0),
       (16, '19G', 0, 3, NULL, FALSE, 0),
       (17, '19H', 3, 3, NULL, FALSE, 0),
       (18, '19J', 3, 3, NULL, FALSE, 0),
       (19, '56A', 4, NULL, NULL, FALSE, 0);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('rooms', 'r_id'),
               COALESCE((SELECT MAX(r_id) FROM rooms), 0)
       );
ALTER TABLE public.rooms
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.rooms TO authenticated;
GRANT UPDATE (deleted) ON public.rooms TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE rooms_r_id_seq TO authenticated;
CREATE POLICY "RoomsSelectAuth"
    ON public.rooms
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "RoomsInsertAuth"
    ON public.rooms
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "RoomsUpdateAuth"
    ON public.rooms
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Lab Group Memberships ---------------------------------------------
CREATE TABLE IF NOT EXISTS lab_group_memberships
(
    l_id integer REFERENCES labs (l_id)  NOT NULL,
    u_id integer REFERENCES users (u_id) NOT NULL,
    PRIMARY KEY (l_id, u_id)
);
ALTER TABLE public.lab_group_memberships
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE ON TABLE public.lab_group_memberships TO authenticated;
CREATE POLICY "LabGroupMembershipsSelectAuth"
    ON public.lab_group_memberships
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "LabGroupMembershipsInsertAuth"
    ON public.lab_group_memberships
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "LabGroupMembershipsUpdateAuth"
    ON public.lab_group_memberships
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Censuses ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS censuses
(
    c_id      serial PRIMARY KEY,
    date_time timestamptz                     NOT NULL,
    r_id      integer REFERENCES rooms (r_id) NOT NULL,
    u_id      integer REFERENCES users (u_id) NOT NULL
);
ALTER TABLE public.censuses
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.censuses TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE censuses_c_id_seq TO authenticated;
CREATE POLICY "CensusesSelectAuth"
    ON public.censuses
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "CensusesInsertAuth"
    ON public.censuses
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);

-- Animals -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS animals
(
    a_id    serial PRIMARY KEY,
    name    text    NOT NULL,
    deleted boolean NOT NULL
);
ALTER TABLE public.animals
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.animals TO authenticated;
GRANT UPDATE (deleted) ON public.animals TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE animals_a_id_seq TO authenticated;
CREATE POLICY "AnimalsSelectAuth"
    ON public.animals
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "AnimalsInsertAuth"
    ON public.animals
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "AnimalsUpdateAuth"
    ON public.animals
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Census Records ----------------------------------------------------
CREATE TABLE IF NOT EXISTS census_records
(
    c_id              integer REFERENCES censuses (c_id) NOT NULL,
    a_id              integer REFERENCES animals (a_id)  NOT NULL,
    number_of_animals smallint                           NOT NULL,
    PRIMARY KEY (c_id, a_id)
);
ALTER TABLE public.census_records
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.census_records TO authenticated;
CREATE POLICY "CensusRecordsSelectAuth"
    ON public.census_records
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "CensusRecordsInsertAuth"
    ON public.census_records
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);

-- Task Frequency ----------------------------------------------------
CREATE TYPE task_frequency AS ENUM (
    'Daily',
    'Weekly',
    'Monthly'
    );

-- Task Lists --------------------------------------------------------
CREATE TABLE IF NOT EXISTS task_lists
(
    tl_id        serial PRIMARY KEY,
    name         text           NOT NULL,
    frequency    task_frequency NOT NULL,
    deleted      boolean        NOT NULL,
    content_hash text           NOT NULL,
    CONSTRAINT distinct_task_lists UNIQUE (name, frequency, deleted, content_hash)
);
ALTER PUBLICATION supabase_realtime ADD TABLE task_lists;
CREATE OR REPLACE FUNCTION generate_task_list_hash(rows jsonb)
    RETURNS text
    SET search_path TO public, auth, pg_temp AS
$$
BEGIN
    RETURN MD5(COALESCE(
            (SELECT JSONB_AGG(
                            task_list
                            ORDER BY (
                                task_list ->> 'index')::int,
                                (task_list ->> 't_id')::INT
                    )
             FROM JSONB_ARRAY_ELEMENTS(rows) AS task_list)::text,
            '[]'
               ));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
WITH seed_data (tl_id, name, frequency, deleted) AS
         (VALUES (0,
                  'Empty/Idle Room Daily Tasks',
                  'Daily',
                  FALSE),
                 (1,
                  'Surgery Room Daily Tasks',
                  'Daily',
                  FALSE),
                 (2,
                  'Storage Room Daily Tasks',
                  'Daily',
                  FALSE),
                 (3,
                  'Cagewash Room Daily Tasks',
                  'Daily',
                  FALSE),
                 (4,
                  'Housing Daily Tasks',
                  'Daily',
                  FALSE),
                 (5,
                  'Hibernaculum Daily Tasks',
                  'Daily',
                  FALSE),

                 (6,
                  'Empty/Idle Room Weekly Tasks',
                  'Weekly',
                  FALSE),
                 (7,
                  'Surgery Room Weekly Tasks',
                  'Weekly',
                  FALSE),
                 (8,
                  'Storage Room Weekly Tasks',
                  'Weekly',
                  FALSE),
                 (9,
                  'Cagewash Room Weekly Tasks',
                  'Weekly',
                  FALSE),
                 (10,
                  'Housing Weekly Tasks',
                  'Weekly',
                  FALSE),
                 (11,
                  'Hibernaculum Weekly Tasks',
                  'Weekly',
                  FALSE),

                 (12,
                  'Surgery Room Monthly Tasks',
                  'Monthly',
                  FALSE),
                 (13,
                  'Storage Room Monthly Tasks',
                  'Monthly',
                  FALSE),
                 (14,
                  'Cagewash Room Monthly Tasks',
                  'Monthly',
                  FALSE),
                 (15,
                  'Housing Monthly Tasks',
                  'Monthly',
                  FALSE),
                 (16,
                  'Hibernaculum Monthly Tasks',
                  'Monthly',
                  FALSE))
INSERT
INTO task_lists (tl_id, name, frequency, deleted, content_hash)
SELECT tl_id,
       name,
       frequency::task_frequency,
       deleted,
       generate_task_list_hash('[]'::jsonb)
FROM seed_data;;
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('task_lists', 'tl_id'),
               COALESCE((SELECT MAX(tl_id) FROM task_lists), 0)
       );
ALTER TABLE public.task_lists
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.task_lists TO authenticated;
GRANT UPDATE (deleted, content_hash) ON public.task_lists TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE task_lists_tl_id_seq TO authenticated;
CREATE POLICY "Task_ListsSelectAuth"
    ON public.task_lists
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskListsInsertAuth"
    ON public.task_lists
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "TaskListsUpdateAuth"
    ON public.task_lists
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());
-- Tasks -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tasks
(
    t_id         serial PRIMARY KEY,
    name         text    NOT NULL,
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
       (39, 'Sanitize Shelves/Racks/Carts', FALSE, FALSE),
       (40, 'Min Room Temperature', FALSE, FALSE),
       (41, 'Max Room Temperature', FALSE, FALSE),
       (42, 'Min Room Humidity', FALSE, FALSE),
       (43, 'Max Room Humidity', FALSE, FALSE),
       (44, 'Min Hibernaculum Temperature', FALSE, FALSE),
       (45, 'Max Hibernaculum Temperature', FALSE, FALSE),
       (46, 'Min Hibernaculum Humidity', FALSE, FALSE),
       (47, 'Max Hibernaculum Humidity', FALSE, FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('tasks', 't_id'),
               COALESCE((SELECT MAX(t_id) FROM tasks), 0)
       );
ALTER TABLE public.tasks
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.tasks TO authenticated;
GRANT UPDATE (deleted) ON public.tasks TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE tasks_t_id_seq TO authenticated;
CREATE POLICY "TasksSelectAuth"
    ON public.tasks
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TasksInsertAuth"
    ON public.tasks
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "TasksUpdateAuth"
    ON public.tasks
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Quantitative Ranges -----------------------------------------------
CREATE TABLE IF NOT EXISTS quantitative_ranges
(
    qr_id   serial PRIMARY KEY,
    unit    text    NOT NULL,
    maximum numeric NOT NULL,
    minimum numeric NOT NULL,
    deleted boolean NOT NULL,
    CHECK ( minimum < maximum )
);
INSERT INTO quantitative_ranges (qr_id, unit, maximum, minimum, deleted)
VALUES (0, 'Fahrenheit', 79, 32, FALSE),
       (1, 'Fahrenheit', 42, 32, FALSE),
       (2, 'RH', 100, 0, FALSE),
       (3, 'RH', 70, 30, FALSE);
SELECT SETVAL(
               PG_GET_SERIAL_SEQUENCE('quantitative_ranges', 'qr_id'),
               COALESCE(
                       (SELECT MAX(qr_id) FROM quantitative_ranges),
                       0
               )
       );
ALTER TABLE public.quantitative_ranges
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.quantitative_ranges TO authenticated;
GRANT UPDATE (deleted) ON public.quantitative_ranges TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE quantitative_ranges_qr_id_seq TO authenticated;
CREATE POLICY "QuantitativeRangesSelectAuth"
    ON public.quantitative_ranges
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "QuantitativeRangesInsertAuth"
    ON public.quantitative_ranges
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "QuantitativeRangesUpdateAuth"
    ON public.quantitative_ranges
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Quantitative Tasks ------------------------------------------------
CREATE TABLE IF NOT EXISTS quantitative_tasks
(
    t_id           integer PRIMARY KEY REFERENCES tasks (t_id) NOT NULL,
    qr_id_warning  integer REFERENCES quantitative_ranges (qr_id),
    qr_id_required integer REFERENCES quantitative_ranges (qr_id),
    CONSTRAINT distinct_ranges CHECK (qr_id_warning != qr_id_required)
);
INSERT INTO quantitative_tasks (t_id, qr_id_warning, qr_id_required)
VALUES (0, 0, NULL),
       (1, 1, NULL),
       (2, 3, NULL),
       (3, 3, 2),
       (40, 0, NULL),
       (41, 0, NULL),
       (42, 2, 3),
       (43, 2, 3),
       (44, 1, NULL),
       (45, 1, NULL),
       (46, 2, 3),
       (47, 2, 3);
ALTER TABLE public.quantitative_tasks
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.quantitative_tasks TO authenticated;
CREATE POLICY "QuantitativeTasksSelectAuth"
    ON public.quantitative_tasks
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "QuantitativeTasksInsertAuth"
    ON public.quantitative_tasks
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());

CREATE OR REPLACE FUNCTION check_quantitative_units()
    RETURNS TRIGGER
    SET search_path TO public, auth, pg_temp AS
$$
DECLARE
    unit_warning  text;
    unit_required text;
BEGIN
    IF NEW.qr_id_warning IS NOT NULL AND
       NEW.qr_id_required IS NOT NULL THEN
        SELECT unit
        INTO unit_warning
        FROM quantitative_ranges
        WHERE qr_id = NEW.qr_id_warning;
        SELECT unit
        INTO unit_required
        FROM quantitative_ranges
        WHERE qr_id = NEW.qr_id_required;
        IF unit_warning != unit_required THEN
            RAISE EXCEPTION
                'Mismatched units: warning range unit is % but required range unit is %',
                unit_warning,
                unit_required;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql STABLE
                    SECURITY DEFINER;

CREATE TRIGGER trigger_validate_units
    BEFORE INSERT OR UPDATE
    ON quantitative_tasks
    FOR EACH ROW
EXECUTE FUNCTION check_quantitative_units();

-- Task List Task Memberships ---------------------------------------------
CREATE TABLE IF NOT EXISTS task_list_task_memberships
(
    tl_id integer REFERENCES task_lists (tl_id) NOT NULL,
    t_id  integer REFERENCES tasks (t_id)       NOT NULL,
    index integer                               NOT NULL,
    PRIMARY KEY (tl_id, t_id),
    CONSTRAINT unique_task_order UNIQUE (tl_id, index) DEFERRABLE
);
INSERT INTO task_list_task_memberships (tl_id, t_id, index)
VALUES (0, 0, 0),
       (0, 2, 1),

       (1, 0, 0),
       (1, 2, 1),
       (1, 4, 2),
       (1, 5, 3),

       (2, 0, 0),
       (2, 2, 1),
       (2, 4, 2),
       (2, 5, 3),

       (3, 0, 0),
       (3, 2, 1),
       (3, 6, 2),
       (3, 5, 3),

       (4, 0, 0),
       (4, 40, 1),
       (4, 41, 2),
       (4, 2, 3),
       (4, 42, 4),
       (4, 43, 5),
       (4, 7, 6),
       (4, 8, 7),
       (4, 4, 8),
       (4, 5, 9),
       (4, 9, 10),

       (5, 1, 0),
       (5, 44, 1),
       (5, 45, 2),
       (5, 46, 3),
       (5, 47, 4),
       (5, 3, 5),
       (5, 7, 6),
       (5, 8, 7),
       (5, 4, 8),
       (5, 5, 9),
       (5, 9, 10),

       (6, 11, 0),

       (7, 10, 0),
       (7, 11, 1),
       (7, 12, 2),

       (8, 10, 0),
       (8, 11, 1),

       (9, 13, 0),
       (9, 10, 1),
       (9, 11, 2),

       (10, 14, 0),
       (10, 15, 1),
       (10, 16, 2),
       (10, 17, 3),
       (10, 10, 4),
       (10, 11, 5),

       (11, 14, 0),
       (11, 15, 1),
       (11, 16, 2),
       (11, 17, 3),
       (11, 10, 4),
       (11, 11, 5),

       (12, 18, 0),
       (12, 39, 1),
       (12, 34, 2),
       (12, 31, 3),
       (12, 19, 4),
       (12, 20, 5),
       (12, 24, 6),
       (12, 25, 7),
       (12, 21, 8),
       (12, 22, 9),
       (12, 26, 10),
       (12, 35, 11),
       (12, 36, 12),
       (12, 37, 13),

       (13, 18, 0),
       (13, 39, 1),
       (13, 19, 2),
       (13, 20, 3),
       (13, 24, 4),
       (13, 25, 5),
       (13, 21, 6),
       (13, 22, 7),
       (13, 26, 8),

       (14, 18, 0),
       (14, 27, 1),
       (14, 28, 2),
       (14, 29, 3),
       (14, 30, 4),
       (14, 31, 5),
       (14, 32, 6),
       (14, 20, 7),
       (14, 21, 8),
       (14, 22, 9),
       (14, 33, 10),

       (15, 18, 0),
       (15, 39, 1),
       (15, 19, 2),
       (15, 20, 3),
       (15, 21, 4),
       (15, 22, 5),
       (15, 26, 6);
UPDATE task_lists tl
SET content_hash =
        generate_task_list_hash(
                (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                        't_id', t_id,
                        'index', index))
                 FROM task_list_task_memberships tltm
                 WHERE tltm.tl_id = tl.tl_id)
        );
ALTER TABLE public.task_list_task_memberships
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.task_list_task_memberships TO authenticated;
GRANT UPDATE (index) ON public.task_list_task_memberships TO authenticated;
CREATE POLICY "TaskListTaskMembershipsSelectAuth"
    ON public.task_list_task_memberships
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskListTaskMembershipsInsertAuth"
    ON public.task_list_task_memberships
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "askListTaskMembershipsUpdateAuth"
    ON public.task_list_task_memberships
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

CREATE OR REPLACE FUNCTION insert_task_list_memberships(tlid integer, rows jsonb)
    RETURNS void
    SET search_path TO public, auth, pg_temp AS
$$
BEGIN
    INSERT INTO task_list_task_memberships (tl_id, t_id, index)
    SELECT tlid,
           (r ->> 't_id')::int,
           (r ->> 'index')::int
    FROM JSONB_ARRAY_ELEMENTS(rows) AS r
    ON CONFLICT (tl_id, t_id)
        DO UPDATE SET index = EXCLUDED.index;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

GRANT EXECUTE ON FUNCTION public.insert_task_list_memberships(integer, jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION insert_task_list(
    name_in text,
    frequency_in task_frequency,
    task_list_task_membership_rows jsonb -- Expecting map {'t_id':, 'index':}
) RETURNS int
    SET search_path TO public, auth, pg_temp AS
$$
DECLARE
    tlid    int;
    payload jsonb;
    hash    text;
BEGIN
    hash := generate_task_list_hash(task_list_task_membership_rows);
    SELECT tl_id
    INTO tlid
    FROM task_lists
    WHERE name = name_in
      AND frequency = frequency_in
      AND content_hash = hash;

    IF tlid IS NULL THEN
        INSERT INTO task_lists (name, frequency, deleted, content_hash)
        VALUES (name_in, frequency_in, FALSE, hash)
        RETURNING tl_id INTO tlid;
        PERFORM insert_task_list_memberships(
                tlid,
                task_list_task_membership_rows
                );
    ELSE
        UPDATE task_lists
        SET deleted = FALSE
        WHERE tl_id = tlid;
    END IF;

    payload := get_task_list(tlid);
    RAISE NOTICE 'payload: %', payload;
    PERFORM realtime.send(
            payload => payload::jsonb,
            event => 'task_list_update'::text,
            topic => 'task_list_channel'::text
            );
    RETURN tlid;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.insert_task_list(text, task_frequency, jsonb) TO authenticated;

DROP POLICY IF EXISTS "Allow sending task list updates" ON realtime.messages;
CREATE POLICY "Allow sending task list updates"
    ON realtime.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (realtime.topic() = 'task_list_channel');

DROP POLICY IF EXISTS "Users can hear task list updates" ON realtime.messages;
CREATE POLICY "Users can hear task list updates"
    ON realtime.messages
    FOR SELECT
    TO authenticated
    USING ((SELECT realtime.topic()) = 'task_list_channel');

CREATE OR REPLACE FUNCTION edit_task_list(
    old_tl_id int,
    name text,
    frequency public.task_frequency,
    task_list_task_membership_rows jsonb
) RETURNS VOID
    SET search_path TO public, auth, pg_temp AS
$$
DECLARE
    new_tlid int;
    payload  json;
BEGIN
    -- Soft delete old list
    UPDATE task_lists
    SET deleted = TRUE
    WHERE tl_id = old_tl_id;

    -- Insert new list
    SELECT insert_task_list(
                   name,
                   frequency,
                   task_list_task_membership_rows
           )
    INTO new_tlid;

    -- Reassign room task lists
    UPDATE task_list_room_memberships
    SET tl_id = new_tlid
    WHERE tl_id = old_tl_id;

    payload := get_task_list(new_tlid);
    PERFORM realtime.send(
            payload => payload::jsonb,
            event => 'task_list_update'::text,
            topic => 'task_list_channel'::text
            );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.edit_task_list(integer, text, task_frequency, jsonb) TO authenticated;


CREATE OR REPLACE FUNCTION reorder_tasks(payload jsonb)
    RETURNS void AS
$$
DECLARE
    tlid        int;
    payload_out jsonb;
BEGIN
    SET CONSTRAINTS unique_task_order DEFERRED;

    UPDATE task_list_task_memberships AS tltm
    SET index = (new_task ->> 'new_index')::int
    FROM JSONB_ARRAY_ELEMENTS(payload) AS new_task
    WHERE tltm.t_id = (new_task ->> 't_id')::int
      AND tltm.tl_id = (new_task ->> 'tl_id')::int;
    SET CONSTRAINTS unique_task_order IMMEDIATE;

    tlid := (payload -> 0 ->> 'tl_id')::int;
    UPDATE task_lists
    SET content_hash = generate_task_list_hash(
            (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                    't_id', t_id,
                    'index', index))
             FROM task_list_task_memberships
             WHERE tl_id = tlid))
    WHERE tl_id = tlid;

    payload_out := get_task_list(tlid);
    PERFORM realtime.send(
            payload => payload_out::jsonb,
            event => 'task_list_update'::text,
            topic => 'task_list_channel'::text
            );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.reorder_tasks(jsonb) TO authenticated;


CREATE OR REPLACE VIEW all_tasks_view
            WITH
            (security_invoker = on)
AS
(
SELECT t.t_id,
       JSONB_BUILD_OBJECT(
               't_id', t.t_id,
               'task_name',
               t.name,
               'manager_only',
               t.manager_only,
               'quantitative_ranges',
               CASE
                   WHEN qt.t_id IS NOT NULL
                       THEN JSONB_BUILD_OBJECT(
                           'unit',
                           COALESCE(qrw.unit, qrr.unit),
                           'warning_range',
                           CASE
                               WHEN qrw.qr_id IS NOT NULL
                                   THEN JSONB_BUILD_OBJECT(
                                       'min',
                                       qrw.minimum,
                                       'max',
                                       qrw.maximum) END,
                           'required_range',
                           CASE
                               WHEN qrr.qr_id IS NOT NULL
                                   THEN JSONB_BUILD_OBJECT(
                                       'min',
                                       qrr.minimum,
                                       'max',
                                       qrr.maximum) END
                            )
                   END
       )
FROM tasks t
         LEFT JOIN quantitative_tasks qt ON t.t_id = qt.t_id
         LEFT JOIN quantitative_ranges qrw
                   ON qt.qr_id_warning = qrw.qr_id
         LEFT JOIN quantitative_ranges qrr
                   ON qt.qr_id_required = qrr.qr_id);
GRANT SELECT ON TABLE public.all_tasks_view TO authenticated;


CREATE OR REPLACE FUNCTION get_task_list(tlid integer)
    RETURNS jsonb
    SET search_path TO public, auth, pg_temp AS
$$
DECLARE
    result jsonb;
BEGIN
    SELECT JSONB_BUILD_OBJECT(
                   'tl_id', tl.tl_id,
                   'task_list_name', tl.name,
                   'frequency', tl.frequency,
                   'tasks', task_list_tasks.tasks,
                   'buildings', building_data.agg_buildings
           )
    INTO result
    FROM task_lists tl
             LEFT JOIN LATERAL (
        SELECT JSONB_AGG(
                       atv.JSONB_BUILD_OBJECT ||
                       JSONB_BUILD_OBJECT('index', tltm.index)
                       ORDER BY tltm.index
               ) AS tasks
        FROM task_list_task_memberships tltm
                 LEFT JOIN all_tasks_view atv ON atv.t_id = tltm.t_id
        WHERE tltm.tl_id = tl.tl_id
        ) task_list_tasks ON TRUE
             LEFT JOIN LATERAL (
        SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                'b_id', b.b_id,
                'building_name', b.name,
                'rooms', room_data.JSONB_AGG
                         )) AS agg_buildings
        FROM (SELECT DISTINCT r.b_id,
                              JSONB_AGG(JSONB_BUILD_OBJECT(
                                      'r_id', r.r_id,
                                      'room_name', r.name))
              FROM task_list_room_memberships tlrm
                       LEFT JOIN rooms r ON tlrm.r_id = r.r_id
              WHERE tlrm.tl_id = tl.tl_id
              GROUP BY r.r_id) room_data
                 LEFT JOIN buildings b ON b.b_id = room_data.b_id
        ) building_data ON TRUE
    WHERE tl.tl_id = tlid;
    RETURN result;
END
$$ LANGUAGE plpgsql SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.get_task_list(integer) TO authenticated;

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
ALTER TABLE public.task_list_room_memberships
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.task_list_room_memberships TO authenticated;
GRANT UPDATE (tl_id) ON public.task_list_room_memberships TO authenticated;
CREATE POLICY "TaskListRoomMembershipsSelectAuth"
    ON public.task_list_room_memberships
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskListRoomMembershipsInsertAuth"
    ON public.task_list_room_memberships
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin());
CREATE POLICY "TaskListRoomMembershipsUpdateAuth"
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
    comment   text,
    u_id      integer REFERENCES users (u_id),
    CONSTRAINT unique_room_checks UNIQUE (date_time, r_id, frequency)
);
ALTER TABLE public.room_check_slots
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.room_check_slots TO authenticated;
GRANT UPDATE (state, comment, u_id) ON public.room_check_slots TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE room_check_slots_rc_id_seq TO authenticated;
ALTER PUBLICATION supabase_realtime ADD TABLE room_check_slots;
CREATE POLICY "RoomCheckSlotsSelectAuth"
    ON public.room_check_slots
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE OR REPLACE FUNCTION get_my_u_id()
    RETURNS integer
    SET search_path TO public, auth, pg_temp AS
$$
SELECT u_id
FROM public.users
WHERE auth_id = auth.uid();
$$ LANGUAGE sql STABLE
                SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.get_my_u_id() TO authenticated;

CREATE POLICY "RoomCheckSlotsInsertAuth"
    ON public.room_check_slots
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (check_is_admin() OR
                u_id IS NULL OR
                u_id = get_my_u_id()
    );
CREATE POLICY "RoomCheckSlotsUpdateAuth"
    ON public.room_check_slots
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (
    TRUE
    )
    WITH CHECK (
    EXISTS(SELECT 1
           FROM room_check_slots r
           WHERE r.rc_id = rc_id
             AND (r.comment = '' OR
                  r.comment IS NULL OR
                  r.comment = room_check_slots.comment
               ))
        AND (COALESCE(check_is_admin(), FALSE) OR
             u_id IS NULL OR
             u_id = get_my_u_id()
        )
    );

CREATE OR REPLACE VIEW full_room_checks_view
    WITH (security_invoker = on) AS
SELECT rcs.rc_id,
       rcs.date_time,
       rcs.frequency,
       rcs.u_id,
       rcs.comment,
       rcs.state,
       r.r_id,
       r.name AS room_name,
       b.b_id,
       b.name AS building_name,
       u.name AS user_name,
       u.ug_id
FROM room_check_slots rcs
         LEFT JOIN rooms r ON rcs.r_id = r.r_id
         LEFT JOIN buildings b ON r.b_id = b.b_id
         LEFT JOIN users u ON rcs.u_id = u.u_id;

GRANT SELECT ON TABLE public.full_room_checks_view TO authenticated;

CREATE OR REPLACE FUNCTION get_room_check_slots(
    start_date pg_catalog.timestamptz DEFAULT NULL
)
    RETURNS TABLE
            (
                b_id                     integer,
                building_name            pg_catalog.text,
                room_checks_by_frequency JSONB
            )
    SET search_path TO public, auth, pg_temp
AS
$$
SELECT b.b_id,
       b.name              AS building_name,
       frequency_data.data AS room_checks_by_frequency
FROM buildings b
         LEFT JOIN LATERAL (
    SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
            'frequency', frequency_data.frequency,
            'dates', date_data.days
                     )) AS data
    FROM (SELECT DISTINCT frequency
          FROM room_check_slots) frequency_data
             LEFT JOIN LATERAL (
        SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                'date_time', date_data.date_time,
                'slots', slot_data.slots
                         )) AS days
        FROM (SELECT DISTINCT date_time
              FROM room_check_slots rcs
                       LEFT JOIN rooms r ON rcs.r_id = r.r_id
              WHERE r.b_id = b.b_id
                AND rcs.frequency = frequency_data.frequency
                AND (start_date IS NULL OR
                     rcs.date_time >= start_date)) date_data
                 LEFT JOIN LATERAL (
            SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                    'rc_id', rcs.rc_id,
                    'state', rcs.state,
                    'r_id', r.r_id,
                    'room_name', r.name,
                    'comment', rcs.comment,
                    'user_id', u.u_id,
                    'ug_id', u.ug_id,
                    'user_name', u.name
                             )) AS slots
            FROM room_check_slots rcs
                     LEFT JOIN rooms r ON rcs.r_id = r.r_id
                     LEFT JOIN users u ON rcs.u_id = u.u_id
            WHERE rcs.date_time = date_data.date_time
              AND rcs.frequency = frequency_data.frequency
              AND r.b_id = b.b_id
            ) slot_data ON TRUE
        WHERE slot_data.slots IS NOT NULL
        ) date_data ON TRUE
    WHERE date_data.days IS NOT NULL
    ) frequency_data ON TRUE
WHERE frequency_data.data IS NOT NULL
$$ LANGUAGE sql STABLE
                SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.get_room_check_slots(timestamptz) TO authenticated;

-- Task Records ------------------------------------------------------
CREATE TABLE IF NOT EXISTS task_records
(
    tr_id     serial PRIMARY KEY,
    t_id      integer REFERENCES tasks (t_id)             NOT NULL,
    rc_id     integer REFERENCES room_check_slots (rc_id) NOT NULL,
    date_time timestamptz DEFAULT NOW()                   NOT NULL
);
ALTER TABLE task_records
    ADD CONSTRAINT unique_task_per_check UNIQUE (t_id, rc_id);
ALTER TABLE public.task_records
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.task_records TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE task_records_tr_id_seq TO authenticated;
CREATE POLICY "TaskRecordsSelectAuth"
    ON public.task_records
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskRecordsInsertAuth"
    ON public.task_records
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
ALTER TABLE public.quantitative_task_records
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.quantitative_task_records TO authenticated;
GRANT UPDATE (value) ON public.quantitative_task_records TO authenticated;
CREATE POLICY "QuantitativeTaskRecordsSelectAuth"
    ON public.quantitative_task_records
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "QuantitativeTaskRecordsInsertAuth"
    ON public.quantitative_task_records
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);
CREATE POLICY "QuantitativeTaskRecordsUpdateAuth"
    ON public.quantitative_task_records
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (check_is_admin())
    WITH CHECK (check_is_admin());

-- Task Record Users -------------------------------------------------
CREATE TABLE IF NOT EXISTS task_record_users
(
    tr_id integer REFERENCES task_records (tr_id) NOT NULL,
    u_id  integer REFERENCES users (u_id)         NOT NULL,
    PRIMARY KEY (tr_id, u_id)
);
ALTER TABLE public.task_record_users
    ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE public.task_record_users TO authenticated;
CREATE POLICY "TaskRecordUsersSelectAuth"
    ON public.task_record_users
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (TRUE);
CREATE POLICY "TaskRecordUsersInsertAuth"
    ON public.task_record_users
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION submit_task_record(
    record_data JSONB,
    user_ids integer[],
    recorded_value numeric
) RETURNS VOID
    SET search_path TO public, auth, pg_temp AS
$$
DECLARE
    tr_id_out integer;
    payload   JSONB;
    rc_id_in  integer;
BEGIN
    rc_id_in := (record_data ->> 'rc_id')::integer;

    INSERT INTO task_records (t_id, rc_id, date_time)
    VALUES ((record_data ->> 't_id')::integer,
            (record_data ->> 'rc_id')::integer,
            (record_data ->> 'date_time')::pg_catalog.timestamptz)
    RETURNING tr_id INTO tr_id_out;

    INSERT INTO task_record_users (tr_id, u_id)
    SELECT tr_id_out, pg_catalog.unnest(user_ids);

    IF recorded_value IS NOT NULL THEN
        INSERT INTO quantitative_task_records(tr_id, value)
        VALUES (tr_id_out, recorded_value);
    END IF;

    SELECT JSONB_BUILD_OBJECT('rooms', JSONB_AGG(JSONB_BUILD_OBJECT(
                   'r_id', r.r_id,
                   'room_name', r.name,
                   'records', room_records.data
           )))
    INTO payload
    FROM rooms r
             INNER JOIN LATERAL (
        SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                'dates', slot_dates.data
                         )) AS data
        FROM room_check_slots rcs
                 INNER JOIN LATERAL (
            SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                    'date_time', tr_grouped.date_time,
                    'records', tr_grouped.records
                             )) AS data
            FROM (SELECT tr.date_time,
                         JSONB_AGG(JSONB_BUILD_OBJECT(
                                 'rc_id', rcs.rc_id,
                                 'tr_id', tr.tr_id,
                                 't_id', tr.t_id,
                                 'recorded_value', qtr.value,
                                 'task', (SELECT JSONB_BUILD_OBJECT(
                                                         'task_name',
                                                         t.name,
                                                         'frequency',
                                                         rcs.frequency,
                                                         'manager_only',
                                                         t.manager_only,
                                                         'assigned_users',
                                                         (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                                                                 'u_id',
                                                                 u.u_id,
                                                                 'name',
                                                                 u.name,
                                                                 'ug_id',
                                                                 u.ug_id
                                                                           ))
                                                          FROM task_record_users tru
                                                                   LEFT JOIN users u ON tru.u_id = u.u_id
                                                          WHERE tru.tr_id = tr.tr_id),
                                                         'quantitative_ranges',
                                                         CASE
                                                             WHEN qt.t_id IS NOT NULL
                                                                 THEN JSONB_BUILD_OBJECT(
                                                                     'unit',
                                                                     COALESCE(qrw.unit, qrr.unit),
                                                                     'warning_range',
                                                                     CASE
                                                                         WHEN qrw.qr_id IS NOT NULL
                                                                             THEN JSONB_BUILD_OBJECT(
                                                                                 'min',
                                                                                 qrw.minimum,
                                                                                 'max',
                                                                                 qrw.maximum) END,
                                                                     'required_range',
                                                                     CASE
                                                                         WHEN qrr.qr_id IS NOT NULL
                                                                             THEN JSONB_BUILD_OBJECT(
                                                                                 'min',
                                                                                 qrr.minimum,
                                                                                 'max',
                                                                                 qrr.maximum) END
                                                                      )
                                                             END
                                                 )
                                          FROM tasks t
                                                   LEFT JOIN quantitative_tasks qt ON t.t_id = qt.t_id
                                                   LEFT JOIN quantitative_ranges qrw
                                                             ON qt.qr_id_warning = qrw.qr_id
                                                   LEFT JOIN quantitative_ranges qrr
                                                             ON qt.qr_id_required = qrr.qr_id
                                          WHERE t.t_id = tr.t_id)
                                   )) AS records
                  FROM task_records tr
                           LEFT JOIN quantitative_task_records qtr
                                     ON tr.tr_id = qtr.tr_id
                  WHERE tr.rc_id = rcs.rc_id
                  GROUP BY tr.date_time) tr_grouped
            ) slot_dates ON TRUE
        WHERE rcs.r_id = r.r_id
          AND slot_dates.data IS NOT NULL
        GROUP BY r.r_id
        ) room_records ON TRUE
    WHERE room_records.data IS NOT NULL;

    PERFORM realtime.send(
            payload => payload::jsonb,
            event => 'task_recorded'::text,
            topic => 'task_record_channel'::text
            );
END
$$ LANGUAGE plpgsql SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.submit_task_record(jsonb, integer[], numeric) TO authenticated;

DROP POLICY IF EXISTS "Users can hear task updates" ON realtime.messages;
CREATE POLICY "Users can hear task updates"
    ON realtime.messages
    FOR SELECT
    TO authenticated
    USING ((SELECT realtime.topic()) = 'task_record_channel');

DROP POLICY IF EXISTS "Allow sending task record updates" ON realtime.messages;
CREATE POLICY "Allow sending task record updates"
    ON realtime.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (realtime.topic() = 'task_record_channel');

CREATE OR REPLACE VIEW room_check_task_lists_view
            WITH
            (security_invoker = on)
AS
SELECT b.b_id,
       b.name                       AS building_name,
       task_lists_by_frequency.data AS task_lists_by_frequency
FROM buildings b
         LEFT JOIN LATERAL (
    SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
            'frequency', task_list_frequency.frequency,
            'task_lists', tl_data.lists
                     )) AS data
    FROM (SELECT DISTINCT frequency
          FROM task_lists) task_list_frequency
             LEFT JOIN LATERAL (
        SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                'tl_id', tl.tl_id,
                'task_list_name', tl.name,
                'rooms', (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                        'r_id', r.r_id,
                        'room_name', r.name
                                           ))
                          FROM task_list_room_memberships tlrm
                                   RIGHT JOIN rooms r ON tlrm.r_id = r.r_id
                          WHERE tlrm.tl_id = tl.tl_id
                            AND r.b_id = b.b_id),
                'tasks', (SELECT JSONB_AGG(atv.JSONB_BUILD_OBJECT ||
                                           JSONB_BUILD_OBJECT('index', tltm.index)
                                           ORDER BY tltm.index)
                          FROM task_list_task_memberships tltm
                                   LEFT JOIN all_tasks_view atv ON atv.t_id = tltm.t_id
                          WHERE tltm.tl_id = tl.tl_id)
                         )) AS lists
        FROM task_lists tl
        WHERE tl.frequency = task_list_frequency.frequency
          AND EXISTS (SELECT 1
                      FROM task_list_room_memberships tlrm
                               JOIN rooms r ON tlrm.r_id = r.r_id
                      WHERE tlrm.tl_id = tl.tl_id
                        AND r.b_id = b.b_id)
        ) tl_data ON TRUE
    ) task_lists_by_frequency ON TRUE
UNION ALL
SELECT -1           AS b_id,
       'Unassigned' AS building_name,
       (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
               'frequency', task_list_frequency.frequency,
               'task_lists', lists
                         ))
        FROM (SELECT DISTINCT frequency
              FROM task_lists) task_list_frequency
                 INNER JOIN LATERAL (
            SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                    'tl_id', tl.tl_id,
                    'task_list_name', tl.name,
                    'rooms', NULL,
                    'tasks',
                    (SELECT JSONB_AGG(atv.JSONB_BUILD_OBJECT ||
                                      JSONB_BUILD_OBJECT('index', tltm.index)
                                      ORDER BY tltm.index)
                     FROM task_list_task_memberships tltm
                              LEFT JOIN all_tasks_view atv ON atv.t_id = tltm.t_id
                     WHERE tltm.tl_id = tl.tl_id)
                             )) AS lists
            FROM task_lists tl
            WHERE tl.frequency = task_list_frequency.frequency
              AND tl.deleted = FALSE
              AND NOT EXISTS (SELECT 1
                              FROM task_list_room_memberships tlrm
                                       JOIN rooms r ON tlrm.r_id = r.r_id
                              WHERE tlrm.tl_id = tl.tl_id)
            ) tl_data ON TRUE
        WHERE tl_data.lists IS NOT NULL);
GRANT SELECT ON TABLE public.room_check_task_lists_view TO authenticated;

CREATE OR REPLACE FUNCTION get_task_records(start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL)
    RETURNS TABLE
            (
                result JSONB
            )
    SET search_path TO public, auth, pg_temp
AS
$$
(SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
        'r_id', r.r_id,
        'room_name', r.name,
        'records', room_records.data
                  ))
 FROM rooms r
          INNER JOIN LATERAL (
     SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
             'dates', slot_dates.data
                      )) AS data
     FROM room_check_slots rcs
              INNER JOIN LATERAL (
         SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                 'date_time', tr_grouped.date_time,
                 'records', tr_grouped.records
                          )) AS data
         FROM (SELECT tr.date_time,
                      JSONB_AGG(JSONB_BUILD_OBJECT(
                              'tr_id', tr.tr_id,
                              'rc_id', tr.rc_id,
                              't_id', tr.t_id,
                              'recorded_value', qtr.value,
                              'task', (SELECT JSONB_BUILD_OBJECT(
                                                      'task_name',
                                                      t.name,
                                                      'frequency',
                                                      rcs.frequency,
                                                      'manager_only',
                                                      t.manager_only,
                                                      'assigned_users',
                                                      (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
                                                              'u_id',
                                                              u.u_id,
                                                              'name',
                                                              u.name,
                                                              'ug_id',
                                                              u.ug_id
                                                                        ))
                                                       FROM task_record_users tru
                                                                LEFT JOIN users u ON tru.u_id = u.u_id
                                                       WHERE tru.tr_id = tr.tr_id),
                                                      'quantitative_ranges',
                                                      CASE
                                                          WHEN qt.t_id IS NOT NULL
                                                              THEN JSONB_BUILD_OBJECT(
                                                                  'unit',
                                                                  COALESCE(qrw.unit, qrr.unit),
                                                                  'warning_range',
                                                                  CASE
                                                                      WHEN qrw.qr_id IS NOT NULL
                                                                          THEN JSONB_BUILD_OBJECT(
                                                                              'min',
                                                                              qrw.minimum,
                                                                              'max',
                                                                              qrw.maximum) END,
                                                                  'required_range',
                                                                  CASE
                                                                      WHEN qrr.qr_id IS NOT NULL
                                                                          THEN JSONB_BUILD_OBJECT(
                                                                              'min',
                                                                              qrr.minimum,
                                                                              'max',
                                                                              qrr.maximum) END
                                                                   )
                                                          END
                                              )
                                       FROM tasks t
                                                LEFT JOIN quantitative_tasks qt ON t.t_id = qt.t_id
                                                LEFT JOIN quantitative_ranges qrw
                                                          ON qt.qr_id_warning = qrw.qr_id
                                                LEFT JOIN quantitative_ranges qrr
                                                          ON qt.qr_id_required = qrr.qr_id
                                       WHERE t.t_id = tr.t_id)
                                )) AS records
               FROM task_records tr
                        LEFT JOIN quantitative_task_records qtr
                                  ON tr.tr_id = qtr.tr_id
               WHERE tr.rc_id = rcs.rc_id
                 AND (start_date IS NOT NULL OR
                      tr.date_time >= start_date)
               GROUP BY tr.date_time) tr_grouped
         ) slot_dates ON TRUE
     WHERE rcs.r_id = r.r_id
       AND slot_dates.data IS NOT NULL
     GROUP BY r.r_id
     ) room_records ON TRUE
 WHERE room_records.data IS NOT NULL);
$$ LANGUAGE sql STABLE
                SECURITY INVOKER;
GRANT EXECUTE ON FUNCTION public.get_task_records(timestamptz) TO authenticated;

