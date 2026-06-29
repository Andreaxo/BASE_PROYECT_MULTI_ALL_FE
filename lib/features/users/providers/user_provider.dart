import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Manages user list state and CRUD operations.
class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all users from the API.
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await UserApiService.getAll();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new user and refresh the list.
  Future<bool> createUser(CreateUserRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await UserApiService.create(request);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing user and refresh the list.
  Future<bool> updateUser(int id, UpdateUserRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await UserApiService.update(id, request);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a user and refresh the list.
  Future<bool> deleteUser(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await UserApiService.delete(id);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
