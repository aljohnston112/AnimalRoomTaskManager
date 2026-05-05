import csv
import random
from collections import defaultdict
from datetime import datetime, timedelta

qt_ids = {0, 1, 2, 3, 40, 41, 42, 43, 44, 45, 46, 47}
t_ids = list({i for i in range(0, 48)} - qt_ids)
qt_ids = list(qt_ids)
rooms = [i for i in range(0, 20)]
users = [i for i in range(1, 5)]
states = ['not_started', 'started', 'done']
frequencies = ['Daily', 'Weekly', 'Monthly']

def generate_full_qt_records(day_to_tr_id):
    rcs_file = 'quantitative_task_records_full.csv'
    with open(rcs_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(
            ['tr_id', 'value']
        )
        for day, tr_id in day_to_tr_id.items():
            writer.writerow([
                tr_id,
                random.randrange(0, 10001) / 100.0
            ])

def generate_full_task_records(rc_id_map):
    tr_id = 0
    rcs_file = 'task_records_full.csv'
    day_to_tr_id = {}
    with open(rcs_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(
            ['tr_id', 't_id', 'rc_id', 'date_time']
        )
        for day, frequency_to_rc_id in rc_id_map.items():
            t_ids_left = list(t_ids)
            qt_ids_left = list(qt_ids)
            for frequency, rc_ids in frequency_to_rc_id.items():
                for rc_id in rc_ids:
                    if frequency == frequencies[0]:
                        for k in range(0, 7):
                            qt_id = random.choice(qt_ids_left)
                            qt_ids_left.remove(qt_id)
                            writer.writerow([
                                tr_id,
                                qt_id,
                                rc_id,
                                day,
                            ])
                            day_to_tr_id[day] = tr_id
                            tr_id += 1
                        for k in range(0, 6):
                            t_id = random.choice(t_ids_left)
                            t_ids_left.remove(t_id)
                            writer.writerow([
                                tr_id,
                                t_id,
                                rc_id,
                                day,
                            ])
                            tr_id += 1
                    if frequency == frequencies[1]:
                        t_id = random.choice(t_ids_left)
                        t_ids_left.remove(t_id)
                        writer.writerow([
                            tr_id,
                            t_id,
                            rc_id,
                            day,
                        ])
                        tr_id += 1
                    if frequency == frequencies[0]:
                        t_id = random.choice(t_ids_left)
                        t_ids_left.remove(t_id)
                        writer.writerow([
                            tr_id,
                            t_id,
                            rc_id,
                            day,
                        ])
                        tr_id += 1
    return day_to_tr_id

def generate_full_room_check_slots(days):
    now = datetime.now()
    start_date = datetime(year=(now.year - 7), month=now.month, day=now.day)
    rc_id = 0
    rc_id_map = defaultdict(lambda: {f: list() for f in frequencies})
    rcs_file = 'room_checks_full.csv'
    with open(rcs_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(
            ['rc_id', 'date_time', 'r_id', 'state', 'frequency', 'comment',
             'u_id']
        )
        day = start_date
        for i in range(days):
            writer.writerow([
                rc_id,
                day.strftime('%Y-%m-%d %H:%M:%S'),
                random.choice(rooms),
                random.choice(states),
                frequencies[0],
                random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                random.choice(users),
            ])
            rc_id_map[day][frequencies[0]].append(rc_id)
            rc_id += 1

            if day.day % 7 == 0:
                writer.writerow([
                    rc_id,
                    day.strftime('%Y-%m-%d %H:%M:%S'),
                    random.choice(rooms),
                    random.choice(states),
                    frequencies[1],
                    random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                    random.choice(users),
                ])
                rc_id_map[day][frequencies[1]].append(rc_id)
                rc_id += 1
            if day.day == 1:
                writer.writerow([
                    rc_id,
                    day.strftime('%Y-%m-%d %H:%M:%S'),
                    random.choice(rooms),
                    random.choice(states),
                    frequencies[2],
                    random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                    random.choice(users),
                ])
                rc_id_map[day][frequencies[2]].append(rc_id)
                rc_id += 1
            day = day + timedelta(days=1)
    return rc_id_map


if __name__ == "__main__":
    days = 7 * 365
    generate_full_qt_records(generate_full_task_records(generate_full_room_check_slots(days)))
    print("Generation complete.")
