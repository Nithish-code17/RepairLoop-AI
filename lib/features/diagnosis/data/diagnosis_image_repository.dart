import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class DiagnosisImageRepository {
  DiagnosisImageRepository(this._storage);

  final FirebaseStorage _storage;

  Future<String> upload({
    required String userId,
    required XFile image,
  }) async {
    final extension = image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final path = 'diagnosis-images/$userId/${const Uuid().v4()}.$extension';
    final reference = _storage.ref(path);
    await reference.putData(
      await image.readAsBytes(),
      SettableMetadata(
        contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
      ),
    );
    return path;
  }
}
