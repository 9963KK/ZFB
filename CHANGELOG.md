# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.1] - 2025-02-10

### Added
- 食材重复检查功能
  - 添加食材时检查名称是否重复
  - 编辑食材时检查名称是否与其他食材重复
  - 添加重复提醒弹窗

### Changed
- 优化 Core Data 相关代码
  - 添加必要的 CoreData 导入
  - 改进数据库查询逻辑

### Fixed
- 修复编译错误
  - 修复 AddIngredientView 中缺少 CoreData 导入的问题
  - 修复 EditIngredientView 中 context 访问的问题

## [1.0.0] - 2025-02-09

### Added
- 基础食材管理功能
  - 添加食材
  - 编辑食材
  - 删除食材
- 食材分类系统
- 过期时间提醒
- 图片上传功能
- 本地数据持久化
