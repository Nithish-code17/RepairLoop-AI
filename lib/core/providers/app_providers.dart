import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/admin/data/admin_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/profile_repository.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/diagnosis/data/diagnosis_image_repository.dart';
import '../../features/diagnosis/data/firebase_ai_diagnosis_service.dart';
import '../../features/diagnosis/data/firebase_ai_logic_diagnosis_provider.dart';
import '../../features/diagnosis/data/diagnosis_service.dart';
import '../../features/diagnosis/data/multimodal_diagnosis_provider.dart';
import '../../features/diagnosis/domain/diagnosis.dart';
import '../../features/lifecycle/data/lifecycle_repository.dart';
import '../../features/lifecycle/domain/lifecycle_event.dart';
import '../../features/products/data/firestore_product_repository.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/products/domain/product.dart';
import '../../features/products/domain/product_component.dart';
import '../../features/repairs/data/firestore_repair_repository.dart';
import '../../features/repairs/data/repair_repository.dart';
import '../../features/repairs/domain/repair_case.dart';
import '../config/app_config.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: 'asia-south1'),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    ref.watch(firestoreProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(firestoreProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => FirestoreProductRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final multimodalDiagnosisProvider = Provider<MultimodalDiagnosisProvider>(
  (ref) => FirebaseAiLogicDiagnosisProvider(),
);

final diagnosisServiceProvider = Provider<DiagnosisService>(
  (ref) => FirebaseAiDiagnosisService(
    ref.watch(firestoreProvider),
    FirebaseAuth.instance,
    ref.watch(multimodalDiagnosisProvider),
  ),
);

final diagnosisImageRepositoryProvider = Provider<DiagnosisImageRepository>(
  (ref) => DiagnosisImageRepository(FirebaseStorage.instance),
);

final repairRepositoryProvider = Provider<RepairRepository>(
  (ref) => FirestoreRepairRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final lifecycleRepositoryProvider = Provider<LifecycleRepository>(
  (ref) => LifecycleRepository(ref.watch(firestoreProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final authUserProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(appConfigProvider).firebaseReady) {
    return Stream.value(null);
  }
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentProfileProvider = StreamProvider<AppUser?>((ref) async* {
  final firebaseUser = await ref.watch(authUserProvider.future);
  if (firebaseUser == null) {
    yield null;
    return;
  }
  yield* ref.watch(profileRepositoryProvider).watchProfile(firebaseUser.uid);
});

final productsProvider = StreamProvider<List<Product>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(productRepositoryProvider).watchProducts(profile);
});

final productProvider = StreamProvider.family<Product?, String>(
  (ref, productId) =>
      ref.watch(productRepositoryProvider).watchProduct(productId),
);

final componentsProvider =
    StreamProvider.family<List<ProductComponent>, String>(
  (ref, productId) =>
      ref.watch(productRepositoryProvider).watchComponents(productId),
);

final diagnosesProvider = StreamProvider.family<List<Diagnosis>, String>(
  (ref, productId) =>
      ref.watch(diagnosisServiceProvider).watchForProduct(productId),
);

final repairsProvider = StreamProvider<List<RepairCase>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(repairRepositoryProvider).watchRepairs(profile);
});

final productRepairsProvider = StreamProvider.family<List<RepairCase>, String>(
  (ref, productId) =>
      ref.watch(repairRepositoryProvider).watchForProduct(productId),
);

final lifecycleProvider = StreamProvider.family<List<LifecycleEvent>, String>(
  (ref, productId) =>
      ref.watch(lifecycleRepositoryProvider).watchForProduct(productId),
);

final adminUsersProvider = StreamProvider<List<AppUser>>(
  (ref) => ref.watch(adminRepositoryProvider).watchUsers(),
);
