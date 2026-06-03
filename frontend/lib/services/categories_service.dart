import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';

// Provider for categories
class CategoriesCache {
  static List<Category>? _cachedCategories;
  static DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 10); // Cache for 10 minutes
  
  static bool get isCacheValid {
    if (_cachedCategories == null || _lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheTimeout;
  }
  
  static List<Category>? get cachedCategories => _cachedCategories;
  
  static void cacheCategories(List<Category> categories) {
    _cachedCategories = categories;
    _lastFetch = DateTime.now();
  }
  
  static void invalidateCache() {
    _cachedCategories = null;
    _lastFetch = null;
  }
}

final categoriesProvider = StateProvider<List<Category>>((ref) {
  if (CategoriesCache.isCacheValid) {
    return CategoriesCache.cachedCategories!;
  }
  return CategoriesService.getAllCategories();
});

class CategoriesService {
  static List<Category> getAllCategories() {
    return [
      // Professional Coaching
      Category(
        id: 'professional_coaching',
        name: 'Professional Coaching',
        description: 'Leadership, Executive, Project Management, CPA/CAT/ACCA',
        icon: '💼',
        subcategories: ['Leadership', 'Executive', 'Project Management', 'CPA/CAT/ACCA'],
        isFeatured: true,
        level: 5,
      ),
      
      // Business & Entrepreneurship Coaching
      Category(
        id: 'business_entrepreneurship',
        name: 'Business & Entrepreneurship Coaching',
        description: 'Startup, Strategy, Finance, Marketing, Innovation',
        icon: '🚀',
        subcategories: ['Startup', 'Strategy', 'Finance', 'Marketing', 'Innovation'],
        isPopular: true,
        isFeatured: true,
        level: 3,
      ),
      
      // Academic Coaching
      Category(
        id: 'academic_coaching',
        name: 'Academic Coaching',
        description: 'Primary, Secondary, University, Nursery, Exams, Research',
        icon: '📚',
        subcategories: ['Primary', 'Secondary', 'University', 'Nursery', 'Exams', 'Research'],
        isPopular: true,
        isFeatured: true,
        level: 1,
      ),
      
      // Language Coaching
      Category(
        id: 'language_coaching',
        name: 'Language Coaching',
        description: 'English, French, Kinyarwanda, Business Communication',
        icon: '🗣️',
        subcategories: ['English', 'French', 'Kinyarwanda', 'Business Communication'],
        level: 2,
      ),
      
      // Technical & Digital Coaching
      Category(
        id: 'technical_digital',
        name: 'Technical & Digital Coaching',
        description: 'AI, Data, Cybersecurity, Cloud, Dev, Digital Marketing',
        icon: '💻',
        subcategories: ['AI', 'Data', 'Cybersecurity', 'Cloud', 'Dev', 'Digital Marketing'],
        isFeatured: true,
        level: 3,
      ),
      
      // Job Seeker Coaching
      Category(
        id: 'job_seeker',
        name: 'Job Seeker Coaching',
        description: 'Career choice, skills, exams, interview, resume',
        icon: '🎯',
        subcategories: ['Career choice', 'Skills', 'Exams', 'Interview', 'Resume'],
        isFeatured: true,
        level: 4,
      ),
      
      // Personal & Corporate Development
      Category(
        id: 'personal_corporate',
        name: 'Personal & Corporate Development',
        description: 'Communication, EI, Time, Team, HR, Ethics',
        icon: '🌱',
        subcategories: ['Communication', 'Emotional Intelligence', 'Time Management', 'Team Building', 'HR', 'Ethics'],
        level: 5,
      ),
    ];
  }

  static List<Category> getPopularCategories(List<Category> allCategories) {
    return allCategories.where((category) => category.isPopular).toList();
  }

  static List<Category> getFeaturedCategories(List<Category> allCategories) {
    return allCategories.where((category) => category.isFeatured).toList();
  }

  static List<Category> getCategoriesByLevel(List<Category> allCategories, int level) {
    return allCategories.where((category) => category.level == level).toList();
  }

  static Category? getCategoryById(List<Category> allCategories, String id) {
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
