/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

library;

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';

import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_connectivity_package/connectivity.dart';
import 'package:carp_communication_package/communication.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_survey_package/survey.dart';
import 'package:carp_audio_package/media.dart';
import 'package:carp_apps_package/apps.dart';
import 'package:carp_health_package/health_package.dart';

import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';

part 'app.dart';
part 'services/bloc.dart';
part 'services/sensing.dart';
part 'sensing/surveys.dart';
part 'sensing/audio_user_task.dart';
part 'services/study_protocol_manager.dart';
part 'sensing/informed_consent.dart';
part 'view_models/probe_descriptions.dart';
part 'view_models/study_view_model.dart';
part 'view_models/task_list_view_model.dart';
part 'views/task_list_page.dart';
part 'views/data_viz_page.dart';
part 'views/study_page.dart';
part 'views/informed_consent_page.dart';
part 'views/cachet.dart';
part 'views/audio_measure_page.dart';

void main() {
  // Make sure to initialize CAMS and packages for json serialization
  CarpMobileSensing.ensureInitialized();
  ResearchPackage.ensureInitialized();
  CognitionPackage.ensureInitialized();

  runApp(const App());
}

final bloc = SensingBLoC();

String toJsonString(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);
