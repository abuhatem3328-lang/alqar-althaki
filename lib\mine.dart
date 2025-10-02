import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

/* ======================= MODELS ======================= */

class Request {
  int? id;
  String type;
  String location;
  num area;
  num price;
  String ownerName;
  String ownerPhone;
  int createdAt;

  Request({
    this.id,
    required this.type,
    required this.location,
    required this.area,
    required this.price,
    required this.ownerName,
    required this.ownerPhone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'location': location,
    'area': area,
    'price': price,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'createdAt': createdAt,
  };

  factory Request.fromMap(Map<String, dynamic> map) => Request(
    id: map['id'],
    type: map['type'] ?? '',
    location: map['location'] ?? '',
    area: map['area'] ?? 0,
    price: map['price'] ?? 0,
    ownerName: map['ownerName'] ?? '',
    ownerPhone: map['ownerPhone'] ?? '',
    createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
  );
}

class Offer {
  int? id;
  String type;
  String location;
  num area;
  num price;
  String ownerName;
  String ownerPhone;
  String? media;
  String? coords;
  String? note;
  int createdAt;

  Offer({
    this.id,
    required this.type,
    required this.location,
    required this.area,
    required this.price,
    required this.ownerName,
    required this.ownerPhone,
    this.media,
    this.coords,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'location': location,
    'area': area,
    'price': price,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'mediaUrl': media,
    'mapLink': coords,
    'note': note,
    'createdAt': createdAt,
  };

  factory Offer.fromMap(Map<String, dynamic> map) => Offer(
    id: map['id'],
    type: map['type'] ?? '',
    location: map['location'] ?? '',
    area: map['area'] ?? 0,
    price: map['price'] ?? 0,
    ownerName: map['ownerName'] ?? '',
    ownerPhone: map['ownerPhone'] ?? '',
    media: map['mediaUrl'],
    coords: map['mapLink'],
    note: map['note'],
    createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
  );
}

/* ======================= FIREBASE MODELS ======================= */

class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLogin': Timestamp.fromDate(lastLogin),
  };

  factory UserProfile.fromFirestore(Map<String, dynamic> data) => UserProfile(
    uid: data['uid'] ?? '',
    email: data['email'] ?? '',
    fullName: data['fullName'] ?? '',
    phoneNumber: data['phoneNumber'] ?? '',
    photoUrl: data['photoUrl'],
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class FirebaseOffer {
  final String? id;
  final String userId;
  final String type;
  final String location;
  final num area;
  final num price;
  final String ownerName;
  final String ownerPhone;
  final List<String> mediaUrls;
  final String? mapLink;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  FirebaseOffer({
    this.id,
    required this.userId,
    required this.type,
    required this.location,
    required this.area,
    required this.price,
    required this.ownerName,
    required this.ownerPhone,
    this.mediaUrls = const [],
    this.mapLink,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type,
    'location': location,
    'area': area,
    'price': price,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'mediaUrls': mediaUrls,
    'mapLink': mapLink,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'isActive': isActive,
  };

  factory FirebaseOffer.fromFirestore(Map<String, dynamic> data, String id) => FirebaseOffer(
    id: id,
    userId: data['userId'] ?? '',
    type: data['type'] ?? '',
    location: data['location'] ?? '',
    area: data['area'] ?? 0,
    price: data['price'] ?? 0,
    ownerName: data['ownerName'] ?? '',
    ownerPhone: data['ownerPhone'] ?? '',
    mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
    mapLink: data['mapLink'],
    note: data['note'],
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    isActive: data['isActive'] ?? true,
  );
}

class FirebaseRequest {
  final String? id;
  final String userId;
  final String type;
  final String location;
  final num area;
  final num price;
  final String ownerName;
  final String ownerPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  FirebaseRequest({
    this.id,
    required this.userId,
    required this.type,
    required this.location,
    required this.area,
    required this.price,
    required this.ownerName,
    required this.ownerPhone,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type,
    'location': location,
    'area': area,
    'price': price,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'isActive': isActive,
  };

  factory FirebaseRequest.fromFirestore(Map<String, dynamic> data, String id) => FirebaseRequest(
    id: id,
    userId: data['userId'] ?? '',
    type: data['type'] ?? '',
    location: data['location'] ?? '',
    area: data['area'] ?? 0,
    price: data['price'] ?? 0,
    ownerName: data['ownerName'] ?? '',
    ownerPhone: data['ownerPhone'] ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    isActive: data['isActive'] ?? true,
  );
}

/* ======================= DATABASE HELPER ======================= */

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'real_estate.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDir.path, dbName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            location TEXT NOT NULL,
            area REAL NOT NULL,
            price REAL NOT NULL,
            ownerName TEXT NOT NULL,
            ownerPhone TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE offers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            location TEXT NOT NULL,
            area REAL NOT NULL,
            price REAL NOT NULL,
            ownerName TEXT NOT NULL,
            ownerPhone TEXT NOT NULL,
            mediaUrl TEXT,
            mapLink TEXT,
            note TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  static Future<int> insertRequest(Request request) async {
    final db = await database;
    return await db.insert('requests', request.toMap());
  }

  static Future<List<Request>> getRequests() async {
    final db = await database;
    final maps = await db.query('requests', orderBy: 'createdAt DESC');
    return maps.map((map) => Request.fromMap(map)).toList();
  }

  static Future<int> updateRequest(Request request) async {
    final db = await database;
    return await db.update(
      'requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  static Future<int> deleteRequest(int id) async {
    final db = await database;
    return await db.delete('requests', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> insertOffer(Offer offer) async {
    final db = await database;
    return await db.insert('offers', offer.toMap());
  }

  static Future<List<Offer>> getOffers() async {
    final db = await database;
    final maps = await db.query('offers', orderBy: 'createdAt DESC');
    return maps.map((map) => Offer.fromMap(map)).toList();
  }

  static Future<int> updateOffer(Offer offer) async {
    final db = await database;
    return await db.update(
      'offers',
      offer.toMap(),
      where: 'id = ?',
      whereArgs: [offer.id],
    );
  }

  static Future<int> deleteOffer(int id) async {
    final db = await database;
    return await db.delete('offers', where: 'id = ?', whereArgs: [id]);
  }
}
/* ======================= FIREBASE SERVICE ======================= */

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Email Authentication
  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print('Error signing up: $e');
      throw e;
    }
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print('Error signing in: $e');
      throw e;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      throw e;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() => _auth.currentUser;

  // User Profile Management
  static Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toFirestore());
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .update(profile.toFirestore());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Offers Management
  static Future<String> createOffer(FirebaseOffer offer) async {
    try {
      final docRef = await _firestore
          .collection('offers')
          .add(offer.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating offer: $e');
      throw e;
    }
  }

  static Future<List<FirebaseOffer>> getOffers() async {
    try {
      final snapshot = await _firestore
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => 
        FirebaseOffer.fromFirestore(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error getting offers: $e');
      return [];
    }
  }

  static Future<List<FirebaseOffer>> getUserOffers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('offers')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => 
        FirebaseOffer.fromFirestore(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error getting user offers: $e');
      return [];
    }
  }

  // Requests Management
  static Future<String> createRequest(FirebaseRequest request) async {
    try {
      final docRef = await _firestore
          .collection('requests')
          .add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating request: $e');
      throw e;
    }
  }

  static Future<List<FirebaseRequest>> getRequests() async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => 
        FirebaseRequest.fromFirestore(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error getting requests: $e');
      return [];
    }
  }

  // Storage Management
  static Future<List<String>> uploadImages(List<File> images) async {
    List<String> urls = [];
    try {
      for (var image in images) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
        final ref = _storage.ref().child('offers/$fileName');
        final uploadTask = await ref.putFile(image);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } catch (e) {
      print('Error uploading images: $e');
      throw e;
    }
  }
}
  /* ======================= LOGIN SCREEN ======================= */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('saved_email', _emailController.text.trim());
        } else {
          await prefs.remove('saved_email');
        }

        final profile = await FirebaseService.getUserProfile(user.uid);
        
        if (!mounted) return;
        
        if (profile == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MyApp(startWithDark: Theme.of(context).brightness == Brightness.dark),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'حدث خطأ في تسجيل الدخول';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'لا يوجد حساب بهذا البريد الإلكتروني';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'كلمة المرور غير صحيحة';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'البريد الإلكتروني غير صالح';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BrandWatermark(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_work, size: 80, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'عقاري الذكي',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'البريد الإلكتروني غير صالح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                              ),
                              const Text('تذكرني'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('ليس لديك حساب؟'),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text('سجل الآن'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
/* ======================= REGISTER SCREEN ======================= */

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        final profile = UserProfile(
          uid: user.uid,
          email: _emailController.text.trim(),
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await FirebaseService.createUserProfile(profile);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MyApp(startWithDark: Theme.of(context).brightness == Brightness.dark),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'حدث خطأ في إنشاء الحساب';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'كلمة المرور ضعيفة جداً';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'البريد الإلكتروني غير صالح';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BrandWatermark(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_work, size: 80, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'عقاري الذكي',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال الاسم';
                          }
                          if (value.length < 3) {
                            return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'البريد الإلكتروني غير صالح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجوال',
                          hintText: '05xxxxxxxx',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال رقم الجوال';
                          }
                          if (value.length < 10) {
                            return 'رقم الجوال غير صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء تأكيد كلمة المرور';
                          }
                          if (value != _passwordController.text) {
                            return 'كلمتا المرور غير متطابقتين';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('إنشاء حساب', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('لديك حساب بالفعل؟'),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text('سجل دخول'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
/* ======================= FORGOT PASSWORD SCREEN ======================= */

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService.resetPassword(_emailController.text.trim());
      
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'حدث خطأ في إرسال رابط الاستعادة';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'لا يوجد حساب بهذا البريد الإلكتروني';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'البريد الإلكتروني غير صالح';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
      ),
      body: Stack(
        children: [
          const BrandWatermark(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _emailSent
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mark_email_read,
                            size: 80,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'تم الإرسال بنجاح!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'تم إرسال رابط استعادة كلمة المرور إلى\n${_emailController.text}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('العودة لتسجيل الدخول'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_reset,
                              size: 80,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                hintText: 'example@email.com',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال البريد الإلكتروني';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'البريد الإلكتروني غير صالح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _resetPassword,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'إرسال رابط الاستعادة',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
/* ======================= PROFILE SETUP SCREEN ======================= */

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseService.getCurrentUser();
    if (user != null) {
      final profile = await FirebaseService.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          _nameController.text = profile.fullName;
          _phoneController.text = profile.phoneNumber;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseService.getCurrentUser();
      if (user != null) {
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await FirebaseService.createUserProfile(profile);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MyApp(startWithDark: Theme.of(context).brightness == Brightness.dark),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في حفظ الملف الشخصي'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BrandWatermark(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 80, color: Colors.blue),
                      const SizedBox(height: 24),
                      const Text(
                        'إعداد الملف الشخصي',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أكمل معلوماتك للمتابعة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال الاسم';
                          }
                          if (value.length < 3) {
                            return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجوال',
                          hintText: '05xxxxxxxx',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال رقم الجوال';
                          }
                          if (value.length < 10) {
                            return 'رقم الجوال غير صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('حفظ والمتابعة', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
/* ======================= PROFILE PAGE ======================= */

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseService.getCurrentUser();
    if (user != null) {
      final profile = await FirebaseService.getUserProfile(user.uid);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut,
            tooltip: 'تسجيل خروج',
          ),
        ],
      ),
      body: Stack(
        children: [
          const BrandWatermark(),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profile == null
                  ? const Center(child: Text('لم يتم العثور على الملف الشخصي'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              _profile!.fullName.isNotEmpty 
                                  ? _profile!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: const Text('الاسم'),
                                    subtitle: Text(_profile!.fullName),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.email),
                                    title: const Text('البريد الإلكتروني'),
                                    subtitle: Text(_profile!.email),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.phone),
                                    title: const Text('رقم الجوال'),
                                    subtitle: Text(_profile!.phoneNumber),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.calendar_today),
                                    title: const Text('تاريخ التسجيل'),
                                    subtitle: Text(
                                      '${_profile!.createdAt.day}/${_profile!.createdAt.month}/${_profile!.createdAt.year}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.security, color: Colors.orange),
                                    title: const Text('تغيير كلمة المرور'),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ChangePasswordScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.edit, color: Colors.blue),
                                    title: const Text('تعديل المعلومات'),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(profile: _profile!),
                                        ),
                                      ).then((_) => _loadProfile());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }
}
/* ======================= CHANGE PASSWORD SCREEN ======================= */

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseService.getCurrentUser();
      if (user != null && user.email != null) {
        // Re-authenticate first
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'حدث خطأ في تغيير كلمة المرور';
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'كلمة المرور الحالية غير صحيحة';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'كلمة المرور الجديدة ضعيفة جداً';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: Stack(
        children: [
          const BrandWatermark(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, size: 60, color: Colors.orange),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور الحالية';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور الجديدة';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      if (value == _currentPasswordController.text) {
                        return 'كلمة المرور الجديدة يجب أن تكون مختلفة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء تأكيد كلمة المرور الجديدة';
                      }
                      if (value != _newPasswordController.text) {
                        return 'كلمتا المرور غير متطابقتين';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
/* ======================= EDIT PROFILE SCREEN ======================= */

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = UserProfile(
        uid: widget.profile.uid,
        email: widget.profile.email,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: widget.profile.photoUrl,
        createdAt: widget.profile.createdAt,
        lastLogin: DateTime.now(),
      );

      await FirebaseService.updateUserProfile(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المعلومات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في تحديث المعلومات'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: Stack(
        children: [
          const BrandWatermark(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.edit, size: 60, color: Colors.blue),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      if (value.length < 3) {
                        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال',
                      hintText: '05xxxxxxxx',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم الجوال';
                      }
                      if (value.length < 10) {
                        return 'رقم الجوال غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('البريد الإلكتروني'),
                    subtitle: Text(widget.profile.email),
                    tileColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'البريد الإلكتروني لا يمكن تغييره',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('حفظ التعديلات', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
/* ======================= BRAND COMPONENTS ======================= */

class BrandWatermark extends StatelessWidget {
  const BrandWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: Center(
          child: Transform.rotate(
            angle: -0.5,
            child: const Text(
              'عقاري\nالذكي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandNameBackground extends StatelessWidget {
  const BrandNameBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: BrandPatternPainter(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
      ),
    );
  }
}

class BrandPatternPainter extends CustomPainter {
  final Color color;
  BrandPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const text = 'عقاري';
    const fontSize = 30.0;
    const spacing = 100.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.rtl,
    );
    textPainter.layout();

    for (double y = -fontSize; y < size.height + fontSize; y += spacing) {
      for (double x = -100; x < size.width + 100; x += spacing) {
        canvas.save();
        canvas.translate(x + (y.toInt() % 2) * 50, y);
        canvas.rotate(-0.2);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
/* ======================= SPLASH SCREEN ======================= */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _controller.forward();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final user = FirebaseService.getCurrentUser();
    
    if (user != null) {
      // User is logged in, check profile
      final profile = await FirebaseService.getUserProfile(user.uid);
      
      if (!mounted) return;
      
      if (profile == null) {
        // No profile, go to profile setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        // Has profile, go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MyApp(
              startWithDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        );
      }
    } else {
      // Not logged in, go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home_work,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'عقاري الذكي',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'منصتك العقارية الموثوقة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
/* ======================= SETTINGS PAGE ======================= */

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String sigName;
  final String sigPhone;
  final Function(String, String) onSaveSignature;
  final num tolPricePct;
  final num tolPriceMinAbs;
  final num tolAreaPct;
  final Function(num, num, num) onSaveTolerance;
  final VoidCallback onOpenFilter;
  final String searchQuery;
  final Function(String) onSaveSearch;
  final VoidCallback onPerformSearch;

  const SettingsPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.sigName,
    required this.sigPhone,
    required this.onSaveSignature,
    required this.tolPricePct,
    required this.tolPriceMinAbs,
    required this.tolAreaPct,
    required this.onSaveTolerance,
    required this.onOpenFilter,
    required this.searchQuery,
    required this.onSaveSearch,
    required this.onPerformSearch,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _sigNameCtrl;
  late final TextEditingController _sigPhoneCtrl;
  late final TextEditingController _tolPricePctCtrl;
  late final TextEditingController _tolPriceMinAbsCtrl;
  late final TextEditingController _tolAreaPctCtrl;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _sigNameCtrl = TextEditingController(text: widget.sigName);
    _sigPhoneCtrl = TextEditingController(text: widget.sigPhone);
    _tolPricePctCtrl = TextEditingController(text: widget.tolPricePct.toString());
    _tolPriceMinAbsCtrl = TextEditingController(text: widget.tolPriceMinAbs.toString());
    _tolAreaPctCtrl = TextEditingController(text: widget.tolAreaPct.toString());
    _searchCtrl = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _sigNameCtrl.dispose();
    _sigPhoneCtrl.dispose();
    _tolPricePctCtrl.dispose();
    _tolPriceMinAbsCtrl.dispose();
    _tolAreaPctCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Stack(
        children: [
          const BrandNameBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('الوضع الليلي'),
                  subtitle: Text(widget.isDark ? 'مفعل' : 'غير مفعل'),
                  value: widget.isDark,
                  onChanged: (_) => widget.onToggleTheme(),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التوقيع الشخصي',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _sigNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'الاسم',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sigPhoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجوال',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          widget.onSaveSignature(
                            _sigNameCtrl.text,
                            _sigPhoneCtrl.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حفظ التوقيع')),
                          );
                        },
                        child: const Text('حفظ التوقيع'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نسب التطابق',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _tolPricePctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'نسبة السعر (%)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tolPriceMinAbsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الحد الأدنى للسعر',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tolAreaPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'نسبة المساحة (%)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          widget.onSaveTolerance(
                            num.tryParse(_tolPricePctCtrl.text) ?? 10,
                            num.tryParse(_tolPriceMinAbsCtrl.text) ?? 50000,
                            num.tryParse(_tolAreaPctCtrl.text) ?? 10,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حفظ نسب التطابق')),
                          );
                        },
                        child: const Text('حفظ النسب'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: ListTile(
                  leading: const Icon(Icons.filter_alt),
                  title: const Text('فلترة متقدمة'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onOpenFilter();
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'البحث السريع',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          labelText: 'كلمة البحث',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              widget.onSaveSearch(_searchCtrl.text);
                              Navigator.of(context).pop();
                              widget.onPerformSearch();
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          widget.onSaveSearch(value);
                          Navigator.of(context).pop();
                          widget.onPerformSearch();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ======================= MAIN FUNCTION ======================= */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const InitialApp());
}

class InitialApp extends StatelessWidget {
  const InitialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عقاري الذكي',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      themeMode: ThemeMode.system,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashScreen(),
      ),
    );
  }
}

/* ======================= MY APP ======================= */

class MyApp extends StatefulWidget {
  final bool startWithDark;
  const MyApp({super.key, this.startWithDark = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.startWithDark;
  }

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عقاري الذكي',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(
          onToggleTheme: _toggleTheme,
          isDark: _isDark,
        ),
      ),
    );
  }
}

/* ======================= LIST FILTER MODEL ======================= */

class ListFilter {
  String type = '';
  String location = '';
  num? minPrice;
  num? maxPrice;
  num? minArea;
  num? maxArea;

  void clear() {
    type = '';
    location = '';
    minPrice = null;
    maxPrice = null;
    minArea = null;
    maxArea = null;
  }

  bool matches(dynamic item) {
    if (type.isNotEmpty && !item.type.toLowerCase().contains(type.toLowerCase())) {
      return false;
    }
    if (location.isNotEmpty && !item.location.toLowerCase().contains(location.toLowerCase())) {
      return false;
    }
    if (minPrice != null && item.price < minPrice!) return false;
    if (maxPrice != null && item.price > maxPrice!) return false;
    if (minArea != null && item.area < minArea!) return false;
    if (maxArea != null && item.area > maxArea!) return false;
    return true;
  }
}
/* ======================= HOME PAGE ======================= */

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Request> _requests = [];
  List<Offer> _offers = [];
  List<Request> _filteredRequests = [];
  List<Offer> _filteredOffers = [];
  List<String> _previousLocations = [];
  
  final ListFilter _reqFilter = ListFilter();
  final ListFilter _offFilter = ListFilter();
  
  String _sigName = '';
  String _sigPhone = '';
  num _tolPricePct = 10;
  num _tolPriceMinAbs = 50000;
  num _tolAreaPct = 10;
  
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sigName = prefs.getString('sig_name') ?? '';
      _sigPhone = prefs.getString('sig_phone') ?? '';
      _tolPricePct = prefs.getDouble('tol_price_pct') ?? 10;
      _tolPriceMinAbs = prefs.getDouble('tol_price_min_abs') ?? 50000;
      _tolAreaPct = prefs.getDouble('tol_area_pct') ?? 10;
    });
  }

  Future<void> _saveSignature(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sig_name', name);
    await prefs.setString('sig_phone', phone);
    setState(() {
      _sigName = name;
      _sigPhone = phone;
    });
  }

  Future<void> _saveTolerance(num pricePct, num priceMinAbs, num areaPct) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tol_price_pct', pricePct.toDouble());
    await prefs.setDouble('tol_price_min_abs', priceMinAbs.toDouble());
    await prefs.setDouble('tol_area_pct', areaPct.toDouble());
    setState(() {
      _tolPricePct = pricePct;
      _tolPriceMinAbs = priceMinAbs;
      _tolAreaPct = areaPct;
    });
  }

  Future<void> _loadData() async {
    final requests = await DatabaseHelper.getRequests();
    final offers = await DatabaseHelper.getOffers();
    
    final locations = <String>{};
    for (final r in requests) {
      if (r.location.isNotEmpty) locations.add(r.location);
    }
    for (final o in offers) {
      if (o.location.isNotEmpty) locations.add(o.location);
    }
    
    setState(() {
      _requests = requests;
      _offers = offers;
      _previousLocations = locations.toList()..sort();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredRequests = _requests.where((r) => _reqFilter.matches(r)).toList();
    _filteredOffers = _offers.where((o) => _offFilter.matches(o)).toList();
  }

  List<Offer> _findMatchingOffers(Request request) {
    final matches = <Offer>[];
    
    for (final offer in _offers) {
      if (offer.type.toLowerCase() != request.type.toLowerCase()) continue;
      if (offer.location.toLowerCase() != request.location.toLowerCase()) continue;
      
      final priceDiff = (offer.price - request.price).abs();
      final priceTolerance = max(request.price * _tolPricePct / 100, _tolPriceMinAbs);
      if (priceDiff > priceTolerance) continue;
      
      final areaDiff = (offer.area - request.area).abs();
      final areaTolerance = request.area * _tolAreaPct / 100;
      if (areaDiff > areaTolerance) continue;
      
      matches.add(offer);
    }
    
    return matches;
  }

  List<Request> _findMatchingRequests(Offer offer) {
    final matches = <Request>[];
    
    for (final request in _requests) {
      if (request.type.toLowerCase() != offer.type.toLowerCase()) continue;
      if (request.location.toLowerCase() != offer.location.toLowerCase()) continue;
      
      final priceDiff = (request.price - offer.price).abs();
      final priceTolerance = max(offer.price * _tolPricePct / 100, _tolPriceMinAbs);
      if (priceDiff > priceTolerance) continue;
      
      final areaDiff = (request.area - offer.area).abs();
      final areaTolerance = offer.area * _tolAreaPct / 100;
      if (areaDiff > areaTolerance) continue;
      
      matches.add(request);
    }
    
    return matches;
  }

  bool _matchesSearch(String query, dynamic item) {
    if (query.isEmpty) return false;
    final q = query.toLowerCase();
    
    if (item.type.toLowerCase().contains(q)) return true;
    if (item.location.toLowerCase().contains(q)) return true;
    if (item.ownerName.toLowerCase().contains(q)) return true;
    if (item.ownerPhone.contains(q)) return true;
    if (item.price.toString().contains(q)) return true;
    if (item.area.toString().contains(q)) return true;
    
    if (item is Offer && item.note != null && item.note!.toLowerCase().contains(q)) {
      return true;
    }
    
    return false;
  }

  void _openSearchResults() {
    if (_searchCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كلمة البحث')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          home: this,
          query: _searchCtrl.text,
        ),
      ),
    );
  }

  void _openFilterDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FilterPage(
          reqFilter: _reqFilter,
          offFilter: _offFilter,
          previousLocations: _previousLocations,
          onApply: () {
            setState(() => _applyFilters());
          },
        ),
      ),
    );
  }

  Future<void> _showAddDialog({Request? req, Offer? off}) async {
    final isRequest = off == null;
    final isEdit = req != null || off != null;
    
    final typeCtrl = TextEditingController(text: req?.type ?? off?.type ?? '');
    final locationCtrl = TextEditingController(text: req?.location ?? off?.location ?? '');
    final areaCtrl = TextEditingController(text: (req?.area ?? off?.area ?? '').toString());
    final priceCtrl = TextEditingController(text: (req?.price ?? off?.price ?? '').toString());
    final nameCtrl = TextEditingController(text: req?.ownerName ?? off?.ownerName ?? _sigName);
    final phoneCtrl = TextEditingController(text: req?.ownerPhone ?? off?.ownerPhone ?? _sigPhone);
    final mediaCtrl = TextEditingController(text: off?.media ?? '');
    final coordsCtrl = TextEditingController(text: off?.coords ?? '');
    
    List<String> selectedMedia = off?.media?.split(',').map((e) => e.trim()).toList() ?? [];

    Future<void> pickMedia() async {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        selectedMedia = images.map((img) => img.path).toList();
        mediaCtrl.text = '${selectedMedia.length} ملف مختار';
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddEditDialog(
        isRequest: isRequest,
        isEdit: isEdit,
        typeController: typeCtrl,
        locationController: locationCtrl,
        areaController: areaCtrl,
        priceController: priceCtrl,
        nameController: nameCtrl,
        phoneController: phoneCtrl,
        mediaController: mediaCtrl,
        coordsController: coordsCtrl,
        previousLocations: _previousLocations,
        onPickMedia: isRequest ? null : pickMedia,
      ),
    );

    if (result == true) {
      final type = typeCtrl.text.trim();
      final location = locationCtrl.text.trim();
      final area = num.tryParse(areaCtrl.text) ?? 0;
      final price = num.tryParse(priceCtrl.text) ?? 0;
      final ownerName = nameCtrl.text.trim();
      final ownerPhone = phoneCtrl.text.trim();
      
      if (type.isEmpty || location.isEmpty || area <= 0 || price <= 0 || 
          ownerName.isEmpty || ownerPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
        );
        return;
      }

      if (isRequest) {
        final request = Request(
          id: req?.id,
          type: type,
          location: location,
          area: area,
          price: price,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          createdAt: req?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        );
        
        if (isEdit) {
          await DatabaseHelper.updateRequest(request);
        } else {
          await DatabaseHelper.insertRequest(request);
        }
      } else {
        final offer = Offer(
          id: off?.id,
          type: type,
          location: location,
          area: area,
          price: price,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          media: selectedMedia.isNotEmpty ? selectedMedia.join(',') : null,
          coords: coordsCtrl.text.trim().isNotEmpty ? coordsCtrl.text.trim() : null,
          createdAt: off?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        );
        
        if (isEdit) {
          await DatabaseHelper.updateOffer(offer);
        } else {
          await DatabaseHelper.insertOffer(offer);
        }
      }
      
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'تم التحديث بنجاح' : 'تم الإضافة بنجاح')),
      );
    }

    typeCtrl.dispose();
    locationCtrl.dispose();
    areaCtrl.dispose();
    priceCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    mediaCtrl.dispose();
    coordsCtrl.dispose();
  }

  void _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showShareDialog(String title, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 30),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ')),
                      );
                    },
                    tooltip: 'نسخ',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 30),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Share.share(text);
                    },
                    tooltip: 'مشاركة',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _shareTextForRequest(Request req) {
    return '''
🏠 *طلب عقار*
النوع: ${req.type}
الموقع: ${req.location}
المساحة: ${req.area} م²
السعر: ${req.price} ريال
المالك: ${req.ownerName}
الجوال: ${req.ownerPhone}
    ''';
  }

  String _shareTextForOffer(Offer off) {
    return '''
🏠 *عرض عقار*
النوع: ${off.type}
الموقع: ${off.location}
المساحة: ${off.area} م²
السعر: ${off.price} ريال
المالك: ${off.ownerName}
الجوال: ${off.ownerPhone}
${off.coords != null ? 'الموقع على الخريطة: ${off.coords}' : ''}
    ''';
  }

  Future<void> _exportRequestsToPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansArabicRegular();
    final boldFont = await PdfGoogleFonts.notoSansArabicBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'قائمة الطلبات',
              style: pw.TextStyle(font: boldFont, fontSize: 24),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 20),
          ..._filteredRequests.map((req) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('النوع: ${req.type}', textDirection: pw.TextDirection.rtl),
                pw.Text('الموقع: ${req.location}', textDirection: pw.TextDirection.rtl),
                pw.Text('المساحة: ${req.area} م²', textDirection: pw.TextDirection.rtl),
                pw.Text('السعر: ${req.price} ريال', textDirection: pw.TextDirection.rtl),
                pw.Text('المالك: ${req.ownerName}', textDirection: pw.TextDirection.rtl),
                pw.Text('الجوال: ${req.ownerPhone}', textDirection: pw.TextDirection.rtl),
              ],
            ),
          )),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'requests_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _exportOffersToPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansArabicRegular();
    final boldFont = await PdfGoogleFonts.notoSansArabicBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'قائمة العروض',
              style: pw.TextStyle(font: boldFont, fontSize: 24),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 20),
          ..._filteredOffers.map((off) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('النوع: ${off.type}', textDirection: pw.TextDirection.rtl),
                pw.Text('الموقع: ${off.location}', textDirection: pw.TextDirection.rtl),
                pw.Text('المساحة: ${off.area} م²', textDirection: pw.TextDirection.rtl),
                pw.Text('السعر: ${off.price} ريال', textDirection: pw.TextDirection.rtl),
                pw.Text('المالك: ${off.ownerName}', textDirection: pw.TextDirection.rtl),
                pw.Text('الجوال: ${off.ownerPhone}', textDirection: pw.TextDirection.rtl),
                if (off.coords != null)
                  pw.Text('رابط الموقع: ${off.coords}', textDirection: pw.TextDirection.rtl),
              ],
            ),
          )),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'offers_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Widget _buildRequests() {
    if (_filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add),
              label: const Text('أضف أول طلب'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final req = _filteredRequests[index];
          final matches = _findMatchingOffers(req);
          
          return Card(
            elevation: matches.isNotEmpty ? 4 : 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RequestDetailPage(request: req, home: this),
                ));
              },
              child: Container(
                decoration: matches.isNotEmpty
                    ? BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.article, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${req.type} - ${req.location}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (matches.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${matches.length} تطابق',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${req.area} م²'),
                          const SizedBox(width: 16),
                          Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${req.price} ريال'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(req.ownerName)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(req.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.call, size: 20),
                                onPressed: () => _callNumber(req.ownerPhone),
                                tooltip: 'اتصال',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showAddDialog(req: req),
                                tooltip: 'تعديل',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await DatabaseHelper.deleteRequest(req.id!);
                                    await _loadData();
                                  }
                                },
                                tooltip: 'حذف',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffers() {
    if (_filteredOffers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد عروض',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add),
              label: const Text('أضف أول عرض'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredOffers.length,
        itemBuilder: (context, index) {
          final off = _filteredOffers[index];
          final matches = _findMatchingRequests(off);
          final hasMedia = off.media != null && off.media!.isNotEmpty;
          
          List<String> mediaPaths = [];
          if (hasMedia) {
            mediaPaths = off.media!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
          
          return Card(
            elevation: matches.isNotEmpty ? 4 : 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OfferDetailPage(offer: off, home: this),
                ));
              },
              child: Container(
                decoration: matches.isNotEmpty
                    ? BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_offer, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${off.type} - ${off.location}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (matches.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${matches.length} تطابق',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      if (hasMedia && mediaPaths.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: mediaPaths.length,
                            itemBuilder: (context, i) {
                              final path = mediaPaths[i];
                              final isVideo = path.toLowerCase().endsWith('.mp4') ||
                                            path.toLowerCase().endsWith('.mov') ||
                                            path.toLowerCase().endsWith('.avi');
                              
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isVideo
                                      ? Container(
                                          color: Colors.black12,
                                          child: const Center(
                                            child: Icon(Icons.play_circle_filled, size: 30),
                                          ),
                                        )
                                      : Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, size: 30),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${off.area} م²'),
                          const SizedBox(width: 16),
                          Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${off.price} ريال'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(off.ownerName)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(off.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.call, size: 20),
                                onPressed: () => _callNumber(off.ownerPhone),
                                tooltip: 'اتصال',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showAddDialog(off: off),
                                tooltip: 'تعديل',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: const Text('هل أنت متأكد من حذف هذا العرض؟'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await DatabaseHelper.deleteOffer(off.id!);
                                    await _loadData();
                                  }
                                },
                                tooltip: 'حذف',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inDays == 0) {
      return 'اليوم ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عقاري الذكي'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: _openFilterDialog,
              tooltip: 'فلترة',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _openSearchResults,
              tooltip: 'بحث',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الطلبات', icon: Icon(Icons.article)),
              Tab(text: 'العروض', icon: Icon(Icons.local_offer)),
            ],
          ),
        ),
        drawer: Drawer(
          child: Stack(
            children: [
              const BrandNameBackground(),
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home_work, color: Colors.white, size: 50),
                        const SizedBox(height: 10),
                        const Text(
                          'عقاري الذكي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'نسخة 2.0',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('الملف الشخصي'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('بحث سريع'),
                    subtitle: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'أدخل كلمة البحث',
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        Navigator.of(context).pop();
                        _openSearchResults();
                      },
                    ),
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('تصدير الطلبات PDF'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _exportRequestsToPdf();
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('تصدير العروض PDF'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _exportOffersToPdf();
                    },
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('الإعدادات'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsPage(
                            isDark: widget.isDark,
                            onToggleTheme: widget.onToggleTheme,  // ← تم التصحيح هنا
                            sigName: _sigName,
                            sigPhone: _sigPhone,
                            onSaveSignature: _saveSignature,
                            tolPricePct: _tolPricePct,
                            tolPriceMinAbs: _tolPriceMinAbs,
                            tolAreaPct: _tolAreaPct,
                            onSaveTolerance: _saveTolerance,
                            onOpenFilter: _openFilterDialog,
                            searchQuery: _searchCtrl.text,
                            onSaveSearch: (q) => _searchCtrl.text = q,
                            onPerformSearch: _openSearchResults,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('حول التطبيق'),
                    onTap: () {
                      Navigator.of(context).pop();
                      showAboutDialog(
                        context: context,
                        applicationName: 'عقاري الذكي',
                        applicationVersion: '2.0',
                        applicationIcon: const Icon(Icons.home_work, size: 50),
                        children: const [
                          Text('تطبيق لإدارة العروض والطلبات العقارية'),
                          SizedBox(height: 8),
                          Text('مع دعم Firebase للمصادقة والتخزين السحابي'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            const BrandNameBackground(),
            TabBarView(
              children: [
                _buildRequests(),
                _buildOffers(),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(),
          tooltip: 'إضافة',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/* ======================= ADD/EDIT DIALOG ======================= */

class _AddEditDialog extends StatefulWidget {
  final bool isRequest;
  final bool isEdit;
  final TextEditingController typeController;
  final TextEditingController locationController;
  final TextEditingController areaController;
  final TextEditingController priceController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController? mediaController;
  final TextEditingController? coordsController;
  final List<String> previousLocations;
  final VoidCallback? onPickMedia;

  const _AddEditDialog({
    required this.isRequest,
    required this.isEdit,
    required this.typeController,
    required this.locationController,
    required this.areaController,
    required this.priceController,
    required this.nameController,
    required this.phoneController,
    this.mediaController,
    this.coordsController,
    required this.previousLocations,
    this.onPickMedia,
  });

  @override
  State<_AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<_AddEditDialog> {
  final _types = [
    'شقة',
    'فيلا',
    'أرض',
    'عمارة',
    'محل تجاري',
    'مكتب',
    'مستودع',
    'مزرعة',
    'استراحة',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isEdit
                      ? (widget.isRequest ? 'تعديل طلب' : 'تعديل عرض')
                      : (widget.isRequest ? 'إضافة طلب جديد' : 'إضافة عرض جديد'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: widget.typeController.text),
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return _types;
                    return _types.where((t) => t.contains(value.text));
                  },
                  onSelected: (value) => widget.typeController.text = value,
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'النوع',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) => widget.typeController.text = value,
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: widget.locationController.text),
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return widget.previousLocations;
                    return widget.previousLocations.where((l) => l.contains(value.text));
                  },
                  onSelected: (value) => widget.locationController.text = value,
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'الموقع',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) => widget.locationController.text = value,
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.areaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'المساحة (م²)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: widget.priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر (ريال)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: widget.nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المالك',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: widget.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                
                if (!widget.isRequest) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.mediaController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'الصور/الفيديوهات',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: widget.onPickMedia,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.coordsController,
                    decoration: const InputDecoration(
                      labelText: 'رابط الموقع على الخريطة (اختياري)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(widget.isEdit ? 'تحديث' : 'إضافة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/* ======================= REQUEST DETAIL PAGE ======================= */

class RequestDetailPage extends StatelessWidget {
  final Request request;
  final _HomePageState home;

  const RequestDetailPage({
    super.key,
    required this.request,
    required this.home,
  });

  @override
  Widget build(BuildContext context) {
    final matches = home._findMatchingOffers(request);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              home._showShareDialog('مشاركة الطلب', home._shareTextForRequest(request));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const BrandNameBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailCard(
                  title: 'معلومات العقار',
                  icon: Icons.home,
                  children: [
                    _DetailRow('النوع', request.type),
                    _DetailRow('الموقع', request.location),
                    _DetailRow('المساحة', '${request.area} م²'),
                    _DetailRow('السعر', '${request.price} ريال'),
                  ],
                ),
                const SizedBox(height: 16),
                
                _DetailCard(
                  title: 'معلومات المالك',
                  icon: Icons.person,
                  children: [
                    _DetailRow('الاسم', request.ownerName),
                    _DetailRow('الجوال', request.ownerPhone),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => home._callNumber(request.ownerPhone),
                          icon: const Icon(Icons.call),
                          label: const Text('اتصال'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://wa.me/${request.ownerPhone}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('واتساب'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (matches.isNotEmpty) ...[
                  _DetailCard(
                    title: 'العروض المطابقة (${matches.length})',
                    icon: Icons.local_offer,
                    iconColor: Colors.green,
                    children: [
                      ...matches.map((offer) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${offer.type} - ${offer.location}'),
                          subtitle: Text(
                            '${offer.area} م² - ${offer.price} ريال\n${offer.ownerName}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => OfferDetailPage(offer: offer, home: home),
                              ));
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => OfferDetailPage(offer: offer, home: home),
                            ));
                          },
                        ),
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= OFFER DETAIL PAGE ======================= */

class OfferDetailPage extends StatefulWidget {
  final Offer offer;
  final _HomePageState home;

  const OfferDetailPage({
    super.key,
    required this.offer,
    required this.home,
  });

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  @override
  Widget build(BuildContext context) {
    final matches = widget.home._findMatchingRequests(widget.offer);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العرض'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              widget.home._showShareDialog('مشاركة العرض', widget.home._shareTextForOffer(widget.offer));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const BrandNameBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.offer.media != null && widget.offer.media!.isNotEmpty)
                  _MediaSection(mediaString: widget.offer.media!),
                
                _DetailCard(
                  title: 'معلومات العقار',
                  icon: Icons.home,
                  children: [
                    _DetailRow('النوع', widget.offer.type),
                    _DetailRow('الموقع', widget.offer.location),
                    _DetailRow('المساحة', '${widget.offer.area} م²'),
                    _DetailRow('السعر', '${widget.offer.price} ريال'),
                    if (widget.offer.note != null && widget.offer.note!.isNotEmpty)
                      _DetailRow('ملاحظات', widget.offer.note!),
                  ],
                ),
                const SizedBox(height: 16),
                
                _DetailCard(
                  title: 'معلومات المالك',
                  icon: Icons.person,
                  children: [
                    _DetailRow('الاسم', widget.offer.ownerName),
                    _DetailRow('الجوال', widget.offer.ownerPhone),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => widget.home._callNumber(widget.offer.ownerPhone),
                          icon: const Icon(Icons.call),
                          label: const Text('اتصال'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://wa.me/${widget.offer.ownerPhone}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('واتساب'),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (widget.offer.coords != null && widget.offer.coords!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailCard(
                    title: 'الموقع على الخريطة',
                    icon: Icons.map,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(widget.offer.coords!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('فتح الموقع'),
                      ),
                    ],
                  ),
                ],
                
                if (matches.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailCard(
                    title: 'الطلبات المطابقة (${matches.length})',
                    icon: Icons.article,
                    iconColor: Colors.green,
                    children: [
                      ...matches.map((req) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${req.type} - ${req.location}'),
                          subtitle: Text(
                            '${req.area} م² - ${req.price} ريال\n${req.ownerName}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => RequestDetailPage(request: req, home: widget.home),
                              ));
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => RequestDetailPage(request: req, home: widget.home),
                            ));
                          },
                        ),
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= DETAIL COMPONENTS ======================= */

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '$label:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MediaSection extends StatefulWidget {
  final String mediaString;
  const _MediaSection({required this.mediaString});

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<String> mediaPaths;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    mediaPaths = widget.mediaString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.avi');
  }

  void _openFullscreen(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: _isVideo(path)
                ? const Icon(Icons.play_circle_filled, size: 100, color: Colors.white)
                : InteractiveViewer(
                    child: Image.file(File(path)),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mediaPaths.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: mediaPaths.length,
              itemBuilder: (context, index) {
                final path = mediaPaths[index];
                return GestureDetector(
                  onTap: () => _openFullscreen(path),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _isVideo(path)
                          ? Container(
                              color: Colors.black12,
                              child: const Center(
                                child: Icon(Icons.play_circle_filled, size: 60),
                              ),
                            )
                          : Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (mediaPaths.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  mediaPaths.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ======================= FILTER PAGE ======================= */

class FilterPage extends StatefulWidget {
  final ListFilter reqFilter;
  final ListFilter offFilter;
  final List<String> previousLocations;
  final VoidCallback onApply;

  const FilterPage({
    super.key,
    required this.reqFilter,
    required this.offFilter,
    required this.previousLocations,
    required this.onApply,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late TextEditingController _reqTypeCtrl;
  late TextEditingController _reqLocationCtrl;
  late TextEditingController _reqMinPriceCtrl;
  late TextEditingController _reqMaxPriceCtrl;
  late TextEditingController _reqMinAreaCtrl;
  late TextEditingController _reqMaxAreaCtrl;
  
  late TextEditingController _offTypeCtrl;
  late TextEditingController _offLocationCtrl;
  late TextEditingController _offMinPriceCtrl;
  late TextEditingController _offMaxPriceCtrl;
  late TextEditingController _offMinAreaCtrl;
  late TextEditingController _offMaxAreaCtrl;

  @override
  void initState() {
    super.initState();
    _reqTypeCtrl = TextEditingController(text: widget.reqFilter.type);
    _reqLocationCtrl = TextEditingController(text: widget.reqFilter.location);
    _reqMinPriceCtrl = TextEditingController(text: widget.reqFilter.minPrice?.toString() ?? '');
    _reqMaxPriceCtrl = TextEditingController(text: widget.reqFilter.maxPrice?.toString() ?? '');
    _reqMinAreaCtrl = TextEditingController(text: widget.reqFilter.minArea?.toString() ?? '');
    _reqMaxAreaCtrl = TextEditingController(text: widget.reqFilter.maxArea?.toString() ?? '');
    
    _offTypeCtrl = TextEditingController(text: widget.offFilter.type);
    _offLocationCtrl = TextEditingController(text: widget.offFilter.location);
    _offMinPriceCtrl = TextEditingController(text: widget.offFilter.minPrice?.toString() ?? '');
    _offMaxPriceCtrl = TextEditingController(text: widget.offFilter.maxPrice?.toString() ?? '');
    _offMinAreaCtrl = TextEditingController(text: widget.offFilter.minArea?.toString() ?? '');
    _offMaxAreaCtrl = TextEditingController(text: widget.offFilter.maxArea?.toString() ?? '');
  }

  void _applyFilters() {
    widget.reqFilter.type = _reqTypeCtrl.text;
    widget.reqFilter.location = _reqLocationCtrl.text;
    widget.reqFilter.minPrice = num.tryParse(_reqMinPriceCtrl.text);
    widget.reqFilter.maxPrice = num.tryParse(_reqMaxPriceCtrl.text);
    widget.reqFilter.minArea = num.tryParse(_reqMinAreaCtrl.text);
    widget.reqFilter.maxArea = num.tryParse(_reqMaxAreaCtrl.text);
    
    widget.offFilter.type = _offTypeCtrl.text;
    widget.offFilter.location = _offLocationCtrl.text;
    widget.offFilter.minPrice = num.tryParse(_offMinPriceCtrl.text);
    widget.offFilter.maxPrice = num.tryParse(_offMaxPriceCtrl.text);
    widget.offFilter.minArea = num.tryParse(_offMinAreaCtrl.text);
    widget.offFilter.maxArea = num.tryParse(_offMaxAreaCtrl.text);
    
    widget.onApply();
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _reqTypeCtrl.clear();
      _reqLocationCtrl.clear();
      _reqMinPriceCtrl.clear();
      _reqMaxPriceCtrl.clear();
      _reqMinAreaCtrl.clear();
      _reqMaxAreaCtrl.clear();
      
      _offTypeCtrl.clear();
      _offLocationCtrl.clear();
      _offMinPriceCtrl.clear();
      _offMaxPriceCtrl.clear();
      _offMinAreaCtrl.clear();
      _offMaxAreaCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('فلترة القوائم'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'فلترة الطلبات'),
              Tab(text: 'فلترة العروض'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFilterForm(_reqTypeCtrl, _reqLocationCtrl, _reqMinPriceCtrl,
                _reqMaxPriceCtrl, _reqMinAreaCtrl, _reqMaxAreaCtrl),
            _buildFilterForm(_offTypeCtrl, _offLocationCtrl, _offMinPriceCtrl,
                _offMaxPriceCtrl, _offMinAreaCtrl, _offMaxAreaCtrl),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('مسح الكل'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterForm(
    TextEditingController typeCtrl,
    TextEditingController locationCtrl,
    TextEditingController minPriceCtrl,
    TextEditingController maxPriceCtrl,
    TextEditingController minAreaCtrl,
    TextEditingController maxAreaCtrl,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: typeCtrl,
            decoration: const InputDecoration(
              labelText: 'النوع',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          Autocomplete<String>(
            initialValue: TextEditingValue(text: locationCtrl.text),
            optionsBuilder: (value) {
              if (value.text.isEmpty) return widget.previousLocations;
              return widget.previousLocations.where((l) => l.contains(value.text));
            },
            onSelected: (value) => locationCtrl.text = value,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => locationCtrl.text = value,
              );
            },
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر الأدنى',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر الأعلى',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minAreaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المساحة الأدنى',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxAreaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المساحة الأعلى',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reqTypeCtrl.dispose();
    _reqLocationCtrl.dispose();
    _reqMinPriceCtrl.dispose();
    _reqMaxPriceCtrl.dispose();
    _reqMinAreaCtrl.dispose();
    _reqMaxAreaCtrl.dispose();
    _offTypeCtrl.dispose();
    _offLocationCtrl.dispose();
    _offMinPriceCtrl.dispose();
    _offMaxPriceCtrl.dispose();
    _offMinAreaCtrl.dispose();
    _offMaxAreaCtrl.dispose();
    super.dispose();
  }
}

/* ======================= SEARCH RESULTS PAGE ======================= */

class SearchResultsPage extends StatelessWidget {
  final _HomePageState home;
  final String query;

  const SearchResultsPage({
    super.key,
    required this.home,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final matchingRequests = home._requests
        .where((r) => home._matchesSearch(query, r))
        .toList();
    final matchingOffers = home._offers
        .where((o) => home._matchesSearch(query, o))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('نتائج البحث: $query'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'طلبات (${matchingRequests.length})'),
              Tab(text: 'عروض (${matchingOffers.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            matchingRequests.isEmpty
                ? const Center(child: Text('لا توجد طلبات مطابقة'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: matchingRequests.length,
                    itemBuilder: (context, index) {
                      final req = matchingRequests[index];
                      return Card(
                        child: ListTile(
                          title: Text('${req.type} - ${req.location}'),
                          subtitle: Text('${req.area} م² - ${req.price} ريال'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => RequestDetailPage(request: req, home: home),
                            ));
                          },
                        ),
                      );
                    },
                  ),
            matchingOffers.isEmpty
                ? const Center(child: Text('لا توجد عروض مطابقة'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: matchingOffers.length,
                    itemBuilder: (context, index) {
                      final off = matchingOffers[index];
                      final hasMedia = off.media != null && off.media!.isNotEmpty;
                      
                      String? firstImage;
                      if (hasMedia) {
                        final paths = off.media!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                        if (paths.isNotEmpty) {
                          firstImage = paths.firstWhere(
                            (p) => !p.toLowerCase().endsWith('.mp4') && !p.toLowerCase().endsWith('.mov'),
                            orElse: () => paths.first,
                          );
                        }
                      }
                      
                      return Card(
                        child: ListTile(
                          leading: hasMedia && firstImage != null
                              ? Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      File(firstImage),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  ),
                                )
                              : null,
                          title: Text('${off.type} - ${off.location}'),
                          subtitle: Text('${off.area} م² - ${off.price} ريال'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => OfferDetailPage(offer: off, home: home),
                            ));
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
