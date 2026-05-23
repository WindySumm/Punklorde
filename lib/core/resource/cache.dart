import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:punklorde/core/resource/model.dart';

class CacheService {
  late final Directory _cacheDir;

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'resource_cache'));
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
  }

  /// 获取缓存目录路径
  String get cacheDirPath => _cacheDir.path;

  /// 获取缓存文件路径（key 中可含 / 以使用子目录）
  String getCachePath(String key) {
    return p.join(_cacheDir.path, key);
  }

  /// 列出所有缓存条目
  Future<List<CacheEntry>> listCacheEntries() async {
    if (!await _cacheDir.exists()) return [];

    final entries = <CacheEntry>[];
    await for (final entity
        in _cacheDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final stat = await entity.stat();
        final relativePath = p.relative(entity.path, from: _cacheDir.path);
        entries.add(
          CacheEntry(
            key: p.split(relativePath).join('/'),
            filePath: entity.path,
            size: stat.size,
            lastModified: stat.modified,
            lastAccessed: stat.accessed,
          ),
        );
      }
    }
    entries.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return entries;
  }

  /// 获取缓存总大小（字节）
  Future<int> getTotalCacheSize() async {
    final entries = await listCacheEntries();
    var total = 0;
    for (final e in entries) {
      total += e.size;
    }
    return total;
  }

  /// 检查缓存是否存在且未过期
  Future<bool> isCacheValid(String key, Duration expiryDuration) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (!await file.exists()) return false;

    final stat = await file.stat();
    final age = DateTime.now().difference(stat.modified);
    return age < expiryDuration;
  }

  /// 读取缓存
  Future<String?> readCache(String key) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// 删除单个缓存
  Future<bool> deleteCache(String key) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      // 清理空父目录
      final dir = file.parent;
      if (dir.path != _cacheDir.path && await dir.exists()) {
        final contents = await dir.list().toList();
        if (contents.isEmpty) {
          await dir.delete();
        }
      }
      return true;
    }
    return false;
  }

  /// 清除所有缓存
  Future<int> clearAllCache() async {
    if (!await _cacheDir.exists()) return 0;

    var count = 0;
    await for (final entity
        in _cacheDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        count++;
      }
    }
    await _cacheDir.delete(recursive: true);
    await _cacheDir.create(recursive: true);
    return count;
  }

  /// 保存数据到缓存
  Future<String> saveCache(String key, List<int> data) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data, flush: true);
    return filePath;
  }
}