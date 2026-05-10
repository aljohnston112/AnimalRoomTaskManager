import 'package:animal_room_task_manager/animal_management/animal_repository.dart';
import 'package:animal_room_task_manager/census/census_repository.dart';
import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:flutter/foundation.dart';

import '../scheduler/scheduling_model.dart';

class Census {
  final Room room;
  final Animal animal;
  final int quantity;

  Census({required this.animal, required this.quantity, required this.room});
}

class CensusScreenModel {
  final LoginUseCase _loginUseCase;
  final CensusRepository _censusRepository;
  final List<Census> _censusEntries = [];

  ValueNotifier<List<Census>> censusEntries = ValueNotifier([]);

  CensusScreenModel({
    required Census? census,
    required LoginUseCase loginUseCase,
    required CensusRepository censusRepository,
  }) : _censusRepository = censusRepository,
       _loginUseCase = loginUseCase {
    census != null ? _censusEntries.add(census) : null;
    censusEntries.value = _censusEntries;
  }

  void addCensusEntry(Census census) {
    final existingIndex = _censusEntries.indexWhere(
      (e) => e.animal.aid == census.animal.aid && e.room.rid == census.room.rid,
    );

    if (existingIndex != -1) {
      final existingEntry = _censusEntries[existingIndex];
      _censusEntries[existingIndex] = Census(
        animal: existingEntry.animal,
        quantity: existingEntry.quantity + census.quantity,
        room: existingEntry.room,
      );
    } else {
      _censusEntries.add(census);
    }

    censusEntries.value = List.from(_censusEntries);
  }

  void replaceCensusEntry(Census census) {
    _censusEntries.removeWhere((e) => e.animal.aid == census.animal.aid);
    addCensusEntry(census);
    censusEntries.value = List.from(_censusEntries);
  }

  void removeCensusEntry(Census census) {
    _censusEntries.removeWhere((e) => e.animal.aid == census.animal.aid);
    censusEntries.value = List.from(_censusEntries);
  }

  void submitCensus() {
    var currentUser = _loginUseCase.loggedInUser;
    if (currentUser?.uid != null) {
      _censusRepository.submitCensus(_censusEntries, currentUser!.uid!);
    }
  }
}

class CensusEntryModel extends ChangeNotifier {
  ValueNotifier<Set<Animal>> animals = ValueNotifier({});
  ValueNotifier<Set<RoomModel>> rooms = ValueNotifier({});

  CensusEntryModel({
    required AnimalRepository animalRepository,
    required RoomRepository roomRepository,
    required Set<int> roomsWithCensuses,
  }) {
    animals = animalRepository.animals;
    animalRepository.loadAnimals();
    roomRepository.rooms.addListener(() {
      var set = roomRepository.rooms.value
          .where((e) => !roomsWithCensuses.contains(e.rid))
          .toSet();
      rooms.value = set;
    });
    roomRepository.loadRooms();
  }

  Animal getAnimal(int aid) {
    return animals.value.firstWhere((a) => a.aid == aid);
  }
}
