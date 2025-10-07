// controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/storage_service.dart';

class AuthController extends GetxController {
  final StorageService storageService = Get.find();
  final ApiService apiService = Get.find<ApiService>();

  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  void checkAuthStatus() {
    isLoggedIn.value = storageService.isLoggedIn;
  }

  Future<bool> login(String username, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authResponse = await apiService.login(username, password);
      isLoggedIn.value = true;

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await apiService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      isLoggedIn.value = false;
      Get.offAllNamed('/auth');
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
