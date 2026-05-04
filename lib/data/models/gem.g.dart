// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gem.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAcornCollection on Isar {
  IsarCollection<Acorn> get acorns => this.collection();
}

const AcornSchema = CollectionSchema(
  name: r'Acorn',
  id: 4379096634282038632,
  properties: {
    r'agentModeDefault': PropertySchema(
      id: 0,
      name: r'agentModeDefault',
      type: IsarType.bool,
    ),
    r'color': PropertySchema(
      id: 1,
      name: r'color',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'icon': PropertySchema(
      id: 3,
      name: r'icon',
      type: IsarType.string,
    ),
    r'isDefault': PropertySchema(
      id: 4,
      name: r'isDefault',
      type: IsarType.bool,
    ),
    r'maxTokens': PropertySchema(
      id: 5,
      name: r'maxTokens',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'ragEnabled': PropertySchema(
      id: 7,
      name: r'ragEnabled',
      type: IsarType.bool,
    ),
    r'syncVersion': PropertySchema(
      id: 8,
      name: r'syncVersion',
      type: IsarType.long,
    ),
    r'systemPrompt': PropertySchema(
      id: 9,
      name: r'systemPrompt',
      type: IsarType.string,
    ),
    r'temperature': PropertySchema(
      id: 10,
      name: r'temperature',
      type: IsarType.double,
    ),
    r'topK': PropertySchema(
      id: 11,
      name: r'topK',
      type: IsarType.long,
    ),
    r'topP': PropertySchema(
      id: 12,
      name: r'topP',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 14,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _acornEstimateSize,
  serialize: _acornSerialize,
  deserialize: _acornDeserialize,
  deserializeProp: _acornDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _acornGetId,
  getLinks: _acornGetLinks,
  attach: _acornAttach,
  version: '3.1.0+1',
);

int _acornEstimateSize(
  Acorn object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.color.length * 3;
  bytesCount += 3 + object.icon.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.systemPrompt.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _acornSerialize(
  Acorn object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.agentModeDefault);
  writer.writeString(offsets[1], object.color);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.icon);
  writer.writeBool(offsets[4], object.isDefault);
  writer.writeLong(offsets[5], object.maxTokens);
  writer.writeString(offsets[6], object.name);
  writer.writeBool(offsets[7], object.ragEnabled);
  writer.writeLong(offsets[8], object.syncVersion);
  writer.writeString(offsets[9], object.systemPrompt);
  writer.writeDouble(offsets[10], object.temperature);
  writer.writeLong(offsets[11], object.topK);
  writer.writeDouble(offsets[12], object.topP);
  writer.writeDateTime(offsets[13], object.updatedAt);
  writer.writeString(offsets[14], object.uuid);
}

Acorn _acornDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Acorn();
  object.agentModeDefault = reader.readBool(offsets[0]);
  object.color = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.icon = reader.readString(offsets[3]);
  object.id = id;
  object.isDefault = reader.readBool(offsets[4]);
  object.maxTokens = reader.readLongOrNull(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.ragEnabled = reader.readBool(offsets[7]);
  object.syncVersion = reader.readLong(offsets[8]);
  object.systemPrompt = reader.readString(offsets[9]);
  object.temperature = reader.readDoubleOrNull(offsets[10]);
  object.topK = reader.readLongOrNull(offsets[11]);
  object.topP = reader.readDoubleOrNull(offsets[12]);
  object.updatedAt = reader.readDateTime(offsets[13]);
  object.uuid = reader.readString(offsets[14]);
  return object;
}

P _acornDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _acornGetId(Acorn object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _acornGetLinks(Acorn object) {
  return [];
}

void _acornAttach(IsarCollection<dynamic> col, Id id, Acorn object) {
  object.id = id;
}

extension AcornByIndex on IsarCollection<Acorn> {
  Future<Acorn?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Acorn? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Acorn?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Acorn?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(Acorn object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Acorn object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Acorn> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Acorn> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension AcornQueryWhereSort on QueryBuilder<Acorn, Acorn, QWhere> {
  QueryBuilder<Acorn, Acorn, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AcornQueryWhere on QueryBuilder<Acorn, Acorn, QWhereClause> {
  QueryBuilder<Acorn, Acorn, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Acorn, Acorn, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterWhereClause> idBetween(
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

  QueryBuilder<Acorn, Acorn, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterWhereClause> uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AcornQueryFilter on QueryBuilder<Acorn, Acorn, QFilterCondition> {
  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> agentModeDefaultEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'agentModeDefault',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'color',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'color',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> colorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'color',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'icon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'icon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> iconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> isDefaultEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDefault',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> maxTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maxTokens',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> maxTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maxTokens',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> maxTokensEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> maxTokensGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> maxTokensLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> maxTokensBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxTokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> ragEnabledEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ragEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> syncVersionEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> syncVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> syncVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> syncVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'systemPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'systemPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'systemPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'systemPrompt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'systemPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'systemPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'systemPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'systemPrompt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'systemPrompt',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> systemPromptIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'systemPrompt',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> temperatureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'temperature',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> temperatureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'temperature',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> temperatureEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'temperature',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> temperatureGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'temperature',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> temperatureLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'temperature',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> temperatureBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'temperature',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topKIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topK',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topKIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topK',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topKEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topK',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topKGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topK',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topKLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topK',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topKBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topK',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topPIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topP',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topPIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topP',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topPEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topP',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topPGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topP',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topPLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topP',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> topPBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topP',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension AcornQueryObject on QueryBuilder<Acorn, Acorn, QFilterCondition> {}

extension AcornQueryLinks on QueryBuilder<Acorn, Acorn, QFilterCondition> {}

extension AcornQuerySortBy on QueryBuilder<Acorn, Acorn, QSortBy> {
  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByAgentModeDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentModeDefault', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByAgentModeDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentModeDefault', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByMaxTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxTokens', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByMaxTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxTokens', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByRagEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragEnabled', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByRagEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragEnabled', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortBySyncVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortBySyncVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortBySystemPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemPrompt', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortBySystemPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemPrompt', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByTemperature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'temperature', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByTemperatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'temperature', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByTopK() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topK', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByTopKDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topK', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByTopP() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topP', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByTopPDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topP', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension AcornQuerySortThenBy on QueryBuilder<Acorn, Acorn, QSortThenBy> {
  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByAgentModeDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentModeDefault', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByAgentModeDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentModeDefault', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByMaxTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxTokens', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByMaxTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxTokens', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByRagEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragEnabled', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByRagEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragEnabled', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenBySyncVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenBySyncVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenBySystemPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemPrompt', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenBySystemPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemPrompt', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByTemperature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'temperature', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByTemperatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'temperature', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByTopK() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topK', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByTopKDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topK', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByTopP() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topP', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByTopPDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topP', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Acorn, Acorn, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension AcornQueryWhereDistinct on QueryBuilder<Acorn, Acorn, QDistinct> {
  QueryBuilder<Acorn, Acorn, QDistinct> distinctByAgentModeDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'agentModeDefault');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByColor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'color', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByIcon(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icon', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDefault');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByMaxTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxTokens');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByRagEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ragEnabled');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctBySyncVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncVersion');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctBySystemPrompt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'systemPrompt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByTemperature() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'temperature');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByTopK() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topK');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByTopP() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topP');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Acorn, Acorn, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension AcornQueryProperty on QueryBuilder<Acorn, Acorn, QQueryProperty> {
  QueryBuilder<Acorn, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Acorn, bool, QQueryOperations> agentModeDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'agentModeDefault');
    });
  }

  QueryBuilder<Acorn, String, QQueryOperations> colorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'color');
    });
  }

  QueryBuilder<Acorn, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Acorn, String, QQueryOperations> iconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icon');
    });
  }

  QueryBuilder<Acorn, bool, QQueryOperations> isDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDefault');
    });
  }

  QueryBuilder<Acorn, int?, QQueryOperations> maxTokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxTokens');
    });
  }

  QueryBuilder<Acorn, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Acorn, bool, QQueryOperations> ragEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ragEnabled');
    });
  }

  QueryBuilder<Acorn, int, QQueryOperations> syncVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncVersion');
    });
  }

  QueryBuilder<Acorn, String, QQueryOperations> systemPromptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'systemPrompt');
    });
  }

  QueryBuilder<Acorn, double?, QQueryOperations> temperatureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'temperature');
    });
  }

  QueryBuilder<Acorn, int?, QQueryOperations> topKProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topK');
    });
  }

  QueryBuilder<Acorn, double?, QQueryOperations> topPProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topP');
    });
  }

  QueryBuilder<Acorn, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Acorn, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
