import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/api/client.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:punklorde/module/feature/chaoxing/view/widgets/chaoxing_webview.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:signals/signals_flutter.dart';
import 'package:punklorde/module/feature/chaoxing/view/widgets/simple_app_bar.dart';

class CourseActivePage extends StatefulWidget {
  final int classId;
  final int courseId;
  final String className;
  final String courseName;

  const CourseActivePage({
    super.key,
    required this.classId,
    required this.courseId,
    required this.className,
    required this.courseName,
  });

  @override
  State<CourseActivePage> createState() => _CourseActivePageState();
}

class _CourseActivePageState extends State<CourseActivePage> {
  final _tabIndex = signal(0);
  final _actives = signal<List<ActiveResult>>([]);
  final _loading = signal(true);
  final _activeType = <int, ActiveType>{};

  @override
  void initState() {
    super.initState();
    _loadActiveList();
  }

  Future<void> _loadActiveList() async {
    _loading.value = true;
    try {
      final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
      if (cred != null) {
        final cache = await AuthCredentialCache.fromCredential(cred);
        final api = ApiClient();
        final result = await api.getActives(
          cache,
          widget.courseId.toString(),
          widget.classId.toString(),
        );
        if (result != null) {
          for (final r in result) {
            _activeType[r.id] = r.getActiveType;
          }
          _actives.value = result;
        }
      }
    } catch (_) {
      // ignore
    } finally {
      _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabIndex.watch(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar.nested(
              title: widget.className,
              subtitle: widget.courseName,
            ),
            _buildTabBar(context, tab),
            Expanded(child: _buildTabContent(context, tab)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, int tab) {
    final colors = context.theme.colors;
    final labels = [
      t.submodule.chaoxing.course_activities, // 活动
      '考试',
      '作业',
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == tab;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tabIndex.value = i,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected
                          ? colors.foreground
                          : colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (selected)
                    Container(height: 2, width: 24, color: colors.primary)
                  else
                    const SizedBox(height: 2),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, int tab) {
    switch (tab) {
      case 0:
        return _buildActivesView();
      case 1:
        return _buildExamView();
      case 2:
        return _buildHomeworkView();
      default:
        return const SizedBox.shrink();
    }
  }

  // ===== 活动 Tab =====

  Widget _buildActivesView() {
    final actives = _actives.watch(context);
    final loading = _loading.watch(context);
    final colors = context.theme.colors;

    if (loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (actives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.clipboardList,
              size: 40,
              color: colors.mutedForeground.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              t.submodule.chaoxing.no_activities,
              style: TextStyle(fontSize: 15, color: colors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: actives.length,
        itemBuilder: (context, index) =>
            _buildActiveCard(context, actives[index]),
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, ActiveResult data) {
    final colors = context.theme.colors;
    final type = _activeType[data.id] ?? ActiveType.unknown;
    final typeLabel = _typeLabel(type, colors);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (typeLabel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeLabel.$2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        typeLabel.$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: typeLabel.$2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (data.description != null && data.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data.description!,
                  style: TextStyle(fontSize: 13, color: colors.mutedForeground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.startTime != null ? formatDate(data.startTime!) : '--',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (data.status != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: data.status == 1
                            ? Colors.green
                            : colors.mutedForeground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.status == 1 ? t.label.ongoing : t.label.ended,
                      style: TextStyle(
                        fontSize: 12,
                        color: data.status == 1
                            ? Colors.green
                            : colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color)? _typeLabel(ActiveType type, FColors colors) {
    switch (type) {
      case ActiveType.signIn:
        return ('签到', colors.primary);
      case ActiveType.signOut:
        return ('签退', colors.destructive);
      case ActiveType.scheduledSignIn:
        return ('定时签到', colors.primary);
      case ActiveType.unknown:
        return null;
    }
  }

  // ===== 考试 Tab =====

  Widget _buildExamView() {
    final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
    if (cred == null) {
      return const Center(child: Text('请先登录学习通'));
    }
    return ChaoxingWebView(
      config: ChaoxingWebViewConfig(
        url:
            'https://mooc1.chaoxing.com/exam-ans/exam/list?courseId=${widget.courseId}&classId=${widget.classId}',
        credential: cred,
        userAgent: cred.ext?["ua"],
      ),
    );
  }

  // ===== 作业 Tab =====

  Widget _buildHomeworkView() {
    final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
    if (cred == null) {
      return const Center(child: Text('请先登录学习通'));
    }
    return ChaoxingWebView(
      config: ChaoxingWebViewConfig(
        url:
            'https://mooc1.chaoxing.com/work/stu-work?courseId=${widget.courseId}&classId=${widget.classId}',
        credential: cred,
        userAgent: cred.ext?["ua"],
      ),
    );
  }
}
