// lib/services/group_service.dart
import '../models/models.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _api = ApiService();

  Future<List<GroupModel>> getMyGroups() async {
    final response = await _api.get('/groups');
    final List<dynamic> data = response['data'] ?? [];
    return data.map((g) => GroupModel.fromJson(g)).toList();
  }

  Future<List<GroupModel>> searchGroups(String query) async {
    final response = await _api.get('/groups/search', queryParams: {'q': query});
    final List<dynamic> data = response['data'] ?? [];
    return data.map((g) => GroupModel.fromJson(g)).toList();
  }

  Future<GroupModel> getGroupById(String groupId) async {
    final response = await _api.get('/groups/$groupId');
    return GroupModel.fromJson(response['data']);
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String groupType,
    bool isPublic = true,
  }) async {
    final response = await _api.post('/groups', body: {
      'name': name,
      if (description != null) 'description': description,
      'group_type': groupType,
      'is_public': isPublic,
    });
    return GroupModel.fromJson(response['data']);
  }

  Future<GroupModel> updateGroup(
    String groupId, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isPublic != null) body['is_public'] = isPublic;
    final response = await _api.put('/groups/$groupId', body: body);
    return GroupModel.fromJson(response['data']);
  }

  Future<void> deleteGroup(String groupId) async {
    await _api.delete('/groups/$groupId');
  }

  Future<void> joinGroup(String groupId, {String? inviteCode}) async {
    await _api.post('/groups/$groupId/join', body: {
      if (inviteCode != null) 'invite_code': inviteCode,
    });
  }

  Future<void> leaveGroup(String groupId) async {
    await _api.delete('/groups/$groupId/members/me');
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final response = await _api.get('/groups/$groupId/members');
    final List<dynamic> data = response['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<String> getInviteCode(String groupId) async {
    final response = await _api.get('/groups/$groupId/invite');
    return response['data']['invite_code'];
  }
}
