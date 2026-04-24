import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore CRUD — mirrors SQLite structure under users/{userId}/.
///
/// Structure:
///   users/{userId}/transactions/{docId}
///   users/{userId}/accounts/{docId}
///   users/{userId}/bills/{docId}
///   users/{userId}/budgets/{docId}
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _fs = FirebaseFirestore.instance;

  CollectionReference _col(String userId, String collection) =>
      _fs.collection('users').doc(userId).collection(collection);

  // ═══════════════════════════════════════════════════════════════════
  // GENERIC CRUD
  // ═══════════════════════════════════════════════════════════════════

  /// Upsert a document. Returns the document ID.
  Future<String> upsert(String userId, String collection, String? docId, Map<String, dynamic> data) async {
    try {
      if (docId != null) {
        await _col(userId, collection).doc(docId).set(data, SetOptions(merge: true));
        return docId;
      } else {
        final ref = await _col(userId, collection).add(data);
        return ref.id;
      }
    } catch (e) {
      debugPrint('FirestoreService: upsert error ($collection): $e');
      rethrow;
    }
  }

  /// Fetch all documents from a collection.
  Future<List<Map<String, dynamic>>> getAll(String userId, String collection) async {
    try {
      final snap = await _col(userId, collection).get();
      return snap.docs.map((d) {
        final data = d.data()! as Map<String, dynamic>;
        data['firestoreId'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('FirestoreService: getAll error ($collection): $e');
      return [];
    }
  }

  /// Delete a document.
  Future<void> deleteDoc(String userId, String collection, String docId) async {
    try {
      await _col(userId, collection).doc(docId).delete();
    } catch (e) {
      debugPrint('FirestoreService: delete error ($collection/$docId): $e');
    }
  }

  /// Fetch documents updated after a given timestamp.
  Future<List<Map<String, dynamic>>> getUpdatedAfter(String userId, String collection, DateTime since) async {
    try {
      final snap = await _col(userId, collection)
          .where('updatedAt', isGreaterThan: since.toIso8601String())
          .get();
      return snap.docs.map((d) {
        final data = d.data()! as Map<String, dynamic>;
        data['firestoreId'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('FirestoreService: getUpdatedAfter error ($collection): $e');
      return [];
    }
  }
}
