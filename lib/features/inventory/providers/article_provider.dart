import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';

class ArticleProvider extends ChangeNotifier {
  List<Article> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadArticles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _articles = await ArticleApiService.getAll();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createArticle(CreateArticleRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ArticleApiService.create(request);
      await loadArticles();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateArticle(int id, UpdateArticleRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ArticleApiService.update(id, request);
      await loadArticles();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteArticle(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ArticleApiService.delete(id);
      await loadArticles();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
