import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_storage.dart';

/// Manages multi-language dictionaries for Spanish, English, and French.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // Auth & Login
      'login_title': 'Iniciar Sesión',
      'login_subtitle': 'Ingresa tus credenciales para acceder',
      'email': 'Correo Electrónico',
      'password': 'Contraseña',
      'login_button': 'Ingresar',
      'login_loading': 'Iniciando sesión...',
      'email_required': 'El correo electrónico es requerido',
      'invalid_email': 'Ingrese un correo válido',
      'password_required': 'La contraseña es requerida',
      'logout': 'Cerrar sesión',

      // Actions & General Buttons
      'retry': 'Reintentar',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'add': 'Agregar',
      'actions': 'Acciones',
      'search': 'Buscar...',
      'status': 'Estado',
      'name': 'Nombre',
      'active': 'Activo',
      'inactive': 'Inactivo',
      'no_data': 'No hay datos disponibles',
      'loading': 'Cargando...',

      // Entities / Modules
      'users': 'Usuarios',
      'user': 'Usuario',
      'roles': 'Roles',
      'role': 'Rol',
      'companies': 'Empresas',
      'company': 'Empresa',
      'categories': 'Categorías',
      'category': 'Categoría',
      'articles': 'Artículos',
      'article': 'Artículo',
      'menus': 'Menús',
      'menu': 'Menú',

      // Form Labels & Validations
      'first_name': 'Nombre',
      'last_name': 'Apellido',
      'first_name_required': 'El nombre es requerido',
      'last_name_required': 'El apellido es requerido',
      'role_required': 'El rol es requerido',
      'company_required': 'La empresa es requerida',
      'name_required': 'El nombre es requerido',

      // Specific Dialogs / Titles
      'add_user': 'Agregar Usuario',
      'edit_user': 'Editar Usuario',
      'delete_user': 'Eliminar Usuario',
      'delete_user_confirm': '¿Está seguro de que desea eliminar este usuario?',
      'delete_confirm_title': 'Confirmar Eliminación',
      'active_company': 'Empresa Activa',
      'users_directory': 'Directorio de Usuarios',
      'search_hint': 'Buscar por ID, nombre o correo...',
      'new_button': 'Nuevo',
      'full_name': 'Nombre completo',
      'created_at': 'Creado el',
      'no_results': 'No se encontraron resultados',
      'search_other_keywords': 'Prueba a buscar con otras palabras clave',
      'total_users': 'Total de usuarios',
      'rows_per_page': 'Filas por página:',
      'page': 'Pág.',
      'of': 'de',
      'error_occurred': 'Ocurrió un error',
      'password_keep_empty': 'Contraseña (dejar vacío para no cambiar)',
      'password_min_length': 'Mínimo 6 caracteres',
      'assigned_role': 'Rol asignado',
      'select_role': 'Seleccione un rol',
      'associated_companies': 'Empresas asociadas',
      'no_companies_found': 'No hay empresas registradas',
      'user_active': 'Usuario activo',
      'save_changes': 'Guardar Cambios',
      'create_user': 'Crear Usuario',
      'enter_first_name': 'Ingrese el nombre',
      'enter_last_name': 'Ingrese el apellido',
      'password_placeholder_edit': '••••••••',
      'created_by': 'Creado por',
      'updated_by': 'Modificado por',
      'updated_at': 'Modificado el',
      'change_password': 'Cambiar Contraseña',
      'new_password': 'Nueva Contraseña',
      'enter_new_password': 'Ingrese la nueva contraseña',
      'password_changed_success': 'Contraseña cambiada con éxito',
      // Category & Article Internal Content (ES)
      'category_list_title': 'Categorías de Inventario',
      'category_list_subtitle': 'Organiza los artículos de tu catálogo en categorías.',
      'category_admin': 'Administración de Categorías',
      'search_category_hint': 'Buscar categoría por nombre o ID...',
      'category_name_label': 'Nombre de la Categoría',
      'category_name_hint': 'Ej: Limpieza, Bebidas, Lácteos',
      'category_name_required': 'El nombre es requerido',
      'category_active_label': 'Categoría Activa',
      'no_categories_found': 'No se encontraron categorías',
      'no_categories_description_search': 'Prueba modificando los filtros de búsqueda',
      'no_categories_description': 'Empieza por crear una nueva categoría de inventario.',
      'no_permission_catalog': 'No tienes permisos para visualizar este catálogo.',
      'delete_category_title': 'Eliminar Categoría',
      'delete_category_confirm': '¿Estás seguro de que deseas eliminar la categoría "{name}" (ID: {id})?',
      'add_category': 'Nueva Categoría',
      'edit_category': 'Editar Categoría',
      'add_article': 'Nuevo Artículo',
      'edit_article': 'Editar Artículo',
      'article_list_title': 'Artículos de Inventario',
      'article_list_subtitle': 'Gestiona los artículos de tu catálogo y sus asociaciones de categoría.',
      'article_catalog': 'Catálogo de Artículos',
      'search_article_hint': 'Buscar artículo por nombre, categoría o ID...',
      'article_name_label': 'Nombre del Artículo',
      'article_name_hint': 'Ej: Detergente Líquido, Coca-Cola 1.5L',
      'article_name_required': 'El nombre es requerido',
      'related_category_label': 'Categoría Relacionada',
      'select_category_hint': 'Selecciona una Categoría',
      'please_select_category': 'Por favor selecciona una categoría',
      'no_articles_found': 'No se encontraron artículos',
      'no_articles_description_search': 'Prueba modificando los filtros de búsqueda',
      'no_articles_description': 'Empieza por crear un nuevo artículo de inventario.',
      'delete_article_title': 'Eliminar Artículo',
      'delete_article_confirm': '¿Estás seguro de que deseas eliminar el artículo "{name}" (ID: {id})?',
      'no_category_assigned': 'Sin Categoría',
    },
    'en': {
      // Auth & Login
      'login_title': 'Login',
      'login_subtitle': 'Enter your credentials to access',
      'email': 'Email Address',
      'password': 'Password',
      'login_button': 'Log In',
      'login_loading': 'Logging in...',
      'email_required': 'Email is required',
      'invalid_email': 'Enter a valid email',
      'password_required': 'Password is required',
      'logout': 'Log Out',

      // Actions & General Buttons
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'add': 'Add',
      'actions': 'Actions',
      'search': 'Search...',
      'status': 'Status',
      'name': 'Name',
      'active': 'Active',
      'inactive': 'Inactive',
      'no_data': 'No data available',
      'loading': 'Loading...',

      // Entities / Modules
      'users': 'Users',
      'user': 'User',
      'roles': 'Roles',
      'role': 'Role',
      'companies': 'Companies',
      'company': 'Company',
      'categories': 'Categories',
      'category': 'Category',
      'articles': 'Articles',
      'article': 'Article',
      'menus': 'Menus',
      'menu': 'Menu',

      // Form Labels & Validations
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'first_name_required': 'First name is required',
      'last_name_required': 'Last name is required',
      'role_required': 'Role is required',
      'company_required': 'Company is required',
      'name_required': 'Name is required',

      // Specific Dialogs / Titles
      'add_user': 'Add User',
      'edit_user': 'Edit User',
      'delete_user': 'Delete User',
      'delete_user_confirm': 'Are you sure you want to delete this user?',
      'delete_confirm_title': 'Confirm Deletion',
      'active_company': 'Active Company',
      'users_directory': 'Users Directory',
      'search_hint': 'Search by ID, name or email...',
      'new_button': 'New',
      'full_name': 'Full Name',
      'created_at': 'Created At',
      'no_results': 'No results found',
      'search_other_keywords': 'Try searching with other keywords',
      'total_users': 'Total users',
      'rows_per_page': 'Rows per page:',
      'page': 'Page',
      'of': 'of',
      'error_occurred': 'An error occurred',
      'password_keep_empty': 'Password (leave empty to keep unchanged)',
      'password_min_length': 'Minimum 6 characters',
      'assigned_role': 'Assigned Role',
      'select_role': 'Select a role',
      'associated_companies': 'Associated Companies',
      'no_companies_found': 'No registered companies found',
      'user_active': 'Active User',
      'save_changes': 'Save Changes',
      'create_user': 'Create User',
      'enter_first_name': 'Enter first name',
      'enter_last_name': 'Enter last name',
      'password_placeholder_edit': '••••••••',
      'created_by': 'Created By',
      'updated_by': 'Updated By',
      'updated_at': 'Updated At',
      'change_password': 'Change Password',
      'new_password': 'New Password',
      'enter_new_password': 'Enter new password',
      'password_changed_success': 'Password changed successfully',
      // Category & Article Internal Content (EN)
      'category_list_title': 'Inventory Categories',
      'category_list_subtitle': 'Organize your catalog items into categories.',
      'category_admin': 'Category Management',
      'search_category_hint': 'Search category by name or ID...',
      'category_name_label': 'Category Name',
      'category_name_hint': 'e.g., Cleaning, Drinks, Dairy',
      'category_name_required': 'Name is required',
      'category_active_label': 'Active Category',
      'no_categories_found': 'No categories found',
      'no_categories_description_search': 'Try modifying search filters',
      'no_categories_description': 'Start by creating a new inventory category.',
      'no_permission_catalog': 'You do not have permission to view this catalog.',
      'delete_category_title': 'Delete Category',
      'delete_category_confirm': 'Are you sure you want to delete category "{name}" (ID: {id})?',
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'add_article': 'Add Item',
      'edit_article': 'Edit Item',
      'article_list_title': 'Inventory Items',
      'article_list_subtitle': 'Manage catalog items and their category associations.',
      'article_catalog': 'Items Catalog',
      'search_article_hint': 'Search item by name, category or ID...',
      'article_name_label': 'Item Name',
      'article_name_hint': 'e.g., Liquid Detergent, Coke 1.5L',
      'article_name_required': 'Name is required',
      'related_category_label': 'Related Category',
      'select_category_hint': 'Select a Category',
      'please_select_category': 'Please select a category',
      'no_articles_found': 'No items found',
      'no_articles_description_search': 'Try modifying search filters',
      'no_articles_description': 'Start by creating a new inventory item.',
      'delete_article_title': 'Delete Item',
      'delete_article_confirm': 'Are you sure you want to delete item "{name}" (ID: {id})?',
      'no_category_assigned': 'No Category',
    },
    'fr': {
      // Auth & Login
      'login_title': 'Connexion',
      'login_subtitle': 'Saisissez vos identifiants pour accéder',
      'email': 'Adresse E-mail',
      'password': 'Mot de passe',
      'login_button': 'Se connecter',
      'login_loading': 'Connexion en cours...',
      'email_required': 'L\'e-mail est requis',
      'invalid_email': 'Entrez un e-mail valide',
      'password_required': 'Le mot de passe est requis',
      'logout': 'Se déconnecter',

      // Actions & General Buttons
      'retry': 'Réessayer',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'add': 'Ajouter',
      'actions': 'Actions',
      'search': 'Rechercher...',
      'status': 'Statut',
      'name': 'Nom',
      'active': 'Actif',
      'inactive': 'Inactif',
      'no_data': 'Aucune donnée disponible',
      'loading': 'Chargement...',

      // Entities / Modules
      'users': 'Utilisateurs',
      'user': 'Utilisateur',
      'roles': 'Rôles',
      'role': 'Rôle',
      'companies': 'Entreprises',
      'company': 'Entreprise',
      'categories': 'Catégories',
      'category': 'Catégorie',
      'articles': 'Articles',
      'article': 'Article',
      'menus': 'Menus',
      'menu': 'Menu',

      // Form Labels & Validations
      'first_name': 'Prénom',
      'last_name': 'Nom de famille',
      'first_name_required': 'Le prénom est requis',
      'last_name_required': 'Le nom de famille est requis',
      'role_required': 'Le rôle est requis',
      'company_required': 'L\'entreprise est requise',
      'name_required': 'Le nom est requis',

      // Specific Dialogs / Titles
      'add_user': 'Ajouter Utilisateur',
      'edit_user': 'Modifier Utilisateur',
      'delete_user': 'Supprimer l\'utilisateur',
      'delete_user_confirm': 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
      'delete_confirm_title': 'Confirmer la suppression',
      'active_company': 'Entreprise Active',
      'users_directory': 'Annuaire des Utilisateurs',
      'search_hint': 'Rechercher par ID, nom ou e-mail...',
      'new_button': 'Nouveau',
      'full_name': 'Nom complet',
      'created_at': 'Créé le',
      'no_results': 'Aucun résultat trouvé',
      'search_other_keywords': 'Essayez de rechercher avec d\'autres mots-clés',
      'total_users': 'Total d\'utilisateurs',
      'rows_per_page': 'Lignes par page:',
      'page': 'Page',
      'of': 'de',
      'error_occurred': 'Une erreur est survenue',
      'password_keep_empty': 'Mot de passe (laisser vide pour ne pas changer)',
      'password_min_length': 'Minimum 6 caractères',
      'assigned_role': 'Rôle assigné',
      'select_role': 'Sélectionner un rôle',
      'associated_companies': 'Entreprises associées',
      'no_companies_found': 'Aucune entreprise enregistrée',
      'user_active': 'Utilisateur actif',
      'save_changes': 'Enregistrer les modifications',
      'create_user': 'Créer l\'utilisateur',
      'enter_first_name': 'Entrez le prénom',
      'enter_last_name': 'Entrez le nom de famille',
      'password_placeholder_edit': '••••••••',
      'created_by': 'Créé par',
      'updated_by': 'Modifié par',
      'updated_at': 'Modifié le',
      'change_password': 'Changer le mot de passe',
      'new_password': 'Nouveau mot de passe',
      'enter_new_password': 'Entrez le nouveau mot de passe',
      'password_changed_success': 'Mot de passe changé avec succès',
      // Category & Article Internal Content (FR)
      'category_list_title': 'Catégories d\'inventaire',
      'category_list_subtitle': 'Organisez les articles de votre catalogue en catégories.',
      'category_admin': 'Gestion des catégories',
      'search_category_hint': 'Rechercher une catégorie par nom ou ID...',
      'category_name_label': 'Nom de la catégorie',
      'category_name_hint': 'Ex: Nettoyage, Boissons, Produits laitiers',
      'category_name_required': 'Le nom est requis',
      'category_active_label': 'Catégorie active',
      'no_categories_found': 'Aucune catégorie trouvée',
      'no_categories_description_search': 'Essayez de modifier les filtres de recherche',
      'no_categories_description': 'Commencez par créer une nouvelle catégorie d\'inventaire.',
      'no_permission_catalog': 'Vous n\'avez pas l\'autorisation de voir ce catalogue.',
      'delete_category_title': 'Supprimer la catégorie',
      'delete_category_confirm': 'Êtes-vous sûr de vouloir supprimer la catégorie "{name}" (ID: {id})?',
      'add_category': 'Ajouter une catégorie',
      'edit_category': 'Modifier la catégorie',
      'add_article': 'Ajouter un article',
      'edit_article': 'Modifier l\'article',
      'article_list_title': 'Articles d\'inventaire',
      'article_list_subtitle': 'Gerez les articles de votre catalogue et leurs associations de catégories.',
      'article_catalog': 'Catalogue d\'articles',
      'search_article_hint': 'Rechercher un article par nom, catégorie ou ID...',
      'article_name_label': 'Nom de l\'article',
      'article_name_hint': 'Ex: Détergent liquide, Coca-Cola 1.5L',
      'article_name_required': 'Le nom est requis',
      'related_category_label': 'Catégorie associée',
      'select_category_hint': 'Sélectionner une catégorie',
      'please_select_category': 'Veuillez sélectionner une catégorie',
      'no_articles_found': 'Aucun article trouvé',
      'no_articles_description_search': 'Essayez de modifier les filtres de recherche',
      'no_articles_description': 'Commencez par créer un nouvel article d\'inventaire.',
      'delete_article_title': 'Supprimer l\'article',
      'delete_article_confirm': 'Êtes-vous sûr de vouloir supprimer l\'article "{name}" (ID: {id})?',
      'no_category_assigned': 'Sans catégorie',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ?? key;
  }
}

/// Flutter Localizations Delegate for AppLocalizations.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Shorthand translation extension for BuildContext.
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}

/// Provider to manage language state, persistence, and HTTP headers configuration.
class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;

  LanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedCode = await AuthStorage.getLocale();
    _locale = Locale(savedCode);
    ApiConfig.activeLocale = savedCode;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode != languageCode) {
      _locale = Locale(languageCode);
      ApiConfig.activeLocale = languageCode;
      await AuthStorage.saveLocale(languageCode);
      notifyListeners();
    }
  }
}
