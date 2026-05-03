import 'package:animal_room_task_manager/animal_management/animal_repository.dart';
import 'package:animal_room_task_manager/census/census_repository.dart';
import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:flutter/foundation.dart';

import '../scheduler/scheduling_model.dart';

class Census {
  final Animal animal;
  final int quantity;

  Census({required this.animal, required this.quantity});
}

class CensusScreenModel {
  final LoginUseCase _loginUseCase;
  final CensusRepository _censusRepository;
  final Room room;
  final List<Census> _censusEntries = [];

  ValueNotifier<List<Census>> censusEntries = ValueNotifier([]);

  CensusScreenModel({
    required Census? census,
    required this.room,
    required LoginUseCase loginUseCase,
    required CensusRepository censusRepository,
  }) : _censusRepository = censusRepository,
       _loginUseCase = loginUseCase {
    census != null ? _censusEntries.add(census) : null;
    censusEntries.value = _censusEntries;
  }

  void addCensusEntry(Census census) {
    final existingIndex = _censusEntries.indexWhere(
      (e) => e.animal.aid == census.animal.aid,
    );

    if (existingIndex != -1) {
      final existingEntry = _censusEntries[existingIndex];
      _censusEntries[existingIndex] = Census(
        animal: existingEntry.animal,
        quantity: existingEntry.quantity + census.quantity,
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
      _censusRepository.submitCensus(
        _censusEntries,
        room.rid,
        currentUser!.uid!,
      );
    }
  }
}

class CensusEntryModel extends ChangeNotifier {
  ValueNotifier<Set<Animal>> animals = ValueNotifier({});
  ValueNotifier<Set<RoomModel>> rooms = ValueNotifier({});

  CensusEntryModel({
    required AnimalRepository animalRepository,
    required RoomRepository roomRepository,
  }) {
    animals = animalRepository.animals;
    animalRepository.loadAnimals();
    rooms = roomRepository.rooms;
    roomRepository.loadRooms();
  }

  Animal getAnimal(int aid) {
    return animals.value.firstWhere((a) => a.aid == aid);
  }
}
