// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, ExerciseEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaPathMeta =
      const VerificationMeta('mediaPath');
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
      'media_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyPartMeta =
      const VerificationMeta('bodyPart');
  @override
  late final GeneratedColumn<String> bodyPart = GeneratedColumn<String>(
      'body_part', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _equipmentMeta =
      const VerificationMeta('equipment');
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
      'equipment', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _loggingTypeMeta =
      const VerificationMeta('loggingType');
  @override
  late final GeneratedColumn<String> loggingType = GeneratedColumn<String>(
      'logging_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _movementPatternMeta =
      const VerificationMeta('movementPattern');
  @override
  late final GeneratedColumn<String> movementPattern = GeneratedColumn<String>(
      'movement_pattern', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _safetyTierMeta =
      const VerificationMeta('safetyTier');
  @override
  late final GeneratedColumn<int> safetyTier = GeneratedColumn<int>(
      'safety_tier', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lateralityMeta =
      const VerificationMeta('laterality');
  @override
  late final GeneratedColumn<String> laterality = GeneratedColumn<String>(
      'laterality', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemicFatigueMeta =
      const VerificationMeta('systemicFatigue');
  @override
  late final GeneratedColumn<String> systemicFatigue = GeneratedColumn<String>(
      'systemic_fatigue', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _suitabilityMeta =
      const VerificationMeta('suitability');
  @override
  late final GeneratedColumn<String> suitability = GeneratedColumn<String>(
      'suitability', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _regressionIdMeta =
      const VerificationMeta('regressionId');
  @override
  late final GeneratedColumn<String> regressionId = GeneratedColumn<String>(
      'regression_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _progressionIdMeta =
      const VerificationMeta('progressionId');
  @override
  late final GeneratedColumn<String> progressionId = GeneratedColumn<String>(
      'progression_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        thumbnailPath,
        mediaPath,
        bodyPart,
        equipment,
        loggingType,
        movementPattern,
        safetyTier,
        laterality,
        systemicFatigue,
        suitability,
        regressionId,
        progressionId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('media_path')) {
      context.handle(_mediaPathMeta,
          mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta));
    }
    if (data.containsKey('body_part')) {
      context.handle(_bodyPartMeta,
          bodyPart.isAcceptableOrUnknown(data['body_part']!, _bodyPartMeta));
    }
    if (data.containsKey('equipment')) {
      context.handle(_equipmentMeta,
          equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta));
    }
    if (data.containsKey('logging_type')) {
      context.handle(
          _loggingTypeMeta,
          loggingType.isAcceptableOrUnknown(
              data['logging_type']!, _loggingTypeMeta));
    }
    if (data.containsKey('movement_pattern')) {
      context.handle(
          _movementPatternMeta,
          movementPattern.isAcceptableOrUnknown(
              data['movement_pattern']!, _movementPatternMeta));
    }
    if (data.containsKey('safety_tier')) {
      context.handle(
          _safetyTierMeta,
          safetyTier.isAcceptableOrUnknown(
              data['safety_tier']!, _safetyTierMeta));
    }
    if (data.containsKey('laterality')) {
      context.handle(
          _lateralityMeta,
          laterality.isAcceptableOrUnknown(
              data['laterality']!, _lateralityMeta));
    }
    if (data.containsKey('systemic_fatigue')) {
      context.handle(
          _systemicFatigueMeta,
          systemicFatigue.isAcceptableOrUnknown(
              data['systemic_fatigue']!, _systemicFatigueMeta));
    }
    if (data.containsKey('suitability')) {
      context.handle(
          _suitabilityMeta,
          suitability.isAcceptableOrUnknown(
              data['suitability']!, _suitabilityMeta));
    }
    if (data.containsKey('regression_id')) {
      context.handle(
          _regressionIdMeta,
          regressionId.isAcceptableOrUnknown(
              data['regression_id']!, _regressionIdMeta));
    }
    if (data.containsKey('progression_id')) {
      context.handle(
          _progressionIdMeta,
          progressionId.isAcceptableOrUnknown(
              data['progression_id']!, _progressionIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      mediaPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_path']),
      bodyPart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_part']),
      equipment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment']),
      loggingType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logging_type']),
      movementPattern: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}movement_pattern']),
      safetyTier: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}safety_tier'])!,
      laterality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}laterality']),
      systemicFatigue: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}systemic_fatigue'])!,
      suitability: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}suitability']),
      regressionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}regression_id']),
      progressionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}progression_id']),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class ExerciseEntity extends DataClass implements Insertable<ExerciseEntity> {
  final String id;
  final String name;
  final String description;
  final String? thumbnailPath;
  final String? mediaPath;
  final String? bodyPart;
  final String? equipment;
  final String? loggingType;
  final String? movementPattern;
  final int safetyTier;
  final String? laterality;
  final String systemicFatigue;
  final String? suitability;
  final String? regressionId;
  final String? progressionId;
  const ExerciseEntity(
      {required this.id,
      required this.name,
      required this.description,
      this.thumbnailPath,
      this.mediaPath,
      this.bodyPart,
      this.equipment,
      this.loggingType,
      this.movementPattern,
      required this.safetyTier,
      this.laterality,
      required this.systemicFatigue,
      this.suitability,
      this.regressionId,
      this.progressionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    if (!nullToAbsent || bodyPart != null) {
      map['body_part'] = Variable<String>(bodyPart);
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || loggingType != null) {
      map['logging_type'] = Variable<String>(loggingType);
    }
    if (!nullToAbsent || movementPattern != null) {
      map['movement_pattern'] = Variable<String>(movementPattern);
    }
    map['safety_tier'] = Variable<int>(safetyTier);
    if (!nullToAbsent || laterality != null) {
      map['laterality'] = Variable<String>(laterality);
    }
    map['systemic_fatigue'] = Variable<String>(systemicFatigue);
    if (!nullToAbsent || suitability != null) {
      map['suitability'] = Variable<String>(suitability);
    }
    if (!nullToAbsent || regressionId != null) {
      map['regression_id'] = Variable<String>(regressionId);
    }
    if (!nullToAbsent || progressionId != null) {
      map['progression_id'] = Variable<String>(progressionId);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      bodyPart: bodyPart == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyPart),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      loggingType: loggingType == null && nullToAbsent
          ? const Value.absent()
          : Value(loggingType),
      movementPattern: movementPattern == null && nullToAbsent
          ? const Value.absent()
          : Value(movementPattern),
      safetyTier: Value(safetyTier),
      laterality: laterality == null && nullToAbsent
          ? const Value.absent()
          : Value(laterality),
      systemicFatigue: Value(systemicFatigue),
      suitability: suitability == null && nullToAbsent
          ? const Value.absent()
          : Value(suitability),
      regressionId: regressionId == null && nullToAbsent
          ? const Value.absent()
          : Value(regressionId),
      progressionId: progressionId == null && nullToAbsent
          ? const Value.absent()
          : Value(progressionId),
    );
  }

  factory ExerciseEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      bodyPart: serializer.fromJson<String?>(json['bodyPart']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      loggingType: serializer.fromJson<String?>(json['loggingType']),
      movementPattern: serializer.fromJson<String?>(json['movementPattern']),
      safetyTier: serializer.fromJson<int>(json['safetyTier']),
      laterality: serializer.fromJson<String?>(json['laterality']),
      systemicFatigue: serializer.fromJson<String>(json['systemicFatigue']),
      suitability: serializer.fromJson<String?>(json['suitability']),
      regressionId: serializer.fromJson<String?>(json['regressionId']),
      progressionId: serializer.fromJson<String?>(json['progressionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'bodyPart': serializer.toJson<String?>(bodyPart),
      'equipment': serializer.toJson<String?>(equipment),
      'loggingType': serializer.toJson<String?>(loggingType),
      'movementPattern': serializer.toJson<String?>(movementPattern),
      'safetyTier': serializer.toJson<int>(safetyTier),
      'laterality': serializer.toJson<String?>(laterality),
      'systemicFatigue': serializer.toJson<String>(systemicFatigue),
      'suitability': serializer.toJson<String?>(suitability),
      'regressionId': serializer.toJson<String?>(regressionId),
      'progressionId': serializer.toJson<String?>(progressionId),
    };
  }

  ExerciseEntity copyWith(
          {String? id,
          String? name,
          String? description,
          Value<String?> thumbnailPath = const Value.absent(),
          Value<String?> mediaPath = const Value.absent(),
          Value<String?> bodyPart = const Value.absent(),
          Value<String?> equipment = const Value.absent(),
          Value<String?> loggingType = const Value.absent(),
          Value<String?> movementPattern = const Value.absent(),
          int? safetyTier,
          Value<String?> laterality = const Value.absent(),
          String? systemicFatigue,
          Value<String?> suitability = const Value.absent(),
          Value<String?> regressionId = const Value.absent(),
          Value<String?> progressionId = const Value.absent()}) =>
      ExerciseEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
        bodyPart: bodyPart.present ? bodyPart.value : this.bodyPart,
        equipment: equipment.present ? equipment.value : this.equipment,
        loggingType: loggingType.present ? loggingType.value : this.loggingType,
        movementPattern: movementPattern.present
            ? movementPattern.value
            : this.movementPattern,
        safetyTier: safetyTier ?? this.safetyTier,
        laterality: laterality.present ? laterality.value : this.laterality,
        systemicFatigue: systemicFatigue ?? this.systemicFatigue,
        suitability: suitability.present ? suitability.value : this.suitability,
        regressionId:
            regressionId.present ? regressionId.value : this.regressionId,
        progressionId:
            progressionId.present ? progressionId.value : this.progressionId,
      );
  ExerciseEntity copyWithCompanion(ExercisesCompanion data) {
    return ExerciseEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      bodyPart: data.bodyPart.present ? data.bodyPart.value : this.bodyPart,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      loggingType:
          data.loggingType.present ? data.loggingType.value : this.loggingType,
      movementPattern: data.movementPattern.present
          ? data.movementPattern.value
          : this.movementPattern,
      safetyTier:
          data.safetyTier.present ? data.safetyTier.value : this.safetyTier,
      laterality:
          data.laterality.present ? data.laterality.value : this.laterality,
      systemicFatigue: data.systemicFatigue.present
          ? data.systemicFatigue.value
          : this.systemicFatigue,
      suitability:
          data.suitability.present ? data.suitability.value : this.suitability,
      regressionId: data.regressionId.present
          ? data.regressionId.value
          : this.regressionId,
      progressionId: data.progressionId.present
          ? data.progressionId.value
          : this.progressionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('equipment: $equipment, ')
          ..write('loggingType: $loggingType, ')
          ..write('movementPattern: $movementPattern, ')
          ..write('safetyTier: $safetyTier, ')
          ..write('laterality: $laterality, ')
          ..write('systemicFatigue: $systemicFatigue, ')
          ..write('suitability: $suitability, ')
          ..write('regressionId: $regressionId, ')
          ..write('progressionId: $progressionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      thumbnailPath,
      mediaPath,
      bodyPart,
      equipment,
      loggingType,
      movementPattern,
      safetyTier,
      laterality,
      systemicFatigue,
      suitability,
      regressionId,
      progressionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.thumbnailPath == this.thumbnailPath &&
          other.mediaPath == this.mediaPath &&
          other.bodyPart == this.bodyPart &&
          other.equipment == this.equipment &&
          other.loggingType == this.loggingType &&
          other.movementPattern == this.movementPattern &&
          other.safetyTier == this.safetyTier &&
          other.laterality == this.laterality &&
          other.systemicFatigue == this.systemicFatigue &&
          other.suitability == this.suitability &&
          other.regressionId == this.regressionId &&
          other.progressionId == this.progressionId);
}

class ExercisesCompanion extends UpdateCompanion<ExerciseEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String?> thumbnailPath;
  final Value<String?> mediaPath;
  final Value<String?> bodyPart;
  final Value<String?> equipment;
  final Value<String?> loggingType;
  final Value<String?> movementPattern;
  final Value<int> safetyTier;
  final Value<String?> laterality;
  final Value<String> systemicFatigue;
  final Value<String?> suitability;
  final Value<String?> regressionId;
  final Value<String?> progressionId;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.bodyPart = const Value.absent(),
    this.equipment = const Value.absent(),
    this.loggingType = const Value.absent(),
    this.movementPattern = const Value.absent(),
    this.safetyTier = const Value.absent(),
    this.laterality = const Value.absent(),
    this.systemicFatigue = const Value.absent(),
    this.suitability = const Value.absent(),
    this.regressionId = const Value.absent(),
    this.progressionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.bodyPart = const Value.absent(),
    this.equipment = const Value.absent(),
    this.loggingType = const Value.absent(),
    this.movementPattern = const Value.absent(),
    this.safetyTier = const Value.absent(),
    this.laterality = const Value.absent(),
    this.systemicFatigue = const Value.absent(),
    this.suitability = const Value.absent(),
    this.regressionId = const Value.absent(),
    this.progressionId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<ExerciseEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? thumbnailPath,
    Expression<String>? mediaPath,
    Expression<String>? bodyPart,
    Expression<String>? equipment,
    Expression<String>? loggingType,
    Expression<String>? movementPattern,
    Expression<int>? safetyTier,
    Expression<String>? laterality,
    Expression<String>? systemicFatigue,
    Expression<String>? suitability,
    Expression<String>? regressionId,
    Expression<String>? progressionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (mediaPath != null) 'media_path': mediaPath,
      if (bodyPart != null) 'body_part': bodyPart,
      if (equipment != null) 'equipment': equipment,
      if (loggingType != null) 'logging_type': loggingType,
      if (movementPattern != null) 'movement_pattern': movementPattern,
      if (safetyTier != null) 'safety_tier': safetyTier,
      if (laterality != null) 'laterality': laterality,
      if (systemicFatigue != null) 'systemic_fatigue': systemicFatigue,
      if (suitability != null) 'suitability': suitability,
      if (regressionId != null) 'regression_id': regressionId,
      if (progressionId != null) 'progression_id': progressionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? description,
      Value<String?>? thumbnailPath,
      Value<String?>? mediaPath,
      Value<String?>? bodyPart,
      Value<String?>? equipment,
      Value<String?>? loggingType,
      Value<String?>? movementPattern,
      Value<int>? safetyTier,
      Value<String?>? laterality,
      Value<String>? systemicFatigue,
      Value<String?>? suitability,
      Value<String?>? regressionId,
      Value<String?>? progressionId,
      Value<int>? rowid}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      mediaPath: mediaPath ?? this.mediaPath,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      loggingType: loggingType ?? this.loggingType,
      movementPattern: movementPattern ?? this.movementPattern,
      safetyTier: safetyTier ?? this.safetyTier,
      laterality: laterality ?? this.laterality,
      systemicFatigue: systemicFatigue ?? this.systemicFatigue,
      suitability: suitability ?? this.suitability,
      regressionId: regressionId ?? this.regressionId,
      progressionId: progressionId ?? this.progressionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (bodyPart.present) {
      map['body_part'] = Variable<String>(bodyPart.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (loggingType.present) {
      map['logging_type'] = Variable<String>(loggingType.value);
    }
    if (movementPattern.present) {
      map['movement_pattern'] = Variable<String>(movementPattern.value);
    }
    if (safetyTier.present) {
      map['safety_tier'] = Variable<int>(safetyTier.value);
    }
    if (laterality.present) {
      map['laterality'] = Variable<String>(laterality.value);
    }
    if (systemicFatigue.present) {
      map['systemic_fatigue'] = Variable<String>(systemicFatigue.value);
    }
    if (suitability.present) {
      map['suitability'] = Variable<String>(suitability.value);
    }
    if (regressionId.present) {
      map['regression_id'] = Variable<String>(regressionId.value);
    }
    if (progressionId.present) {
      map['progression_id'] = Variable<String>(progressionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('equipment: $equipment, ')
          ..write('loggingType: $loggingType, ')
          ..write('movementPattern: $movementPattern, ')
          ..write('safetyTier: $safetyTier, ')
          ..write('laterality: $laterality, ')
          ..write('systemicFatigue: $systemicFatigue, ')
          ..write('suitability: $suitability, ')
          ..write('regressionId: $regressionId, ')
          ..write('progressionId: $progressionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseFavoritesTable extends ExerciseFavorites
    with TableInfo<$ExerciseFavoritesTable, ExerciseFavoriteEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES exercises (id) ON DELETE CASCADE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [exerciseId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_favorites';
  @override
  VerificationContext validateIntegrity(
      Insertable<ExerciseFavoriteEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId};
  @override
  ExerciseFavoriteEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseFavoriteEntity(
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExerciseFavoritesTable createAlias(String alias) {
    return $ExerciseFavoritesTable(attachedDatabase, alias);
  }
}

class ExerciseFavoriteEntity extends DataClass
    implements Insertable<ExerciseFavoriteEntity> {
  final String exerciseId;
  final DateTime createdAt;
  const ExerciseFavoriteEntity(
      {required this.exerciseId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseFavoritesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseFavoritesCompanion(
      exerciseId: Value(exerciseId),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseFavoriteEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseFavoriteEntity(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseFavoriteEntity copyWith({String? exerciseId, DateTime? createdAt}) =>
      ExerciseFavoriteEntity(
        exerciseId: exerciseId ?? this.exerciseId,
        createdAt: createdAt ?? this.createdAt,
      );
  ExerciseFavoriteEntity copyWithCompanion(ExerciseFavoritesCompanion data) {
    return ExerciseFavoriteEntity(
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseFavoriteEntity(')
          ..write('exerciseId: $exerciseId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseFavoriteEntity &&
          other.exerciseId == this.exerciseId &&
          other.createdAt == this.createdAt);
}

class ExerciseFavoritesCompanion
    extends UpdateCompanion<ExerciseFavoriteEntity> {
  final Value<String> exerciseId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExerciseFavoritesCompanion({
    this.exerciseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseFavoritesCompanion.insert({
    required String exerciseId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId);
  static Insertable<ExerciseFavoriteEntity> custom({
    Expression<String>? exerciseId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseFavoritesCompanion copyWith(
      {Value<String>? exerciseId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ExerciseFavoritesCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseFavoritesCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutEntriesTable extends WorkoutEntries
    with TableInfo<$WorkoutEntriesTable, WorkoutEntryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isCompleteMeta =
      const VerificationMeta('isComplete');
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
      'is_complete', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_complete" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _setOutcomeMeta =
      const VerificationMeta('setOutcome');
  @override
  late final GeneratedColumn<String> setOutcome = GeneratedColumn<String>(
      'set_outcome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supersetGroupIdMeta =
      const VerificationMeta('supersetGroupId');
  @override
  late final GeneratedColumn<String> supersetGroupId = GeneratedColumn<String>(
      'superset_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        exerciseId,
        reps,
        weight,
        distance,
        duration,
        isComplete,
        timestamp,
        sessionId,
        setOutcome,
        supersetGroupId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutEntryEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('is_complete')) {
      context.handle(
          _isCompleteMeta,
          isComplete.isAcceptableOrUnknown(
              data['is_complete']!, _isCompleteMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('set_outcome')) {
      context.handle(
          _setOutcomeMeta,
          setOutcome.isAcceptableOrUnknown(
              data['set_outcome']!, _setOutcomeMeta));
    }
    if (data.containsKey('superset_group_id')) {
      context.handle(
          _supersetGroupIdMeta,
          supersetGroupId.isAcceptableOrUnknown(
              data['superset_group_id']!, _supersetGroupIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutEntryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutEntryEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      isComplete: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_complete'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp']),
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      setOutcome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_outcome']),
      supersetGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}superset_group_id']),
    );
  }

  @override
  $WorkoutEntriesTable createAlias(String alias) {
    return $WorkoutEntriesTable(attachedDatabase, alias);
  }
}

class WorkoutEntryEntity extends DataClass
    implements Insertable<WorkoutEntryEntity> {
  final String id;
  final String exerciseId;
  final int reps;
  final double weight;
  final double? distance;
  final int? duration;
  final bool isComplete;
  final DateTime? timestamp;
  final String? sessionId;
  final String? setOutcome;
  final String? supersetGroupId;
  const WorkoutEntryEntity(
      {required this.id,
      required this.exerciseId,
      required this.reps,
      required this.weight,
      this.distance,
      this.duration,
      required this.isComplete,
      this.timestamp,
      this.sessionId,
      this.setOutcome,
      this.supersetGroupId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['reps'] = Variable<int>(reps);
    map['weight'] = Variable<double>(weight);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['is_complete'] = Variable<bool>(isComplete);
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<DateTime>(timestamp);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || setOutcome != null) {
      map['set_outcome'] = Variable<String>(setOutcome);
    }
    if (!nullToAbsent || supersetGroupId != null) {
      map['superset_group_id'] = Variable<String>(supersetGroupId);
    }
    return map;
  }

  WorkoutEntriesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutEntriesCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      reps: Value(reps),
      weight: Value(weight),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      isComplete: Value(isComplete),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      setOutcome: setOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(setOutcome),
      supersetGroupId: supersetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroupId),
    );
  }

  factory WorkoutEntryEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutEntryEntity(
      id: serializer.fromJson<String>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      reps: serializer.fromJson<int>(json['reps']),
      weight: serializer.fromJson<double>(json['weight']),
      distance: serializer.fromJson<double?>(json['distance']),
      duration: serializer.fromJson<int?>(json['duration']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      timestamp: serializer.fromJson<DateTime?>(json['timestamp']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      setOutcome: serializer.fromJson<String?>(json['setOutcome']),
      supersetGroupId: serializer.fromJson<String?>(json['supersetGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'reps': serializer.toJson<int>(reps),
      'weight': serializer.toJson<double>(weight),
      'distance': serializer.toJson<double?>(distance),
      'duration': serializer.toJson<int?>(duration),
      'isComplete': serializer.toJson<bool>(isComplete),
      'timestamp': serializer.toJson<DateTime?>(timestamp),
      'sessionId': serializer.toJson<String?>(sessionId),
      'setOutcome': serializer.toJson<String?>(setOutcome),
      'supersetGroupId': serializer.toJson<String?>(supersetGroupId),
    };
  }

  WorkoutEntryEntity copyWith(
          {String? id,
          String? exerciseId,
          int? reps,
          double? weight,
          Value<double?> distance = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          bool? isComplete,
          Value<DateTime?> timestamp = const Value.absent(),
          Value<String?> sessionId = const Value.absent(),
          Value<String?> setOutcome = const Value.absent(),
          Value<String?> supersetGroupId = const Value.absent()}) =>
      WorkoutEntryEntity(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        distance: distance.present ? distance.value : this.distance,
        duration: duration.present ? duration.value : this.duration,
        isComplete: isComplete ?? this.isComplete,
        timestamp: timestamp.present ? timestamp.value : this.timestamp,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        setOutcome: setOutcome.present ? setOutcome.value : this.setOutcome,
        supersetGroupId: supersetGroupId.present
            ? supersetGroupId.value
            : this.supersetGroupId,
      );
  WorkoutEntryEntity copyWithCompanion(WorkoutEntriesCompanion data) {
    return WorkoutEntryEntity(
      id: data.id.present ? data.id.value : this.id,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      distance: data.distance.present ? data.distance.value : this.distance,
      duration: data.duration.present ? data.duration.value : this.duration,
      isComplete:
          data.isComplete.present ? data.isComplete.value : this.isComplete,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      setOutcome:
          data.setOutcome.present ? data.setOutcome.value : this.setOutcome,
      supersetGroupId: data.supersetGroupId.present
          ? data.supersetGroupId.value
          : this.supersetGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutEntryEntity(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('isComplete: $isComplete, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId, ')
          ..write('setOutcome: $setOutcome, ')
          ..write('supersetGroupId: $supersetGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, reps, weight, distance,
      duration, isComplete, timestamp, sessionId, setOutcome, supersetGroupId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutEntryEntity &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.distance == this.distance &&
          other.duration == this.duration &&
          other.isComplete == this.isComplete &&
          other.timestamp == this.timestamp &&
          other.sessionId == this.sessionId &&
          other.setOutcome == this.setOutcome &&
          other.supersetGroupId == this.supersetGroupId);
}

class WorkoutEntriesCompanion extends UpdateCompanion<WorkoutEntryEntity> {
  final Value<String> id;
  final Value<String> exerciseId;
  final Value<int> reps;
  final Value<double> weight;
  final Value<double?> distance;
  final Value<int?> duration;
  final Value<bool> isComplete;
  final Value<DateTime?> timestamp;
  final Value<String?> sessionId;
  final Value<String?> setOutcome;
  final Value<String?> supersetGroupId;
  final Value<int> rowid;
  const WorkoutEntriesCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.setOutcome = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutEntriesCompanion.insert({
    required String id,
    required String exerciseId,
    required int reps,
    required double weight,
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.setOutcome = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        exerciseId = Value(exerciseId),
        reps = Value(reps),
        weight = Value(weight);
  static Insertable<WorkoutEntryEntity> custom({
    Expression<String>? id,
    Expression<String>? exerciseId,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<double>? distance,
    Expression<int>? duration,
    Expression<bool>? isComplete,
    Expression<DateTime>? timestamp,
    Expression<String>? sessionId,
    Expression<String>? setOutcome,
    Expression<String>? supersetGroupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (distance != null) 'distance': distance,
      if (duration != null) 'duration': duration,
      if (isComplete != null) 'is_complete': isComplete,
      if (timestamp != null) 'timestamp': timestamp,
      if (sessionId != null) 'session_id': sessionId,
      if (setOutcome != null) 'set_outcome': setOutcome,
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? exerciseId,
      Value<int>? reps,
      Value<double>? weight,
      Value<double?>? distance,
      Value<int?>? duration,
      Value<bool>? isComplete,
      Value<DateTime?>? timestamp,
      Value<String?>? sessionId,
      Value<String?>? setOutcome,
      Value<String?>? supersetGroupId,
      Value<int>? rowid}) {
    return WorkoutEntriesCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      isComplete: isComplete ?? this.isComplete,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      setOutcome: setOutcome ?? this.setOutcome,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (setOutcome.present) {
      map['set_outcome'] = Variable<String>(setOutcome.value);
    }
    if (supersetGroupId.present) {
      map['superset_group_id'] = Variable<String>(supersetGroupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutEntriesCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('isComplete: $isComplete, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId, ')
          ..write('setOutcome: $setOutcome, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts
    with TableInfo<$WorkoutsTable, WorkoutEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class WorkoutEntity extends DataClass implements Insertable<WorkoutEntity> {
  final String id;
  final String name;
  const WorkoutEntity({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory WorkoutEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  WorkoutEntity copyWith({String? id, String? name}) => WorkoutEntity(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  WorkoutEntity copyWithCompanion(WorkoutsCompanion data) {
    return WorkoutEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutEntity(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutEntity &&
          other.id == this.id &&
          other.name == this.name);
}

class WorkoutsCompanion extends UpdateCompanion<WorkoutEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<WorkoutEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith(
      {Value<String>? id, Value<String>? name, Value<int>? rowid}) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutExercisesTable extends WorkoutExercises
    with TableInfo<$WorkoutExercisesTable, WorkoutExerciseEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workouts (id) ON DELETE CASCADE'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _supersetGroupIdMeta =
      const VerificationMeta('supersetGroupId');
  @override
  late final GeneratedColumn<String> supersetGroupId = GeneratedColumn<String>(
      'superset_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workoutId,
        exerciseId,
        position,
        reps,
        weight,
        distance,
        duration,
        timestamp,
        supersetGroupId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_exercises';
  @override
  VerificationContext validateIntegrity(
      Insertable<WorkoutExerciseEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('superset_group_id')) {
      context.handle(
          _supersetGroupIdMeta,
          supersetGroupId.isAcceptableOrUnknown(
              data['superset_group_id']!, _supersetGroupIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutExerciseEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutExerciseEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp']),
      supersetGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}superset_group_id']),
    );
  }

  @override
  $WorkoutExercisesTable createAlias(String alias) {
    return $WorkoutExercisesTable(attachedDatabase, alias);
  }
}

class WorkoutExerciseEntity extends DataClass
    implements Insertable<WorkoutExerciseEntity> {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int position;
  final int reps;
  final double weight;
  final double? distance;
  final int? duration;
  final DateTime? timestamp;
  final String? supersetGroupId;
  const WorkoutExerciseEntity(
      {required this.id,
      required this.workoutId,
      required this.exerciseId,
      required this.position,
      required this.reps,
      required this.weight,
      this.distance,
      this.duration,
      this.timestamp,
      this.supersetGroupId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['reps'] = Variable<int>(reps);
    map['weight'] = Variable<double>(weight);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<DateTime>(timestamp);
    }
    if (!nullToAbsent || supersetGroupId != null) {
      map['superset_group_id'] = Variable<String>(supersetGroupId);
    }
    return map;
  }

  WorkoutExercisesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutExercisesCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      reps: Value(reps),
      weight: Value(weight),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
      supersetGroupId: supersetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroupId),
    );
  }

  factory WorkoutExerciseEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutExerciseEntity(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      reps: serializer.fromJson<int>(json['reps']),
      weight: serializer.fromJson<double>(json['weight']),
      distance: serializer.fromJson<double?>(json['distance']),
      duration: serializer.fromJson<int?>(json['duration']),
      timestamp: serializer.fromJson<DateTime?>(json['timestamp']),
      supersetGroupId: serializer.fromJson<String?>(json['supersetGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'reps': serializer.toJson<int>(reps),
      'weight': serializer.toJson<double>(weight),
      'distance': serializer.toJson<double?>(distance),
      'duration': serializer.toJson<int?>(duration),
      'timestamp': serializer.toJson<DateTime?>(timestamp),
      'supersetGroupId': serializer.toJson<String?>(supersetGroupId),
    };
  }

  WorkoutExerciseEntity copyWith(
          {String? id,
          String? workoutId,
          String? exerciseId,
          int? position,
          int? reps,
          double? weight,
          Value<double?> distance = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<DateTime?> timestamp = const Value.absent(),
          Value<String?> supersetGroupId = const Value.absent()}) =>
      WorkoutExerciseEntity(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        exerciseId: exerciseId ?? this.exerciseId,
        position: position ?? this.position,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        distance: distance.present ? distance.value : this.distance,
        duration: duration.present ? duration.value : this.duration,
        timestamp: timestamp.present ? timestamp.value : this.timestamp,
        supersetGroupId: supersetGroupId.present
            ? supersetGroupId.value
            : this.supersetGroupId,
      );
  WorkoutExerciseEntity copyWithCompanion(WorkoutExercisesCompanion data) {
    return WorkoutExerciseEntity(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      distance: data.distance.present ? data.distance.value : this.distance,
      duration: data.duration.present ? data.duration.value : this.duration,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      supersetGroupId: data.supersetGroupId.present
          ? data.supersetGroupId.value
          : this.supersetGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExerciseEntity(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('timestamp: $timestamp, ')
          ..write('supersetGroupId: $supersetGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId, exerciseId, position, reps,
      weight, distance, duration, timestamp, supersetGroupId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutExerciseEntity &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.distance == this.distance &&
          other.duration == this.duration &&
          other.timestamp == this.timestamp &&
          other.supersetGroupId == this.supersetGroupId);
}

class WorkoutExercisesCompanion extends UpdateCompanion<WorkoutExerciseEntity> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> reps;
  final Value<double> weight;
  final Value<double?> distance;
  final Value<int?> duration;
  final Value<DateTime?> timestamp;
  final Value<String?> supersetGroupId;
  final Value<int> rowid;
  const WorkoutExercisesCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutExercisesCompanion.insert({
    required String id,
    required String workoutId,
    required String exerciseId,
    required int position,
    required int reps,
    required double weight,
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutId = Value(workoutId),
        exerciseId = Value(exerciseId),
        position = Value(position),
        reps = Value(reps),
        weight = Value(weight);
  static Insertable<WorkoutExerciseEntity> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<double>? distance,
    Expression<int>? duration,
    Expression<DateTime>? timestamp,
    Expression<String>? supersetGroupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (distance != null) 'distance': distance,
      if (duration != null) 'duration': duration,
      if (timestamp != null) 'timestamp': timestamp,
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutId,
      Value<String>? exerciseId,
      Value<int>? position,
      Value<int>? reps,
      Value<double>? weight,
      Value<double?>? distance,
      Value<int?>? duration,
      Value<DateTime?>? timestamp,
      Value<String?>? supersetGroupId,
      Value<int>? rowid}) {
    return WorkoutExercisesCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (supersetGroupId.present) {
      map['superset_group_id'] = Variable<String>(supersetGroupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercisesCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('timestamp: $timestamp, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramsTable extends Programs
    with TableInfo<$ProgramsTable, ProgramEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationEnabledMeta =
      const VerificationMeta('notificationEnabled');
  @override
  late final GeneratedColumn<bool> notificationEnabled = GeneratedColumn<bool>(
      'notification_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notification_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notificationTimeMinutesMeta =
      const VerificationMeta('notificationTimeMinutes');
  @override
  late final GeneratedColumn<int> notificationTimeMinutes =
      GeneratedColumn<int>('notification_time_minutes', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isAiGeneratedMeta =
      const VerificationMeta('isAiGenerated');
  @override
  late final GeneratedColumn<bool> isAiGenerated = GeneratedColumn<bool>(
      'is_ai_generated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_ai_generated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _generationContextMeta =
      const VerificationMeta('generationContext');
  @override
  late final GeneratedColumn<String> generationContext =
      GeneratedColumn<String>('generation_context', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deloadWeekMeta =
      const VerificationMeta('deloadWeek');
  @override
  late final GeneratedColumn<int> deloadWeek = GeneratedColumn<int>(
      'deload_week', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weeklyProgressionNotesMeta =
      const VerificationMeta('weeklyProgressionNotes');
  @override
  late final GeneratedColumn<String> weeklyProgressionNotes =
      GeneratedColumn<String>('weekly_progression_notes', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coachIntroMeta =
      const VerificationMeta('coachIntro');
  @override
  late final GeneratedColumn<String> coachIntro = GeneratedColumn<String>(
      'coach_intro', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coachRationaleMeta =
      const VerificationMeta('coachRationale');
  @override
  late final GeneratedColumn<String> coachRationale = GeneratedColumn<String>(
      'coach_rationale', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coachRationaleSpokenMeta =
      const VerificationMeta('coachRationaleSpoken');
  @override
  late final GeneratedColumn<String> coachRationaleSpoken =
      GeneratedColumn<String>('coach_rationale_spoken', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _workoutBreakdownsMeta =
      const VerificationMeta('workoutBreakdowns');
  @override
  late final GeneratedColumn<String> workoutBreakdowns =
      GeneratedColumn<String>('workout_breakdowns', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _programmeDescriptionAudioRemotePathMeta =
      const VerificationMeta('programmeDescriptionAudioRemotePath');
  @override
  late final GeneratedColumn<String> programmeDescriptionAudioRemotePath =
      GeneratedColumn<String>(
          'programme_description_audio_remote_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        notificationEnabled,
        notificationTimeMinutes,
        isAiGenerated,
        generationContext,
        deloadWeek,
        weeklyProgressionNotes,
        coachIntro,
        coachRationale,
        coachRationaleSpoken,
        workoutBreakdowns,
        programmeDescriptionAudioRemotePath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(Insertable<ProgramEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notification_enabled')) {
      context.handle(
          _notificationEnabledMeta,
          notificationEnabled.isAcceptableOrUnknown(
              data['notification_enabled']!, _notificationEnabledMeta));
    }
    if (data.containsKey('notification_time_minutes')) {
      context.handle(
          _notificationTimeMinutesMeta,
          notificationTimeMinutes.isAcceptableOrUnknown(
              data['notification_time_minutes']!,
              _notificationTimeMinutesMeta));
    }
    if (data.containsKey('is_ai_generated')) {
      context.handle(
          _isAiGeneratedMeta,
          isAiGenerated.isAcceptableOrUnknown(
              data['is_ai_generated']!, _isAiGeneratedMeta));
    }
    if (data.containsKey('generation_context')) {
      context.handle(
          _generationContextMeta,
          generationContext.isAcceptableOrUnknown(
              data['generation_context']!, _generationContextMeta));
    }
    if (data.containsKey('deload_week')) {
      context.handle(
          _deloadWeekMeta,
          deloadWeek.isAcceptableOrUnknown(
              data['deload_week']!, _deloadWeekMeta));
    }
    if (data.containsKey('weekly_progression_notes')) {
      context.handle(
          _weeklyProgressionNotesMeta,
          weeklyProgressionNotes.isAcceptableOrUnknown(
              data['weekly_progression_notes']!, _weeklyProgressionNotesMeta));
    }
    if (data.containsKey('coach_intro')) {
      context.handle(
          _coachIntroMeta,
          coachIntro.isAcceptableOrUnknown(
              data['coach_intro']!, _coachIntroMeta));
    }
    if (data.containsKey('coach_rationale')) {
      context.handle(
          _coachRationaleMeta,
          coachRationale.isAcceptableOrUnknown(
              data['coach_rationale']!, _coachRationaleMeta));
    }
    if (data.containsKey('coach_rationale_spoken')) {
      context.handle(
          _coachRationaleSpokenMeta,
          coachRationaleSpoken.isAcceptableOrUnknown(
              data['coach_rationale_spoken']!, _coachRationaleSpokenMeta));
    }
    if (data.containsKey('workout_breakdowns')) {
      context.handle(
          _workoutBreakdownsMeta,
          workoutBreakdowns.isAcceptableOrUnknown(
              data['workout_breakdowns']!, _workoutBreakdownsMeta));
    }
    if (data.containsKey('programme_description_audio_remote_path')) {
      context.handle(
          _programmeDescriptionAudioRemotePathMeta,
          programmeDescriptionAudioRemotePath.isAcceptableOrUnknown(
              data['programme_description_audio_remote_path']!,
              _programmeDescriptionAudioRemotePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      notificationEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notification_enabled'])!,
      notificationTimeMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}notification_time_minutes']),
      isAiGenerated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_ai_generated'])!,
      generationContext: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}generation_context']),
      deloadWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deload_week']),
      weeklyProgressionNotes: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}weekly_progression_notes']),
      coachIntro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}coach_intro']),
      coachRationale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}coach_rationale']),
      coachRationaleSpoken: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}coach_rationale_spoken']),
      workoutBreakdowns: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}workout_breakdowns']),
      programmeDescriptionAudioRemotePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}programme_description_audio_remote_path']),
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class ProgramEntity extends DataClass implements Insertable<ProgramEntity> {
  final String id;
  final String name;
  final bool notificationEnabled;
  final int? notificationTimeMinutes;
  final bool isAiGenerated;
  final String? generationContext;
  final int? deloadWeek;
  final String? weeklyProgressionNotes;
  final String? coachIntro;
  final String? coachRationale;
  final String? coachRationaleSpoken;
  final String? workoutBreakdowns;

  /// Firebase Storage path for Type C programme description MP3 (e.g. audio/users/uid/.../description.mp3).
  final String? programmeDescriptionAudioRemotePath;
  const ProgramEntity(
      {required this.id,
      required this.name,
      required this.notificationEnabled,
      this.notificationTimeMinutes,
      required this.isAiGenerated,
      this.generationContext,
      this.deloadWeek,
      this.weeklyProgressionNotes,
      this.coachIntro,
      this.coachRationale,
      this.coachRationaleSpoken,
      this.workoutBreakdowns,
      this.programmeDescriptionAudioRemotePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['notification_enabled'] = Variable<bool>(notificationEnabled);
    if (!nullToAbsent || notificationTimeMinutes != null) {
      map['notification_time_minutes'] = Variable<int>(notificationTimeMinutes);
    }
    map['is_ai_generated'] = Variable<bool>(isAiGenerated);
    if (!nullToAbsent || generationContext != null) {
      map['generation_context'] = Variable<String>(generationContext);
    }
    if (!nullToAbsent || deloadWeek != null) {
      map['deload_week'] = Variable<int>(deloadWeek);
    }
    if (!nullToAbsent || weeklyProgressionNotes != null) {
      map['weekly_progression_notes'] =
          Variable<String>(weeklyProgressionNotes);
    }
    if (!nullToAbsent || coachIntro != null) {
      map['coach_intro'] = Variable<String>(coachIntro);
    }
    if (!nullToAbsent || coachRationale != null) {
      map['coach_rationale'] = Variable<String>(coachRationale);
    }
    if (!nullToAbsent || coachRationaleSpoken != null) {
      map['coach_rationale_spoken'] = Variable<String>(coachRationaleSpoken);
    }
    if (!nullToAbsent || workoutBreakdowns != null) {
      map['workout_breakdowns'] = Variable<String>(workoutBreakdowns);
    }
    if (!nullToAbsent || programmeDescriptionAudioRemotePath != null) {
      map['programme_description_audio_remote_path'] =
          Variable<String>(programmeDescriptionAudioRemotePath);
    }
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      notificationEnabled: Value(notificationEnabled),
      notificationTimeMinutes: notificationTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationTimeMinutes),
      isAiGenerated: Value(isAiGenerated),
      generationContext: generationContext == null && nullToAbsent
          ? const Value.absent()
          : Value(generationContext),
      deloadWeek: deloadWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(deloadWeek),
      weeklyProgressionNotes: weeklyProgressionNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyProgressionNotes),
      coachIntro: coachIntro == null && nullToAbsent
          ? const Value.absent()
          : Value(coachIntro),
      coachRationale: coachRationale == null && nullToAbsent
          ? const Value.absent()
          : Value(coachRationale),
      coachRationaleSpoken: coachRationaleSpoken == null && nullToAbsent
          ? const Value.absent()
          : Value(coachRationaleSpoken),
      workoutBreakdowns: workoutBreakdowns == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutBreakdowns),
      programmeDescriptionAudioRemotePath:
          programmeDescriptionAudioRemotePath == null && nullToAbsent
              ? const Value.absent()
              : Value(programmeDescriptionAudioRemotePath),
    );
  }

  factory ProgramEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notificationEnabled:
          serializer.fromJson<bool>(json['notificationEnabled']),
      notificationTimeMinutes:
          serializer.fromJson<int?>(json['notificationTimeMinutes']),
      isAiGenerated: serializer.fromJson<bool>(json['isAiGenerated']),
      generationContext:
          serializer.fromJson<String?>(json['generationContext']),
      deloadWeek: serializer.fromJson<int?>(json['deloadWeek']),
      weeklyProgressionNotes:
          serializer.fromJson<String?>(json['weeklyProgressionNotes']),
      coachIntro: serializer.fromJson<String?>(json['coachIntro']),
      coachRationale: serializer.fromJson<String?>(json['coachRationale']),
      coachRationaleSpoken:
          serializer.fromJson<String?>(json['coachRationaleSpoken']),
      workoutBreakdowns:
          serializer.fromJson<String?>(json['workoutBreakdowns']),
      programmeDescriptionAudioRemotePath: serializer
          .fromJson<String?>(json['programmeDescriptionAudioRemotePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'notificationEnabled': serializer.toJson<bool>(notificationEnabled),
      'notificationTimeMinutes':
          serializer.toJson<int?>(notificationTimeMinutes),
      'isAiGenerated': serializer.toJson<bool>(isAiGenerated),
      'generationContext': serializer.toJson<String?>(generationContext),
      'deloadWeek': serializer.toJson<int?>(deloadWeek),
      'weeklyProgressionNotes':
          serializer.toJson<String?>(weeklyProgressionNotes),
      'coachIntro': serializer.toJson<String?>(coachIntro),
      'coachRationale': serializer.toJson<String?>(coachRationale),
      'coachRationaleSpoken': serializer.toJson<String?>(coachRationaleSpoken),
      'workoutBreakdowns': serializer.toJson<String?>(workoutBreakdowns),
      'programmeDescriptionAudioRemotePath':
          serializer.toJson<String?>(programmeDescriptionAudioRemotePath),
    };
  }

  ProgramEntity copyWith(
          {String? id,
          String? name,
          bool? notificationEnabled,
          Value<int?> notificationTimeMinutes = const Value.absent(),
          bool? isAiGenerated,
          Value<String?> generationContext = const Value.absent(),
          Value<int?> deloadWeek = const Value.absent(),
          Value<String?> weeklyProgressionNotes = const Value.absent(),
          Value<String?> coachIntro = const Value.absent(),
          Value<String?> coachRationale = const Value.absent(),
          Value<String?> coachRationaleSpoken = const Value.absent(),
          Value<String?> workoutBreakdowns = const Value.absent(),
          Value<String?> programmeDescriptionAudioRemotePath =
              const Value.absent()}) =>
      ProgramEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        notificationTimeMinutes: notificationTimeMinutes.present
            ? notificationTimeMinutes.value
            : this.notificationTimeMinutes,
        isAiGenerated: isAiGenerated ?? this.isAiGenerated,
        generationContext: generationContext.present
            ? generationContext.value
            : this.generationContext,
        deloadWeek: deloadWeek.present ? deloadWeek.value : this.deloadWeek,
        weeklyProgressionNotes: weeklyProgressionNotes.present
            ? weeklyProgressionNotes.value
            : this.weeklyProgressionNotes,
        coachIntro: coachIntro.present ? coachIntro.value : this.coachIntro,
        coachRationale:
            coachRationale.present ? coachRationale.value : this.coachRationale,
        coachRationaleSpoken: coachRationaleSpoken.present
            ? coachRationaleSpoken.value
            : this.coachRationaleSpoken,
        workoutBreakdowns: workoutBreakdowns.present
            ? workoutBreakdowns.value
            : this.workoutBreakdowns,
        programmeDescriptionAudioRemotePath:
            programmeDescriptionAudioRemotePath.present
                ? programmeDescriptionAudioRemotePath.value
                : this.programmeDescriptionAudioRemotePath,
      );
  ProgramEntity copyWithCompanion(ProgramsCompanion data) {
    return ProgramEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notificationEnabled: data.notificationEnabled.present
          ? data.notificationEnabled.value
          : this.notificationEnabled,
      notificationTimeMinutes: data.notificationTimeMinutes.present
          ? data.notificationTimeMinutes.value
          : this.notificationTimeMinutes,
      isAiGenerated: data.isAiGenerated.present
          ? data.isAiGenerated.value
          : this.isAiGenerated,
      generationContext: data.generationContext.present
          ? data.generationContext.value
          : this.generationContext,
      deloadWeek:
          data.deloadWeek.present ? data.deloadWeek.value : this.deloadWeek,
      weeklyProgressionNotes: data.weeklyProgressionNotes.present
          ? data.weeklyProgressionNotes.value
          : this.weeklyProgressionNotes,
      coachIntro:
          data.coachIntro.present ? data.coachIntro.value : this.coachIntro,
      coachRationale: data.coachRationale.present
          ? data.coachRationale.value
          : this.coachRationale,
      coachRationaleSpoken: data.coachRationaleSpoken.present
          ? data.coachRationaleSpoken.value
          : this.coachRationaleSpoken,
      workoutBreakdowns: data.workoutBreakdowns.present
          ? data.workoutBreakdowns.value
          : this.workoutBreakdowns,
      programmeDescriptionAudioRemotePath:
          data.programmeDescriptionAudioRemotePath.present
              ? data.programmeDescriptionAudioRemotePath.value
              : this.programmeDescriptionAudioRemotePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('notificationTimeMinutes: $notificationTimeMinutes, ')
          ..write('isAiGenerated: $isAiGenerated, ')
          ..write('generationContext: $generationContext, ')
          ..write('deloadWeek: $deloadWeek, ')
          ..write('weeklyProgressionNotes: $weeklyProgressionNotes, ')
          ..write('coachIntro: $coachIntro, ')
          ..write('coachRationale: $coachRationale, ')
          ..write('coachRationaleSpoken: $coachRationaleSpoken, ')
          ..write('workoutBreakdowns: $workoutBreakdowns, ')
          ..write(
              'programmeDescriptionAudioRemotePath: $programmeDescriptionAudioRemotePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      notificationEnabled,
      notificationTimeMinutes,
      isAiGenerated,
      generationContext,
      deloadWeek,
      weeklyProgressionNotes,
      coachIntro,
      coachRationale,
      coachRationaleSpoken,
      workoutBreakdowns,
      programmeDescriptionAudioRemotePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.notificationEnabled == this.notificationEnabled &&
          other.notificationTimeMinutes == this.notificationTimeMinutes &&
          other.isAiGenerated == this.isAiGenerated &&
          other.generationContext == this.generationContext &&
          other.deloadWeek == this.deloadWeek &&
          other.weeklyProgressionNotes == this.weeklyProgressionNotes &&
          other.coachIntro == this.coachIntro &&
          other.coachRationale == this.coachRationale &&
          other.coachRationaleSpoken == this.coachRationaleSpoken &&
          other.workoutBreakdowns == this.workoutBreakdowns &&
          other.programmeDescriptionAudioRemotePath ==
              this.programmeDescriptionAudioRemotePath);
}

class ProgramsCompanion extends UpdateCompanion<ProgramEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> notificationEnabled;
  final Value<int?> notificationTimeMinutes;
  final Value<bool> isAiGenerated;
  final Value<String?> generationContext;
  final Value<int?> deloadWeek;
  final Value<String?> weeklyProgressionNotes;
  final Value<String?> coachIntro;
  final Value<String?> coachRationale;
  final Value<String?> coachRationaleSpoken;
  final Value<String?> workoutBreakdowns;
  final Value<String?> programmeDescriptionAudioRemotePath;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.notificationTimeMinutes = const Value.absent(),
    this.isAiGenerated = const Value.absent(),
    this.generationContext = const Value.absent(),
    this.deloadWeek = const Value.absent(),
    this.weeklyProgressionNotes = const Value.absent(),
    this.coachIntro = const Value.absent(),
    this.coachRationale = const Value.absent(),
    this.coachRationaleSpoken = const Value.absent(),
    this.workoutBreakdowns = const Value.absent(),
    this.programmeDescriptionAudioRemotePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required String name,
    this.notificationEnabled = const Value.absent(),
    this.notificationTimeMinutes = const Value.absent(),
    this.isAiGenerated = const Value.absent(),
    this.generationContext = const Value.absent(),
    this.deloadWeek = const Value.absent(),
    this.weeklyProgressionNotes = const Value.absent(),
    this.coachIntro = const Value.absent(),
    this.coachRationale = const Value.absent(),
    this.coachRationaleSpoken = const Value.absent(),
    this.workoutBreakdowns = const Value.absent(),
    this.programmeDescriptionAudioRemotePath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<ProgramEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? notificationEnabled,
    Expression<int>? notificationTimeMinutes,
    Expression<bool>? isAiGenerated,
    Expression<String>? generationContext,
    Expression<int>? deloadWeek,
    Expression<String>? weeklyProgressionNotes,
    Expression<String>? coachIntro,
    Expression<String>? coachRationale,
    Expression<String>? coachRationaleSpoken,
    Expression<String>? workoutBreakdowns,
    Expression<String>? programmeDescriptionAudioRemotePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notificationEnabled != null)
        'notification_enabled': notificationEnabled,
      if (notificationTimeMinutes != null)
        'notification_time_minutes': notificationTimeMinutes,
      if (isAiGenerated != null) 'is_ai_generated': isAiGenerated,
      if (generationContext != null) 'generation_context': generationContext,
      if (deloadWeek != null) 'deload_week': deloadWeek,
      if (weeklyProgressionNotes != null)
        'weekly_progression_notes': weeklyProgressionNotes,
      if (coachIntro != null) 'coach_intro': coachIntro,
      if (coachRationale != null) 'coach_rationale': coachRationale,
      if (coachRationaleSpoken != null)
        'coach_rationale_spoken': coachRationaleSpoken,
      if (workoutBreakdowns != null) 'workout_breakdowns': workoutBreakdowns,
      if (programmeDescriptionAudioRemotePath != null)
        'programme_description_audio_remote_path':
            programmeDescriptionAudioRemotePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<bool>? notificationEnabled,
      Value<int?>? notificationTimeMinutes,
      Value<bool>? isAiGenerated,
      Value<String?>? generationContext,
      Value<int?>? deloadWeek,
      Value<String?>? weeklyProgressionNotes,
      Value<String?>? coachIntro,
      Value<String?>? coachRationale,
      Value<String?>? coachRationaleSpoken,
      Value<String?>? workoutBreakdowns,
      Value<String?>? programmeDescriptionAudioRemotePath,
      Value<int>? rowid}) {
    return ProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTimeMinutes:
          notificationTimeMinutes ?? this.notificationTimeMinutes,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      generationContext: generationContext ?? this.generationContext,
      deloadWeek: deloadWeek ?? this.deloadWeek,
      weeklyProgressionNotes:
          weeklyProgressionNotes ?? this.weeklyProgressionNotes,
      coachIntro: coachIntro ?? this.coachIntro,
      coachRationale: coachRationale ?? this.coachRationale,
      coachRationaleSpoken: coachRationaleSpoken ?? this.coachRationaleSpoken,
      workoutBreakdowns: workoutBreakdowns ?? this.workoutBreakdowns,
      programmeDescriptionAudioRemotePath:
          programmeDescriptionAudioRemotePath ??
              this.programmeDescriptionAudioRemotePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notificationEnabled.present) {
      map['notification_enabled'] = Variable<bool>(notificationEnabled.value);
    }
    if (notificationTimeMinutes.present) {
      map['notification_time_minutes'] =
          Variable<int>(notificationTimeMinutes.value);
    }
    if (isAiGenerated.present) {
      map['is_ai_generated'] = Variable<bool>(isAiGenerated.value);
    }
    if (generationContext.present) {
      map['generation_context'] = Variable<String>(generationContext.value);
    }
    if (deloadWeek.present) {
      map['deload_week'] = Variable<int>(deloadWeek.value);
    }
    if (weeklyProgressionNotes.present) {
      map['weekly_progression_notes'] =
          Variable<String>(weeklyProgressionNotes.value);
    }
    if (coachIntro.present) {
      map['coach_intro'] = Variable<String>(coachIntro.value);
    }
    if (coachRationale.present) {
      map['coach_rationale'] = Variable<String>(coachRationale.value);
    }
    if (coachRationaleSpoken.present) {
      map['coach_rationale_spoken'] =
          Variable<String>(coachRationaleSpoken.value);
    }
    if (workoutBreakdowns.present) {
      map['workout_breakdowns'] = Variable<String>(workoutBreakdowns.value);
    }
    if (programmeDescriptionAudioRemotePath.present) {
      map['programme_description_audio_remote_path'] =
          Variable<String>(programmeDescriptionAudioRemotePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('notificationTimeMinutes: $notificationTimeMinutes, ')
          ..write('isAiGenerated: $isAiGenerated, ')
          ..write('generationContext: $generationContext, ')
          ..write('deloadWeek: $deloadWeek, ')
          ..write('weeklyProgressionNotes: $weeklyProgressionNotes, ')
          ..write('coachIntro: $coachIntro, ')
          ..write('coachRationale: $coachRationale, ')
          ..write('coachRationaleSpoken: $coachRationaleSpoken, ')
          ..write('workoutBreakdowns: $workoutBreakdowns, ')
          ..write(
              'programmeDescriptionAudioRemotePath: $programmeDescriptionAudioRemotePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramExercisesTable extends ProgramExercises
    with TableInfo<$ProgramExercisesTable, ProgramExerciseEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _programIdMeta =
      const VerificationMeta('programId');
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
      'program_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES programs (id) ON DELETE CASCADE'));
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>('scheduled_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [position, programId, workoutId, scheduledDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'program_exercises';
  @override
  VerificationContext validateIntegrity(
      Insertable<ProgramExerciseEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(_programIdMeta,
          programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta));
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {programId, position};
  @override
  ProgramExerciseEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramExerciseEntity(
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      programId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}program_id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      scheduledDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_date'])!,
    );
  }

  @override
  $ProgramExercisesTable createAlias(String alias) {
    return $ProgramExercisesTable(attachedDatabase, alias);
  }
}

class ProgramExerciseEntity extends DataClass
    implements Insertable<ProgramExerciseEntity> {
  final int position;
  final String programId;
  final String workoutId;
  final DateTime scheduledDate;
  const ProgramExerciseEntity(
      {required this.position,
      required this.programId,
      required this.workoutId,
      required this.scheduledDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['position'] = Variable<int>(position);
    map['program_id'] = Variable<String>(programId);
    map['workout_id'] = Variable<String>(workoutId);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    return map;
  }

  ProgramExercisesCompanion toCompanion(bool nullToAbsent) {
    return ProgramExercisesCompanion(
      position: Value(position),
      programId: Value(programId),
      workoutId: Value(workoutId),
      scheduledDate: Value(scheduledDate),
    );
  }

  factory ProgramExerciseEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramExerciseEntity(
      position: serializer.fromJson<int>(json['position']),
      programId: serializer.fromJson<String>(json['programId']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'position': serializer.toJson<int>(position),
      'programId': serializer.toJson<String>(programId),
      'workoutId': serializer.toJson<String>(workoutId),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
    };
  }

  ProgramExerciseEntity copyWith(
          {int? position,
          String? programId,
          String? workoutId,
          DateTime? scheduledDate}) =>
      ProgramExerciseEntity(
        position: position ?? this.position,
        programId: programId ?? this.programId,
        workoutId: workoutId ?? this.workoutId,
        scheduledDate: scheduledDate ?? this.scheduledDate,
      );
  ProgramExerciseEntity copyWithCompanion(ProgramExercisesCompanion data) {
    return ProgramExerciseEntity(
      position: data.position.present ? data.position.value : this.position,
      programId: data.programId.present ? data.programId.value : this.programId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramExerciseEntity(')
          ..write('position: $position, ')
          ..write('programId: $programId, ')
          ..write('workoutId: $workoutId, ')
          ..write('scheduledDate: $scheduledDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(position, programId, workoutId, scheduledDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramExerciseEntity &&
          other.position == this.position &&
          other.programId == this.programId &&
          other.workoutId == this.workoutId &&
          other.scheduledDate == this.scheduledDate);
}

class ProgramExercisesCompanion extends UpdateCompanion<ProgramExerciseEntity> {
  final Value<int> position;
  final Value<String> programId;
  final Value<String> workoutId;
  final Value<DateTime> scheduledDate;
  final Value<int> rowid;
  const ProgramExercisesCompanion({
    this.position = const Value.absent(),
    this.programId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramExercisesCompanion.insert({
    required int position,
    required String programId,
    required String workoutId,
    required DateTime scheduledDate,
    this.rowid = const Value.absent(),
  })  : position = Value(position),
        programId = Value(programId),
        workoutId = Value(workoutId),
        scheduledDate = Value(scheduledDate);
  static Insertable<ProgramExerciseEntity> custom({
    Expression<int>? position,
    Expression<String>? programId,
    Expression<String>? workoutId,
    Expression<DateTime>? scheduledDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (position != null) 'position': position,
      if (programId != null) 'program_id': programId,
      if (workoutId != null) 'workout_id': workoutId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramExercisesCompanion copyWith(
      {Value<int>? position,
      Value<String>? programId,
      Value<String>? workoutId,
      Value<DateTime>? scheduledDate,
      Value<int>? rowid}) {
    return ProgramExercisesCompanion(
      position: position ?? this.position,
      programId: programId ?? this.programId,
      workoutId: workoutId ?? this.workoutId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramExercisesCompanion(')
          ..write('position: $position, ')
          ..write('programId: $programId, ')
          ..write('workoutId: $workoutId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSessionEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, workoutId, date, name, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<WorkoutSessionEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSessionEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSessionEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSessionEntity extends DataClass
    implements Insertable<WorkoutSessionEntity> {
  final String id;
  final String workoutId;
  final DateTime date;
  final String? name;
  final String? notes;
  const WorkoutSessionEntity(
      {required this.id,
      required this.workoutId,
      required this.date,
      this.name,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      date: Value(date),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory WorkoutSessionEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSessionEntity(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      date: serializer.fromJson<DateTime>(json['date']),
      name: serializer.fromJson<String?>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'date': serializer.toJson<DateTime>(date),
      'name': serializer.toJson<String?>(name),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutSessionEntity copyWith(
          {String? id,
          String? workoutId,
          DateTime? date,
          Value<String?> name = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      WorkoutSessionEntity(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        date: date ?? this.date,
        name: name.present ? name.value : this.name,
        notes: notes.present ? notes.value : this.notes,
      );
  WorkoutSessionEntity copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSessionEntity(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      date: data.date.present ? data.date.value : this.date,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionEntity(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId, date, name, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSessionEntity &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.date == this.date &&
          other.name == this.name &&
          other.notes == this.notes);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSessionEntity> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<DateTime> date;
  final Value<String?> name;
  final Value<String?> notes;
  final Value<int> rowid;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.date = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    required String id,
    required String workoutId,
    required DateTime date,
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutId = Value(workoutId),
        date = Value(date);
  static Insertable<WorkoutSessionEntity> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<DateTime>? date,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (date != null) 'date': date,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutId,
      Value<DateTime>? date,
      Value<String?>? name,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      date: date ?? this.date,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _primaryGoalMeta =
      const VerificationMeta('primaryGoal');
  @override
  late final GeneratedColumn<String> primaryGoal = GeneratedColumn<String>(
      'primary_goal', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _daysPerWeekMeta =
      const VerificationMeta('daysPerWeek');
  @override
  late final GeneratedColumn<int> daysPerWeek = GeneratedColumn<int>(
      'days_per_week', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sessionLengthMinutesMeta =
      const VerificationMeta('sessionLengthMinutes');
  @override
  late final GeneratedColumn<int> sessionLengthMinutes = GeneratedColumn<int>(
      'session_length_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _equipmentMeta =
      const VerificationMeta('equipment');
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
      'equipment', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _experienceLevelMeta =
      const VerificationMeta('experienceLevel');
  @override
  late final GeneratedColumn<String> experienceLevel = GeneratedColumn<String>(
      'experience_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _injuriesNotesMeta =
      const VerificationMeta('injuriesNotes');
  @override
  late final GeneratedColumn<String> injuriesNotes = GeneratedColumn<String>(
      'injuries_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _onboardingCompletedAtMeta =
      const VerificationMeta('onboardingCompletedAt');
  @override
  late final GeneratedColumn<DateTime> onboardingCompletedAt =
      GeneratedColumn<DateTime>('onboarding_completed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _blockedDaysMeta =
      const VerificationMeta('blockedDays');
  @override
  late final GeneratedColumn<String> blockedDays = GeneratedColumn<String>(
      'blocked_days', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        primaryGoal,
        daysPerWeek,
        sessionLengthMinutes,
        equipment,
        experienceLevel,
        injuriesNotes,
        weightKg,
        heightCm,
        onboardingCompletedAt,
        age,
        blockedDays
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('primary_goal')) {
      context.handle(
          _primaryGoalMeta,
          primaryGoal.isAcceptableOrUnknown(
              data['primary_goal']!, _primaryGoalMeta));
    }
    if (data.containsKey('days_per_week')) {
      context.handle(
          _daysPerWeekMeta,
          daysPerWeek.isAcceptableOrUnknown(
              data['days_per_week']!, _daysPerWeekMeta));
    }
    if (data.containsKey('session_length_minutes')) {
      context.handle(
          _sessionLengthMinutesMeta,
          sessionLengthMinutes.isAcceptableOrUnknown(
              data['session_length_minutes']!, _sessionLengthMinutesMeta));
    }
    if (data.containsKey('equipment')) {
      context.handle(_equipmentMeta,
          equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta));
    }
    if (data.containsKey('experience_level')) {
      context.handle(
          _experienceLevelMeta,
          experienceLevel.isAcceptableOrUnknown(
              data['experience_level']!, _experienceLevelMeta));
    }
    if (data.containsKey('injuries_notes')) {
      context.handle(
          _injuriesNotesMeta,
          injuriesNotes.isAcceptableOrUnknown(
              data['injuries_notes']!, _injuriesNotesMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('onboarding_completed_at')) {
      context.handle(
          _onboardingCompletedAtMeta,
          onboardingCompletedAt.isAcceptableOrUnknown(
              data['onboarding_completed_at']!, _onboardingCompletedAtMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('blocked_days')) {
      context.handle(
          _blockedDaysMeta,
          blockedDays.isAcceptableOrUnknown(
              data['blocked_days']!, _blockedDaysMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      primaryGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}primary_goal']),
      daysPerWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}days_per_week']),
      sessionLengthMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}session_length_minutes']),
      equipment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment']),
      experienceLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}experience_level']),
      injuriesNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}injuries_notes']),
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg']),
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm']),
      onboardingCompletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}onboarding_completed_at']),
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age']),
      blockedDays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blocked_days']),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfileEntity extends DataClass
    implements Insertable<UserProfileEntity> {
  final String id;
  final String? primaryGoal;
  final int? daysPerWeek;
  final int? sessionLengthMinutes;
  final String? equipment;
  final String? experienceLevel;
  final String? injuriesNotes;
  final double? weightKg;
  final double? heightCm;
  final DateTime? onboardingCompletedAt;
  final int? age;
  final String? blockedDays;
  const UserProfileEntity(
      {required this.id,
      this.primaryGoal,
      this.daysPerWeek,
      this.sessionLengthMinutes,
      this.equipment,
      this.experienceLevel,
      this.injuriesNotes,
      this.weightKg,
      this.heightCm,
      this.onboardingCompletedAt,
      this.age,
      this.blockedDays});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || primaryGoal != null) {
      map['primary_goal'] = Variable<String>(primaryGoal);
    }
    if (!nullToAbsent || daysPerWeek != null) {
      map['days_per_week'] = Variable<int>(daysPerWeek);
    }
    if (!nullToAbsent || sessionLengthMinutes != null) {
      map['session_length_minutes'] = Variable<int>(sessionLengthMinutes);
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || experienceLevel != null) {
      map['experience_level'] = Variable<String>(experienceLevel);
    }
    if (!nullToAbsent || injuriesNotes != null) {
      map['injuries_notes'] = Variable<String>(injuriesNotes);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || onboardingCompletedAt != null) {
      map['onboarding_completed_at'] =
          Variable<DateTime>(onboardingCompletedAt);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || blockedDays != null) {
      map['blocked_days'] = Variable<String>(blockedDays);
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      primaryGoal: primaryGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryGoal),
      daysPerWeek: daysPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysPerWeek),
      sessionLengthMinutes: sessionLengthMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionLengthMinutes),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      experienceLevel: experienceLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(experienceLevel),
      injuriesNotes: injuriesNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(injuriesNotes),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      onboardingCompletedAt: onboardingCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingCompletedAt),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      blockedDays: blockedDays == null && nullToAbsent
          ? const Value.absent()
          : Value(blockedDays),
    );
  }

  factory UserProfileEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileEntity(
      id: serializer.fromJson<String>(json['id']),
      primaryGoal: serializer.fromJson<String?>(json['primaryGoal']),
      daysPerWeek: serializer.fromJson<int?>(json['daysPerWeek']),
      sessionLengthMinutes:
          serializer.fromJson<int?>(json['sessionLengthMinutes']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      experienceLevel: serializer.fromJson<String?>(json['experienceLevel']),
      injuriesNotes: serializer.fromJson<String?>(json['injuriesNotes']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      onboardingCompletedAt:
          serializer.fromJson<DateTime?>(json['onboardingCompletedAt']),
      age: serializer.fromJson<int?>(json['age']),
      blockedDays: serializer.fromJson<String?>(json['blockedDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'primaryGoal': serializer.toJson<String?>(primaryGoal),
      'daysPerWeek': serializer.toJson<int?>(daysPerWeek),
      'sessionLengthMinutes': serializer.toJson<int?>(sessionLengthMinutes),
      'equipment': serializer.toJson<String?>(equipment),
      'experienceLevel': serializer.toJson<String?>(experienceLevel),
      'injuriesNotes': serializer.toJson<String?>(injuriesNotes),
      'weightKg': serializer.toJson<double?>(weightKg),
      'heightCm': serializer.toJson<double?>(heightCm),
      'onboardingCompletedAt':
          serializer.toJson<DateTime?>(onboardingCompletedAt),
      'age': serializer.toJson<int?>(age),
      'blockedDays': serializer.toJson<String?>(blockedDays),
    };
  }

  UserProfileEntity copyWith(
          {String? id,
          Value<String?> primaryGoal = const Value.absent(),
          Value<int?> daysPerWeek = const Value.absent(),
          Value<int?> sessionLengthMinutes = const Value.absent(),
          Value<String?> equipment = const Value.absent(),
          Value<String?> experienceLevel = const Value.absent(),
          Value<String?> injuriesNotes = const Value.absent(),
          Value<double?> weightKg = const Value.absent(),
          Value<double?> heightCm = const Value.absent(),
          Value<DateTime?> onboardingCompletedAt = const Value.absent(),
          Value<int?> age = const Value.absent(),
          Value<String?> blockedDays = const Value.absent()}) =>
      UserProfileEntity(
        id: id ?? this.id,
        primaryGoal: primaryGoal.present ? primaryGoal.value : this.primaryGoal,
        daysPerWeek: daysPerWeek.present ? daysPerWeek.value : this.daysPerWeek,
        sessionLengthMinutes: sessionLengthMinutes.present
            ? sessionLengthMinutes.value
            : this.sessionLengthMinutes,
        equipment: equipment.present ? equipment.value : this.equipment,
        experienceLevel: experienceLevel.present
            ? experienceLevel.value
            : this.experienceLevel,
        injuriesNotes:
            injuriesNotes.present ? injuriesNotes.value : this.injuriesNotes,
        weightKg: weightKg.present ? weightKg.value : this.weightKg,
        heightCm: heightCm.present ? heightCm.value : this.heightCm,
        onboardingCompletedAt: onboardingCompletedAt.present
            ? onboardingCompletedAt.value
            : this.onboardingCompletedAt,
        age: age.present ? age.value : this.age,
        blockedDays: blockedDays.present ? blockedDays.value : this.blockedDays,
      );
  UserProfileEntity copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileEntity(
      id: data.id.present ? data.id.value : this.id,
      primaryGoal:
          data.primaryGoal.present ? data.primaryGoal.value : this.primaryGoal,
      daysPerWeek:
          data.daysPerWeek.present ? data.daysPerWeek.value : this.daysPerWeek,
      sessionLengthMinutes: data.sessionLengthMinutes.present
          ? data.sessionLengthMinutes.value
          : this.sessionLengthMinutes,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      experienceLevel: data.experienceLevel.present
          ? data.experienceLevel.value
          : this.experienceLevel,
      injuriesNotes: data.injuriesNotes.present
          ? data.injuriesNotes.value
          : this.injuriesNotes,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      onboardingCompletedAt: data.onboardingCompletedAt.present
          ? data.onboardingCompletedAt.value
          : this.onboardingCompletedAt,
      age: data.age.present ? data.age.value : this.age,
      blockedDays:
          data.blockedDays.present ? data.blockedDays.value : this.blockedDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileEntity(')
          ..write('id: $id, ')
          ..write('primaryGoal: $primaryGoal, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('sessionLengthMinutes: $sessionLengthMinutes, ')
          ..write('equipment: $equipment, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('injuriesNotes: $injuriesNotes, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt, ')
          ..write('age: $age, ')
          ..write('blockedDays: $blockedDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      primaryGoal,
      daysPerWeek,
      sessionLengthMinutes,
      equipment,
      experienceLevel,
      injuriesNotes,
      weightKg,
      heightCm,
      onboardingCompletedAt,
      age,
      blockedDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileEntity &&
          other.id == this.id &&
          other.primaryGoal == this.primaryGoal &&
          other.daysPerWeek == this.daysPerWeek &&
          other.sessionLengthMinutes == this.sessionLengthMinutes &&
          other.equipment == this.equipment &&
          other.experienceLevel == this.experienceLevel &&
          other.injuriesNotes == this.injuriesNotes &&
          other.weightKg == this.weightKg &&
          other.heightCm == this.heightCm &&
          other.onboardingCompletedAt == this.onboardingCompletedAt &&
          other.age == this.age &&
          other.blockedDays == this.blockedDays);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileEntity> {
  final Value<String> id;
  final Value<String?> primaryGoal;
  final Value<int?> daysPerWeek;
  final Value<int?> sessionLengthMinutes;
  final Value<String?> equipment;
  final Value<String?> experienceLevel;
  final Value<String?> injuriesNotes;
  final Value<double?> weightKg;
  final Value<double?> heightCm;
  final Value<DateTime?> onboardingCompletedAt;
  final Value<int?> age;
  final Value<String?> blockedDays;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.primaryGoal = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.sessionLengthMinutes = const Value.absent(),
    this.equipment = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.injuriesNotes = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
    this.age = const Value.absent(),
    this.blockedDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    required String id,
    this.primaryGoal = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.sessionLengthMinutes = const Value.absent(),
    this.equipment = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.injuriesNotes = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
    this.age = const Value.absent(),
    this.blockedDays = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<UserProfileEntity> custom({
    Expression<String>? id,
    Expression<String>? primaryGoal,
    Expression<int>? daysPerWeek,
    Expression<int>? sessionLengthMinutes,
    Expression<String>? equipment,
    Expression<String>? experienceLevel,
    Expression<String>? injuriesNotes,
    Expression<double>? weightKg,
    Expression<double>? heightCm,
    Expression<DateTime>? onboardingCompletedAt,
    Expression<int>? age,
    Expression<String>? blockedDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (primaryGoal != null) 'primary_goal': primaryGoal,
      if (daysPerWeek != null) 'days_per_week': daysPerWeek,
      if (sessionLengthMinutes != null)
        'session_length_minutes': sessionLengthMinutes,
      if (equipment != null) 'equipment': equipment,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (injuriesNotes != null) 'injuries_notes': injuriesNotes,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at': onboardingCompletedAt,
      if (age != null) 'age': age,
      if (blockedDays != null) 'blocked_days': blockedDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? primaryGoal,
      Value<int?>? daysPerWeek,
      Value<int?>? sessionLengthMinutes,
      Value<String?>? equipment,
      Value<String?>? experienceLevel,
      Value<String?>? injuriesNotes,
      Value<double?>? weightKg,
      Value<double?>? heightCm,
      Value<DateTime?>? onboardingCompletedAt,
      Value<int?>? age,
      Value<String?>? blockedDays,
      Value<int>? rowid}) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionLengthMinutes: sessionLengthMinutes ?? this.sessionLengthMinutes,
      equipment: equipment ?? this.equipment,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      injuriesNotes: injuriesNotes ?? this.injuriesNotes,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      age: age ?? this.age,
      blockedDays: blockedDays ?? this.blockedDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (primaryGoal.present) {
      map['primary_goal'] = Variable<String>(primaryGoal.value);
    }
    if (daysPerWeek.present) {
      map['days_per_week'] = Variable<int>(daysPerWeek.value);
    }
    if (sessionLengthMinutes.present) {
      map['session_length_minutes'] = Variable<int>(sessionLengthMinutes.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (experienceLevel.present) {
      map['experience_level'] = Variable<String>(experienceLevel.value);
    }
    if (injuriesNotes.present) {
      map['injuries_notes'] = Variable<String>(injuriesNotes.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (onboardingCompletedAt.present) {
      map['onboarding_completed_at'] =
          Variable<DateTime>(onboardingCompletedAt.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (blockedDays.present) {
      map['blocked_days'] = Variable<String>(blockedDays.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('primaryGoal: $primaryGoal, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('sessionLengthMinutes: $sessionLengthMinutes, ')
          ..write('equipment: $equipment, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('injuriesNotes: $injuriesNotes, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt, ')
          ..write('age: $age, ')
          ..write('blockedDays: $blockedDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserScorecardsTable extends UserScorecards
    with TableInfo<$UserScorecardsTable, UserScorecardEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserScorecardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _consistencyMeta =
      const VerificationMeta('consistency');
  @override
  late final GeneratedColumn<double> consistency = GeneratedColumn<double>(
      'consistency', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _progressionMeta =
      const VerificationMeta('progression');
  @override
  late final GeneratedColumn<double> progression = GeneratedColumn<double>(
      'progression', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(3.0));
  static const VerificationMeta _enduranceMeta =
      const VerificationMeta('endurance');
  @override
  late final GeneratedColumn<double> endurance = GeneratedColumn<double>(
      'endurance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(3.0));
  static const VerificationMeta _varietyMeta =
      const VerificationMeta('variety');
  @override
  late final GeneratedColumn<double> variety = GeneratedColumn<double>(
      'variety', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _fundamentalsMeta =
      const VerificationMeta('fundamentals');
  @override
  late final GeneratedColumn<double> fundamentals = GeneratedColumn<double>(
      'fundamentals', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _selfAwarenessMeta =
      const VerificationMeta('selfAwareness');
  @override
  late final GeneratedColumn<double> selfAwareness = GeneratedColumn<double>(
      'self_awareness', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _curiosityMeta =
      const VerificationMeta('curiosity');
  @override
  late final GeneratedColumn<double> curiosity = GeneratedColumn<double>(
      'curiosity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _reliabilityMeta =
      const VerificationMeta('reliability');
  @override
  late final GeneratedColumn<double> reliability = GeneratedColumn<double>(
      'reliability', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _adaptabilityMeta =
      const VerificationMeta('adaptability');
  @override
  late final GeneratedColumn<double> adaptability = GeneratedColumn<double>(
      'adaptability', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _independenceMeta =
      const VerificationMeta('independence');
  @override
  late final GeneratedColumn<double> independence = GeneratedColumn<double>(
      'independence', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(3.0));
  static const VerificationMeta _computedLevelMeta =
      const VerificationMeta('computedLevel');
  @override
  late final GeneratedColumn<int> computedLevel = GeneratedColumn<int>(
      'computed_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        consistency,
        progression,
        endurance,
        variety,
        fundamentals,
        selfAwareness,
        curiosity,
        reliability,
        adaptability,
        independence,
        computedLevel,
        lastUpdated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_scorecards';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserScorecardEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('consistency')) {
      context.handle(
          _consistencyMeta,
          consistency.isAcceptableOrUnknown(
              data['consistency']!, _consistencyMeta));
    }
    if (data.containsKey('progression')) {
      context.handle(
          _progressionMeta,
          progression.isAcceptableOrUnknown(
              data['progression']!, _progressionMeta));
    }
    if (data.containsKey('endurance')) {
      context.handle(_enduranceMeta,
          endurance.isAcceptableOrUnknown(data['endurance']!, _enduranceMeta));
    }
    if (data.containsKey('variety')) {
      context.handle(_varietyMeta,
          variety.isAcceptableOrUnknown(data['variety']!, _varietyMeta));
    }
    if (data.containsKey('fundamentals')) {
      context.handle(
          _fundamentalsMeta,
          fundamentals.isAcceptableOrUnknown(
              data['fundamentals']!, _fundamentalsMeta));
    }
    if (data.containsKey('self_awareness')) {
      context.handle(
          _selfAwarenessMeta,
          selfAwareness.isAcceptableOrUnknown(
              data['self_awareness']!, _selfAwarenessMeta));
    }
    if (data.containsKey('curiosity')) {
      context.handle(_curiosityMeta,
          curiosity.isAcceptableOrUnknown(data['curiosity']!, _curiosityMeta));
    }
    if (data.containsKey('reliability')) {
      context.handle(
          _reliabilityMeta,
          reliability.isAcceptableOrUnknown(
              data['reliability']!, _reliabilityMeta));
    }
    if (data.containsKey('adaptability')) {
      context.handle(
          _adaptabilityMeta,
          adaptability.isAcceptableOrUnknown(
              data['adaptability']!, _adaptabilityMeta));
    }
    if (data.containsKey('independence')) {
      context.handle(
          _independenceMeta,
          independence.isAcceptableOrUnknown(
              data['independence']!, _independenceMeta));
    }
    if (data.containsKey('computed_level')) {
      context.handle(
          _computedLevelMeta,
          computedLevel.isAcceptableOrUnknown(
              data['computed_level']!, _computedLevelMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserScorecardEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserScorecardEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      consistency: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}consistency'])!,
      progression: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progression'])!,
      endurance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}endurance'])!,
      variety: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}variety'])!,
      fundamentals: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fundamentals'])!,
      selfAwareness: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}self_awareness'])!,
      curiosity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}curiosity'])!,
      reliability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reliability'])!,
      adaptability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}adaptability'])!,
      independence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}independence'])!,
      computedLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}computed_level'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $UserScorecardsTable createAlias(String alias) {
    return $UserScorecardsTable(attachedDatabase, alias);
  }
}

class UserScorecardEntity extends DataClass
    implements Insertable<UserScorecardEntity> {
  final String id;
  final double consistency;
  final double progression;
  final double endurance;
  final double variety;
  final double fundamentals;
  final double selfAwareness;
  final double curiosity;
  final double reliability;
  final double adaptability;
  final double independence;
  final int computedLevel;
  final DateTime? lastUpdated;
  const UserScorecardEntity(
      {required this.id,
      required this.consistency,
      required this.progression,
      required this.endurance,
      required this.variety,
      required this.fundamentals,
      required this.selfAwareness,
      required this.curiosity,
      required this.reliability,
      required this.adaptability,
      required this.independence,
      required this.computedLevel,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['consistency'] = Variable<double>(consistency);
    map['progression'] = Variable<double>(progression);
    map['endurance'] = Variable<double>(endurance);
    map['variety'] = Variable<double>(variety);
    map['fundamentals'] = Variable<double>(fundamentals);
    map['self_awareness'] = Variable<double>(selfAwareness);
    map['curiosity'] = Variable<double>(curiosity);
    map['reliability'] = Variable<double>(reliability);
    map['adaptability'] = Variable<double>(adaptability);
    map['independence'] = Variable<double>(independence);
    map['computed_level'] = Variable<int>(computedLevel);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  UserScorecardsCompanion toCompanion(bool nullToAbsent) {
    return UserScorecardsCompanion(
      id: Value(id),
      consistency: Value(consistency),
      progression: Value(progression),
      endurance: Value(endurance),
      variety: Value(variety),
      fundamentals: Value(fundamentals),
      selfAwareness: Value(selfAwareness),
      curiosity: Value(curiosity),
      reliability: Value(reliability),
      adaptability: Value(adaptability),
      independence: Value(independence),
      computedLevel: Value(computedLevel),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory UserScorecardEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserScorecardEntity(
      id: serializer.fromJson<String>(json['id']),
      consistency: serializer.fromJson<double>(json['consistency']),
      progression: serializer.fromJson<double>(json['progression']),
      endurance: serializer.fromJson<double>(json['endurance']),
      variety: serializer.fromJson<double>(json['variety']),
      fundamentals: serializer.fromJson<double>(json['fundamentals']),
      selfAwareness: serializer.fromJson<double>(json['selfAwareness']),
      curiosity: serializer.fromJson<double>(json['curiosity']),
      reliability: serializer.fromJson<double>(json['reliability']),
      adaptability: serializer.fromJson<double>(json['adaptability']),
      independence: serializer.fromJson<double>(json['independence']),
      computedLevel: serializer.fromJson<int>(json['computedLevel']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'consistency': serializer.toJson<double>(consistency),
      'progression': serializer.toJson<double>(progression),
      'endurance': serializer.toJson<double>(endurance),
      'variety': serializer.toJson<double>(variety),
      'fundamentals': serializer.toJson<double>(fundamentals),
      'selfAwareness': serializer.toJson<double>(selfAwareness),
      'curiosity': serializer.toJson<double>(curiosity),
      'reliability': serializer.toJson<double>(reliability),
      'adaptability': serializer.toJson<double>(adaptability),
      'independence': serializer.toJson<double>(independence),
      'computedLevel': serializer.toJson<int>(computedLevel),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  UserScorecardEntity copyWith(
          {String? id,
          double? consistency,
          double? progression,
          double? endurance,
          double? variety,
          double? fundamentals,
          double? selfAwareness,
          double? curiosity,
          double? reliability,
          double? adaptability,
          double? independence,
          int? computedLevel,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      UserScorecardEntity(
        id: id ?? this.id,
        consistency: consistency ?? this.consistency,
        progression: progression ?? this.progression,
        endurance: endurance ?? this.endurance,
        variety: variety ?? this.variety,
        fundamentals: fundamentals ?? this.fundamentals,
        selfAwareness: selfAwareness ?? this.selfAwareness,
        curiosity: curiosity ?? this.curiosity,
        reliability: reliability ?? this.reliability,
        adaptability: adaptability ?? this.adaptability,
        independence: independence ?? this.independence,
        computedLevel: computedLevel ?? this.computedLevel,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  UserScorecardEntity copyWithCompanion(UserScorecardsCompanion data) {
    return UserScorecardEntity(
      id: data.id.present ? data.id.value : this.id,
      consistency:
          data.consistency.present ? data.consistency.value : this.consistency,
      progression:
          data.progression.present ? data.progression.value : this.progression,
      endurance: data.endurance.present ? data.endurance.value : this.endurance,
      variety: data.variety.present ? data.variety.value : this.variety,
      fundamentals: data.fundamentals.present
          ? data.fundamentals.value
          : this.fundamentals,
      selfAwareness: data.selfAwareness.present
          ? data.selfAwareness.value
          : this.selfAwareness,
      curiosity: data.curiosity.present ? data.curiosity.value : this.curiosity,
      reliability:
          data.reliability.present ? data.reliability.value : this.reliability,
      adaptability: data.adaptability.present
          ? data.adaptability.value
          : this.adaptability,
      independence: data.independence.present
          ? data.independence.value
          : this.independence,
      computedLevel: data.computedLevel.present
          ? data.computedLevel.value
          : this.computedLevel,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserScorecardEntity(')
          ..write('id: $id, ')
          ..write('consistency: $consistency, ')
          ..write('progression: $progression, ')
          ..write('endurance: $endurance, ')
          ..write('variety: $variety, ')
          ..write('fundamentals: $fundamentals, ')
          ..write('selfAwareness: $selfAwareness, ')
          ..write('curiosity: $curiosity, ')
          ..write('reliability: $reliability, ')
          ..write('adaptability: $adaptability, ')
          ..write('independence: $independence, ')
          ..write('computedLevel: $computedLevel, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      consistency,
      progression,
      endurance,
      variety,
      fundamentals,
      selfAwareness,
      curiosity,
      reliability,
      adaptability,
      independence,
      computedLevel,
      lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserScorecardEntity &&
          other.id == this.id &&
          other.consistency == this.consistency &&
          other.progression == this.progression &&
          other.endurance == this.endurance &&
          other.variety == this.variety &&
          other.fundamentals == this.fundamentals &&
          other.selfAwareness == this.selfAwareness &&
          other.curiosity == this.curiosity &&
          other.reliability == this.reliability &&
          other.adaptability == this.adaptability &&
          other.independence == this.independence &&
          other.computedLevel == this.computedLevel &&
          other.lastUpdated == this.lastUpdated);
}

class UserScorecardsCompanion extends UpdateCompanion<UserScorecardEntity> {
  final Value<String> id;
  final Value<double> consistency;
  final Value<double> progression;
  final Value<double> endurance;
  final Value<double> variety;
  final Value<double> fundamentals;
  final Value<double> selfAwareness;
  final Value<double> curiosity;
  final Value<double> reliability;
  final Value<double> adaptability;
  final Value<double> independence;
  final Value<int> computedLevel;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const UserScorecardsCompanion({
    this.id = const Value.absent(),
    this.consistency = const Value.absent(),
    this.progression = const Value.absent(),
    this.endurance = const Value.absent(),
    this.variety = const Value.absent(),
    this.fundamentals = const Value.absent(),
    this.selfAwareness = const Value.absent(),
    this.curiosity = const Value.absent(),
    this.reliability = const Value.absent(),
    this.adaptability = const Value.absent(),
    this.independence = const Value.absent(),
    this.computedLevel = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserScorecardsCompanion.insert({
    required String id,
    this.consistency = const Value.absent(),
    this.progression = const Value.absent(),
    this.endurance = const Value.absent(),
    this.variety = const Value.absent(),
    this.fundamentals = const Value.absent(),
    this.selfAwareness = const Value.absent(),
    this.curiosity = const Value.absent(),
    this.reliability = const Value.absent(),
    this.adaptability = const Value.absent(),
    this.independence = const Value.absent(),
    this.computedLevel = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<UserScorecardEntity> custom({
    Expression<String>? id,
    Expression<double>? consistency,
    Expression<double>? progression,
    Expression<double>? endurance,
    Expression<double>? variety,
    Expression<double>? fundamentals,
    Expression<double>? selfAwareness,
    Expression<double>? curiosity,
    Expression<double>? reliability,
    Expression<double>? adaptability,
    Expression<double>? independence,
    Expression<int>? computedLevel,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (consistency != null) 'consistency': consistency,
      if (progression != null) 'progression': progression,
      if (endurance != null) 'endurance': endurance,
      if (variety != null) 'variety': variety,
      if (fundamentals != null) 'fundamentals': fundamentals,
      if (selfAwareness != null) 'self_awareness': selfAwareness,
      if (curiosity != null) 'curiosity': curiosity,
      if (reliability != null) 'reliability': reliability,
      if (adaptability != null) 'adaptability': adaptability,
      if (independence != null) 'independence': independence,
      if (computedLevel != null) 'computed_level': computedLevel,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserScorecardsCompanion copyWith(
      {Value<String>? id,
      Value<double>? consistency,
      Value<double>? progression,
      Value<double>? endurance,
      Value<double>? variety,
      Value<double>? fundamentals,
      Value<double>? selfAwareness,
      Value<double>? curiosity,
      Value<double>? reliability,
      Value<double>? adaptability,
      Value<double>? independence,
      Value<int>? computedLevel,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return UserScorecardsCompanion(
      id: id ?? this.id,
      consistency: consistency ?? this.consistency,
      progression: progression ?? this.progression,
      endurance: endurance ?? this.endurance,
      variety: variety ?? this.variety,
      fundamentals: fundamentals ?? this.fundamentals,
      selfAwareness: selfAwareness ?? this.selfAwareness,
      curiosity: curiosity ?? this.curiosity,
      reliability: reliability ?? this.reliability,
      adaptability: adaptability ?? this.adaptability,
      independence: independence ?? this.independence,
      computedLevel: computedLevel ?? this.computedLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (consistency.present) {
      map['consistency'] = Variable<double>(consistency.value);
    }
    if (progression.present) {
      map['progression'] = Variable<double>(progression.value);
    }
    if (endurance.present) {
      map['endurance'] = Variable<double>(endurance.value);
    }
    if (variety.present) {
      map['variety'] = Variable<double>(variety.value);
    }
    if (fundamentals.present) {
      map['fundamentals'] = Variable<double>(fundamentals.value);
    }
    if (selfAwareness.present) {
      map['self_awareness'] = Variable<double>(selfAwareness.value);
    }
    if (curiosity.present) {
      map['curiosity'] = Variable<double>(curiosity.value);
    }
    if (reliability.present) {
      map['reliability'] = Variable<double>(reliability.value);
    }
    if (adaptability.present) {
      map['adaptability'] = Variable<double>(adaptability.value);
    }
    if (independence.present) {
      map['independence'] = Variable<double>(independence.value);
    }
    if (computedLevel.present) {
      map['computed_level'] = Variable<int>(computedLevel.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserScorecardsCompanion(')
          ..write('id: $id, ')
          ..write('consistency: $consistency, ')
          ..write('progression: $progression, ')
          ..write('endurance: $endurance, ')
          ..write('variety: $variety, ')
          ..write('fundamentals: $fundamentals, ')
          ..write('selfAwareness: $selfAwareness, ')
          ..write('curiosity: $curiosity, ')
          ..write('reliability: $reliability, ')
          ..write('adaptability: $adaptability, ')
          ..write('independence: $independence, ')
          ..write('computedLevel: $computedLevel, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionCheckInsTable extends SessionCheckIns
    with TableInfo<$SessionCheckInsTable, SessionCheckInEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionCheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _programmeIdMeta =
      const VerificationMeta('programmeId');
  @override
  late final GeneratedColumn<String> programmeId = GeneratedColumn<String>(
      'programme_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkInTypeMeta =
      const VerificationMeta('checkInType');
  @override
  late final GeneratedColumn<String> checkInType = GeneratedColumn<String>(
      'check_in_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
      'rating', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _freeTextMeta =
      const VerificationMeta('freeText');
  @override
  late final GeneratedColumn<String> freeText = GeneratedColumn<String>(
      'free_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, programmeId, checkInType, rating, freeText, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_check_ins';
  @override
  VerificationContext validateIntegrity(
      Insertable<SessionCheckInEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('programme_id')) {
      context.handle(
          _programmeIdMeta,
          programmeId.isAcceptableOrUnknown(
              data['programme_id']!, _programmeIdMeta));
    }
    if (data.containsKey('check_in_type')) {
      context.handle(
          _checkInTypeMeta,
          checkInType.isAcceptableOrUnknown(
              data['check_in_type']!, _checkInTypeMeta));
    } else if (isInserting) {
      context.missing(_checkInTypeMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('free_text')) {
      context.handle(_freeTextMeta,
          freeText.isAcceptableOrUnknown(data['free_text']!, _freeTextMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionCheckInEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionCheckInEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      programmeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}programme_id']),
      checkInType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_in_type'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rating'])!,
      freeText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}free_text']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SessionCheckInsTable createAlias(String alias) {
    return $SessionCheckInsTable(attachedDatabase, alias);
  }
}

class SessionCheckInEntity extends DataClass
    implements Insertable<SessionCheckInEntity> {
  final String id;
  final String? sessionId;
  final String? programmeId;
  final String checkInType;
  final String rating;
  final String? freeText;
  final DateTime createdAt;
  const SessionCheckInEntity(
      {required this.id,
      this.sessionId,
      this.programmeId,
      required this.checkInType,
      required this.rating,
      this.freeText,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || programmeId != null) {
      map['programme_id'] = Variable<String>(programmeId);
    }
    map['check_in_type'] = Variable<String>(checkInType);
    map['rating'] = Variable<String>(rating);
    if (!nullToAbsent || freeText != null) {
      map['free_text'] = Variable<String>(freeText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SessionCheckInsCompanion toCompanion(bool nullToAbsent) {
    return SessionCheckInsCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      programmeId: programmeId == null && nullToAbsent
          ? const Value.absent()
          : Value(programmeId),
      checkInType: Value(checkInType),
      rating: Value(rating),
      freeText: freeText == null && nullToAbsent
          ? const Value.absent()
          : Value(freeText),
      createdAt: Value(createdAt),
    );
  }

  factory SessionCheckInEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionCheckInEntity(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      programmeId: serializer.fromJson<String?>(json['programmeId']),
      checkInType: serializer.fromJson<String>(json['checkInType']),
      rating: serializer.fromJson<String>(json['rating']),
      freeText: serializer.fromJson<String?>(json['freeText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String?>(sessionId),
      'programmeId': serializer.toJson<String?>(programmeId),
      'checkInType': serializer.toJson<String>(checkInType),
      'rating': serializer.toJson<String>(rating),
      'freeText': serializer.toJson<String?>(freeText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SessionCheckInEntity copyWith(
          {String? id,
          Value<String?> sessionId = const Value.absent(),
          Value<String?> programmeId = const Value.absent(),
          String? checkInType,
          String? rating,
          Value<String?> freeText = const Value.absent(),
          DateTime? createdAt}) =>
      SessionCheckInEntity(
        id: id ?? this.id,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        programmeId: programmeId.present ? programmeId.value : this.programmeId,
        checkInType: checkInType ?? this.checkInType,
        rating: rating ?? this.rating,
        freeText: freeText.present ? freeText.value : this.freeText,
        createdAt: createdAt ?? this.createdAt,
      );
  SessionCheckInEntity copyWithCompanion(SessionCheckInsCompanion data) {
    return SessionCheckInEntity(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      programmeId:
          data.programmeId.present ? data.programmeId.value : this.programmeId,
      checkInType:
          data.checkInType.present ? data.checkInType.value : this.checkInType,
      rating: data.rating.present ? data.rating.value : this.rating,
      freeText: data.freeText.present ? data.freeText.value : this.freeText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionCheckInEntity(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('programmeId: $programmeId, ')
          ..write('checkInType: $checkInType, ')
          ..write('rating: $rating, ')
          ..write('freeText: $freeText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionId, programmeId, checkInType, rating, freeText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionCheckInEntity &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.programmeId == this.programmeId &&
          other.checkInType == this.checkInType &&
          other.rating == this.rating &&
          other.freeText == this.freeText &&
          other.createdAt == this.createdAt);
}

class SessionCheckInsCompanion extends UpdateCompanion<SessionCheckInEntity> {
  final Value<String> id;
  final Value<String?> sessionId;
  final Value<String?> programmeId;
  final Value<String> checkInType;
  final Value<String> rating;
  final Value<String?> freeText;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SessionCheckInsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.programmeId = const Value.absent(),
    this.checkInType = const Value.absent(),
    this.rating = const Value.absent(),
    this.freeText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionCheckInsCompanion.insert({
    required String id,
    this.sessionId = const Value.absent(),
    this.programmeId = const Value.absent(),
    required String checkInType,
    required String rating,
    this.freeText = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        checkInType = Value(checkInType),
        rating = Value(rating),
        createdAt = Value(createdAt);
  static Insertable<SessionCheckInEntity> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? programmeId,
    Expression<String>? checkInType,
    Expression<String>? rating,
    Expression<String>? freeText,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (programmeId != null) 'programme_id': programmeId,
      if (checkInType != null) 'check_in_type': checkInType,
      if (rating != null) 'rating': rating,
      if (freeText != null) 'free_text': freeText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionCheckInsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? sessionId,
      Value<String?>? programmeId,
      Value<String>? checkInType,
      Value<String>? rating,
      Value<String?>? freeText,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SessionCheckInsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      programmeId: programmeId ?? this.programmeId,
      checkInType: checkInType ?? this.checkInType,
      rating: rating ?? this.rating,
      freeText: freeText ?? this.freeText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (programmeId.present) {
      map['programme_id'] = Variable<String>(programmeId.value);
    }
    if (checkInType.present) {
      map['check_in_type'] = Variable<String>(checkInType.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (freeText.present) {
      map['free_text'] = Variable<String>(freeText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionCheckInsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('programmeId: $programmeId, ')
          ..write('checkInType: $checkInType, ')
          ..write('rating: $rating, ')
          ..write('freeText: $freeText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $ExerciseFavoritesTable exerciseFavorites =
      $ExerciseFavoritesTable(this);
  late final $WorkoutEntriesTable workoutEntries = $WorkoutEntriesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutExercisesTable workoutExercises =
      $WorkoutExercisesTable(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $ProgramExercisesTable programExercises =
      $ProgramExercisesTable(this);
  late final $WorkoutSessionsTable workoutSessions =
      $WorkoutSessionsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $UserScorecardsTable userScorecards = $UserScorecardsTable(this);
  late final $SessionCheckInsTable sessionCheckIns =
      $SessionCheckInsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        exercises,
        exerciseFavorites,
        workoutEntries,
        workouts,
        workoutExercises,
        programs,
        programExercises,
        workoutSessions,
        userProfiles,
        userScorecards,
        sessionCheckIns
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('exercises',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('exercise_favorites', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workouts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('workout_exercises', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('programs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('program_exercises', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String name,
  Value<String> description,
  Value<String?> thumbnailPath,
  Value<String?> mediaPath,
  Value<String?> bodyPart,
  Value<String?> equipment,
  Value<String?> loggingType,
  Value<String?> movementPattern,
  Value<int> safetyTier,
  Value<String?> laterality,
  Value<String> systemicFatigue,
  Value<String?> suitability,
  Value<String?> regressionId,
  Value<String?> progressionId,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<String?> thumbnailPath,
  Value<String?> mediaPath,
  Value<String?> bodyPart,
  Value<String?> equipment,
  Value<String?> loggingType,
  Value<String?> movementPattern,
  Value<int> safetyTier,
  Value<String?> laterality,
  Value<String> systemicFatigue,
  Value<String?> suitability,
  Value<String?> regressionId,
  Value<String?> progressionId,
  Value<int> rowid,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, ExerciseEntity> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseFavoritesTable,
      List<ExerciseFavoriteEntity>> _exerciseFavoritesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.exerciseFavorites,
          aliasName: $_aliasNameGenerator(
              db.exercises.id, db.exerciseFavorites.exerciseId));

  $$ExerciseFavoritesTableProcessedTableManager get exerciseFavoritesRefs {
    final manager = $$ExerciseFavoritesTableTableManager(
            $_db, $_db.exerciseFavorites)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_exerciseFavoritesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutEntriesTable, List<WorkoutEntryEntity>>
      _workoutEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutEntries,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.workoutEntries.exerciseId));

  $$WorkoutEntriesTableProcessedTableManager get workoutEntriesRefs {
    final manager = $$WorkoutEntriesTableTableManager($_db, $_db.workoutEntries)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutExercisesTable,
      List<WorkoutExerciseEntity>> _workoutExercisesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutExercises,
          aliasName: $_aliasNameGenerator(
              db.exercises.id, db.workoutExercises.exerciseId));

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
            $_db, $_db.workoutExercises)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyPart => $composableBuilder(
      column: $table.bodyPart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loggingType => $composableBuilder(
      column: $table.loggingType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movementPattern => $composableBuilder(
      column: $table.movementPattern,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get safetyTier => $composableBuilder(
      column: $table.safetyTier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get laterality => $composableBuilder(
      column: $table.laterality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemicFatigue => $composableBuilder(
      column: $table.systemicFatigue,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get suitability => $composableBuilder(
      column: $table.suitability, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regressionId => $composableBuilder(
      column: $table.regressionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get progressionId => $composableBuilder(
      column: $table.progressionId, builder: (column) => ColumnFilters(column));

  Expression<bool> exerciseFavoritesRefs(
      Expression<bool> Function($$ExerciseFavoritesTableFilterComposer f) f) {
    final $$ExerciseFavoritesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseFavorites,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseFavoritesTableFilterComposer(
              $db: $db,
              $table: $db.exerciseFavorites,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutEntriesRefs(
      Expression<bool> Function($$WorkoutEntriesTableFilterComposer f) f) {
    final $$WorkoutEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutEntries,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutEntriesTableFilterComposer(
              $db: $db,
              $table: $db.workoutEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutExercisesRefs(
      Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutExercises,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutExercisesTableFilterComposer(
              $db: $db,
              $table: $db.workoutExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyPart => $composableBuilder(
      column: $table.bodyPart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loggingType => $composableBuilder(
      column: $table.loggingType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movementPattern => $composableBuilder(
      column: $table.movementPattern,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get safetyTier => $composableBuilder(
      column: $table.safetyTier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get laterality => $composableBuilder(
      column: $table.laterality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemicFatigue => $composableBuilder(
      column: $table.systemicFatigue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get suitability => $composableBuilder(
      column: $table.suitability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regressionId => $composableBuilder(
      column: $table.regressionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get progressionId => $composableBuilder(
      column: $table.progressionId,
      builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get bodyPart =>
      $composableBuilder(column: $table.bodyPart, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get loggingType => $composableBuilder(
      column: $table.loggingType, builder: (column) => column);

  GeneratedColumn<String> get movementPattern => $composableBuilder(
      column: $table.movementPattern, builder: (column) => column);

  GeneratedColumn<int> get safetyTier => $composableBuilder(
      column: $table.safetyTier, builder: (column) => column);

  GeneratedColumn<String> get laterality => $composableBuilder(
      column: $table.laterality, builder: (column) => column);

  GeneratedColumn<String> get systemicFatigue => $composableBuilder(
      column: $table.systemicFatigue, builder: (column) => column);

  GeneratedColumn<String> get suitability => $composableBuilder(
      column: $table.suitability, builder: (column) => column);

  GeneratedColumn<String> get regressionId => $composableBuilder(
      column: $table.regressionId, builder: (column) => column);

  GeneratedColumn<String> get progressionId => $composableBuilder(
      column: $table.progressionId, builder: (column) => column);

  Expression<T> exerciseFavoritesRefs<T extends Object>(
      Expression<T> Function($$ExerciseFavoritesTableAnnotationComposer a) f) {
    final $$ExerciseFavoritesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.exerciseFavorites,
            getReferencedColumn: (t) => t.exerciseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ExerciseFavoritesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.exerciseFavorites,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> workoutEntriesRefs<T extends Object>(
      Expression<T> Function($$WorkoutEntriesTableAnnotationComposer a) f) {
    final $$WorkoutEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutEntries,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutExercisesRefs<T extends Object>(
      Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutExercises,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    ExerciseEntity,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (ExerciseEntity, $$ExercisesTableReferences),
    ExerciseEntity,
    PrefetchHooks Function(
        {bool exerciseFavoritesRefs,
        bool workoutEntriesRefs,
        bool workoutExercisesRefs})> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            Value<String?> bodyPart = const Value.absent(),
            Value<String?> equipment = const Value.absent(),
            Value<String?> loggingType = const Value.absent(),
            Value<String?> movementPattern = const Value.absent(),
            Value<int> safetyTier = const Value.absent(),
            Value<String?> laterality = const Value.absent(),
            Value<String> systemicFatigue = const Value.absent(),
            Value<String?> suitability = const Value.absent(),
            Value<String?> regressionId = const Value.absent(),
            Value<String?> progressionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            name: name,
            description: description,
            thumbnailPath: thumbnailPath,
            mediaPath: mediaPath,
            bodyPart: bodyPart,
            equipment: equipment,
            loggingType: loggingType,
            movementPattern: movementPattern,
            safetyTier: safetyTier,
            laterality: laterality,
            systemicFatigue: systemicFatigue,
            suitability: suitability,
            regressionId: regressionId,
            progressionId: progressionId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> description = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            Value<String?> bodyPart = const Value.absent(),
            Value<String?> equipment = const Value.absent(),
            Value<String?> loggingType = const Value.absent(),
            Value<String?> movementPattern = const Value.absent(),
            Value<int> safetyTier = const Value.absent(),
            Value<String?> laterality = const Value.absent(),
            Value<String> systemicFatigue = const Value.absent(),
            Value<String?> suitability = const Value.absent(),
            Value<String?> regressionId = const Value.absent(),
            Value<String?> progressionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            name: name,
            description: description,
            thumbnailPath: thumbnailPath,
            mediaPath: mediaPath,
            bodyPart: bodyPart,
            equipment: equipment,
            loggingType: loggingType,
            movementPattern: movementPattern,
            safetyTier: safetyTier,
            laterality: laterality,
            systemicFatigue: systemicFatigue,
            suitability: suitability,
            regressionId: regressionId,
            progressionId: progressionId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {exerciseFavoritesRefs = false,
              workoutEntriesRefs = false,
              workoutExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exerciseFavoritesRefs) db.exerciseFavorites,
                if (workoutEntriesRefs) db.workoutEntries,
                if (workoutExercisesRefs) db.workoutExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseFavoritesRefs)
                    await $_getPrefetchedData<ExerciseEntity, $ExercisesTable,
                            ExerciseFavoriteEntity>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._exerciseFavoritesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .exerciseFavoritesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (workoutEntriesRefs)
                    await $_getPrefetchedData<ExerciseEntity, $ExercisesTable,
                            WorkoutEntryEntity>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._workoutEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .workoutEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (workoutExercisesRefs)
                    await $_getPrefetchedData<ExerciseEntity, $ExercisesTable,
                            WorkoutExerciseEntity>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._workoutExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .workoutExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    ExerciseEntity,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (ExerciseEntity, $$ExercisesTableReferences),
    ExerciseEntity,
    PrefetchHooks Function(
        {bool exerciseFavoritesRefs,
        bool workoutEntriesRefs,
        bool workoutExercisesRefs})>;
typedef $$ExerciseFavoritesTableCreateCompanionBuilder
    = ExerciseFavoritesCompanion Function({
  required String exerciseId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ExerciseFavoritesTableUpdateCompanionBuilder
    = ExerciseFavoritesCompanion Function({
  Value<String> exerciseId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ExerciseFavoritesTableReferences extends BaseReferences<
    _$AppDatabase, $ExerciseFavoritesTable, ExerciseFavoriteEntity> {
  $$ExerciseFavoritesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias($_aliasNameGenerator(
          db.exerciseFavorites.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExerciseFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseFavoritesTable> {
  $$ExerciseFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseFavoritesTable> {
  $$ExerciseFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseFavoritesTable> {
  $$ExerciseFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseFavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExerciseFavoritesTable,
    ExerciseFavoriteEntity,
    $$ExerciseFavoritesTableFilterComposer,
    $$ExerciseFavoritesTableOrderingComposer,
    $$ExerciseFavoritesTableAnnotationComposer,
    $$ExerciseFavoritesTableCreateCompanionBuilder,
    $$ExerciseFavoritesTableUpdateCompanionBuilder,
    (ExerciseFavoriteEntity, $$ExerciseFavoritesTableReferences),
    ExerciseFavoriteEntity,
    PrefetchHooks Function({bool exerciseId})> {
  $$ExerciseFavoritesTableTableManager(
      _$AppDatabase db, $ExerciseFavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseFavoritesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> exerciseId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExerciseFavoritesCompanion(
            exerciseId: exerciseId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String exerciseId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExerciseFavoritesCompanion.insert(
            exerciseId: exerciseId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExerciseFavoritesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$ExerciseFavoritesTableReferences._exerciseIdTable(db),
                    referencedColumn: $$ExerciseFavoritesTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExerciseFavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExerciseFavoritesTable,
    ExerciseFavoriteEntity,
    $$ExerciseFavoritesTableFilterComposer,
    $$ExerciseFavoritesTableOrderingComposer,
    $$ExerciseFavoritesTableAnnotationComposer,
    $$ExerciseFavoritesTableCreateCompanionBuilder,
    $$ExerciseFavoritesTableUpdateCompanionBuilder,
    (ExerciseFavoriteEntity, $$ExerciseFavoritesTableReferences),
    ExerciseFavoriteEntity,
    PrefetchHooks Function({bool exerciseId})>;
typedef $$WorkoutEntriesTableCreateCompanionBuilder = WorkoutEntriesCompanion
    Function({
  required String id,
  required String exerciseId,
  required int reps,
  required double weight,
  Value<double?> distance,
  Value<int?> duration,
  Value<bool> isComplete,
  Value<DateTime?> timestamp,
  Value<String?> sessionId,
  Value<String?> setOutcome,
  Value<String?> supersetGroupId,
  Value<int> rowid,
});
typedef $$WorkoutEntriesTableUpdateCompanionBuilder = WorkoutEntriesCompanion
    Function({
  Value<String> id,
  Value<String> exerciseId,
  Value<int> reps,
  Value<double> weight,
  Value<double?> distance,
  Value<int?> duration,
  Value<bool> isComplete,
  Value<DateTime?> timestamp,
  Value<String?> sessionId,
  Value<String?> setOutcome,
  Value<String?> supersetGroupId,
  Value<int> rowid,
});

final class $$WorkoutEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutEntriesTable, WorkoutEntryEntity> {
  $$WorkoutEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.workoutEntries.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutEntriesTable> {
  $$WorkoutEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isComplete => $composableBuilder(
      column: $table.isComplete, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setOutcome => $composableBuilder(
      column: $table.setOutcome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnFilters(column));

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutEntriesTable> {
  $$WorkoutEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isComplete => $composableBuilder(
      column: $table.isComplete, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setOutcome => $composableBuilder(
      column: $table.setOutcome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnOrderings(column));

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutEntriesTable> {
  $$WorkoutEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
      column: $table.isComplete, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get setOutcome => $composableBuilder(
      column: $table.setOutcome, builder: (column) => column);

  GeneratedColumn<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutEntriesTable,
    WorkoutEntryEntity,
    $$WorkoutEntriesTableFilterComposer,
    $$WorkoutEntriesTableOrderingComposer,
    $$WorkoutEntriesTableAnnotationComposer,
    $$WorkoutEntriesTableCreateCompanionBuilder,
    $$WorkoutEntriesTableUpdateCompanionBuilder,
    (WorkoutEntryEntity, $$WorkoutEntriesTableReferences),
    WorkoutEntryEntity,
    PrefetchHooks Function({bool exerciseId})> {
  $$WorkoutEntriesTableTableManager(
      _$AppDatabase db, $WorkoutEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<double?> distance = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<bool> isComplete = const Value.absent(),
            Value<DateTime?> timestamp = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String?> setOutcome = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutEntriesCompanion(
            id: id,
            exerciseId: exerciseId,
            reps: reps,
            weight: weight,
            distance: distance,
            duration: duration,
            isComplete: isComplete,
            timestamp: timestamp,
            sessionId: sessionId,
            setOutcome: setOutcome,
            supersetGroupId: supersetGroupId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String exerciseId,
            required int reps,
            required double weight,
            Value<double?> distance = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<bool> isComplete = const Value.absent(),
            Value<DateTime?> timestamp = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String?> setOutcome = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutEntriesCompanion.insert(
            id: id,
            exerciseId: exerciseId,
            reps: reps,
            weight: weight,
            distance: distance,
            duration: duration,
            isComplete: isComplete,
            timestamp: timestamp,
            sessionId: sessionId,
            setOutcome: setOutcome,
            supersetGroupId: supersetGroupId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$WorkoutEntriesTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$WorkoutEntriesTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutEntriesTable,
    WorkoutEntryEntity,
    $$WorkoutEntriesTableFilterComposer,
    $$WorkoutEntriesTableOrderingComposer,
    $$WorkoutEntriesTableAnnotationComposer,
    $$WorkoutEntriesTableCreateCompanionBuilder,
    $$WorkoutEntriesTableUpdateCompanionBuilder,
    (WorkoutEntryEntity, $$WorkoutEntriesTableReferences),
    WorkoutEntryEntity,
    PrefetchHooks Function({bool exerciseId})>;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  required String id,
  required String name,
  Value<int> rowid,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> rowid,
});

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, WorkoutEntity> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutExercisesTable,
      List<WorkoutExerciseEntity>> _workoutExercisesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutExercises,
          aliasName: $_aliasNameGenerator(
              db.workouts.id, db.workoutExercises.workoutId));

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
            $_db, $_db.workoutExercises)
        .filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutExercisesRefs(
      Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutExercises,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutExercisesTableFilterComposer(
              $db: $db,
              $table: $db.workoutExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> workoutExercisesRefs<T extends Object>(
      Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutExercises,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    WorkoutEntity,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (WorkoutEntity, $$WorkoutsTableReferences),
    WorkoutEntity,
    PrefetchHooks Function({bool workoutExercisesRefs})> {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutsCompanion(
            id: id,
            name: name,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutsCompanion.insert(
            id: id,
            name: name,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WorkoutsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({workoutExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutExercisesRefs) db.workoutExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutExercisesRefs)
                    await $_getPrefetchedData<WorkoutEntity, $WorkoutsTable,
                            WorkoutExerciseEntity>(
                        currentTable: table,
                        referencedTable: $$WorkoutsTableReferences
                            ._workoutExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutsTableReferences(db, table, p0)
                                .workoutExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    WorkoutEntity,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (WorkoutEntity, $$WorkoutsTableReferences),
    WorkoutEntity,
    PrefetchHooks Function({bool workoutExercisesRefs})>;
typedef $$WorkoutExercisesTableCreateCompanionBuilder
    = WorkoutExercisesCompanion Function({
  required String id,
  required String workoutId,
  required String exerciseId,
  required int position,
  required int reps,
  required double weight,
  Value<double?> distance,
  Value<int?> duration,
  Value<DateTime?> timestamp,
  Value<String?> supersetGroupId,
  Value<int> rowid,
});
typedef $$WorkoutExercisesTableUpdateCompanionBuilder
    = WorkoutExercisesCompanion Function({
  Value<String> id,
  Value<String> workoutId,
  Value<String> exerciseId,
  Value<int> position,
  Value<int> reps,
  Value<double> weight,
  Value<double?> distance,
  Value<int?> duration,
  Value<DateTime?> timestamp,
  Value<String?> supersetGroupId,
  Value<int> rowid,
});

final class $$WorkoutExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutExercisesTable, WorkoutExerciseEntity> {
  $$WorkoutExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
          $_aliasNameGenerator(db.workoutExercises.workoutId, db.workouts.id));

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias($_aliasNameGenerator(
          db.workoutExercises.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableFilterComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableOrderingComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableAnnotationComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutExercisesTable,
    WorkoutExerciseEntity,
    $$WorkoutExercisesTableFilterComposer,
    $$WorkoutExercisesTableOrderingComposer,
    $$WorkoutExercisesTableAnnotationComposer,
    $$WorkoutExercisesTableCreateCompanionBuilder,
    $$WorkoutExercisesTableUpdateCompanionBuilder,
    (WorkoutExerciseEntity, $$WorkoutExercisesTableReferences),
    WorkoutExerciseEntity,
    PrefetchHooks Function({bool workoutId, bool exerciseId})> {
  $$WorkoutExercisesTableTableManager(
      _$AppDatabase db, $WorkoutExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<double?> distance = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<DateTime?> timestamp = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutExercisesCompanion(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            position: position,
            reps: reps,
            weight: weight,
            distance: distance,
            duration: duration,
            timestamp: timestamp,
            supersetGroupId: supersetGroupId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutId,
            required String exerciseId,
            required int position,
            required int reps,
            required double weight,
            Value<double?> distance = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<DateTime?> timestamp = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutExercisesCompanion.insert(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            position: position,
            reps: reps,
            weight: weight,
            distance: distance,
            duration: duration,
            timestamp: timestamp,
            supersetGroupId: supersetGroupId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workoutId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workoutId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutId,
                    referencedTable:
                        $$WorkoutExercisesTableReferences._workoutIdTable(db),
                    referencedColumn: $$WorkoutExercisesTableReferences
                        ._workoutIdTable(db)
                        .id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$WorkoutExercisesTableReferences._exerciseIdTable(db),
                    referencedColumn: $$WorkoutExercisesTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutExercisesTable,
    WorkoutExerciseEntity,
    $$WorkoutExercisesTableFilterComposer,
    $$WorkoutExercisesTableOrderingComposer,
    $$WorkoutExercisesTableAnnotationComposer,
    $$WorkoutExercisesTableCreateCompanionBuilder,
    $$WorkoutExercisesTableUpdateCompanionBuilder,
    (WorkoutExerciseEntity, $$WorkoutExercisesTableReferences),
    WorkoutExerciseEntity,
    PrefetchHooks Function({bool workoutId, bool exerciseId})>;
typedef $$ProgramsTableCreateCompanionBuilder = ProgramsCompanion Function({
  required String id,
  required String name,
  Value<bool> notificationEnabled,
  Value<int?> notificationTimeMinutes,
  Value<bool> isAiGenerated,
  Value<String?> generationContext,
  Value<int?> deloadWeek,
  Value<String?> weeklyProgressionNotes,
  Value<String?> coachIntro,
  Value<String?> coachRationale,
  Value<String?> coachRationaleSpoken,
  Value<String?> workoutBreakdowns,
  Value<String?> programmeDescriptionAudioRemotePath,
  Value<int> rowid,
});
typedef $$ProgramsTableUpdateCompanionBuilder = ProgramsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<bool> notificationEnabled,
  Value<int?> notificationTimeMinutes,
  Value<bool> isAiGenerated,
  Value<String?> generationContext,
  Value<int?> deloadWeek,
  Value<String?> weeklyProgressionNotes,
  Value<String?> coachIntro,
  Value<String?> coachRationale,
  Value<String?> coachRationaleSpoken,
  Value<String?> workoutBreakdowns,
  Value<String?> programmeDescriptionAudioRemotePath,
  Value<int> rowid,
});

final class $$ProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $ProgramsTable, ProgramEntity> {
  $$ProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProgramExercisesTable,
      List<ProgramExerciseEntity>> _programExercisesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.programExercises,
          aliasName: $_aliasNameGenerator(
              db.programs.id, db.programExercises.programId));

  $$ProgramExercisesTableProcessedTableManager get programExercisesRefs {
    final manager = $$ProgramExercisesTableTableManager(
            $_db, $_db.programExercises)
        .filter((f) => f.programId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_programExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationEnabled => $composableBuilder(
      column: $table.notificationEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationTimeMinutes => $composableBuilder(
      column: $table.notificationTimeMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAiGenerated => $composableBuilder(
      column: $table.isAiGenerated, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generationContext => $composableBuilder(
      column: $table.generationContext,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deloadWeek => $composableBuilder(
      column: $table.deloadWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weeklyProgressionNotes => $composableBuilder(
      column: $table.weeklyProgressionNotes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coachIntro => $composableBuilder(
      column: $table.coachIntro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coachRationale => $composableBuilder(
      column: $table.coachRationale,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coachRationaleSpoken => $composableBuilder(
      column: $table.coachRationaleSpoken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutBreakdowns => $composableBuilder(
      column: $table.workoutBreakdowns,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programmeDescriptionAudioRemotePath =>
      $composableBuilder(
          column: $table.programmeDescriptionAudioRemotePath,
          builder: (column) => ColumnFilters(column));

  Expression<bool> programExercisesRefs(
      Expression<bool> Function($$ProgramExercisesTableFilterComposer f) f) {
    final $$ProgramExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.programExercises,
        getReferencedColumn: (t) => t.programId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgramExercisesTableFilterComposer(
              $db: $db,
              $table: $db.programExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationEnabled => $composableBuilder(
      column: $table.notificationEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationTimeMinutes => $composableBuilder(
      column: $table.notificationTimeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAiGenerated => $composableBuilder(
      column: $table.isAiGenerated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generationContext => $composableBuilder(
      column: $table.generationContext,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deloadWeek => $composableBuilder(
      column: $table.deloadWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weeklyProgressionNotes => $composableBuilder(
      column: $table.weeklyProgressionNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coachIntro => $composableBuilder(
      column: $table.coachIntro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coachRationale => $composableBuilder(
      column: $table.coachRationale,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coachRationaleSpoken => $composableBuilder(
      column: $table.coachRationaleSpoken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutBreakdowns => $composableBuilder(
      column: $table.workoutBreakdowns,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programmeDescriptionAudioRemotePath =>
      $composableBuilder(
          column: $table.programmeDescriptionAudioRemotePath,
          builder: (column) => ColumnOrderings(column));
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get notificationEnabled => $composableBuilder(
      column: $table.notificationEnabled, builder: (column) => column);

  GeneratedColumn<int> get notificationTimeMinutes => $composableBuilder(
      column: $table.notificationTimeMinutes, builder: (column) => column);

  GeneratedColumn<bool> get isAiGenerated => $composableBuilder(
      column: $table.isAiGenerated, builder: (column) => column);

  GeneratedColumn<String> get generationContext => $composableBuilder(
      column: $table.generationContext, builder: (column) => column);

  GeneratedColumn<int> get deloadWeek => $composableBuilder(
      column: $table.deloadWeek, builder: (column) => column);

  GeneratedColumn<String> get weeklyProgressionNotes => $composableBuilder(
      column: $table.weeklyProgressionNotes, builder: (column) => column);

  GeneratedColumn<String> get coachIntro => $composableBuilder(
      column: $table.coachIntro, builder: (column) => column);

  GeneratedColumn<String> get coachRationale => $composableBuilder(
      column: $table.coachRationale, builder: (column) => column);

  GeneratedColumn<String> get coachRationaleSpoken => $composableBuilder(
      column: $table.coachRationaleSpoken, builder: (column) => column);

  GeneratedColumn<String> get workoutBreakdowns => $composableBuilder(
      column: $table.workoutBreakdowns, builder: (column) => column);

  GeneratedColumn<String> get programmeDescriptionAudioRemotePath =>
      $composableBuilder(
          column: $table.programmeDescriptionAudioRemotePath,
          builder: (column) => column);

  Expression<T> programExercisesRefs<T extends Object>(
      Expression<T> Function($$ProgramExercisesTableAnnotationComposer a) f) {
    final $$ProgramExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.programExercises,
        getReferencedColumn: (t) => t.programId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgramExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.programExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProgramsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgramsTable,
    ProgramEntity,
    $$ProgramsTableFilterComposer,
    $$ProgramsTableOrderingComposer,
    $$ProgramsTableAnnotationComposer,
    $$ProgramsTableCreateCompanionBuilder,
    $$ProgramsTableUpdateCompanionBuilder,
    (ProgramEntity, $$ProgramsTableReferences),
    ProgramEntity,
    PrefetchHooks Function({bool programExercisesRefs})> {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> notificationEnabled = const Value.absent(),
            Value<int?> notificationTimeMinutes = const Value.absent(),
            Value<bool> isAiGenerated = const Value.absent(),
            Value<String?> generationContext = const Value.absent(),
            Value<int?> deloadWeek = const Value.absent(),
            Value<String?> weeklyProgressionNotes = const Value.absent(),
            Value<String?> coachIntro = const Value.absent(),
            Value<String?> coachRationale = const Value.absent(),
            Value<String?> coachRationaleSpoken = const Value.absent(),
            Value<String?> workoutBreakdowns = const Value.absent(),
            Value<String?> programmeDescriptionAudioRemotePath =
                const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgramsCompanion(
            id: id,
            name: name,
            notificationEnabled: notificationEnabled,
            notificationTimeMinutes: notificationTimeMinutes,
            isAiGenerated: isAiGenerated,
            generationContext: generationContext,
            deloadWeek: deloadWeek,
            weeklyProgressionNotes: weeklyProgressionNotes,
            coachIntro: coachIntro,
            coachRationale: coachRationale,
            coachRationaleSpoken: coachRationaleSpoken,
            workoutBreakdowns: workoutBreakdowns,
            programmeDescriptionAudioRemotePath:
                programmeDescriptionAudioRemotePath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<bool> notificationEnabled = const Value.absent(),
            Value<int?> notificationTimeMinutes = const Value.absent(),
            Value<bool> isAiGenerated = const Value.absent(),
            Value<String?> generationContext = const Value.absent(),
            Value<int?> deloadWeek = const Value.absent(),
            Value<String?> weeklyProgressionNotes = const Value.absent(),
            Value<String?> coachIntro = const Value.absent(),
            Value<String?> coachRationale = const Value.absent(),
            Value<String?> coachRationaleSpoken = const Value.absent(),
            Value<String?> workoutBreakdowns = const Value.absent(),
            Value<String?> programmeDescriptionAudioRemotePath =
                const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgramsCompanion.insert(
            id: id,
            name: name,
            notificationEnabled: notificationEnabled,
            notificationTimeMinutes: notificationTimeMinutes,
            isAiGenerated: isAiGenerated,
            generationContext: generationContext,
            deloadWeek: deloadWeek,
            weeklyProgressionNotes: weeklyProgressionNotes,
            coachIntro: coachIntro,
            coachRationale: coachRationale,
            coachRationaleSpoken: coachRationaleSpoken,
            workoutBreakdowns: workoutBreakdowns,
            programmeDescriptionAudioRemotePath:
                programmeDescriptionAudioRemotePath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProgramsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({programExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (programExercisesRefs) db.programExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (programExercisesRefs)
                    await $_getPrefetchedData<ProgramEntity, $ProgramsTable,
                            ProgramExerciseEntity>(
                        currentTable: table,
                        referencedTable: $$ProgramsTableReferences
                            ._programExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProgramsTableReferences(db, table, p0)
                                .programExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.programId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProgramsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProgramsTable,
    ProgramEntity,
    $$ProgramsTableFilterComposer,
    $$ProgramsTableOrderingComposer,
    $$ProgramsTableAnnotationComposer,
    $$ProgramsTableCreateCompanionBuilder,
    $$ProgramsTableUpdateCompanionBuilder,
    (ProgramEntity, $$ProgramsTableReferences),
    ProgramEntity,
    PrefetchHooks Function({bool programExercisesRefs})>;
typedef $$ProgramExercisesTableCreateCompanionBuilder
    = ProgramExercisesCompanion Function({
  required int position,
  required String programId,
  required String workoutId,
  required DateTime scheduledDate,
  Value<int> rowid,
});
typedef $$ProgramExercisesTableUpdateCompanionBuilder
    = ProgramExercisesCompanion Function({
  Value<int> position,
  Value<String> programId,
  Value<String> workoutId,
  Value<DateTime> scheduledDate,
  Value<int> rowid,
});

final class $$ProgramExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $ProgramExercisesTable, ProgramExerciseEntity> {
  $$ProgramExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProgramsTable _programIdTable(_$AppDatabase db) =>
      db.programs.createAlias(
          $_aliasNameGenerator(db.programExercises.programId, db.programs.id));

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<String>('program_id')!;

    final manager = $$ProgramsTableTableManager($_db, $_db.programs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProgramExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramExercisesTable> {
  $$ProgramExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => ColumnFilters(column));

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.programId,
        referencedTable: $db.programs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgramsTableFilterComposer(
              $db: $db,
              $table: $db.programs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgramExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramExercisesTable> {
  $$ProgramExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate,
      builder: (column) => ColumnOrderings(column));

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.programId,
        referencedTable: $db.programs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgramsTableOrderingComposer(
              $db: $db,
              $table: $db.programs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgramExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramExercisesTable> {
  $$ProgramExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => column);

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.programId,
        referencedTable: $db.programs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgramsTableAnnotationComposer(
              $db: $db,
              $table: $db.programs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgramExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgramExercisesTable,
    ProgramExerciseEntity,
    $$ProgramExercisesTableFilterComposer,
    $$ProgramExercisesTableOrderingComposer,
    $$ProgramExercisesTableAnnotationComposer,
    $$ProgramExercisesTableCreateCompanionBuilder,
    $$ProgramExercisesTableUpdateCompanionBuilder,
    (ProgramExerciseEntity, $$ProgramExercisesTableReferences),
    ProgramExerciseEntity,
    PrefetchHooks Function({bool programId})> {
  $$ProgramExercisesTableTableManager(
      _$AppDatabase db, $ProgramExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> position = const Value.absent(),
            Value<String> programId = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<DateTime> scheduledDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgramExercisesCompanion(
            position: position,
            programId: programId,
            workoutId: workoutId,
            scheduledDate: scheduledDate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int position,
            required String programId,
            required String workoutId,
            required DateTime scheduledDate,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgramExercisesCompanion.insert(
            position: position,
            programId: programId,
            workoutId: workoutId,
            scheduledDate: scheduledDate,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProgramExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({programId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (programId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.programId,
                    referencedTable:
                        $$ProgramExercisesTableReferences._programIdTable(db),
                    referencedColumn: $$ProgramExercisesTableReferences
                        ._programIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProgramExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProgramExercisesTable,
    ProgramExerciseEntity,
    $$ProgramExercisesTableFilterComposer,
    $$ProgramExercisesTableOrderingComposer,
    $$ProgramExercisesTableAnnotationComposer,
    $$ProgramExercisesTableCreateCompanionBuilder,
    $$ProgramExercisesTableUpdateCompanionBuilder,
    (ProgramExerciseEntity, $$ProgramExercisesTableReferences),
    ProgramExerciseEntity,
    PrefetchHooks Function({bool programId})>;
typedef $$WorkoutSessionsTableCreateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  required String id,
  required String workoutId,
  required DateTime date,
  Value<String?> name,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$WorkoutSessionsTableUpdateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  Value<String> id,
  Value<String> workoutId,
  Value<DateTime> date,
  Value<String?> name,
  Value<String?> notes,
  Value<int> rowid,
});

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$WorkoutSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutSessionsTable,
    WorkoutSessionEntity,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (
      WorkoutSessionEntity,
      BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSessionEntity>
    ),
    WorkoutSessionEntity,
    PrefetchHooks Function()> {
  $$WorkoutSessionsTableTableManager(
      _$AppDatabase db, $WorkoutSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion(
            id: id,
            workoutId: workoutId,
            date: date,
            name: name,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutId,
            required DateTime date,
            Value<String?> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion.insert(
            id: id,
            workoutId: workoutId,
            date: date,
            name: name,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutSessionsTable,
    WorkoutSessionEntity,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (
      WorkoutSessionEntity,
      BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSessionEntity>
    ),
    WorkoutSessionEntity,
    PrefetchHooks Function()>;
typedef $$UserProfilesTableCreateCompanionBuilder = UserProfilesCompanion
    Function({
  required String id,
  Value<String?> primaryGoal,
  Value<int?> daysPerWeek,
  Value<int?> sessionLengthMinutes,
  Value<String?> equipment,
  Value<String?> experienceLevel,
  Value<String?> injuriesNotes,
  Value<double?> weightKg,
  Value<double?> heightCm,
  Value<DateTime?> onboardingCompletedAt,
  Value<int?> age,
  Value<String?> blockedDays,
  Value<int> rowid,
});
typedef $$UserProfilesTableUpdateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<String> id,
  Value<String?> primaryGoal,
  Value<int?> daysPerWeek,
  Value<int?> sessionLengthMinutes,
  Value<String?> equipment,
  Value<String?> experienceLevel,
  Value<String?> injuriesNotes,
  Value<double?> weightKg,
  Value<double?> heightCm,
  Value<DateTime?> onboardingCompletedAt,
  Value<int?> age,
  Value<String?> blockedDays,
  Value<int> rowid,
});

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryGoal => $composableBuilder(
      column: $table.primaryGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysPerWeek => $composableBuilder(
      column: $table.daysPerWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionLengthMinutes => $composableBuilder(
      column: $table.sessionLengthMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get injuriesNotes => $composableBuilder(
      column: $table.injuriesNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get onboardingCompletedAt => $composableBuilder(
      column: $table.onboardingCompletedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blockedDays => $composableBuilder(
      column: $table.blockedDays, builder: (column) => ColumnFilters(column));
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryGoal => $composableBuilder(
      column: $table.primaryGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysPerWeek => $composableBuilder(
      column: $table.daysPerWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionLengthMinutes => $composableBuilder(
      column: $table.sessionLengthMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get injuriesNotes => $composableBuilder(
      column: $table.injuriesNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get onboardingCompletedAt => $composableBuilder(
      column: $table.onboardingCompletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockedDays => $composableBuilder(
      column: $table.blockedDays, builder: (column) => ColumnOrderings(column));
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get primaryGoal => $composableBuilder(
      column: $table.primaryGoal, builder: (column) => column);

  GeneratedColumn<int> get daysPerWeek => $composableBuilder(
      column: $table.daysPerWeek, builder: (column) => column);

  GeneratedColumn<int> get sessionLengthMinutes => $composableBuilder(
      column: $table.sessionLengthMinutes, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel, builder: (column) => column);

  GeneratedColumn<String> get injuriesNotes => $composableBuilder(
      column: $table.injuriesNotes, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<DateTime> get onboardingCompletedAt => $composableBuilder(
      column: $table.onboardingCompletedAt, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get blockedDays => $composableBuilder(
      column: $table.blockedDays, builder: (column) => column);
}

class $$UserProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfileEntity,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfileEntity,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileEntity>
    ),
    UserProfileEntity,
    PrefetchHooks Function()> {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> primaryGoal = const Value.absent(),
            Value<int?> daysPerWeek = const Value.absent(),
            Value<int?> sessionLengthMinutes = const Value.absent(),
            Value<String?> equipment = const Value.absent(),
            Value<String?> experienceLevel = const Value.absent(),
            Value<String?> injuriesNotes = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<DateTime?> onboardingCompletedAt = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<String?> blockedDays = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesCompanion(
            id: id,
            primaryGoal: primaryGoal,
            daysPerWeek: daysPerWeek,
            sessionLengthMinutes: sessionLengthMinutes,
            equipment: equipment,
            experienceLevel: experienceLevel,
            injuriesNotes: injuriesNotes,
            weightKg: weightKg,
            heightCm: heightCm,
            onboardingCompletedAt: onboardingCompletedAt,
            age: age,
            blockedDays: blockedDays,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> primaryGoal = const Value.absent(),
            Value<int?> daysPerWeek = const Value.absent(),
            Value<int?> sessionLengthMinutes = const Value.absent(),
            Value<String?> equipment = const Value.absent(),
            Value<String?> experienceLevel = const Value.absent(),
            Value<String?> injuriesNotes = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<DateTime?> onboardingCompletedAt = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<String?> blockedDays = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesCompanion.insert(
            id: id,
            primaryGoal: primaryGoal,
            daysPerWeek: daysPerWeek,
            sessionLengthMinutes: sessionLengthMinutes,
            equipment: equipment,
            experienceLevel: experienceLevel,
            injuriesNotes: injuriesNotes,
            weightKg: weightKg,
            heightCm: heightCm,
            onboardingCompletedAt: onboardingCompletedAt,
            age: age,
            blockedDays: blockedDays,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfileEntity,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfileEntity,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileEntity>
    ),
    UserProfileEntity,
    PrefetchHooks Function()>;
typedef $$UserScorecardsTableCreateCompanionBuilder = UserScorecardsCompanion
    Function({
  required String id,
  Value<double> consistency,
  Value<double> progression,
  Value<double> endurance,
  Value<double> variety,
  Value<double> fundamentals,
  Value<double> selfAwareness,
  Value<double> curiosity,
  Value<double> reliability,
  Value<double> adaptability,
  Value<double> independence,
  Value<int> computedLevel,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$UserScorecardsTableUpdateCompanionBuilder = UserScorecardsCompanion
    Function({
  Value<String> id,
  Value<double> consistency,
  Value<double> progression,
  Value<double> endurance,
  Value<double> variety,
  Value<double> fundamentals,
  Value<double> selfAwareness,
  Value<double> curiosity,
  Value<double> reliability,
  Value<double> adaptability,
  Value<double> independence,
  Value<int> computedLevel,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$UserScorecardsTableFilterComposer
    extends Composer<_$AppDatabase, $UserScorecardsTable> {
  $$UserScorecardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get consistency => $composableBuilder(
      column: $table.consistency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progression => $composableBuilder(
      column: $table.progression, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get endurance => $composableBuilder(
      column: $table.endurance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get variety => $composableBuilder(
      column: $table.variety, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fundamentals => $composableBuilder(
      column: $table.fundamentals, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get selfAwareness => $composableBuilder(
      column: $table.selfAwareness, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get curiosity => $composableBuilder(
      column: $table.curiosity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get reliability => $composableBuilder(
      column: $table.reliability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get adaptability => $composableBuilder(
      column: $table.adaptability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get independence => $composableBuilder(
      column: $table.independence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get computedLevel => $composableBuilder(
      column: $table.computedLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$UserScorecardsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserScorecardsTable> {
  $$UserScorecardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get consistency => $composableBuilder(
      column: $table.consistency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progression => $composableBuilder(
      column: $table.progression, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get endurance => $composableBuilder(
      column: $table.endurance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get variety => $composableBuilder(
      column: $table.variety, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fundamentals => $composableBuilder(
      column: $table.fundamentals,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get selfAwareness => $composableBuilder(
      column: $table.selfAwareness,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get curiosity => $composableBuilder(
      column: $table.curiosity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get reliability => $composableBuilder(
      column: $table.reliability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get adaptability => $composableBuilder(
      column: $table.adaptability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get independence => $composableBuilder(
      column: $table.independence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get computedLevel => $composableBuilder(
      column: $table.computedLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$UserScorecardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserScorecardsTable> {
  $$UserScorecardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get consistency => $composableBuilder(
      column: $table.consistency, builder: (column) => column);

  GeneratedColumn<double> get progression => $composableBuilder(
      column: $table.progression, builder: (column) => column);

  GeneratedColumn<double> get endurance =>
      $composableBuilder(column: $table.endurance, builder: (column) => column);

  GeneratedColumn<double> get variety =>
      $composableBuilder(column: $table.variety, builder: (column) => column);

  GeneratedColumn<double> get fundamentals => $composableBuilder(
      column: $table.fundamentals, builder: (column) => column);

  GeneratedColumn<double> get selfAwareness => $composableBuilder(
      column: $table.selfAwareness, builder: (column) => column);

  GeneratedColumn<double> get curiosity =>
      $composableBuilder(column: $table.curiosity, builder: (column) => column);

  GeneratedColumn<double> get reliability => $composableBuilder(
      column: $table.reliability, builder: (column) => column);

  GeneratedColumn<double> get adaptability => $composableBuilder(
      column: $table.adaptability, builder: (column) => column);

  GeneratedColumn<double> get independence => $composableBuilder(
      column: $table.independence, builder: (column) => column);

  GeneratedColumn<int> get computedLevel => $composableBuilder(
      column: $table.computedLevel, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$UserScorecardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserScorecardsTable,
    UserScorecardEntity,
    $$UserScorecardsTableFilterComposer,
    $$UserScorecardsTableOrderingComposer,
    $$UserScorecardsTableAnnotationComposer,
    $$UserScorecardsTableCreateCompanionBuilder,
    $$UserScorecardsTableUpdateCompanionBuilder,
    (
      UserScorecardEntity,
      BaseReferences<_$AppDatabase, $UserScorecardsTable, UserScorecardEntity>
    ),
    UserScorecardEntity,
    PrefetchHooks Function()> {
  $$UserScorecardsTableTableManager(
      _$AppDatabase db, $UserScorecardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserScorecardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserScorecardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserScorecardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> consistency = const Value.absent(),
            Value<double> progression = const Value.absent(),
            Value<double> endurance = const Value.absent(),
            Value<double> variety = const Value.absent(),
            Value<double> fundamentals = const Value.absent(),
            Value<double> selfAwareness = const Value.absent(),
            Value<double> curiosity = const Value.absent(),
            Value<double> reliability = const Value.absent(),
            Value<double> adaptability = const Value.absent(),
            Value<double> independence = const Value.absent(),
            Value<int> computedLevel = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserScorecardsCompanion(
            id: id,
            consistency: consistency,
            progression: progression,
            endurance: endurance,
            variety: variety,
            fundamentals: fundamentals,
            selfAwareness: selfAwareness,
            curiosity: curiosity,
            reliability: reliability,
            adaptability: adaptability,
            independence: independence,
            computedLevel: computedLevel,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<double> consistency = const Value.absent(),
            Value<double> progression = const Value.absent(),
            Value<double> endurance = const Value.absent(),
            Value<double> variety = const Value.absent(),
            Value<double> fundamentals = const Value.absent(),
            Value<double> selfAwareness = const Value.absent(),
            Value<double> curiosity = const Value.absent(),
            Value<double> reliability = const Value.absent(),
            Value<double> adaptability = const Value.absent(),
            Value<double> independence = const Value.absent(),
            Value<int> computedLevel = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserScorecardsCompanion.insert(
            id: id,
            consistency: consistency,
            progression: progression,
            endurance: endurance,
            variety: variety,
            fundamentals: fundamentals,
            selfAwareness: selfAwareness,
            curiosity: curiosity,
            reliability: reliability,
            adaptability: adaptability,
            independence: independence,
            computedLevel: computedLevel,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserScorecardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserScorecardsTable,
    UserScorecardEntity,
    $$UserScorecardsTableFilterComposer,
    $$UserScorecardsTableOrderingComposer,
    $$UserScorecardsTableAnnotationComposer,
    $$UserScorecardsTableCreateCompanionBuilder,
    $$UserScorecardsTableUpdateCompanionBuilder,
    (
      UserScorecardEntity,
      BaseReferences<_$AppDatabase, $UserScorecardsTable, UserScorecardEntity>
    ),
    UserScorecardEntity,
    PrefetchHooks Function()>;
typedef $$SessionCheckInsTableCreateCompanionBuilder = SessionCheckInsCompanion
    Function({
  required String id,
  Value<String?> sessionId,
  Value<String?> programmeId,
  required String checkInType,
  required String rating,
  Value<String?> freeText,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SessionCheckInsTableUpdateCompanionBuilder = SessionCheckInsCompanion
    Function({
  Value<String> id,
  Value<String?> sessionId,
  Value<String?> programmeId,
  Value<String> checkInType,
  Value<String> rating,
  Value<String?> freeText,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SessionCheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionCheckInsTable> {
  $$SessionCheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programmeId => $composableBuilder(
      column: $table.programmeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkInType => $composableBuilder(
      column: $table.checkInType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get freeText => $composableBuilder(
      column: $table.freeText, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SessionCheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionCheckInsTable> {
  $$SessionCheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programmeId => $composableBuilder(
      column: $table.programmeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkInType => $composableBuilder(
      column: $table.checkInType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get freeText => $composableBuilder(
      column: $table.freeText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SessionCheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionCheckInsTable> {
  $$SessionCheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get programmeId => $composableBuilder(
      column: $table.programmeId, builder: (column) => column);

  GeneratedColumn<String> get checkInType => $composableBuilder(
      column: $table.checkInType, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get freeText =>
      $composableBuilder(column: $table.freeText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SessionCheckInsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionCheckInsTable,
    SessionCheckInEntity,
    $$SessionCheckInsTableFilterComposer,
    $$SessionCheckInsTableOrderingComposer,
    $$SessionCheckInsTableAnnotationComposer,
    $$SessionCheckInsTableCreateCompanionBuilder,
    $$SessionCheckInsTableUpdateCompanionBuilder,
    (
      SessionCheckInEntity,
      BaseReferences<_$AppDatabase, $SessionCheckInsTable, SessionCheckInEntity>
    ),
    SessionCheckInEntity,
    PrefetchHooks Function()> {
  $$SessionCheckInsTableTableManager(
      _$AppDatabase db, $SessionCheckInsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionCheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionCheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionCheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String?> programmeId = const Value.absent(),
            Value<String> checkInType = const Value.absent(),
            Value<String> rating = const Value.absent(),
            Value<String?> freeText = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionCheckInsCompanion(
            id: id,
            sessionId: sessionId,
            programmeId: programmeId,
            checkInType: checkInType,
            rating: rating,
            freeText: freeText,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> sessionId = const Value.absent(),
            Value<String?> programmeId = const Value.absent(),
            required String checkInType,
            required String rating,
            Value<String?> freeText = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionCheckInsCompanion.insert(
            id: id,
            sessionId: sessionId,
            programmeId: programmeId,
            checkInType: checkInType,
            rating: rating,
            freeText: freeText,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionCheckInsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionCheckInsTable,
    SessionCheckInEntity,
    $$SessionCheckInsTableFilterComposer,
    $$SessionCheckInsTableOrderingComposer,
    $$SessionCheckInsTableAnnotationComposer,
    $$SessionCheckInsTableCreateCompanionBuilder,
    $$SessionCheckInsTableUpdateCompanionBuilder,
    (
      SessionCheckInEntity,
      BaseReferences<_$AppDatabase, $SessionCheckInsTable, SessionCheckInEntity>
    ),
    SessionCheckInEntity,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$ExerciseFavoritesTableTableManager get exerciseFavorites =>
      $$ExerciseFavoritesTableTableManager(_db, _db.exerciseFavorites);
  $$WorkoutEntriesTableTableManager get workoutEntries =>
      $$WorkoutEntriesTableTableManager(_db, _db.workoutEntries);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutExercisesTableTableManager get workoutExercises =>
      $$WorkoutExercisesTableTableManager(_db, _db.workoutExercises);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$ProgramExercisesTableTableManager get programExercises =>
      $$ProgramExercisesTableTableManager(_db, _db.programExercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$UserScorecardsTableTableManager get userScorecards =>
      $$UserScorecardsTableTableManager(_db, _db.userScorecards);
  $$SessionCheckInsTableTableManager get sessionCheckIns =>
      $$SessionCheckInsTableTableManager(_db, _db.sessionCheckIns);
}
