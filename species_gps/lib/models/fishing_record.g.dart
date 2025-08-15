// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fishing_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFishingRecordCollection on Isar {
  IsarCollection<FishingRecord> get fishingRecords => this.collection();
}

const FishingRecordSchema = CollectionSchema(
  name: r'FishingRecord',
  id: 1234567890,
  properties: {
    r'accuracy': PropertySchema(
      id: 0,
      name: r'accuracy',
      type: IsarType.double,
    ),
    r'audioPath': PropertySchema(
      id: 1,
      name: r'audioPath',
      type: IsarType.string,
    ),
    r'count': PropertySchema(
      id: 2,
      name: r'count',
      type: IsarType.long,
    ),
    r'latitude': PropertySchema(
      id: 3,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'location': PropertySchema(
      id: 4,
      name: r'location',
      type: IsarType.string,
    ),
    r'longitude': PropertySchema(
      id: 5,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'notes': PropertySchema(
      id: 6,
      name: r'notes',
      type: IsarType.string,
    ),
    r'photoPath': PropertySchema(
      id: 7,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'species': PropertySchema(
      id: 8,
      name: r'species',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 9,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _fishingRecordEstimateSize,
  serialize: _fishingRecordSerialize,
  deserialize: _fishingRecordDeserialize,
  deserializeProp: _fishingRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'timestamp': IndexSchema(
      id: 1234567891,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _fishingRecordGetId,
  getLinks: _fishingRecordGetLinks,
  attach: _fishingRecordAttach,
  version: '3.1.0',
);

int _fishingRecordEstimateSize(
  FishingRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.audioPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.location.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.species.length * 3;
  return bytesCount;
}

void _fishingRecordSerialize(
  FishingRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.accuracy);
  writer.writeString(offsets[1], object.audioPath);
  writer.writeLong(offsets[2], object.count);
  writer.writeDouble(offsets[3], object.latitude);
  writer.writeString(offsets[4], object.location);
  writer.writeDouble(offsets[5], object.longitude);
  writer.writeString(offsets[6], object.notes);
  writer.writeString(offsets[7], object.photoPath);
  writer.writeString(offsets[8], object.species);
  writer.writeDateTime(offsets[9], object.timestamp);
}

FishingRecord _fishingRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FishingRecord(
    accuracy: reader.readDoubleOrNull(offsets[0]),
    audioPath: reader.readStringOrNull(offsets[1]),
    category: MarineCategory.fish, // 임시 기본값
    count: reader.readLong(offsets[2]),
    id: id,
    latitude: reader.readDouble(offsets[3]),
    longitude: reader.readDouble(offsets[5]),
    notes: reader.readStringOrNull(offsets[6]),
    photoPath: reader.readStringOrNull(offsets[7]),
    species: reader.readString(offsets[8]),
    timestamp: reader.readDateTime(offsets[9]),
  );
  return object;
}

P _fishingRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _fishingRecordGetId(FishingRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _fishingRecordGetLinks(FishingRecord object) {
  return [];
}

void _fishingRecordAttach(
    IsarCollection<dynamic> col, Id id, FishingRecord object) {
  object.id = id;
}

extension FishingRecordQueryWhereSort
    on QueryBuilder<FishingRecord, FishingRecord, QWhere> {
  QueryBuilder<FishingRecord, FishingRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension FishingRecordQueryWhere
    on QueryBuilder<FishingRecord, FishingRecord, QWhereClause> {
  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FishingRecordQueryFilter
    on QueryBuilder<FishingRecord, FishingRecord, QFilterCondition> {
  QueryBuilder<FishingRecord, FishingRecord, QAfterFilterCondition>
      accuracyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accuracy',
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterFilterCondition>
      accuracyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accuracy',
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterFilterCondition>
      accuracyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterFilterCondition>
      accuracyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterFilterCondition>
      accuracyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterFilterCondition>
      accuracyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accuracy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension FishingRecordQueryObject
    on QueryBuilder<FishingRecord, FishingRecord, QFilterCondition> {}

extension FishingRecordQueryLinks
    on QueryBuilder<FishingRecord, FishingRecord, QFilterCondition> {}

extension FishingRecordQuerySortBy
    on QueryBuilder<FishingRecord, FishingRecord, QSortBy> {
  QueryBuilder<FishingRecord, FishingRecord, QAfterSortBy> sortByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.asc);
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterSortBy>
      sortByAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.desc);
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension FishingRecordQuerySortThenBy
    on QueryBuilder<FishingRecord, FishingRecord, QSortThenBy> {
  QueryBuilder<FishingRecord, FishingRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FishingRecord, FishingRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension FishingRecordQueryWhereDistinct
    on QueryBuilder<FishingRecord, FishingRecord, QDistinct> {
  QueryBuilder<FishingRecord, FishingRecord, QDistinct> distinctByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuracy');
    });
  }
}

extension FishingRecordQueryProperty
    on QueryBuilder<FishingRecord, FishingRecord, QQueryProperty> {
  QueryBuilder<FishingRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FishingRecord, double?, QQueryOperations> accuracyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuracy');
    });
  }

  QueryBuilder<FishingRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}