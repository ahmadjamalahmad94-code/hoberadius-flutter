// MikroTik network-programming models — mirror of the web
// `/api/v1/mikrotik/<id>/program*` contract (hotspot / pppoe wizard).

class ProgramCommand {
  const ProgramCommand({required this.path, required this.attrs});
  final String path;
  final Map<String, dynamic> attrs;

  factory ProgramCommand.fromJson(Map<String, dynamic> j) => ProgramCommand(
        path: j['path']?.toString() ?? '',
        attrs: _map(j['attrs']),
      );
}

class ProgramPlan {
  const ProgramPlan({
    required this.kind,
    required this.script,
    required this.summary,
    required this.warnings,
    required this.risks,
    required this.commands,
  });

  final String kind;
  final String script;
  final List<String> summary;
  final List<String> warnings;
  final List<String> risks;
  final List<ProgramCommand> commands;

  bool get hasRisks => risks.isNotEmpty;

  factory ProgramPlan.fromJson(Map<String, dynamic> j) => ProgramPlan(
        kind: j['kind']?.toString() ?? '',
        script: j['script']?.toString() ?? '',
        summary: _strList(j['summary']),
        warnings: _strList(j['warnings']),
        risks: _strList(j['risks']),
        commands: _list(j['commands']).map(ProgramCommand.fromJson).toList(),
      );
}

/// Result of `program/plan`: the plan + an optional change preview + a
/// backup-status warning string (empty if a fresh backup exists).
class ProgramPlanResult {
  const ProgramPlanResult({
    required this.plan,
    required this.backupWarning,
    required this.changePreview,
  });

  final ProgramPlan plan;
  final String backupWarning;
  final Map<String, dynamic> changePreview;

  factory ProgramPlanResult.fromJson(Map<String, dynamic> j) =>
      ProgramPlanResult(
        plan: ProgramPlan.fromJson(_map(j['plan'])),
        backupWarning: j['backup_warning_ar']?.toString() ?? '',
        changePreview: _map(j['change_preview']),
      );
}

/// Per-command execution step (from `dataclasses.asdict`; shape varies, so the
/// raw map is kept and the common fields surfaced).
class ProgramStep {
  const ProgramStep(this.raw);
  final Map<String, dynamic> raw;

  String get path => (raw['path'] ?? raw['target'] ?? '').toString();
  bool get ok => raw['ok'] == true || raw['status'] == 'ok';
  String get status => (raw['status'] ?? (ok ? 'ok' : 'failed')).toString();
  String get message =>
      (raw['message'] ?? raw['error'] ?? raw['detail'] ?? '').toString();

  factory ProgramStep.fromJson(Map<String, dynamic> j) => ProgramStep(j);
}

class ProgramApplyResult {
  const ProgramApplyResult({
    required this.ok,
    required this.error,
    required this.summary,
    required this.resultStatus,
    required this.steps,
  });

  final bool ok;
  final String error;
  final String summary;
  final String resultStatus;
  final List<ProgramStep> steps;

  factory ProgramApplyResult.fromJson(Map<String, dynamic> j) =>
      ProgramApplyResult(
        ok: j['ok'] == true,
        error: j['error']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        resultStatus: j['result_status']?.toString() ?? '',
        steps: _list(j['steps']).map(ProgramStep.fromJson).toList(),
      );
}

/// `program/apply` envelope (success path): the plan, the apply result, and
/// the safety evaluation.
class ProgramApplyResponse {
  const ProgramApplyResponse({required this.applyResult, required this.plan});
  final ProgramApplyResult applyResult;
  final ProgramPlan plan;

  factory ProgramApplyResponse.fromJson(Map<String, dynamic> j) =>
      ProgramApplyResponse(
        applyResult: ProgramApplyResult.fromJson(_map(j['apply_result'])),
        plan: ProgramPlan.fromJson(_map(j['plan'])),
      );
}

/// `program` GET: form defaults + live router state for building the form.
class ProgramState {
  const ProgramState({
    required this.nasName,
    required this.nasAddress,
    required this.kind,
    required this.formFields,
    required this.interfaces,
  });

  final String nasName;
  final String nasAddress;
  final String kind;
  final Map<String, dynamic> formFields;

  /// Live interface names from the router (best-effort; empty if unreachable).
  final List<String> interfaces;

  factory ProgramState.fromJson(Map<String, dynamic> j) {
    final nas = _map(j['nas']);
    final state = _map(j['router_state']);
    final ifaces = <String>[];
    for (final row in _list(state['interfaces'])) {
      final name = (row['name'] ?? row['.id'] ?? '').toString();
      if (name.isNotEmpty) ifaces.add(name);
    }
    return ProgramState(
      nasName: nas['name']?.toString() ?? '',
      nasAddress: nas['address']?.toString() ?? '',
      kind: j['kind']?.toString() ?? 'hotspot',
      formFields: _map(j['form_fields']),
      interfaces: ifaces,
    );
  }
}

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return const {};
}

List<Map<String, dynamic>> _list(Object? v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map(_map).toList();
}

List<String> _strList(Object? v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).toList();
}
