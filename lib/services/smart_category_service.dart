/// Keyword-based smart categorization service.
///
/// Maps transaction titles to categories using keyword matching.
/// No AI APIs — pure rule-based logic.
class SmartCategoryService {
  SmartCategoryService._();
  static final SmartCategoryService instance = SmartCategoryService._();

  /// Keyword → Category mapping (lowercase).
  static const Map<String, String> _keywords = {
    // Food
    'zomato': 'Food', 'swiggy': 'Food', 'restaurant': 'Food', 'pizza': 'Food',
    'burger': 'Food', 'cafe': 'Food', 'coffee': 'Food', 'lunch': 'Food',
    'dinner': 'Food', 'breakfast': 'Food', 'food': 'Food', 'snack': 'Food',
    'grocery': 'Food', 'dmart': 'Food', 'bigbasket': 'Food', 'blinkit': 'Food',
    'zepto': 'Food', 'instamart': 'Food', 'milk': 'Food', 'chai': 'Food',
    'biryani': 'Food', 'dominos': 'Food', 'mcdonalds': 'Food', 'kfc': 'Food',
    // Transport
    'uber': 'Transport', 'ola': 'Transport', 'rapido': 'Transport',
    'petrol': 'Transport', 'diesel': 'Transport', 'fuel': 'Transport',
    'parking': 'Transport', 'metro': 'Transport', 'bus': 'Transport',
    'cab': 'Transport', 'auto': 'Transport', 'train': 'Transport',
    'toll': 'Transport', 'commute': 'Transport',
    // Shopping
    'amazon': 'Shopping', 'flipkart': 'Shopping', 'myntra': 'Shopping',
    'ajio': 'Shopping', 'shopping': 'Shopping', 'clothes': 'Shopping',
    'shoes': 'Shopping', 'meesho': 'Shopping', 'nykaa': 'Shopping',
    // Entertainment
    'netflix': 'Entertainment', 'spotify': 'Entertainment', 'hotstar': 'Entertainment',
    'prime': 'Entertainment', 'movie': 'Entertainment', 'cinema': 'Entertainment',
    'pvr': 'Entertainment', 'inox': 'Entertainment', 'game': 'Entertainment',
    'youtube': 'Entertainment', 'disney': 'Entertainment', 'jio': 'Entertainment',
    // Bills
    'electricity': 'Bills', 'water': 'Bills', 'wifi': 'Bills', 'internet': 'Bills',
    'rent': 'Bills', 'emi': 'Bills', 'insurance': 'Bills', 'phone': 'Bills',
    'recharge': 'Bills', 'broadband': 'Bills', 'gas': 'Bills',
    'mobile': 'Bills', 'bill': 'Bills', 'subscription': 'Bills',
    // Health
    'doctor': 'Health', 'hospital': 'Health', 'medicine': 'Health',
    'pharmacy': 'Health', 'medical': 'Health', 'gym': 'Health',
    'fitness': 'Health', 'apollo': 'Health', 'health': 'Health',
    // Education
    'tuition': 'Education', 'course': 'Education', 'udemy': 'Education',
    'book': 'Education', 'school': 'Education', 'college': 'Education',
    'exam': 'Education', 'coaching': 'Education', 'class': 'Education',
    // Travel
    'flight': 'Travel', 'hotel': 'Travel', 'airbnb': 'Travel',
    'booking': 'Travel', 'makemytrip': 'Travel', 'goibibo': 'Travel',
    'trip': 'Travel', 'travel': 'Travel', 'vacation': 'Travel',
    // Income
    'salary': 'Salary', 'pay': 'Salary', 'payroll': 'Salary',
    'freelance': 'Freelance', 'project': 'Freelance', 'client': 'Freelance',
    'dividend': 'Investment', 'interest': 'Investment', 'mutual fund': 'Investment',
    'stock': 'Investment', 'returns': 'Investment',
    'business': 'Business', 'revenue': 'Business', 'profit': 'Business',
    'gift': 'Gift', 'bonus': 'Gift', 'reward': 'Gift',
  };

  /// Suggest a category based on the transaction title.
  /// Returns null if no keyword match is found.
  String? suggest(String title) {
    final lower = title.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Try exact word match first
    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Returns a confidence-scored suggestion.
  ({String category, double confidence})? suggestWithConfidence(String title) {
    final lower = title.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final matches = <String, int>{};
    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key)) {
        matches[entry.value] = (matches[entry.value] ?? 0) + 1;
      }
    }
    if (matches.isEmpty) return null;

    final best = matches.entries.reduce((a, b) => a.value >= b.value ? a : b);
    // More keyword matches = higher confidence
    final confidence = (best.value / 3).clamp(0.3, 1.0);
    return (category: best.key, confidence: confidence);
  }
}
