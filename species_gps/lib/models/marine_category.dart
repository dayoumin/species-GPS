/// 해양 수산생명자원 분류군
enum MarineCategory {
  fish('어류'),           // 고등어, 갈치, 전어 등
  mollusk('패류'),         // 굴, 전복, 홍합, 바지락 등
  cephalopod('두족류'),    // 오징어, 문어, 낙지 등
  crustacean('갑각류'),    // 게, 새우, 랍스터 등
  echinoderm('극피동물'),   // 성게, 해삼, 불가사리 등
  seaweed('해조류'),       // 김, 미역, 다시마 등
  other('기타');           // 해파리, 멍게 등

  final String korean;
  const MarineCategory(this.korean);

  /// 한글 이름으로 enum 값 찾기
  static MarineCategory fromKorean(String korean) {
    return MarineCategory.values.firstWhere(
      (category) => category.korean == korean,
      orElse: () => MarineCategory.other,
    );
  }

  /// Isar 저장용 인덱스 값 (enum의 기본 index와 충돌 방지)
  int get dbIndex => MarineCategory.values.indexOf(this);

  /// 인덱스로 enum 값 가져오기
  static MarineCategory fromIndex(int index) {
    if (index < 0 || index >= MarineCategory.values.length) {
      return MarineCategory.other;
    }
    return MarineCategory.values[index];
  }
}

/// 분류군별 예시 종
class CategoryExamples {
  static const Map<MarineCategory, List<String>> examples = {
    MarineCategory.fish: ['고등어', '갈치', '전어', '조기', '명태', '참치', '방어'],
    MarineCategory.mollusk: ['굴', '전복', '홍합', '바지락', '꼬막', '가리비', '소라'],
    MarineCategory.cephalopod: ['오징어', '문어', '낙지', '주꾸미', '갑오징어'],
    MarineCategory.crustacean: ['대게', '꽃게', '새우', '랍스터', '가재', '대하'],
    MarineCategory.echinoderm: ['성게', '해삼', '불가사리'],
    MarineCategory.seaweed: ['김', '미역', '다시마', '톳', '파래', '매생이'],
    MarineCategory.other: ['해파리', '멍게', '미정'],
  };

  /// 종명이 속한 분류군 추측 (자동 완성용)
  static MarineCategory? guessCategory(String species) {
    for (final entry in examples.entries) {
      if (entry.value.contains(species)) {
        return entry.key;
      }
    }
    return null;
  }
}