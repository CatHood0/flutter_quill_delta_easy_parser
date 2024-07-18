bool mapEquality(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
  if(map1 == null || map2 == null) return false;
  // Check if both maps have the same keys
  if (map1.keys.toSet().difference(map2.keys.toSet()).isNotEmpty ||
      map2.keys.toSet().difference(map1.keys.toSet()).isNotEmpty) {
    return false;
  }

  // Check if all key-value pairs are equal
  for (var key in map1.keys) {
    var value1 = map1[key];
    var value2 = map2[key];

    if (value1 is Map<String, dynamic> && value2 is Map<String, dynamic>) {
      // Recursively check nested maps
      if (!mapEquality(value1, value2)) {
        return false;
      }
    } else if (value1 != value2) {
      // Compare values directly
      return false;
    }
  }

  return true;
}
