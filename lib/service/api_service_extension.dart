// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:urchat_back_testing/model/user.dart';
// import 'package:urchat_back_testing/service/api_service.dart';

// extension ApiServiceExtension on ApiService {
//   static Future<User> getUserProfile(String username) async {
//     final response = await http.get(
//       Uri.parse('$ApiService.baseUrl/users/$username'),
//       headers: ApiService.headers,
//     );

//     if (response.statusCode == 200) {
//       return User.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load user profile');
//     }
//   }
// }
