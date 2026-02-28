import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<GroupModel> _myGroups = [];
  List<GroupModel> _publicGroups = [];
  GroupModel? _selectedGroup;
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get myGroups => _myGroups;
  List<GroupModel> get publicGroups => _publicGroups;
  GroupModel? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _groupService.getMyGroups();
      _myGroups = (data as List).map((e) => GroupModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPublicGroups({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final groups = await _groupService.searchGroups('');
      if (page == 1) {
        _publicGroups = groups;
      } else {
        _publicGroups.addAll(groups);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup({
    required String name,
    String? description,
    required String groupType,
    bool isPublic = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        groupType: groupType,
        isPublic: isPublic,
      );
      _myGroups.insert(0, group);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> selectGroup(String groupId) async {
    try {
      _selectedGroup = await _groupService.getGroupById(groupId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
