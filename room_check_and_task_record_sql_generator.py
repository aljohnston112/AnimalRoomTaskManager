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

def generate_task_record_users(tr_ids):
    tru_file = 'test_data/task_record_users.csv'
    with open(tru_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['tr_id', 'u_id'])
        for tr_id in tr_ids:
            u_id = random.choice(users)
            writer.writerow([tr_id, u_id])

def generate_full_qt_records(day_to_tr_id):
    rcs_file = 'test_data/quantitative_task_records.csv'
    with open(rcs_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(
            ['tr_id', 'value']
        )
        for day, tr_ids in day_to_tr_id.items():
            for tr_id in tr_ids:
                writer.writerow([
                    tr_id,
                    random.randrange(0, 10001) / 100.0
                ])

def generate_full_task_records(day_room_frequency_to_rc_ids):
    tr_id = 0
    rcs_file = 'test_data/task_records.csv'
    day_to_tr_ids = defaultdict(lambda: [])
    day_to_qr_tr_ids = defaultdict(lambda: [])
    with open(rcs_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(
            ['tr_id', 't_id', 'rc_id', 'date_time']
        )
        for day, room_frequency_to_rc_ids in day_room_frequency_to_rc_ids.items():
            for room, frequency_to_rc_ids in room_frequency_to_rc_ids.items():
                t_ids_left = list(t_ids)
                qt_ids_left = list(qt_ids)
                for frequency, rc_ids in frequency_to_rc_ids.items():
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
                                day_to_qr_tr_ids[day].append(tr_id)
                                day_to_tr_ids[day].append(tr_id)
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
                                day_to_tr_ids[day].append(tr_id)
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
                            day_to_tr_ids[day].append(tr_id)
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
                            day_to_tr_ids[day].append(tr_id)
                            tr_id += 1
    return day_to_tr_ids, day_to_qr_tr_ids

def generate_full_room_check_slots(days):
    now = datetime.now()
    start_date = datetime(year=(now.year - 7), month=now.month, day=now.day)
    rc_id = 0
    day_room_frequency_to_rc_ids = defaultdict(lambda: defaultdict(lambda: {f: [] for f in frequencies}))
    rcs_file = 'test_data/room_check_slots.csv'
    with open(rcs_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(
            ['rc_id', 'date_time', 'r_id', 'state', 'frequency', 'comment',
             'u_id']
        )
        day = start_date
        for i in range(days):
            for room in rooms:
                writer.writerow([
                    rc_id,
                    day.strftime('%Y-%m-%d %H:%M:%S'),
                    room,
                    random.choice(states),
                    frequencies[0],
                    random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                    random.choice(users),
                ])
                day_room_frequency_to_rc_ids[day][room][frequencies[0]].append(rc_id)
                rc_id += 1

                if day.day % 7 == 0:
                    writer.writerow([
                        rc_id,
                        day.strftime('%Y-%m-%d %H:%M:%S'),
                        room,
                        random.choice(states),
                        frequencies[1],
                        random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                        random.choice(users),
                    ])
                    day_room_frequency_to_rc_ids[day][room][frequencies[1]].append(rc_id)
                    rc_id += 1
                if day.day == 1:
                    writer.writerow([
                        rc_id,
                        day.strftime('%Y-%m-%d %H:%M:%S'),
                        room,
                        random.choice(states),
                        frequencies[2],
                        random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                        random.choice(users),
                    ])
                    day_room_frequency_to_rc_ids[day][room][frequencies[2]].append(rc_id)
                    rc_id += 1
            day = day + timedelta(days=1)
    return day_room_frequency_to_rc_ids


if __name__ == "__main__":
    days = 7 * 365
    g_day_to_tr_ids, g_day_to_qr_tr_ids = generate_full_task_records(generate_full_room_check_slots(days))
    generate_full_qt_records(g_day_to_qr_tr_ids)
    generate_task_record_users([t_id for t_ids in g_day_to_tr_ids.values() for t_id in t_ids])
    print("Generation complete.")
