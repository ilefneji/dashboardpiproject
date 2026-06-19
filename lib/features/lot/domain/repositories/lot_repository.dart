import '../entities/lot.dart';

abstract class LotRepository {
  // Lot methods
  Future<List<Lot>> getLots();
  Future<Lot?> getLot(int id);
  Future<Lot?> createLot(Lot lot);
  Future<bool> updateLot(Lot lot);
  Future<bool> deleteLot(int id);
  
  // Task affectation methods
  Future<bool> affectTask(int lotId, int taskId);
  Future<bool> affectTasks(int lotId, List<int> taskIds);
  Future<bool> removeTask(int lotId, int taskId);
  Future<bool> syncTasks(int lotId, List<int> taskIds);
}
