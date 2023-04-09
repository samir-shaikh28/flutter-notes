// Login Exception
class UserNotFoundException implements Exception {}

class WrongPasswordAuthException implements Exception {}

// Register Exception
class WeakPasswordException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

// Generic Exception
class GenericAuthException implements Exception {}

class UserNotLoggedInAuthException implements Exception {}
