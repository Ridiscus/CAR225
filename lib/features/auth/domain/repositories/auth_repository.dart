abstract class AuthRepository {
  // On retourne un Either (Garde ça simple pour l'instant : Future<void>)
  Future<void> login(String email, String password);
}






